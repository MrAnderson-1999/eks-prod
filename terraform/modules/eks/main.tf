# EKS Module - Abstraction over terraform-aws-modules/eks/aws
# This module provides a curated abstraction specifically for secure EKS deployment

# Version constraints are defined in versions.tf

# Additional security group for node groups
resource "aws_security_group" "additional_node_sg" {
  count = var.create_additional_node_security_group ? 1 : 0
  
  name_prefix = "${local.cluster_name}-additional-node-sg"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow nodes to communicate with ALB"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-additional-node-sg"
  })
}

# IRSA for EBS CSI Driver
module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.60"

  role_name = "${local.cluster_name}-ebs-csi-driver"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.common_tags
}

# Get VPC information for security group rules
data "aws_vpc" "selected" {
  id = var.vpc_id
}

locals {
  cluster_name = "${var.name}-${var.environment}"
  
  # Common tags for all resources
  common_tags = merge(var.tags, {
    Name        = local.cluster_name
    Environment = var.environment
    Region      = var.aws_region
    ManagedBy   = "Terraform"
    Purpose     = "EKS Cluster"
  })

  # Default node group configuration
  default_node_groups = {
    main = {
      name           = "main"
      instance_types = var.default_node_group_instance_types
      ami_type       = var.default_node_group_ami_type
      capacity_type  = var.default_node_group_capacity_type
      
      min_size     = var.default_node_group_min_size
      max_size     = var.default_node_group_max_size
      desired_size = var.default_node_group_desired_size
      
      disk_size = var.default_node_group_disk_size
      
      k8s_labels = {
        Environment = var.environment
        NodeGroup   = "main"
      }
      
      tags = local.common_tags
    }
  }
  
  # Merge default and custom node groups
  all_node_groups = merge(local.default_node_groups, var.custom_node_groups)
}

# KMS Key for EKS secrets encryption
resource "aws_kms_key" "eks" {
  count = var.create_kms_key ? 1 : 0
  
  description             = "EKS Secret Encryption Key for ${local.cluster_name}"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-eks-secrets"
  })
}

resource "aws_kms_alias" "eks" {
  count = var.create_kms_key ? 1 : 0
  
  name          = "alias/${local.cluster_name}-eks-secrets"
  target_key_id = aws_kms_key.eks[0].key_id
}

# CloudWatch Log Group for EKS Control Plane Logs
resource "aws_cloudwatch_log_group" "eks_cluster" {
  count = var.enable_cluster_logging ? 1 : 0
  
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_days

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-cluster-logs"
  })
}

