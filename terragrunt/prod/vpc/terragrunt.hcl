# Include environment configuration (which includes backend and root)
include "env" {
  path = find_in_parent_folders("root.hcl")
}

# Set the source of the module
terraform {
  source = "../../../terraform/modules/vpc"
}

# Module-specific variables
inputs = {
  name                  = "eks-security"
  environment          = "prod"
  aws_region           = "us-west-2"
  
  # VPC Configuration
  vpc_cidr = "10.1.0.0/16"
  
  # Availability Zones (3 AZs for production)
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  
  # Subnet Configuration
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
  
  # NAT Gateway Configuration (High Availability for production)
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  
  # VPC Flow Logs
  enable_flow_logs         = true
  flow_log_retention_days  = 30
  
  # Tags
  tags = {
    Project     = "eks-security"
    Environment = "prod"
    Owner       = "platform-team"
    ManagedBy   = "Terragrunt"
  }
}