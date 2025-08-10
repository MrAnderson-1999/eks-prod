# Include root configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id             = "vpc-fake"
    private_subnets    = ["subnet-fake1", "subnet-fake2"]
    vpc_cidr_block     = "10.0.0.0/16"
  }
}

dependency "kms" {
  config_path = "./kms"
  mock_outputs = {
    kms_keys = {
      eks_security = {
        arn = "arn:aws:kms:us-west-2:123456789012:key/fake"
      }
    }
  }
}

dependency "iam_roles" {
  config_path = "../iam-roles"
  mock_outputs = {
    role_arns = {
      eks_cluster    = "arn:aws:iam::123456789012:role/fake-cluster-role"
      eks_node_group = "arn:aws:iam::123456789012:role/fake-node-role"
    }
  }
}

dependency "security" {
  config_path = "../security"
  mock_outputs = {
    security_group_ids = {
      eks_nodes = "sg-fake"
    }
  }
}

terraform {
  source = "../../../terraform/modules/eks"
}

inputs = {
  cluster_name    = "eks-security-prod"
  cluster_version = "1.29"

  # Network Configuration
  vpc_id              = dependency.vpc.outputs.vpc_id
  private_subnet_ids  = dependency.vpc.outputs.private_subnets
  vpc_cidr_blocks     = [dependency.vpc.outputs.vpc_cidr_block]

  # Security Configuration
  kms_key_arn                   = dependency.kms.outputs.kms_keys.eks_security.arn
  cluster_service_role_arn      = dependency.iam_roles.outputs.role_arns.eks_cluster
  node_group_role_arn          = dependency.iam_roles.outputs.role_arns.eks_node_group
  additional_security_group_ids = [dependency.security.outputs.security_group_ids.eks_nodes]

  # Node Configuration - Production sizing
  node_instance_types = ["t3.large"]
  node_capacity_type  = "ON_DEMAND"
  node_min_size      = 2
  node_max_size      = 6
  node_desired_size  = 3

  tags = {
    Environment = "prod"
    Project     = "eks-security"
    ManagedBy   = "Terragrunt"
  }
}