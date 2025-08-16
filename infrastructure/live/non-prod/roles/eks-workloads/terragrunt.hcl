include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Need EKS OIDC issuer URL for IRSA trust on ALB controller
dependency "eks_cluster" {
  config_path = "../../eks/cluster"
  mock_outputs = {
    cluster_oidc_issuer_url = "https://oidc.eks.us-west-2.amazonaws.com/id/mock"
  }
}

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

  # No dependency references here to avoid Terragrunt evaluation ordering issues
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

    # aws_load_balancer_controller role moved to dedicated module
  }
}