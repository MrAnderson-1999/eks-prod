# VPC Module - Abstraction over terraform-aws-modules/vpc/aws
# This module provides a curated abstraction specifically for EKS deployment requirements

# Terraform and provider configuration managed by Terragrunt

locals {
  # Common tags for all resources
  common_tags = merge(var.tags, {
    Name        = var.name
    Environment = var.environment
    Region      = var.aws_region
    ManagedBy   = "Terraform"
    Purpose     = "EKS Infrastructure"
  })

  # VPC Endpoints required for EKS private clusters
  vpc_endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
    }
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
    }
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
    }
    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
    }
    sts = {
      service             = "sts"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
    }
    logs = {
      service             = "logs"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
    }
  }
}

# VPC using the official terraform-aws-modules/vpc/aws module
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.name}-${var.environment}"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  
  # Subnet naming with AZ suffix
  private_subnet_names = [
    for i, az in var.availability_zones : "${var.name}-${var.environment}-private-${substr(az, -1, 1)}"
  ]
  public_subnet_names = [
    for i, az in var.availability_zones : "${var.name}-${var.environment}-public-${substr(az, -1, 1)}"
  ]

  # NAT Gateway configuration
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  # Internet Gateway
  create_igw = true

  # DNS settings (required for EKS)
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC Flow Logs
  enable_flow_log                      = var.enable_flow_logs
  create_flow_log_cloudwatch_iam_role  = var.enable_flow_logs
  create_flow_log_cloudwatch_log_group = var.enable_flow_logs
  flow_log_cloudwatch_log_group_retention_in_days = var.flow_log_retention_days

  # EKS-specific subnet tags (Names set via subnet_names parameters)
  public_subnet_tags = merge({
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/subnets/role" = "public"
    "karpenter.sh/discovery" = "${var.name}-${var.environment}"
    "Type" = "Public"
    "Tier" = "Public"
  }, var.public_subnet_tags)

  private_subnet_tags = merge({
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/subnets/role" = "private"
    "karpenter.sh/discovery" = "${var.name}-${var.environment}"
    "Type" = "Private"
    "Tier" = "Private"
  }, var.private_subnet_tags)

  tags = local.common_tags
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.name}-${var.environment}-vpc-endpoints"
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id

  # Allow HTTPS traffic from VPC CIDR
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-${var.environment}-vpc-endpoints-sg"
  })
}

# VPC Endpoints using the official terraform-aws-modules/vpc/aws endpoints submodule
module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.0"

  vpc_id = module.vpc.vpc_id

  endpoints = local.vpc_endpoints

  tags = local.common_tags
}
