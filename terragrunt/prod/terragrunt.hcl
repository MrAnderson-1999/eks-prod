# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "skip"
  contents  = <<EOF
provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      Environment = "prod"
      Project     = "eks-security"
      ManagedBy   = "Terragrunt"
      Owner       = "platform-team"
      Region      = "us-west-2"
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
    bucket         = "eks-security-prod-terraform-state-aed59318"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "eks-security-prod-terraform-lock"
    kms_key_id     = "arn:aws:kms:us-west-2:740047840996:key/75e767ae-2e54-4962-af55-bfcfe7289346"
  }
}
