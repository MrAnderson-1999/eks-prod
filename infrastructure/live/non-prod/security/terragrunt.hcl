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
  source = "${find_in_parent_folders("modules")}/security-groups"
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
  }
}