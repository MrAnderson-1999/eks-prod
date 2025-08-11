# Include root configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Set the source of the module
terraform {
  source = "${find_in_parent_folders("modules")}/vpc"
}

# Module-specific variables
inputs = {
  name                  = "eks-security-non-prod"
  environment          = "non-prod"
  aws_region           = "us-west-2"
  cluster_name         = "eks-security-non-prod"
  
  # VPC Configuration
  vpc_cidr = "10.0.0.0/16"
  
  # Availability Zones (3 AZs for resilience)
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  
  # Subnet Configuration
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  
  # NAT Gateway Configuration (Cost-optimized for non-prod)
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  
  # VPC Flow Logs
  enable_flow_logs         = true
  flow_log_retention_days  = 14
  
  # Tags
  tags = {
    Project     = "eks-security"
    Environment = "non-prod"
    ManagedBy   = "Terragrunt"
  }

  # Explicit subnet role tags for ALB auto-discovery
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}