# Provider configurations for ALB Controller
# Uses shared configuration for consistency

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.95.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes" 
      version = "= 2.33.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "= 2.15.0"
    }
  }
}

# Get EKS cluster info for providers
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

# AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "non-prod"
      Project     = "eks-security"
      ManagedBy   = "Terraform"
      Layer       = "Applications"
    }
  }
}

# Kubernetes Provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Helm Provider
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
