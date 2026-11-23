output "sns_topic_arn" {
  description = "SNS topic ARN for Cost Guard alerts"
  value       = aws_sns_topic.cost_guard.arn
}

output "dynamodb_table_name" {
  description = "DynamoDB table storing sent alerts"
  value       = aws_dynamodb_table.cost_guard_alerts.name
}

output "lambda_function_name" {
  description = "Cost Guard Lambda function name"
  value       = aws_lambda_function.cost_guard.function_name
}

output "eventbridge_rule_name" {
  description = "EventBridge rule name"
  value       = aws_cloudwatch_event_rule.cost_guard.name
}