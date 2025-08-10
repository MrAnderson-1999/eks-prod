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

# Set the source of the module
terraform {
  source = "../../../terraform/modules/iam-roles"
}

inputs = {
  name_prefix = "${include.env.locals.name}-${include.env.locals.stage}"
  
  roles = {
    # EKS Cluster Service Role
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
    
    # EKS Node Group Role
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
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      ]
      
      tags = {
        Purpose = "EKS Node Group Role"
        Service = "EKS"
      }
    }
    
    # EKS Pod Execution Role (for Fargate if needed)
    eks_fargate_pod_execution = {
      description = "IAM role for EKS Fargate pod execution"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              Service = "eks-fargate-pods.amazonaws.com"
            }
            Action = "sts:AssumeRole"
          }
        ]
      })
      
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
      ]
      
      tags = {
        Purpose = "EKS Fargate Pod Execution Role"
        Service = "EKS"
      }
    }
    
    # AWS Load Balancer Controller Role
    aws_load_balancer_controller = {
      description = "IAM role for AWS Load Balancer Controller"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              Federated = "arn:aws:iam::740047840996:oidc-provider/OIDC_PROVIDER_URL"  # Will be updated after EKS creation
            }
            Action = "sts:AssumeRoleWithWebIdentity"
            Condition = {
              StringEquals = {
                "OIDC_PROVIDER_URL:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
                "OIDC_PROVIDER_URL:aud" = "sts.amazonaws.com"
              }
            }
          }
        ]
      })
      
      inline_policies = {
        load_balancer_controller = {
          policy = jsonencode({
            Version = "2012-10-17"
            Statement = [
              {
                Effect = "Allow"
                Action = [
                  "iam:CreateServiceLinkedRole",
                  "ec2:DescribeAccountAttributes",
                  "ec2:DescribeAddresses",
                  "ec2:DescribeAvailabilityZones",
                  "ec2:DescribeInternetGateways",
                  "ec2:DescribeVpcs",
                  "ec2:DescribeSubnets",
                  "ec2:DescribeSecurityGroups",
                  "ec2:DescribeInstances",
                  "ec2:DescribeNetworkInterfaces",
                  "ec2:DescribeTags",
                  "ec2:GetCoipPoolUsage",
                  "ec2:DescribeCoipPools",
                  "elasticloadbalancing:DescribeLoadBalancers",
                  "elasticloadbalancing:DescribeLoadBalancerAttributes",
                  "elasticloadbalancing:DescribeListeners",
                  "elasticloadbalancing:DescribeListenerCertificates",
                  "elasticloadbalancing:DescribeSSLPolicies",
                  "elasticloadbalancing:DescribeRules",
                  "elasticloadbalancing:DescribeTargetGroups",
                  "elasticloadbalancing:DescribeTargetGroupAttributes",
                  "elasticloadbalancing:DescribeTargetHealth",
                  "elasticloadbalancing:DescribeTags"
                ]
                Resource = "*"
              },
              {
                Effect = "Allow"
                Action = [
                  "cognito-idp:DescribeUserPoolClient",
                  "acm:ListCertificates",
                  "acm:DescribeCertificate",
                  "iam:ListServerCertificates",
                  "iam:GetServerCertificate",
                  "waf-regional:GetWebACL",
                  "waf-regional:GetWebACLForResource",
                  "waf-regional:AssociateWebACL",
                  "waf-regional:DisassociateWebACL",
                  "wafv2:GetWebACL",
                  "wafv2:GetWebACLForResource",
                  "wafv2:AssociateWebACL",
                  "wafv2:DisassociateWebACL",
                  "shield:DescribeProtection",
                  "shield:GetSubscriptionState",
                  "shield:DescribeSubscription",
                  "shield:CreateProtection",
                  "shield:DeleteProtection"
                ]
                Resource = "*"
              },
              {
                Effect = "Allow"
                Action = [
                  "ec2:AuthorizeSecurityGroupIngress",
                  "ec2:RevokeSecurityGroupIngress"
                ]
                Resource = "*"
              },
              {
                Effect = "Allow"
                Action = [
                  "ec2:CreateSecurityGroup"
                ]
                Resource = "*"
              },
              {
                Effect = "Allow"
                Action = [
                  "ec2:CreateTags"
                ]
                Resource = "arn:aws:ec2:*:*:security-group/*"
                Condition = {
                  StringEquals = {
                    "ec2:CreateAction" = "CreateSecurityGroup"
                  }
                  Null = {
                    "aws:RequestedRegion" = "false"
                  }
                }
              },
              {
                Effect = "Allow"
                Action = [
                  "elasticloadbalancing:CreateLoadBalancer",
                  "elasticloadbalancing:CreateTargetGroup"
                ]
                Resource = "*"
                Condition = {
                  Null = {
                    "aws:RequestedRegion" = "false"
                  }
                }
              },
              {
                Effect = "Allow"
                Action = [
                  "elasticloadbalancing:CreateListener",
                  "elasticloadbalancing:DeleteListener",
                  "elasticloadbalancing:CreateRule",
                  "elasticloadbalancing:DeleteRule"
                ]
                Resource = "*"
              },
              {
                Effect = "Allow"
                Action = [
                  "elasticloadbalancing:AddTags",
                  "elasticloadbalancing:RemoveTags"
                ]
                Resource = [
                  "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                  "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                  "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
                ]
                Condition = {
                  Null = {
                    "aws:RequestedRegion" = "false"
                    "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
                  }
                }
              },
              {
                Effect = "Allow"
                Action = [
                  "elasticloadbalancing:ModifyLoadBalancerAttributes",
                  "elasticloadbalancing:SetIpAddressType",
                  "elasticloadbalancing:SetSecurityGroups",
                  "elasticloadbalancing:SetSubnets",
                  "elasticloadbalancing:DeleteLoadBalancer",
                  "elasticloadbalancing:ModifyTargetGroup",
                  "elasticloadbalancing:ModifyTargetGroupAttributes",
                  "elasticloadbalancing:DeleteTargetGroup"
                ]
                Resource = "*"
                Condition = {
                  Null = {
                    "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
                  }
                }
              },
              {
                Effect = "Allow"
                Action = [
                  "elasticloadbalancing:RegisterTargets",
                  "elasticloadbalancing:DeregisterTargets"
                ]
                Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
              }
            ]
          })
        }
      }
      
      tags = {
        Purpose = "AWS Load Balancer Controller IRSA Role"
        Service = "EKS"
      }
    }
  }
}