# EKS Cluster using the official terraform-aws-modules/eks/aws module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.cluster_name
  kubernetes_version = var.cluster_version

  # VPC and Subnet Configuration
  vpc_id     = var.vpc_id
  subnet_ids = var.node_group_subnet_ids  # Use private subnets only for security
  control_plane_subnet_ids = var.node_group_subnet_ids  # Control plane in private subnets

  # Security-first configuration - private endpoint only by default
  endpoint_private_access      = true  # Always enable private access
  endpoint_public_access       = var.cluster_endpoint_public_access
  endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # IAM Role Configuration
  create_iam_role = var.create_iam_role
  iam_role_arn    = var.cluster_service_role_arn

  # Security Configuration - Use module-managed KMS key for encryption
  create_kms_key              = var.create_kms_key
  kms_key_deletion_window_in_days = var.kms_key_deletion_window

  # Logging Configuration
  enabled_log_types = var.enable_cluster_logging ? var.cluster_log_types : []
  cloudwatch_log_group_retention_in_days = var.cluster_log_retention_days
  create_cloudwatch_log_group = false  # We manage log group separately

  # IRSA (IAM Roles for Service Accounts)
  enable_irsa = var.enable_irsa

  # Cluster Security Group Rules
  additional_security_group_ids = var.additional_security_group_ids

  # EKS Managed Node Groups with security-focused configuration
  eks_managed_node_groups = merge(
    # System node group for system workloads
    var.enable_system_node_group ? {
      system = {
        name         = "system-ng"
        min_size     = var.system_node_group_min_size
        max_size     = var.system_node_group_max_size
        desired_size = var.system_node_group_desired_size

        instance_types = var.system_node_group_instance_types
        capacity_type  = var.system_node_group_capacity_type
        
        # Security configurations
        ami_type       = var.default_node_group_ami_type
        disk_size      = var.system_node_group_disk_size
        disk_encrypted = true
        disk_kms_key_id = var.create_kms_key ? aws_kms_key.eks[0].arn : var.external_kms_key_arn

        # Metadata options for security
        metadata_options = {
          http_endpoint               = "enabled"
          http_tokens                 = "required"
          http_put_response_hop_limit = 2
          instance_metadata_tags      = "disabled"
        }

        # Taints for system workloads
        taints = var.system_node_group_taints

        labels = merge({
          role = "system"
          "node.kubernetes.io/system" = "true"
        }, var.system_node_group_labels)

        # IAM Role Configuration
        create_iam_role = var.create_node_group_role
        iam_role_arn    = var.node_group_role_arn
        
        # Subnets for node groups (private only)
        subnet_ids = var.node_group_subnet_ids
        
        # Security Groups
        vpc_security_group_ids = concat(
          var.additional_security_group_ids,
          var.create_additional_node_security_group ? [aws_security_group.additional_node_sg[0].id] : []
        )

        # Update configuration
        update_config = {
          max_unavailable_percentage = var.node_group_max_unavailable_percentage
        }

        tags = merge(local.common_tags, {
          Environment = var.environment
          NodeGroup   = "system"
          Purpose     = "system-workloads"
        })
      }
    } : {},
    
    # Workload node group for application workloads
    var.enable_workload_node_group ? {
      workload = {
        name         = "workload-ng"
        min_size     = var.workload_node_group_min_size
        max_size     = var.workload_node_group_max_size
        desired_size = var.workload_node_group_desired_size

        instance_types = var.workload_node_group_instance_types
        capacity_type  = var.workload_node_group_capacity_type
        
        # Security configurations
        ami_type       = var.default_node_group_ami_type
        disk_size      = var.workload_node_group_disk_size
        disk_encrypted = true
        disk_kms_key_id = var.create_kms_key ? aws_kms_key.eks[0].arn : var.external_kms_key_arn

        # Metadata options for security
        metadata_options = {
          http_endpoint               = "enabled"
          http_tokens                 = "required"
          http_put_response_hop_limit = 2
          instance_metadata_tags      = "disabled"
        }

        labels = merge({
          role = "workload"
        }, var.workload_node_group_labels)

        # IAM Role Configuration
        create_iam_role = var.create_node_group_role
        iam_role_arn    = var.node_group_role_arn
        
        # Subnets for node groups (private only)
        subnet_ids = var.node_group_subnet_ids
        
        # Security Groups
        vpc_security_group_ids = concat(
          var.additional_security_group_ids,
          var.create_additional_node_security_group ? [aws_security_group.additional_node_sg[0].id] : []
        )

        # Update configuration
        update_config = {
          max_unavailable_percentage = var.node_group_max_unavailable_percentage
        }

        tags = merge(local.common_tags, {
          Environment = var.environment
          NodeGroup   = "workload"
          Purpose     = "application-workloads"
        })
      }
    } : {},
    
    # Additional custom node groups
    {
      for k, v in var.custom_node_groups : k => {
        name                          = v.name
        instance_types                = v.instance_types
        capacity_type                 = v.capacity_type
        ami_type                      = v.ami_type
        
        # Scaling configuration
        min_size                      = v.min_size
        max_size                      = v.max_size
        desired_size                  = v.desired_size
        
        # Storage configuration
        disk_size                     = v.disk_size
        disk_encrypted                = true
        disk_kms_key_id              = var.create_kms_key ? aws_kms_key.eks[0].arn : var.external_kms_key_arn
        
        # Metadata options for security
        metadata_options = {
          http_endpoint               = "enabled"
          http_tokens                 = "required"
          http_put_response_hop_limit = 2
          instance_metadata_tags      = "disabled"
        }
        
        # Update configuration
        update_config = {
          max_unavailable_percentage = var.node_group_max_unavailable_percentage
        }
        
        # IAM Role Configuration
        create_iam_role = var.create_node_group_role
        iam_role_arn    = var.node_group_role_arn
        
        # Subnets for node groups
        subnet_ids = var.node_group_subnet_ids
        
        # Security Groups
        vpc_security_group_ids = concat(
          var.additional_security_group_ids,
          var.create_additional_node_security_group ? [aws_security_group.additional_node_sg[0].id] : []
        )
        
        # Labels and Tags
        labels = merge(v.k8s_labels, {
          Environment = var.environment
          NodeGroup   = k
        })
        
        tags = merge(local.common_tags, v.tags, {
          Environment = var.environment
          NodeGroup   = k
        })
        
        # Taints (if specified)
        taints = v.taints
      }
    }
  )

  # EKS Add-ons with security-focused configuration
  addons = merge(
    # Default security-focused addons
    {
      coredns = {
        most_recent = true
        configuration_values = jsonencode({
          tolerations = [{
            key      = "node.kubernetes.io/system"
            operator = "Exists"
            effect   = "NoSchedule"
          }]
        })
      }
      kube-proxy = {
        most_recent = true
      }
      vpc-cni = {
        most_recent = true
        configuration_values = jsonencode({
          env = {
            ENABLE_PREFIX_DELEGATION = "true"
            ENABLE_POD_ENI           = "true"
            POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
          }
        })
      }
      aws-ebs-csi-driver = {
        most_recent = true
        service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
      }
    },
    # Additional user-defined addons
    var.cluster_addons
  )

  tags = local.common_tags
}

# Additional Security Group Rules for Node Groups (if needed)
resource "aws_security_group_rule" "node_group_additional" {
  for_each = var.additional_node_security_group_rules

  type                     = each.value.type
  from_port               = each.value.from_port
  to_port                 = each.value.to_port
  protocol                = each.value.protocol
  cidr_blocks             = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks        = lookup(each.value, "ipv6_cidr_blocks", null)
  prefix_list_ids         = lookup(each.value, "prefix_list_ids", null)
  security_group_id       = module.eks.node_security_group_id
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  description             = each.value.description
}

# Security group rule for cluster endpoint access from VPC
resource "aws_security_group_rule" "cluster_ingress_workstation_https" {
  count = var.cluster_endpoint_private_access ? 1 : 0
  
  description       = "Allow VPC to communicate with the cluster API Server"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  security_group_id = module.eks.cluster_security_group_id
}
