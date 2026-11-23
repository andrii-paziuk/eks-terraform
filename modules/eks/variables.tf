variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS"
  type        = list(string)
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "Allowed CIDRs for public Kubernetes API access"
  type        = list(string)
}

variable "node_instance_types" {
  description = "EC2 instance types for managed node group"
  type        = list(string)
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
