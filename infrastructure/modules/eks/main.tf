module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # VPC Configuration
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # SECURITY: Private cluster configuration
  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = true

  # IRSA enablement (required for aws-load-balancer-controller on Fargate)
  enable_irsa = var.enable_irsa

  # Match current cluster configuration to prevent replacement
  bootstrap_self_managed_addons = false

  # Access entries managed separately to avoid circular dependencies
  # Use AWS CLI or separate terraform module for access entries

  # KMS encryption - FIXED FORMAT
  create_kms_key = false
  cluster_encryption_config = {
    provider_key_arn = var.kms_key_arn
    resources        = ["secrets"]
  }

  # Logging
  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = 30

  # Fargate Profiles - Serverless container hosting
  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "default"
        },
        {
          namespace = "kube-system"
        }
      ]
      
      subnet_ids = var.private_subnet_ids
      
      # Use external IAM role
      create_iam_role = false
      iam_role_arn    = var.fargate_profile_role_arn
      
      tags = merge(var.tags, {
        Purpose = "Serverless workloads"
      })
    }
    
    applications = {
      name = "applications"
      selectors = [
        {
          namespace = "applications"
        },
        {
          namespace = "monitoring"
        },
        {
          namespace = "logging"
        }
      ]
      
      subnet_ids = var.private_subnet_ids
      
      # Use external IAM role
      create_iam_role = false
      iam_role_arn    = var.fargate_profile_role_arn
      
      tags = merge(var.tags, {
        Purpose = "Application workloads"
      })
    }
  }

  # EKS Add-ons for Fargate deployment (serverless - no EBS CSI driver needed)
  cluster_addons = {
    # Pod Identity Agent - New recommended approach for IAM roles
    eks-pod-identity-agent = {
      addon_version = "v1.3.8-eksbuild.2"  # Latest for K8s 1.32
    }
    
    coredns = {
      addon_version = "v1.11.4-eksbuild.14"  # Latest for K8s 1.32
    }
    
    kube-proxy = {
      addon_version = "v1.32.6-eksbuild.2"  # Latest for K8s 1.32
    }
    
    vpc-cni = {
      addon_version = "v1.20.1-eksbuild.1"  # Latest for K8s 1.32
    }
    
    # EBS CSI driver removed - Fargate uses ephemeral storage only
  }

  # Use external IAM roles
  create_iam_role = false
  iam_role_arn    = var.cluster_service_role_arn

  tags = var.tags
}

# ALB to nodes security group
resource "aws_security_group" "alb_to_nodes" {
  name_prefix = "${var.cluster_name}-alb-to-nodes"
  description = "Security group for ALB to nodes communication"
  vpc_id      = var.vpc_id

  ingress {
    description = "ALB to nodes"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_blocks
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-alb-to-nodes-sg"
  })
}

data "aws_caller_identity" "current" {}


# In your EKS module
data "tls_certificate" "cluster" {
  url = module.eks.cluster_oidc_issuer_url
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = module.eks.cluster_oidc_issuer_url

  tags = var.tags
}