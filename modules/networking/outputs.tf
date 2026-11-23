output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "availability_zones" {
  description = "Availability Zones used by the VPC"
  value       = local.azs
}

output "nat_public_ips" {
  description = "Public IP addresses of NAT Gateways"
  value       = module.vpc.nat_public_ips
}

output "flow_log_group_arn" {
  description = "CloudWatch Log Group ARN for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.flow_logs.arn
}
