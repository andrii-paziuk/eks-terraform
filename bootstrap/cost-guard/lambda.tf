data "archive_file" "cost_guard" {
  type        = "zip"
  source_file = "${path.module}/lambda/cost_guard.py"
  output_path = "${path.module}/cost_guard.zip"
}

resource "aws_lambda_function" "cost_guard" {
  function_name = "${var.project_name}-cost-guard"
  description   = "Monitors EKS cluster runtime and sends alerts"
  role          = aws_iam_role.cost_guard_lambda.arn

  runtime          = "python3.12"
  handler          = "cost_guard.lambda_handler"
  filename         = data.archive_file.cost_guard.output_path
  source_code_hash = data.archive_file.cost_guard.output_base64sha256

  timeout     = 30
  memory_size = 128

  environment {
    variables = {
      CLUSTER_NAME        = var.cluster_name
      ALERT_AFTER_MINUTES = tostring(var.alert_after_minutes)
      SNS_TOPIC_ARN       = aws_sns_topic.cost_guard.arn
      DYNAMODB_TABLE      = aws_dynamodb_table.cost_guard_alerts.name
      PROJECT_NAME        = var.project_name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy.cost_guard_lambda
  ]

  tags = {
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}
