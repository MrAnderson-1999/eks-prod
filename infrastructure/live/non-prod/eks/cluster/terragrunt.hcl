include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../../vpc"
  mock_outputs = {
    vpc_id          = "vpc-mock"
    private_subnets = ["subnet-mock1", "subnet-mock2"]
    vpc_cidr_block  = "10.0.0.0/16"
  }
}

dependency "kms" {
  config_path = "../../kms"
  mock_outputs = {
    kms_keys = {
      eks_security = {
        arn = "arn:aws:kms:us-west-2:123456789012:key/mock-key-id"
      }
    }
  }
}

dependency "global_roles" {
  config_path = "../../roles/global"
  mock_outputs = {
    role_arns = {
      eks_cluster                 = "arn:aws:iam::123456789012:role/mock-eks-cluster-role"
      eks_fargate_pod_execution  = "arn:aws:iam::123456789012:role/mock-fargate-role"
    }
  }
}

dependency "security" {
  config_path = "../../security"
  mock_outputs = {
    security_group_ids = {
      eks_nodes = "sg-mock"
    }
  }
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}


terraform {
  source = "${find_in_parent_folders("modules")}/eks"
}

inputs = {
  cluster_name    = local.environment_vars.inputs.cluster_name
  cluster_version = "1.32" # Latest Kubernetes version

  # Network Configuration
  vpc_id              = dependency.vpc.outputs.vpc_id
  private_subnet_ids  = dependency.vpc.outputs.private_subnets
  vpc_cidr_blocks     = [dependency.vpc.outputs.vpc_cidr_block]

  # Security Configuration
  kms_key_arn                   = dependency.kms.outputs.kms_keys.eks_security.arn
  cluster_service_role_arn      = dependency.global_roles.outputs.role_arns.eks_cluster
  fargate_profile_role_arn      = dependency.global_roles.outputs.role_arns.eks_fargate_pod_execution
  additional_security_group_ids = [dependency.security.outputs.security_group_ids.eks_nodes]

  # Fargate Configuration - Serverless container hosting
  enable_fargate = true

  # Enable IRSA (required for ALB Controller on Fargate)
  enable_irsa = true

  tags = {
    Environment = "non-prod"
    Project     = "eks-security"
    ManagedBy   = "Terragrunt"
  }
  

}
