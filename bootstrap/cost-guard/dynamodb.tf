resource "aws_dynamodb_table" "cost_guard_alerts" {
  name         = "${var.project_name}-cost-guard-alerts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "alert_id"

  attribute {
    name = "alert_id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}
