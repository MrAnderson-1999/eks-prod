# EKS Module - Official terraform-aws-modules/eks/aws
# Secure private cluster configuration following AWS best practices

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # VPC Configuration - CRITICAL: Use private subnets for nodes
  vpc_id                          = var.vpc_id
  subnet_ids                      = var.private_subnet_ids  # Control plane subnets
  control_plane_subnet_ids        = var.private_subnet_ids  # Private subnets only

  # SECURITY: Private cluster configuration
  cluster_endpoint_public_access  = false  # Private cluster for ALB ingress
  cluster_endpoint_private_access = true

  # Enable IRSA for service accounts
  enable_irsa = true

  # KMS encryption
  create_kms_key = false  # Use external KMS key
  cluster_encryption_config = {
    provider_key_arn = var.kms_key_arn
    resources        = ["secrets"]
  }

  # Logging
  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = 30

  # EKS Managed Node Groups - In private subnets only
  eks_managed_node_groups = {
    main = {
      name = "main-ng"
      
      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type
      
      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # CRITICAL: Nodes in private subnets only
      subnet_ids = var.private_subnet_ids

      # Security configurations
      vpc_security_group_ids = var.additional_security_group_ids

      # EBS encryption
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 50
            volume_type = "gp3"
            encrypted   = true
            kms_key_id  = var.kms_key_arn
            delete_on_termination = true
          }
        }
      }

      # Security hardening
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      # IAM roles (use external roles)
      create_iam_role = false
      iam_role_arn    = var.node_group_role_arn

      update_config = {
        max_unavailable_percentage = 25
      }
    }
  }

  # Cluster Add-ons - WITHOUT service account role ARNs initially
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      # Service account role will be added via separate IRSA configuration
    }
    aws-ebs-csi-driver = {
      most_recent = true
      # Service account role will be added via separate IRSA configuration
    }
  }

  # Use external IAM roles
  create_iam_role            = false
  iam_role_arn              = var.cluster_service_role_arn
  create_node_security_group = false

  tags = var.tags
}

module "alb_security_group" {
  source = "../security-groups"
  name_prefix = "${var.cluster_name}-alb-security-group"
  security_groups = {
    alb_to_nodes = {
      ingress_rules = [
        {
          from_port = 30000
          to_port = 32767
          protocol = "tcp"
          cidr_blocks = var.vpc_cidr_blocks
        }
      ]
    }
  }
  tags = var.tags
}