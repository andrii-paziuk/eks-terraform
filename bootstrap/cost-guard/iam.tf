data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cost_guard_lambda" {
  name               = "${var.project_name}-cost-guard-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.cost_guard_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "cost_guard_lambda" {
  statement {
    sid       = "ReadEKSCluster"
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = ["*"]
  }

  statement {
    sid       = "PublishAlerts"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.cost_guard.arn]
  }

  statement {
    sid    = "ManageAlertRecords"
    effect = "Allow"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]

    resources = [aws_dynamodb_table.cost_guard_alerts.arn]
  }

  statement {
    sid    = "DetectOrphanedResources"
    effect = "Allow"

    actions = [
      "ec2:DescribeNatGateways",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes",
      "ec2:DescribeAddresses",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTags"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cost_guard_lambda" {
  name   = "${var.project_name}-cost-guard-lambda"
  role   = aws_iam_role.cost_guard_lambda.id
  policy = data.aws_iam_policy_document.cost_guard_lambda.json
}
