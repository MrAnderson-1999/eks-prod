#!/bin/bash

# Script to disable public API access for EKS cluster (revert to private-only)
# Usage: ./disable-public-api.sh [CLUSTER_NAME] [REGION]

set -e

# Default values
DEFAULT_CLUSTER="eks-security-non-prod"
DEFAULT_REGION="us-west-2"

# Parse arguments
CLUSTER_NAME="${1:-$DEFAULT_CLUSTER}"
REGION="${2:-$DEFAULT_REGION}"

# Function to disable public API access
disable_public_access() {
    local cluster_name="$1"
    local region="$2"
    
    echo "🔒 Disabling public API access for cluster: $cluster_name"
    echo "📍 Region: $region"
    
    # Disable public access, keep private access enabled
    UPDATE_OUTPUT=$(aws eks update-cluster-config \
        --name "$cluster_name" \
        --resources-vpc-config endpointPrivateAccess=true,endpointPublicAccess=false \
        --region "$region" \
        --output json)
    
    UPDATE_ID=$(echo "$UPDATE_OUTPUT" | jq -r '.update.id')
    echo "📋 Update ID: $UPDATE_ID"
    
    # Wait for update to complete
    echo "⏳ Waiting for EKS endpoint update to complete..."
    aws eks wait cluster-active --cluster-name "$cluster_name" --region "$region"
    
    # Check update status
    STATUS=$(aws eks describe-update \
        --name "$cluster_name" \
        --update-id "$UPDATE_ID" \
        --region "$region" \
        --query 'update.status' \
        --output text)
    
    if [ "$STATUS" = "Successful" ]; then
        echo "✅ EKS cluster API is now private-only!"
        echo ""
        echo "🔧 Next steps:"
        echo "   • kubectl commands will only work from within the VPC"
        echo "   • Use a bastion host, VPN, or AWS Cloud9 for cluster access"
        echo "   • Run 'terragrunt apply' to ensure Terraform state matches"
    else
        echo "❌ Update failed with status: $STATUS"
        exit 1
    fi
}

# Function to display current cluster config
show_current_config() {
    local cluster_name="$1"
    local region="$2"
    
    echo "📊 Current EKS endpoint configuration:"
    aws eks describe-cluster \
        --name "$cluster_name" \
        --region "$region" \
        --query 'cluster.resourcesVpcConfig.{EndpointPrivateAccess:endpointPrivateAccess,EndpointPublicAccess:endpointPublicAccess,PublicAccessCidrs:publicAccessCidrs}' \
        --output table
}

# Main execution
echo "🔒 EKS Public API Access Disabler"
echo "================================="

echo ""
echo "📋 Configuration:"
echo "   Cluster: $CLUSTER_NAME"
echo "   Region: $REGION"
echo ""

# Show current config
show_current_config "$CLUSTER_NAME" "$REGION"
echo ""

# Confirm before proceeding
read -p "🤔 Disable public API access for this cluster? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    disable_public_access "$CLUSTER_NAME" "$REGION"
    echo ""
    show_current_config "$CLUSTER_NAME" "$REGION"
else
    echo "❌ Operation cancelled"
    exit 0
fi

echo ""
echo "🎯 Script completed successfully!"
