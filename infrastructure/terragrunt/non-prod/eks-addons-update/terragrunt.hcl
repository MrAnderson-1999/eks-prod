include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "eks" {
  config_path = "../eks"
  mock_outputs = {
    cluster_name = "mock-cluster"
  }
}

dependency "irsa_roles" {
  config_path = "../eks-irsa-roles"
  mock_outputs = {
    role_arns = {
      vpc_cni        = "arn:aws:iam::123456789012:role/mock-vpc-cni-role"
      ebs_csi_driver = "arn:aws:iam::123456789012:role/mock-ebs-csi-role"
    }
  }
}

terraform {
  source = "../../../terraform/modules/eks-addons-update"
}

inputs = {
  cluster_name      = dependency.eks.outputs.cluster_name
  vpc_cni_role_arn  = dependency.irsa_roles.outputs.role_arns.vpc_cni
  ebs_csi_role_arn  = dependency.irsa_roles.outputs.role_arns.ebs_csi_driver

  tags = {
    Environment = "non-prod"
    Project     = "eks-security"
    ManagedBy   = "Terragrunt"
  }
}
