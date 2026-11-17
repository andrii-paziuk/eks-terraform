variable "bucket_name" {
  description = "Name of the S3 bucket used for Terraform state"
  type        = string
}

variable "bucket_description" {
  description = "Description of the S3 bucket"
  type        = string
}

variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
}
