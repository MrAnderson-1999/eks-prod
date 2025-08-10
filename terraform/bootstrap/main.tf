# =============================================================================
# Bootstrap Configuration - Creates Terraform Backend Infrastructure
# =============================================================================
# This configuration creates the S3 bucket and DynamoDB table needed
# for Terraform remote state storage and locking.
# 
# Run this FIRST before any other Terraform configurations.
# This uses local state since it creates the remote state infrastructure.

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  
  # Uses local state - DO NOT add backend configuration here
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform-bootstrap"
    }
  }
}

# =============================================================================
# Variables
# =============================================================================

variable "aws_region" {
  description = "AWS region for backend resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (develop, staging, production)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning on the state bucket"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable encryption on the state bucket"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow Terraform to destroy the bucket even if it contains objects (USE WITH CAUTION)"
  type        = bool
  default     = false
}

# =============================================================================
# Locals
# =============================================================================

locals {
  bucket_name = "${var.project_name}-${var.environment}-terraform-state"
  table_name  = "${var.project_name}-${var.environment}-terraform-lock"
  
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "terraform-backend"
    ManagedBy   = "terraform-bootstrap"
  }
}

# =============================================================================
# Random suffix for bucket uniqueness
# =============================================================================

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# =============================================================================
# S3 Bucket for Terraform State
# =============================================================================

resource "aws_s3_bucket" "terraform_state" {
  bucket        = "${local.bucket_name}-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy

  tags = merge(local.common_tags, {
    Name = "${local.bucket_name}-${random_id.bucket_suffix.hex}"
  })
}

# Enable versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
    }
    bucket_key_enabled = true
  }
}

# Add notification configuration for monitoring
resource "aws_s3_bucket_notification" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  # Enable EventBridge for state file changes monitoring
  eventbridge = true
}

# Bucket policy for additional security
resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyUnSecureCommunications"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "DenyUnencryptedObjectUploads"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      {
        Sid    = "DenyIncorrectKMSKey"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.terraform_state.arn
          }
        }
      }
    ]
  })
}

# Block public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  depends_on = [aws_s3_bucket_versioning.terraform_state]

  rule {
    id     = "terraform_state_lifecycle"
    status = "Enabled"
    
    # Apply to all objects in the bucket
    filter {}

    # NO expiration for current versions - keep state files indefinitely
    # Terraform state files are critical and storage cost is minimal
    
    # Keep old versions for 1 year - sufficient for rollback/audit
    noncurrent_version_expiration {
      noncurrent_days = 1095 
    }

    # Clean up incomplete multipart uploads quickly
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# =============================================================================
# DynamoDB Table for State Locking
# =============================================================================

resource "aws_dynamodb_table" "terraform_lock" {
  name           = local.table_name
  billing_mode   = "PAY_PER_REQUEST"  # More cost-effective for infrequent use
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # Enable point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  # Enable encryption at rest
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.terraform_state.arn
  }

  # Deletion protection
  deletion_protection_enabled = true

  tags = merge(local.common_tags, {
    Name        = local.table_name
    Description = "Terraform state locking for ${var.environment} environment"
  })
}

# KMS Key for DynamoDB encryption
resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state encryption in ${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow DynamoDB Service"
        Effect = "Allow"
        Principal = {
          Service = "dynamodb.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow S3 Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.table_name}-key"
  })
}

# KMS Key Alias
resource "aws_kms_alias" "terraform_state" {
  name          = "alias/${local.table_name}-key-${random_id.bucket_suffix.hex}"
  target_key_id = aws_kms_key.terraform_state.key_id
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# =============================================================================
# Outputs
# =============================================================================

output "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "state_bucket_region" {
  description = "Region of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.region
}

output "lock_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "lock_table_arn" {
  description = "ARN of the DynamoDB table for Terraform state locking"
  value       = aws_dynamodb_table.terraform_lock.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  value       = aws_kms_key.terraform_state.arn
}

output "kms_key_id" {
  description = "ID of the KMS key used for encryption"
  value       = aws_kms_key.terraform_state.id
}

output "backend_configuration" {
  description = "Backend configuration for use in other Terraform configurations"
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    region         = var.aws_region
    dynamodb_table = aws_dynamodb_table.terraform_lock.name
    encrypt        = var.enable_encryption
  }
}

output "backend_config_file" {
  description = "Backend configuration in tfvars format"
  value = <<-EOT
# =============================================================================
# Terraform Backend Configuration - ${var.environment} Environment
# =============================================================================
# This file was generated by the bootstrap process
# Generated on: ${timestamp()}

bucket         = "${aws_s3_bucket.terraform_state.id}"
key            = "${var.environment}/terraform.tfstate"
region         = "${var.aws_region}"
dynamodb_table = "${aws_dynamodb_table.terraform_lock.name}"
encrypt        = ${var.enable_encryption}
kms_key_id     = "${aws_kms_key.terraform_state.arn}"
EOT
} 