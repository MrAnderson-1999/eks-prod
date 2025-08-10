# Include environment configuration (which includes backend and root)
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Include environment variables
include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

# Dependencies
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id                = "vpc-12345678"
    private_subnets       = ["subnet-12345678", "subnet-87654321"]
    public_subnets        = ["subnet-11111111", "subnet-22222222"]
    cluster_subnet_ids    = ["subnet-12345678", "subnet-87654321", "subnet-11111111", "subnet-22222222"]
    node_group_subnet_ids = ["subnet-12345678", "subnet-87654321"]
  }
}

dependency "iam_roles" {
  config_path = "../iam-roles"
  mock_outputs = {
    role_arns = {
      eks_cluster                   = "arn:aws:iam::123456789012:role/mock-eks-cluster-role"
      eks_node_group               = "arn:aws:iam::123456789012:role/mock-eks-node-group-role"
      eks_fargate_pod_execution    = "arn:aws:iam::123456789012:role/mock-eks-fargate-role"
      aws_load_balancer_controller = "arn:aws:iam::123456789012:role/mock-alb-controller-role"
    }
  }
}

dependency "security_groups" {
  config_path = "../security"
  mock_outputs = {
    security_group_ids = {
      eks_cluster = "sg-12345678"
      eks_nodes   = "sg-87654321"
      eks_alb     = "sg-11111111"
    }
  }
}

# Set the source of the module
terraform {
  source = "../../../terraform/modules/eks"
}

inputs = {
  # Basic Configuration
  name         = include.env.locals.name
  environment  = include.env.locals.stage
  aws_region   = include.env.locals.region
  
  # Cluster Configuration
  cluster_version = "1.29"
  
  # Network Configuration
  vpc_id                      = dependency.vpc.outputs.vpc_id
  cluster_subnet_ids          = dependency.vpc.outputs.cluster_subnet_ids
  node_group_subnet_ids       = dependency.vpc.outputs.node_group_subnet_ids
  control_plane_subnet_ids    = dependency.vpc.outputs.private_subnets
  
  # Security-first Access Configuration
  cluster_endpoint_public_access       = false  # Private endpoint only for security
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = []
  
  # IAM Role Configuration - Use external roles
  create_iam_role           = false
  cluster_service_role_arn  = dependency.iam_roles.outputs.role_arns.eks_cluster
  create_node_group_role    = false
  node_group_role_arn       = dependency.iam_roles.outputs.role_arns.eks_node_group
  
  # Security Configuration
  create_kms_key              = true
  kms_key_deletion_window     = 7
  
  # External security groups (created by our security module)
  additional_security_group_ids = [
    dependency.security_groups.outputs.security_group_ids.eks_cluster
  ]
  
  # Node Group Security Group Rules
  additional_node_security_group_rules = {
    cluster_to_node_443 = {
      description              = "Cluster API to node groups"
      type                     = "ingress"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = dependency.security_groups.outputs.security_group_ids.eks_cluster
    }
    cluster_to_node_kubelet = {
      description              = "Cluster to node kubelet"
      type                     = "ingress"
      from_port                = 10250
      to_port                  = 10250
      protocol                 = "tcp"
      source_security_group_id = dependency.security_groups.outputs.security_group_ids.eks_cluster
    }
  }
  
  # Logging Configuration
  enable_cluster_logging      = true
  cluster_log_types          = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_log_retention_days = 7
  
  # IRSA Configuration
  enable_irsa = true
  
    # Security-focused Node Groups Configuration
  enable_system_node_group   = true
  enable_workload_node_group = true
  create_additional_node_security_group = true
  
  # System Node Group (for system workloads)
  system_node_group_min_size          = 2
  system_node_group_max_size          = 6  
  system_node_group_desired_size      = 3
  system_node_group_instance_types    = ["t3.medium"]
  system_node_group_capacity_type     = "ON_DEMAND"
  system_node_group_disk_size         = 50
  
  # Workload Node Group (for application workloads)
  workload_node_group_min_size        = 1
  workload_node_group_max_size        = 10
  workload_node_group_desired_size    = 2
  workload_node_group_instance_types  = ["t3.large"]
  workload_node_group_capacity_type   = "SPOT"
  workload_node_group_disk_size       = 100
  
  # Default AMI type for all node groups
  default_node_group_ami_type = "AL2_x86_64"

  # Additional custom node groups (optional)
  custom_node_groups = {}
  
  # EKS Add-ons (module provides security-focused defaults)
  cluster_addons = {
    # Additional add-ons can be specified here
    # The module automatically configures:
    # - coredns with system node toleration
    # - kube-proxy
    # - vpc-cni with security settings
    # - aws-ebs-csi-driver with IRSA
  }
  
  # Force update configuration
  force_update_version = false
  node_group_max_unavailable_percentage = 25
  
  # Tags
  tags = {
    Environment = include.env.locals.stage
    Project     = include.env.locals.name
    ManagedBy   = "Terraform"
    Purpose     = "EKS Cluster"
  }
}

# Dependency on VPC module
dependency "vpc" {
  config_path = "../vpc"
  
  mock_outputs = {
    vpc_id                = "vpc-12345678"
    private_subnets       = ["subnet-12345678", "subnet-87654321"]
    public_subnets        = ["subnet-11111111", "subnet-22222222"]
    cluster_subnet_ids    = ["subnet-12345678", "subnet-87654321", "subnet-11111111", "subnet-22222222"]
    node_group_subnet_ids = ["subnet-12345678", "subnet-87654321"]
  }
}