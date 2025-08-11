# Include root configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}



# Set the source of the module
terraform {
  source = "${find_in_parent_folders("modules")}/kms"
}

inputs = {
  name_prefix = "eks-security-non-prod"
  kms_keys = {
    eks_security = {
      description = "KMS key for EKS security"
      deletion_window_in_days = 7
      enable_key_rotation = true
      key_usage = "ENCRYPT_DECRYPT"
      customer_master_key_spec = "SYMMETRIC_DEFAULT"
      aliases = ["eks-security-non-prod-kms-key"]
    }
    
  }
}