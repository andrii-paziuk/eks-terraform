resource "aws_sns_topic" "cost_guard" {
  name = "${var.project_name}-cost-guard-alerts"

  tags = {
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.notification_emails)

  topic_arn = aws_sns_topic.cost_guard.arn
  protocol  = "email"
  endpoint  = each.value
}
