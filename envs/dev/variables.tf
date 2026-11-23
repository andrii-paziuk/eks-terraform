variable "aws_region" {
  description = "AWS region where infrastructure will be deployed"
  type        = string
  default     = "ca-central-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
}

variable "tags" {
  description = "Common tags applied to all infrastructure resources"
  type        = map(string)

  default = {
    Project     = "alpha"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "Allowed IPv4 CIDRs for public EKS API access"
  type        = list(string)
}


variable "cluster_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.36"
}

variable "node_instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
}

variable "node_min_size" {
  description = "Minimum worker node count"
  type        = number
}

variable "node_max_size" {
  description = "Maximum worker node count"
  type        = number
}

variable "node_desired_size" {
  description = "Desired worker node count"
  type        = number
}
