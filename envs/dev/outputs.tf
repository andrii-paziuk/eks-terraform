output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "availability_zones" {
  description = "Availability Zones"
  value       = module.networking.availability_zones
}

output "nat_public_ips" {
  description = "NAT Gateway public IPs"
  value       = module.networking.nat_public_ips
}
