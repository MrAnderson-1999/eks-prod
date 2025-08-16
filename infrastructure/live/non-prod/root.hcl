# =============================================================================
# Non-Production Environment Root Configuration
# =============================================================================

# Load environment-specific variables
locals {
  env_vars = read_terragrunt_config("${get_parent_terragrunt_dir()}/env.hcl")
  
  # Environment-specific values
  name          = local.env_vars.locals.name
  region        = local.env_vars.locals.region
  stage         = local.env_vars.locals.stage
  bucket_suffix = "ac97c39c"
  kms_key       = "arn:aws:kms:us-west-2:740047840996:key/af7b51eb-4fae-435e-b563-1248347b5892"
}

# Generate centralized provider versions and configuration
generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.95.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes" 
      version = "= 2.33.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "= 2.15.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "= 3.6.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "= 4.0.6"
    }
  }
}
EOF
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
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
