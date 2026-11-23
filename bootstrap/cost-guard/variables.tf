variable "aws_region" {
  description = "AWS region where Cost Guard is deployed"
  type        = string
  default     = "ca-central-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "alpha"
}

variable "cluster_name" {
  description = "EKS cluster monitored by Cost Guard"
  type        = string
  default     = "alpha-dev-eks"
}

variable "notification_emails" {
  description = "Email addresses receiving Cost Guard alerts"
  type        = list(string)

  validation {
    condition     = length(var.notification_emails) > 0
    error_message = "At least one notification email must be provided."
  }
}

variable "alert_after_minutes" {
  description = "Alert when the EKS cluster runs longer than this many minutes"
  type        = number
  default     = 60
}

variable "check_interval_minutes" {
  description = "How often Cost Guard checks the cluster"
  type        = number
  default     = 5

  validation {
    condition     = var.check_interval_minutes >= 1
    error_message = "Check interval must be at least 1 minute."
  }
}
