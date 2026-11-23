data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(
    data.aws_availability_zones.available.names,
    0,
    var.az_count
  )

  common_tags = merge(var.tags, {
    ManagedBy = "Terraform"
    Module    = "networking"
  })
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.8.0"

  name = var.name
  cidr = var.vpc_cidr

  azs             = local.azs
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  # NAT Gateway configuration
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  # DNS
  enable_dns_support   = true
  enable_dns_hostnames = true

  # Public subnet configuration
  map_public_ip_on_launch = true

  # Route tables
  create_multiple_public_route_tables = false

  # Kubernetes subnet discovery
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery"           = var.cluster_name
  }

  tags = local.common_tags
}

# CloudWatch Log Group for VPC Flow Logs

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/${var.name}/flow-logs"
  retention_in_days = var.flow_logs_retention_days

  tags = local.common_tags
}

# IAM Role for VPC Flow Logs

data "aws_iam_policy_document" "flow_logs_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "flow_logs" {
  name               = "${var.name}-vpc-flow-logs"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume_role.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "flow_logs" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]

    resources = [
      "${aws_cloudwatch_log_group.flow_logs.arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  name   = "${var.name}-vpc-flow-logs"
  role   = aws_iam_role.flow_logs.id
  policy = data.aws_iam_policy_document.flow_logs.json
}

resource "aws_flow_log" "this" {
  vpc_id                   = module.vpc.vpc_id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.flow_logs.arn
  iam_role_arn             = aws_iam_role.flow_logs.arn
  max_aggregation_interval = 60

  depends_on = [
    aws_iam_role_policy.flow_logs
  ]

  tags = local.common_tags
}
