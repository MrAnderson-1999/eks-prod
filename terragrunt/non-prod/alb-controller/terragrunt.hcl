# Include root configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Include environment configuration to expose locals
include "env" {
  path = find_in_parent_folders("env.hcl")
  expose = true
}

dependency "eks" {
  config_path = "../eks"
  mock_outputs = {
    cluster_name      = "mock-cluster"
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/mock"
    cluster_oidc_issuer_url = "https://mock.oidc.url"
  }
}

terraform {
  source = "../../../terraform/modules/alb-controller"
}

inputs = {
  project_name      = include.env.locals.name
  environment       = include.env.locals.stage
  cluster_name      = dependency.eks.outputs.cluster_name
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
  oidc_issuer       = dependency.eks.outputs.cluster_oidc_issuer_url
  
  tags = {
    Environment = include.env.locals.stage
    Project     = include.env.locals.name
    ManagedBy   = "Terraform"
    Purpose     = "ALB Controller IRSA"
  }
}
