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

# Get VPC outputs
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-12345678"
  }
}

# Set the source of the module
terraform {
  source = "${get_parent_terragrunt_dir()}/../terraform/modules/security-groups"
}

inputs = {
  name_prefix = "${include.env.locals.name}-${include.env.locals.stage}"
  
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
          # Will be replaced with security group reference in EKS configuration
          cidr_blocks = []
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

# Dependency on EKS module
dependency "eks" {
  config_path = "../eks"
  
  mock_outputs = {
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
  }
}

# Module-specific variables
inputs = {
  name        = "eks-security"
  environment = "prod"
  aws_region  = "us-west-2"
  
  # OIDC Provider ARN from EKS cluster
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
  
  # Service Account Roles
  create_alb_controller_role     = true
  create_ebs_csi_driver_role     = true
  create_external_dns_role       = true
  create_cluster_autoscaler_role = true
  
  # Custom IAM Roles (using the existing iam-roles module)
  iam_roles = {
    application_deployer = {
      description = "Role for application deployment in EKS"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = "sts:AssumeRoleWithWebIdentity"
            Effect = "Allow"
            Principal = {
              Federated = dependency.eks.outputs.oidc_provider_arn
            }
            Condition = {
              StringEquals = {
                "${replace(dependency.eks.outputs.oidc_provider_arn, "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/", "")}:sub" = "system:serviceaccount:production:application-deployer"
                "${replace(dependency.eks.outputs.oidc_provider_arn, "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/", "")}:aud" = "sts.amazonaws.com"
              }
            }
          }
        ]
      })
      inline_policies = {
        s3_access = {
          policy = jsonencode({
            Version = "2012-10-17"
            Statement = [
              {
                Effect = "Allow"
                Action = [
                  "s3:GetObject",
                  "s3:PutObject",
                  "s3:DeleteObject"
                ]
                Resource = "arn:aws:s3:::eks-security-prod-app-data/*"
              }
            ]
          })
        }
      }
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess"
      ]
    }
    
    monitoring_role = {
      description = "Role for monitoring and observability services"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = "sts:AssumeRoleWithWebIdentity"
            Effect = "Allow"
            Principal = {
              Federated = dependency.eks.outputs.oidc_provider_arn
            }
            Condition = {
              StringEquals = {
                "${replace(dependency.eks.outputs.oidc_provider_arn, "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/", "")}:sub" = "system:serviceaccount:monitoring:prometheus"
                "${replace(dependency.eks.outputs.oidc_provider_arn, "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/", "")}:aud" = "sts.amazonaws.com"
              }
            }
          }
        ]
      })
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
      ]
    }
  }
  
  # Tags
  tags = {
    Project     = "eks-security"
    Environment = "prod"
    Owner       = "platform-team"
    ManagedBy   = "Terragrunt"
  }
}