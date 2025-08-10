# =============================================================================
# Root Terragrunt Configuration - All Environments
# =============================================================================
# This file centralizes backend configuration and provider generation
# for all environments and modules.

locals {
  # These will be provided by the module's terragrunt.hcl file
  # which includes both root and env configurations
}

# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "skip"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"

  default_tags {
    tags = {
      Environment = "${local.stage}"
      Project     = "${local.name}"
      ManagedBy   = "Terragrunt"
      Owner       = "platform-team"
      Region      = "${local.region}"
    }
  }
}
EOF
}

# Centralized remote state configuration
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "${local.name}-${local.stage}-terraform-state-${local.bucket_suffixes[local.stage]}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "${local.name}-${local.stage}-terraform-lock"
    kms_key_id     = local.kms_keys[local.stage]
  }
}

# Common inputs that all modules can inherit
inputs = {
  project_name = local.name
  environment  = local.stage
  aws_region   = local.region
  
  # Common tags applied to all resources
  tags = {
    Project     = local.name
    Environment = local.stage
    Owner       = "platform-team"
    ManagedBy   = "Terragrunt"
    Region      = local.region
  }
}
