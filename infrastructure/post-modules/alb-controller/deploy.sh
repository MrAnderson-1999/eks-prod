#!/bin/bash

# ALB Controller Deployment Script
# This script handles the complete deployment process for the ALB Controller

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo -e "${BLUE}🚀 ALB Controller Deployment${NC}"
echo "=================================="

# Step 1: Enable public API access
echo -e "\n${YELLOW}Step 1: Enabling public API access...${NC}"
if ! "$PROJECT_ROOT/scripts/enable-public-api.sh"; then
    echo -e "${RED}❌ Failed to enable public API access${NC}"
    exit 1
fi

# Step 2: Update kubeconfig
echo -e "\n${YELLOW}Step 2: Updating kubeconfig...${NC}"
aws eks update-kubeconfig --region us-west-2 --name eks-security-non-prod

# Step 3: Verify cluster access
echo -e "\n${YELLOW}Step 3: Verifying cluster access...${NC}"
if ! kubectl get nodes >/dev/null 2>&1; then
    echo -e "${RED}❌ Cannot access Kubernetes cluster${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Cluster access verified${NC}"

# Step 4: Initialize Terraform
echo -e "\n${YELLOW}Step 4: Initializing Terraform...${NC}"
cd "$SCRIPT_DIR"
terraform init

# Step 5: Plan deployment
echo -e "\n${YELLOW}Step 5: Planning ALB Controller deployment...${NC}"
terraform plan

# Step 6: Apply deployment
echo -e "\n${YELLOW}Step 6: Deploying ALB Controller...${NC}"
read -p "$(echo -e ${YELLOW}Continue with deployment? ${NC}(y/N): )" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    terraform apply -auto-approve
    
    # Step 7: Verify deployment
    echo -e "\n${YELLOW}Step 7: Verifying deployment...${NC}"
    sleep 30  # Wait for pods to start
    
    if kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller | grep Running >/dev/null 2>&1; then
        echo -e "${GREEN}✅ ALB Controller deployed successfully!${NC}"
        kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
    else
        echo -e "${RED}❌ ALB Controller deployment verification failed${NC}"
        kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
    fi
    
    echo -e "\n${BLUE}🎯 Deployment Complete!${NC}"
    echo -e "${YELLOW}💡 Remember to disable public API access when done:${NC}"
    echo -e "   $PROJECT_ROOT/scripts/disable-public-api.sh"
else
    echo -e "${YELLOW}❌ Deployment cancelled${NC}"
fi
