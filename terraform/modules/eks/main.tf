# EKS Module - Official terraform-aws-modules/eks/aws
# Secure private cluster configuration following AWS best practices

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # VPC Configuration - FIXED
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids  # This is correct for control plane

  # SECURITY: Private cluster configuration - FIXED
  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = true

  # Enable IRSA
  enable_irsa = true

  # KMS encryption - FIXED
  create_kms_key = false
  cluster_encryption_config = [
    {
      provider_key_arn = var.kms_key_arn
      resources        = ["secrets"]
    }
  ]

  # Logging
  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = 30

  # EKS Managed Node Groups
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
            volume_size           = 50
            volume_type           = "gp3"
            encrypted             = true
            kms_key_id           = var.kms_key_arn
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

      # Use external IAM role
      create_iam_role = false
      iam_role_arn    = var.node_group_role_arn

      update_config = {
        max_unavailable_percentage = 25
      }
    }
  }

  # Cluster Add-ons - Basic configuration
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # Use external IAM roles
  create_iam_role = false
  iam_role_arn    = var.cluster_service_role_arn

  tags = var.tags
}

# Add this resource to your EKS module
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