include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "eks" {
  config_path = "../eks"
  mock_outputs = {
    cluster_name = "mock-cluster"
  }
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-mock"
  }
}

dependency "irsa_roles" {
  config_path = "../eks-irsa-roles"
  mock_outputs = {
    role_arns = {
      aws_load_balancer_controller = "arn:aws:iam::123456789012:role/mock-alb-controller-role"
    }
  }
}

terraform {
  source = "../../../terraform/modules/alb-controller-deployment"
}

inputs = {
  cluster_name            = dependency.eks.outputs.cluster_name
  vpc_id                 = dependency.vpc.outputs.vpc_id
  aws_region             = "us-west-2"
  alb_controller_role_arn = dependency.irsa_roles.outputs.role_arns.aws_load_balancer_controller

  tags = {
    Environment = "prod"
    Project     = "eks-security"
    ManagedBy   = "Terragrunt"
  }
}
