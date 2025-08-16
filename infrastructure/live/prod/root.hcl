# =============================================================================
# Production Environment Root Configuration
# =============================================================================

# Load environment-specific variables
locals {
  env_vars = read_terragrunt_config("${get_parent_terragrunt_dir()}/env.hcl")
  
  # Environment-specific values
  name          = local.env_vars.locals.name
  region        = local.env_vars.locals.region
  stage         = local.env_vars.locals.stage
  bucket_suffix = "aed59318"
  kms_key       = "arn:aws:kms:us-west-2:740047840996:key/75e767ae-2e54-4962-af55-bfcfe7289346"
}

# Centralized remote state configuration
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "${local.name}-${local.stage}-terraform-state-${local.bucket_suffix}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "${local.name}-${local.stage}-terraform-lock"
    kms_key_id     = local.kms_key
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
