import os
import json
import logging
import hashlib
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

REGION = os.environ["AWS_REGION"]
CLUSTER_NAME = os.environ["CLUSTER_NAME"]
PROJECT_NAME = os.environ["PROJECT_NAME"]
ALERT_AFTER_MINUTES = int(os.environ["ALERT_AFTER_MINUTES"])
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
DYNAMODB_TABLE = os.environ["DYNAMODB_TABLE"]

eks = boto3.client("eks", region_name=REGION)
ec2 = boto3.client("ec2", region_name=REGION)
elbv2 = boto3.client("elbv2", region_name=REGION)
sns = boto3.client("sns", region_name=REGION)
dynamodb = boto3.resource("dynamodb", region_name=REGION)

table = dynamodb.Table(DYNAMODB_TABLE)


def send_alert(alert_id, subject, message):
    """Send an alert once, using DynamoDB for deduplication."""

    try:
        table.put_item(
            Item={
                "alert_id": alert_id,
                "alerted_at": datetime.now(timezone.utc).isoformat(),
            },
            ConditionExpression="attribute_not_exists(alert_id)",
        )
    except ClientError as error:
        if error.response["Error"]["Code"] == "ConditionalCheckFailedException":
            logger.info("Alert already sent: %s", alert_id)
            return False
        raise

    try:
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject[:100],
            Message=message,
        )
    except Exception:
        table.delete_item(Key={"alert_id": alert_id})
        raise

    logger.info("Alert sent: %s", alert_id)
    return True


def get_tagged_resources():
    """Find selected AWS resources carrying Project=<project name>."""

    tag_filter = [{"Name": "tag:Project", "Values": [PROJECT_NAME]}]
    resources = []

    # NAT Gateways
    nat_response = ec2.describe_nat_gateways(
        Filter=tag_filter + [
            {
                "Name": "state",
                "Values": ["pending", "available", "failed"],
            }
        ]
    )

    for nat in nat_response.get("NatGateways", []):
        resources.append({
            "type": "NAT Gateway",
            "id": nat["NatGatewayId"],
            "state": nat["State"],
        })

    # EC2 instances (exclude terminated instances)
    paginator = ec2.get_paginator("describe_instances")

    for page in paginator.paginate(
        Filters=tag_filter + [
            {
                "Name": "instance-state-name",
                "Values": ["pending", "running", "stopping", "stopped"],
            }
        ]
    ):
        for reservation in page.get("Reservations", []):
            for instance in reservation.get("Instances", []):
                resources.append({
                    "type": "EC2 Instance",
                    "id": instance["InstanceId"],
                    "state": instance["State"]["Name"],
                })

    # EBS volumes (exclude deleted volumes)
    volume_response = ec2.describe_volumes(
        Filters=tag_filter
    )

    for volume in volume_response.get("Volumes", []):
        resources.append({
            "type": "EBS Volume",
            "id": volume["VolumeId"],
            "state": volume["State"],
        })

    # Elastic IP addresses
    address_response = ec2.describe_addresses(
        Filters=tag_filter
    )

    for address in address_response.get("Addresses", []):
        resources.append({
            "type": "Elastic IP",
            "id": address.get("AllocationId", address.get("PublicIp", "unknown")),
            "public_ip": address.get("PublicIp", "unknown"),
        })

    # Application / Network / Gateway Load Balancers
    paginator = elbv2.get_paginator("describe_load_balancers")

    for page in paginator.paginate():
        load_balancers = page.get("LoadBalancers", [])

        if not load_balancers:
            continue

        arns = [lb["LoadBalancerArn"] for lb in load_balancers]

        tag_response = elbv2.describe_tags(
            ResourceArns=arns
        )

        for item in tag_response.get("TagDescriptions", []):
            tags = {
                tag["Key"]: tag["Value"]
                for tag in item.get("Tags", [])
            }

            if tags.get("Project") == PROJECT_NAME:
                lb = next(
                    lb for lb in load_balancers
                    if lb["LoadBalancerArn"] == item["ResourceArn"]
                )

                resources.append({
                    "type": "Load Balancer",
                    "id": lb["LoadBalancerArn"].split("/")[-1],
                    "state": lb.get("State", {}).get("Code", "unknown"),
                })

    return resources


