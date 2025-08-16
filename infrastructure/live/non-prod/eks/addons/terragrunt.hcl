include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path = find_in_parent_folders("env.hcl")
}

terraform {
  source = "../../../../modules//eks-addons"
}

dependency "eks" {
  config_path = "../cluster"
  
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    cluster_name                          = "mock-cluster"
    cluster_endpoint                      = "https://mock-endpoint"
    cluster_certificate_authority_data   = "LS0tLS1CRUdJTi"
    oidc_provider_arn                    = "arn:aws:iam::123456789012:oidc-provider/mock"
    vpc_id                               = "vpc-mock"
    node_security_group_id               = "sg-mock"
  }
}

dependency "vpc" {
  config_path = "../../vpc"
  
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id = "vpc-mock"
  }
}

inputs = {
  # Cluster information from EKS module
  cluster_name                          = dependency.eks.outputs.cluster_name
  cluster_endpoint                      = dependency.eks.outputs.cluster_endpoint
  cluster_certificate_authority_data   = dependency.eks.outputs.cluster_certificate_authority_data
  oidc_provider_arn                    = dependency.eks.outputs.oidc_provider_arn
  vpc_id                               = dependency.eks.outputs.vpc_id
  node_security_group_id               = dependency.eks.outputs.node_security_group_id
  
  # EKS Addons configuration
  enable_ebs_csi_driver = true
  vpc_cni_version       = null  # Use latest compatible version
  ebs_csi_driver_version = null # Use latest compatible version
  
  # AWS Load Balancer Controller
  aws_load_balancer_controller_chart_version = "1.13.0"
  aws_load_balancer_controller_log_level     = "info"
  
  # Optional: External DNS (disabled by default)
  enable_external_dns           = false
  external_dns_hosted_zone_arns = []
  
  # Optional: Cert Manager (disabled by default) 
  enable_cert_manager           = false
  cert_manager_hosted_zone_arns = []
  
  # Optional: ArgoCD (disabled by default)
  enable_argocd_ecr_access = false
  enable_argocd_deployment = false
  argocd_chart_version     = "7.6.12"
  argocd_domain           = "argocd.${local.env_vars.locals.domain_name}"
  enable_argocd_ingress   = false
  argocd_certificate_arn  = null
  
  # Tags
  tags = {
    Environment = "non-prod"
    Module      = "eks-addons"
    ManagedBy   = "terraform"
  }
}
