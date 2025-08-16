# Include root configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

# Set the source of the module
terraform {
  source = "${find_in_parent_folders("modules")}/vpc"
}

# Module-specific variables
inputs = {
  name                  = "${local.environment_vars.locals.name}-vpc"
  environment          = local.environment_vars.locals.stage
  aws_region           = local.environment_vars.locals.region
  cluster_name         = local.environment_vars.locals.cluster_name
  
  # VPC Configuration
  vpc_cidr = "10.0.0.0/16"
  
  # Availability Zones (2 AZs - following AWS EKS official template)
  availability_zones = ["us-west-2a", "us-west-2b"]
  
  # Subnet Configuration (Following AWS official EKS template /18 subnets)
  # Public subnets: 192.168.0.0/18 (0-63.255), 192.168.64.0/18 (64-127.255)
  # Private subnets: 192.168.128.0/18 (128-191.255), 192.168.192.0/18 (192-255.255)
  public_subnets  = ["10.0.0.0/18", "10.0.64.0/18"]       # 16,384 IPs each
  private_subnets = ["10.0.128.0/18", "10.0.192.0/18"]    # 16,384 IPs each
  
  # NAT Gateway Configuration (High Availability - one per AZ)
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  
  # VPC Flow Logs
  enable_flow_logs         = true
  flow_log_retention_days  = 14
  
  # Tags
  tags = {
    Project     = local.environment_vars.locals.name
    Environment = local.environment_vars.locals.stage
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