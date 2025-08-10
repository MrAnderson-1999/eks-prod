# Include root configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Get VPC outputs
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-12345678"
    vpc_cidr_block = "10.0.0.0/16"
  }
}

# Set the source of the module
terraform {
  source = "../../../terraform/modules/security-groups"
}

inputs = {
  name_prefix = "eks-security-non-prod"
  
  security_groups = {
    # EKS Cluster Security Group
    eks_cluster = {
      description = "Security group for EKS cluster control plane"
      vpc_id      = dependency.vpc.outputs.vpc_id
      
      ingress_rules = [
        {
          description = "HTTPS from anywhere"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      
      egress_rules = [
        {
          description = "All outbound traffic"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      
      tags = {
        Purpose = "EKS Cluster Control Plane"
      }
    }
    
    # EKS Node Group Security Group
    eks_nodes = {
      description = "Security group for EKS worker nodes"
      vpc_id      = dependency.vpc.outputs.vpc_id
      
      ingress_rules = [
        {
          description = "Node to node communication"
          from_port   = 0
          to_port     = 65535
          protocol    = "tcp"
          self        = true
        },
        {
          description = "Cluster to node communication"
          from_port   = 1025
          to_port     = 65535
          protocol    = "tcp"
          cidr_blocks = [dependency.vpc.outputs.vpc_cidr_block]
        },
        {
          description = "Node to node communication (UDP)"
          from_port   = 0
          to_port     = 65535
          protocol    = "udp"
          self        = true
        }
      ]
      
      egress_rules = [
        {
          description = "All outbound traffic"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      
      tags = {
        Purpose = "EKS Worker Nodes"
      }
    }
    
    # EKS ALB Security Group
    eks_alb = {
      description = "Security group for ALB used by EKS"
      vpc_id      = dependency.vpc.outputs.vpc_id
      
      ingress_rules = [
        {
          description = "HTTP from anywhere"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          description = "HTTPS from anywhere"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      
      egress_rules = [
        {
          description = "All outbound traffic"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      
      tags = {
        Purpose = "EKS Application Load Balancer"
      }
    }
  }
}