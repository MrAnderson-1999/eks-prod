# Include root configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Set the source of the module
terraform {
  source = "${find_in_parent_folders("modules")}/iam-roles"
}

inputs = {
  name_prefix = "eks-security-non-prod"
  
  roles = {
    eks_cluster = {
      description = "IAM role for EKS cluster service"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              Service = "eks.amazonaws.com"
            }
            Action = "sts:AssumeRole"
          }
        ]
      })
      
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
      ]
      
      tags = {
        Purpose = "EKS Cluster Service Role"
        Service = "EKS"
      }
    }
    
    eks_node_group = {
      description = "IAM role for EKS node groups"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              Service = "ec2.amazonaws.com"
            }
            Action = "sts:AssumeRole"
          }
        ]
      })
      
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"  # Added for node management
      ]
      
      tags = {
        Purpose = "EKS Node Group Role"
        Service = "EKS"
      }
    }

    pipeline_role = {
      description = "IAM role for pipeline"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              Service = "codepipeline.amazonaws.com"
            }
            Action = "sts:AssumeRole"
          }
        ]
      })
      
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"  # Correct CodePipeline policy name
      ]
      
      tags = {
        Purpose = "Pipeline Role"
        Service = "Pipeline"
      }
    }
  }
}