#!/bin/bash

# Script to temporarily enable public API access for EKS cluster
# Usage: ./enable-public-api.sh [CLUSTER_NAME] [REGION] [YOUR_IP]

set -e

# Default values
DEFAULT_CLUSTER="eks-security-non-prod"
DEFAULT_REGION="us-west-2"

# Parse arguments
CLUSTER_NAME="${1:-$DEFAULT_CLUSTER}"
REGION="${2:-$DEFAULT_REGION}"
USER_IP="${3}"

# Function to get current public IP
get_current_ip() {
    echo "🌐 Getting current public IP..."
    CURRENT_IP=$(curl -s ifconfig.me)
    echo "✅ Current IP: $CURRENT_IP"
    echo "$CURRENT_IP"
}

# Function to enable public API access
enable_public_access() {
    local cluster_name="$1"
    local region="$2"
    local ip_cidr="$3"
    
    echo "🔓 Enabling public API access for cluster: $cluster_name"
    echo "📍 Region: $region"
    echo "🛡️  Allowed IP: $ip_cidr"
    
    # Enable public access with specific IP
    UPDATE_OUTPUT=$(aws eks update-cluster-config \
        --name "$cluster_name" \
        --resources-vpc-config endpointPrivateAccess=true,endpointPublicAccess=true,publicAccessCidrs="$ip_cidr" \
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
        echo "✅ EKS cluster API is now publicly accessible!"
        echo ""
        echo "🔧 Next steps:"
        echo "   1. Update kubeconfig: aws eks update-kubeconfig --region $region --name $cluster_name"
        echo "   2. Test access: kubectl get nodes"
        echo "   3. Deploy your applications (ArgoCD, etc.)"
        echo ""
        echo "⚠️  Remember to run 'terragrunt apply' later to revert to private access"
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
echo "🚀 EKS Public API Access Enabler"
echo "=================================="

# Get user IP if not provided
if [ -z "$USER_IP" ]; then
    USER_IP=$(get_current_ip)
fi

# Convert IP to CIDR if needed
if [[ "$USER_IP" != *"/32" ]]; then
    USER_IP="$USER_IP/32"
fi

echo ""
echo "📋 Configuration:"
echo "   Cluster: $CLUSTER_NAME"
echo "   Region: $REGION"
echo "   Your IP: $USER_IP"
echo ""

# Show current config
show_current_config "$CLUSTER_NAME" "$REGION"
echo ""

# Confirm before proceeding
read -p "🤔 Enable public API access for this cluster? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    enable_public_access "$CLUSTER_NAME" "$REGION" "$USER_IP"
    echo ""
    show_current_config "$CLUSTER_NAME" "$REGION"
else
    echo "❌ Operation cancelled"
    exit 0
fi

echo ""
echo "🎯 Script completed successfully!"
echo "💡 Tip: Create an alias in your ~/.zshrc:"
echo "   alias eks-public='$PWD/$(basename "$0")'"
