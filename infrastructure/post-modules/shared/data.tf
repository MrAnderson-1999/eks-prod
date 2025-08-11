# Remote state data sources for applications to reference infrastructure outputs

# Get EKS cluster information
data "terraform_remote_state" "eks_cluster" {
  backend = "s3"
  config = {
    bucket         = "terraform-state-740047840996-us-west-2"
    key            = "environments/non-prod/eks/cluster/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock-740047840996-us-west-2"
    encrypt        = true
  }
}

# Get VPC information
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket         = "terraform-state-740047840996-us-west-2"
    key            = "environments/non-prod/vpc/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock-740047840996-us-west-2"
    encrypt        = true
  }
}

# Get IAM roles information
data "terraform_remote_state" "eks_workload_roles" {
  backend = "s3"
  config = {
    bucket         = "terraform-state-740047840996-us-west-2"
    key            = "environments/non-prod/roles/eks-workloads/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock-740047840996-us-west-2"
    encrypt        = true
  }
}

# Get EKS cluster info for providers
data "aws_eks_cluster" "cluster" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = local.cluster_name
}

# Local values for easy reference
locals {
  cluster_name               = data.terraform_remote_state.eks_cluster.outputs.cluster_name
  vpc_id                    = data.terraform_remote_state.vpc.outputs.vpc_id
  aws_region                = "us-west-2"
  alb_controller_role_arn   = data.terraform_remote_state.eks_workload_roles.outputs.role_arns.aws_load_balancer_controller
  
  # Common tags
  common_tags = {
    Environment = "non-prod"
    Project     = "eks-security"
    ManagedBy   = "Terraform"
    Layer       = "Applications"
  }
}
