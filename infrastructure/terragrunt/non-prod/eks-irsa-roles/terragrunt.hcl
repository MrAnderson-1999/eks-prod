include "root" {
  path = find_in_parent_folders("root.hcl")
}

# No longer need dependency on EKS OIDC for Pod Identity
# dependency "eks" {
#   config_path = "../eks"
#   mock_outputs = {
#     oidc_provider_arn       = "arn:aws:iam::123456789012:oidc-provider/fake"
#     cluster_oidc_issuer_url = "https://oidc.eks.us-west-2.amazonaws.com/id/fake"
#   }
# }

terraform {
  source = "${find_in_parent_folders("modules")}/iam-roles"
}

locals {
  # Standard Pod Identity trust policy for all roles
  pod_identity_trust_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

inputs = {
  name_prefix = "eks-non-prod-irsa"  # Keep name for backwards compatibility
  
  roles = {
    vpc_cni = {
      description = "VPC CNI Pod Identity role"
      assume_role_policy = local.pod_identity_trust_policy
      managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"]
      inline_policies = {}
      tags = { Purpose = "VPC CNI Pod Identity" }
    }

    # EBS CSI driver role commented out - not needed for Fargate
    # ebs_csi_driver = {
    #   description = "EBS CSI driver Pod Identity role"
    #   assume_role_policy = local.pod_identity_trust_policy
    #   managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]
    #   inline_policies = {}
    #   tags = { Purpose = "EBS CSI Pod Identity" }
    # }

    coredns = {
      description = "CoreDNS Pod Identity role"
      assume_role_policy = local.pod_identity_trust_policy
      # CoreDNS typically doesn't need special AWS permissions, but can be used for DNS query logging to CloudWatch
      inline_policies = {
        dns_logging_policy = {
          policy = jsonencode({
            Version = "2012-10-17"
            Statement = [
              {
                Effect = "Allow"
                Action = [
                  "logs:CreateLogGroup",
                  "logs:CreateLogStream",
                  "logs:PutLogEvents",
                  "logs:DescribeLogGroups",
                  "logs:DescribeLogStreams"
                ]
                Resource = "arn:aws:logs:*:*:log-group:/aws/eks/coredns/*"
              }
            ]
          })
        }
      }
      managed_policy_arns = []
      tags = { Purpose = "CoreDNS Pod Identity" }
    }

    kube_proxy = {
      description = "kube-proxy Pod Identity role"
      assume_role_policy = local.pod_identity_trust_policy
      # kube-proxy typically doesn't need AWS permissions, but can be used for enhanced monitoring
      inline_policies = {
        monitoring_policy = {
          policy = jsonencode({
            Version = "2012-10-17"
            Statement = [
              {
                Effect = "Allow"
                Action = [
                  "cloudwatch:PutMetricData",
                  "ec2:DescribeInstances",
                  "ec2:DescribeNetworkInterfaces"
                ]
                Resource = "*"
              }
            ]
          })
        }
      }
      managed_policy_arns = []
      tags = { Purpose = "kube-proxy Pod Identity" }
    }

    aws_load_balancer_controller = {
      description = "AWS Load Balancer Controller Pod Identity role"
      assume_role_policy = local.pod_identity_trust_policy
      
      # Use comprehensive ALB controller policy
      inline_policies = {
        alb_controller_policy = {
          policy = jsonencode({
            Version = "2012-10-17"
            Statement = [
              {
                Effect = "Allow"
                Action = [
                  "iam:CreateServiceLinkedRole"
                ]
                Resource = "*"
                Condition = {
                  StringEquals = {
                    "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com"
                  }
                }
              },
              {
                Effect = "Allow"
                Action = [
                  "ec2:DescribeAccountAttributes",
                  "ec2:DescribeAddresses",
                  "ec2:DescribeAvailabilityZones",
                  "ec2:DescribeInternetGateways",
                  "ec2:DescribeVpcs",
                  "ec2:DescribeVpcPeeringConnections",
                  "ec2:DescribeSubnets",
                  "ec2:DescribeSecurityGroups",
                  "ec2:DescribeInstances",
                  "ec2:DescribeNetworkInterfaces",
                  "ec2:DescribeTags",
                  "ec2:GetCoipPoolUsage",
                  "ec2:GetManagedPrefixListEntries",
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
                  "ec2:RevokeSecurityGroupIngress",
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
                    "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
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
                    "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
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
                    "aws:RequestTag/elbv2.k8s.aws/cluster" = "true"
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
      managed_policy_arns = []
      tags = { Purpose = "ALB Controller Pod Identity" }
    }
  }
}