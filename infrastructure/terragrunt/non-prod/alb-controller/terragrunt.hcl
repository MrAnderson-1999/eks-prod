include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Additional providers needed for ALB controller (Kubernetes & Helm)
generate "additional_providers" {
  path      = "additional_providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
# Configure Kubernetes provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Configure Helm provider
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
EOF
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
  vpc_id                  = dependency.vpc.outputs.vpc_id
  aws_region              = "us-west-2"
  alb_controller_role_arn = dependency.irsa_roles.outputs.role_arns.aws_load_balancer_controller

  tags = {
    Environment = "non-prod"
    Project     = "eks-security"
    ManagedBy   = "Terragrunt"
  }
}
