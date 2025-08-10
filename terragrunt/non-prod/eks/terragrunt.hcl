# Include root configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Dependencies
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id                = "vpc-12345678"
    private_subnets       = ["subnet-12345678", "subnet-87654321"]
    public_subnets        = ["subnet-11111111", "subnet-22222222"]
    cluster_subnet_ids    = ["subnet-12345678", "subnet-87654321", "subnet-11111111", "subnet-22222222"]
    node_group_subnet_ids = ["subnet-12345678", "subnet-87654321"]
  }
}

# Set the source of the module - Using simple EKS approach
terraform {
  source = "../../../terraform/modules/eks"
  
  # Override to use simple configuration
  extra_arguments "simple" {
    commands = ["apply", "plan", "destroy"]
    env_vars = {
      TF_VAR_use_simple_config = "true"
    }
  }
}

inputs = {
  # Cluster Configuration
  cluster_name    = "eks-security-non-prod"
  cluster_version = "1.29"

  # Network Configuration
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnets

  # Access Configuration
  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # Node Groups Configuration - Simple and Clean
  eks_managed_node_groups = {
    system = {
      min_size     = 2
      max_size     = 4
      desired_size = 2
      
      instance_types = ["t3.medium"]
      capacity_type = "ON_DEMAND"
      
      labels = {
        Environment = "non-prod"
        NodeGroup   = "system"
      }
      
      update_config = {
        max_unavailable_percentage = 25
      }
    }
    
    workload = {
      min_size     = 1
      max_size     = 3
      desired_size = 1
      
      instance_types = ["t3.medium"]
      capacity_type = "ON_DEMAND"
      
      labels = {
        Environment = "non-prod"
        NodeGroup   = "workload"
      }
      
      update_config = {
        max_unavailable_percentage = 25
      }
    }
  }

  # Tags
  tags = {
    Environment = "non-prod"
    Project     = "eks-security"
    ManagedBy   = "Terraform"
    Purpose     = "EKS Cluster"
  }
}