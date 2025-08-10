# Include root configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Set the source of the module
terraform {
  source = "../../../terraform/modules/kms"
}

inputs = {
  name_prefix = "eks-security-prod"
  kms_keys = {
    eks_security = {
      description = "KMS key for EKS security in production"
      deletion_window_in_days = 7
      enable_key_rotation = true
      key_usage = "ENCRYPT_DECRYPT"
      customer_master_key_spec = "SYMMETRIC_DEFAULT"
    }
  }
}
