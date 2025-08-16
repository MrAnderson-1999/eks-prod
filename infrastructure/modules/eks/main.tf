#==============================================================================
# DATA SOURCES
#==============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {}

#==============================================================================
# EKS CLUSTER WITH BASIC CONFIGURATION
#==============================================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # VPC Configuration
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  create_iam_role = true

  # Endpoint Configuration
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # IRSA Configuration - ESSENTIAL
  enable_irsa = true

  # KMS Encryption
  create_kms_key = var.create_kms_key
  cluster_encryption_config = var.kms_key_arn != null ? {
    provider_key_arn = var.kms_key_arn
    resources        = ["secrets"]
  } : {}

  # CloudWatch Logging
  cluster_enabled_log_types              = var.cluster_enabled_log_types
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    for name, config in var.node_groups : name => {
      min_size       = config.min_size
      max_size       = config.max_size
      desired_size   = config.desired_size
      instance_types = config.instance_types
      capacity_type  = config.capacity_type
      
      # Node group configuration
      ami_type  = lookup(config, "ami_type", "AL2_x86_64")
      disk_size = lookup(config, "disk_size", 20)
      
      # Labels and taints
      labels = lookup(config, "labels", {})
      taints = lookup(config, "taints", [])
      
      # Update configuration
      update_config = {
        max_unavailable_percentage = lookup(config, "max_unavailable_percentage", 25)
      }
    }
  }

  # Basic Core Add-ons Only (no IRSA dependencies)
  cluster_addons = {
    coredns = {
      addon_version     = var.coredns_version
      resolve_conflicts = "OVERWRITE"
    }
    
    kube-proxy = {
      addon_version     = var.kube_proxy_version
      resolve_conflicts = "OVERWRITE"
    }
    
    # Basic VPC CNI without IRSA
    vpc-cni = {
      addon_version     = var.vpc_cni_version
      resolve_conflicts = "OVERWRITE"
    }
  }

  # Access Entries for Admin Access
  access_entries = {
    for idx, arn in var.admin_role_arns : "admin-${idx}" => {
      principal_arn     = arn
      kubernetes_groups = ["system:masters"]
      type             = "STANDARD"
    }
  }

  tags = var.tags
}