def check_orphaned_resources(resources=None):
    """Check for tagged resources when the EKS cluster is absent."""

    if resources is None:
        resources = get_tagged_resources()

    if not resources:
        logger.info("No tagged orphaned resources found.")
        return {"status": "no_orphaned_resources"}

    resource_ids = sorted(
        f"{resource['type']}:{resource['id']}"
        for resource in resources
    )

    fingerprint = hashlib.sha256(
        "|".join(resource_ids).encode("utf-8")
    ).hexdigest()[:24]

    alert_id = f"orphan-resources#{fingerprint}"

    resource_lines = [
        f"- {item['type']}: {item['id']} "
        f"(state: {item.get('state', 'unknown')})"
        for item in resources
    ]

    message = (
        "ALPHA COST GUARD - POSSIBLE ORPHANED RESOURCES\n\n"
        f"EKS cluster: {CLUSTER_NAME} was not found.\n"
        f"Region: {REGION}\n"
        f"Project tag: Project={PROJECT_NAME}\n\n"
        "The following tagged resources still exist:\n\n"
        + "\n".join(resource_lines)
        + "\n\nReview these resources in AWS Console. "
        "They may continue generating charges."
    )

    sent = send_alert(
        alert_id=alert_id,
        subject="ALPHA: Possible orphaned AWS resources",
        message=message,
    )

    return {
        "status": "orphan_resources_found",
        "resource_count": len(resources),
        "alert_sent": sent,
    }


def lambda_handler(event, context):
    logger.info("Starting ALPHA Cost Guard inspection")

    # Always inventory tagged resources, regardless of EKS status.
    resources = get_tagged_resources()

    logger.info(
        "Resource inventory: %s",
        json.dumps(resources, default=str),
    )

    logger.info(
        "Found %d resources tagged Project=%s",
        len(resources),
        PROJECT_NAME,
    )

    try:
        response = eks.describe_cluster(name=CLUSTER_NAME)

    except eks.exceptions.ResourceNotFoundException:
        logger.warning("EKS cluster %s was not found.", CLUSTER_NAME)

        return check_orphaned_resources(resources)

    cluster = response["cluster"]
    created_at = cluster["createdAt"]
    now = datetime.now(timezone.utc)

    runtime_minutes = (
        now - created_at
    ).total_seconds() / 60

    logger.info(
        "Cluster status: %s, runtime: %.1f minutes",
        cluster["status"],
        runtime_minutes,
    )

    if runtime_minutes <= ALERT_AFTER_MINUTES:
        return {
            "status": "within_limit",
            "runtime_minutes": round(runtime_minutes, 2),
            "resource_count": len(resources),
        }

    alert_id = f"{CLUSTER_NAME}#{created_at.isoformat()}"

    message = (
        "ALPHA COST GUARD ALERT\n\n"
        f"EKS cluster: {CLUSTER_NAME}\n"
        f"Region: {REGION}\n"
        f"Cluster status: {cluster['status']}\n"
        f"Runtime: {runtime_minutes:.1f} minutes\n"
        f"Alert threshold: {ALERT_AFTER_MINUTES} minutes\n"
        f"Tagged resources found: {len(resources)}\n\n"
        "The cluster has exceeded the configured runtime limit. "
        "Review whether it should be destroyed."
    )

    sent = send_alert(
        alert_id=alert_id,
        subject=f"ALPHA: EKS exceeded {ALERT_AFTER_MINUTES} minutes",
        message=message,
    )

    return {
        "status": "alert_sent" if sent else "already_alerted",
        "runtime_minutes": round(runtime_minutes, 2),
        "resource_count": len(resources),
    }

def test_orphan_detection(event, context):
    return check_orphaned_resources()