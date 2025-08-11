# Terragrunt configuration for EKS Pod Identity associations
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${find_in_parent_folders("modules")}/eks-pod-identity"
}

# Dependencies - Pod Identity requires EKS cluster and IAM roles
dependency "eks_cluster" {
  config_path = "../cluster"
  
  mock_outputs = {
    cluster_name                 = "mock-cluster"
    cluster_oidc_issuer_url     = "https://oidc.eks.mock.amazonaws.com/id/MOCK"
    cluster_certificate_authority_data = "mock-cert-data"
    cluster_endpoint            = "https://mock.eks.amazonaws.com"
  }
}

dependency "eks_workload_roles" {
  config_path = "../../roles/eks-workloads"
  
  mock_outputs = {
    role_arns = {
      vpc_cni                    = "arn:aws:iam::123456789012:role/mock-vpc-cni-role"
      aws_load_balancer_controller = "arn:aws:iam::123456789012:role/mock-alb-controller-role"
      coredns                    = "arn:aws:iam::123456789012:role/mock-coredns-role"
      kube_proxy                 = "arn:aws:iam::123456789012:role/mock-kube-proxy-role"
    }
  }
}

inputs = {
  cluster_name = dependency.eks_cluster.outputs.cluster_name

  # VPC CNI Pod Identity
  vpc_cni_enabled  = true
  vpc_cni_role_arn = dependency.eks_workload_roles.outputs.role_arns.vpc_cni

  # ALB Controller Pod Identity
  alb_controller_enabled  = true
  alb_controller_role_arn = dependency.eks_workload_roles.outputs.role_arns.aws_load_balancer_controller

  # Enhanced add-ons (using existing roles with Pod Identity trust policies)
  coredns_enhanced_enabled = true
  coredns_role_arn        = dependency.eks_workload_roles.outputs.role_arns.coredns

  kube_proxy_enhanced_enabled = true
  kube_proxy_role_arn         = dependency.eks_workload_roles.outputs.role_arns.kube_proxy

  # Future: Custom Pod Identities can be added here
  custom_pod_identities = {
    # Example:
    # my_app = {
    #   namespace       = "applications"
    #   service_account = "my-app-service-account"
    #   role_arn        = "arn:aws:iam::123456789012:role/my-app-role"
    #   tags = {
    #     Application = "my-app"
    #   }
    # }
  }

  tags = {
    Environment = "non-prod"
    Project     = "eks-security"
    ManagedBy   = "Terragrunt"
    Component   = "pod-identity"
  }
}
