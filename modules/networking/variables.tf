variable "name" {
  description = "Name of the VPC"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "az_count" {
  description = "Number of Availability Zones"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count == 2
    error_message = "This platform currently requires exactly two Availability Zones."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == var.az_count
    error_message = "The number of public subnets must match az_count."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == var.az_count
    error_message = "The number of private subnets must match az_count."
  }
}

variable "flow_logs_retention_days" {
  description = "CloudWatch retention period for VPC Flow Logs"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
