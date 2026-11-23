resource "aws_cloudwatch_event_rule" "cost_guard" {
  name                = "${var.project_name}-cost-guard-check"
  description         = "Run Cost Guard periodically"
  schedule_expression = "rate(${var.check_interval_minutes} minutes)"

  tags = {
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

resource "aws_cloudwatch_event_target" "cost_guard" {
  rule      = aws_cloudwatch_event_rule.cost_guard.name
  target_id = "CostGuardLambda"
  arn       = aws_lambda_function.cost_guard.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_guard.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_guard.arn
}