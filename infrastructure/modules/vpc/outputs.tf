# VPC Module Outputs

# VPC Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = module.vpc.default_security_group_id
}

# Subnet Information
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = module.vpc.private_subnet_arns
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = module.vpc.public_subnet_arns
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = module.vpc.private_subnets_cidr_blocks
}

output "public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = module.vpc.public_subnets_cidr_blocks
}

# Internet Gateway
output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

output "igw_arn" {
  description = "The ARN of the Internet Gateway"
  value       = module.vpc.igw_arn
}

# NAT Gateway
output "nat_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = module.vpc.natgw_ids
}

output "nat_public_ips" {
  description = "List of public Elastic IPs of NAT Gateways"
  value       = module.vpc.nat_public_ips
}

# Route Tables
output "private_route_table_ids" {
  description = "List of IDs of the private route tables"
  value       = module.vpc.private_route_table_ids
}

output "public_route_table_ids" {
  description = "List of IDs of the public route tables"
  value       = module.vpc.public_route_table_ids
}

# VPC Endpoints
output "vpc_endpoint_s3_id" {
  description = "The ID of VPC endpoint for S3"
  value       = try(module.vpc_endpoints.endpoints["s3"]["id"], null)
}

output "vpc_endpoint_ec2_id" {
  description = "The ID of VPC endpoint for EC2"
  value       = try(module.vpc_endpoints.endpoints["ec2"]["id"], null)
}

output "vpc_endpoint_ecr_api_id" {
  description = "The ID of VPC endpoint for ECR API"
  value       = try(module.vpc_endpoints.endpoints["ecr_api"]["id"], null)
}

output "vpc_endpoint_ecr_dkr_id" {
  description = "The ID of VPC endpoint for ECR DKR"
  value       = try(module.vpc_endpoints.endpoints["ecr_dkr"]["id"], null)
}

output "vpc_endpoint_logs_id" {
  description = "The ID of VPC endpoint for CloudWatch Logs"
  value       = try(module.vpc_endpoints.endpoints["logs"]["id"], null)
}

output "vpc_endpoint_sts_id" {
  description = "The ID of VPC endpoint for STS"
  value       = try(module.vpc_endpoints.endpoints["sts"]["id"], null)
}

output "vpc_endpoint_kms_id" {
  description = "The ID of VPC endpoint for KMS (if enabled)"
  value       = try(module.vpc_endpoints.endpoints["kms"]["id"], null)
}

output "vpc_endpoint_elasticloadbalancing_id" {
  description = "The ID of VPC endpoint for Elastic Load Balancing"
  value       = try(module.vpc_endpoints.endpoints["elasticloadbalancing"]["id"], null)
}

output "vpc_endpoint_autoscaling_id" {
  description = "The ID of VPC endpoint for Auto Scaling"
  value       = try(module.vpc_endpoints.endpoints["autoscaling"]["id"], null)
}

# Security Groups
output "vpc_endpoints_security_group_id" {
  description = "Security group ID for VPC endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

# Additional outputs for EKS integration
output "cluster_subnet_group_name" {
  description = "Name to use for EKS cluster subnet group (combination of public and private subnets)"
  value       = "${var.name}-${var.environment}-cluster-subnets"
}

output "node_group_subnet_ids" {
  description = "Subnet IDs for EKS node groups (private subnets only)"
  value       = module.vpc.private_subnets
}

output "cluster_subnet_ids" {
  description = "Subnet IDs for EKS cluster (combination of public and private subnets)"
  value       = concat(module.vpc.public_subnets, module.vpc.private_subnets)
}
