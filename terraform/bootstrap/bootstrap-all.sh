#!/bin/bash

# =============================================================================
# Bootstrap All Environments - One-time Backend Initialization
# =============================================================================
# Creates S3 buckets and DynamoDB tables for all environments at once
# This allows you to delete local bootstrap state after completion

set -e

# Default values
PROJECT_NAME="${1:-eks-security}"
AWS_REGION="${2:-us-west-2}"
ENVIRONMENTS=("non-prod" "prod")

# Helper functions
info() { echo "ℹ️  $1"; }
success() { echo "✅ $1"; }
error() { echo "❌ $1"; exit 1; }

# Validate prerequisites
command -v terraform >/dev/null || error "Terraform not installed"
command -v aws >/dev/null || error "AWS CLI not installed"
aws sts get-caller-identity >/dev/null || error "AWS credentials not configured"

# Navigate to bootstrap directory
cd "$(dirname "$0")"

info "Bootstrapping all environments: ${ENVIRONMENTS[*]}"
info "Project: $PROJECT_NAME"
info "Region: $AWS_REGION"
echo ""

# Track created resources
declare -A CREATED_BUCKETS
declare -A CREATED_TABLES
declare -A CREATED_KMS_KEYS

# Bootstrap each environment
for ENVIRONMENT in "${ENVIRONMENTS[@]}"; do
    info "=== Bootstrapping $ENVIRONMENT environment ==="
    
    # Create tfvars file for this environment if it doesn't exist
    TFVARS_FILE="env/${ENVIRONMENT}.tfvars"
    if [[ ! -f "$TFVARS_FILE" ]]; then
        info "Creating $TFVARS_FILE"
        mkdir -p env
        cat > "$TFVARS_FILE" << EOF
# Bootstrap Configuration Variables - ${ENVIRONMENT} Environment
aws_region   = "${AWS_REGION}"
environment  = "${ENVIRONMENT}"
project_name = "${PROJECT_NAME}"

# Backend Configuration
enable_versioning = true
enable_encryption = true
force_destroy     = false
EOF
    fi

    # Environment-specific state file
    STATE_FILE="terraform.tfstate.${ENVIRONMENT}"
    
    # Check if backend resources already exist
    BUCKET_PREFIX="${PROJECT_NAME}-${ENVIRONMENT}-terraform-state"
    TABLE_NAME="${PROJECT_NAME}-${ENVIRONMENT}-terraform-lock"
    
    EXISTING_BUCKET=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '${BUCKET_PREFIX}-')].Name" --output text 2>/dev/null | head -1)

    if [[ -n "$EXISTING_BUCKET" ]]; then
        info "Backend resources already exist for ${ENVIRONMENT}"
        info "Found existing bucket: ${EXISTING_BUCKET}"
        ACTUAL_BUCKET="$EXISTING_BUCKET"
        
        # Get KMS key ARN from existing infrastructure
        KMS_KEY_ARN=$(terraform output -state="$STATE_FILE" -raw kms_key_arn 2>/dev/null || echo "")
        if [[ -z "$KMS_KEY_ARN" ]]; then
            info "KMS key ARN not found in outputs, refreshing Terraform state..."
            terraform refresh -state="$STATE_FILE" -var-file="$TFVARS_FILE" >/dev/null 2>&1
            KMS_KEY_ARN=$(terraform output -state="$STATE_FILE" -raw kms_key_arn 2>/dev/null || echo "")
        fi
        
        if [[ -z "$KMS_KEY_ARN" ]]; then
            error "Failed to get KMS key ARN from existing infrastructure"
        fi
    else
        info "Creating backend resources for ${ENVIRONMENT}..."
        
        # Apply Terraform configuration
        terraform apply -state="$STATE_FILE" -var-file="$TFVARS_FILE" -auto-approve
        
        # Get the bucket name and KMS key from Terraform output
        ACTUAL_BUCKET=$(terraform output -state="$STATE_FILE" -raw state_bucket_name)
        KMS_KEY_ARN=$(terraform output -state="$STATE_FILE" -raw kms_key_arn)
        
        if [[ -z "$ACTUAL_BUCKET" ]]; then
            error "Failed to get bucket name from Terraform output"
        fi
        
        if [[ -z "$KMS_KEY_ARN" ]]; then
            error "Failed to get KMS key ARN from Terraform output"
        fi
        
        success "Backend resources created successfully for ${ENVIRONMENT}"
        info "Created bucket: ${ACTUAL_BUCKET}"
    fi
    
    # Store created resources
    CREATED_BUCKETS[$ENVIRONMENT]="$ACTUAL_BUCKET"
    CREATED_TABLES[$ENVIRONMENT]="$TABLE_NAME"
    CREATED_KMS_KEYS[$ENVIRONMENT]="$KMS_KEY_ARN"
    
    success "Completed ${ENVIRONMENT} environment"
    echo ""
done

# Summary
success "Bootstrap completed for all environments!"
echo ""
info "Created Resources Summary:"
echo ""

for ENVIRONMENT in "${ENVIRONMENTS[@]}"; do
    echo "📁 ${ENVIRONMENT^^} ENVIRONMENT:"
    echo "  S3 Bucket:     ${CREATED_BUCKETS[$ENVIRONMENT]}"
    echo "  DynamoDB Table: ${CREATED_TABLES[$ENVIRONMENT]}"
    echo "  KMS Key:       ${CREATED_KMS_KEYS[$ENVIRONMENT]}"
    echo ""
done

info "Backend configurations are now centralized in:"
echo "  📄 /terragrunt/terragrunt.hcl (root configuration)"
echo "  📄 /terragrunt/non-prod/env.hcl"
echo "  📄 /terragrunt/prod/env.hcl"
echo ""

info "You can now safely:"
echo "  1. Use the centralized terragrunt configuration"
echo "  2. Delete bootstrap local state files (terraform.tfstate.*)"
echo "  3. All environments will automatically use correct backends"
echo ""

success "🚀 All environments are ready for Terragrunt operations!"
