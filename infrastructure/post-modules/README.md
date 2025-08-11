# Applications Layer

This directory contains Kubernetes applications and services that run on the EKS cluster.

## 🏗️ Architecture

```
applications/
├── alb-controller/          # AWS Load Balancer Controller
├── argocd/                  # ArgoCD GitOps platform (coming soon)
├── monitoring/              # Monitoring stack (coming soon)
└── shared/                  # Shared configurations and data sources
```

## 🚀 Deployment Workflow

### Prerequisites
1. Core infrastructure must be deployed via Terragrunt:
   ```bash
   cd infrastructure/terragrunt/non-prod
   terragrunt run-all apply
   ```

2. EKS cluster must have public API access for initial deployment

### Quick Start

#### ALB Controller
```bash
# Deploy ALB Controller (automated script)
./applications/alb-controller/deploy.sh

# Or manual deployment:
# 1. Enable public API access
./scripts/enable-public-api.sh

# 2. Deploy ALB Controller
cd applications/alb-controller
terraform init
terraform apply

# 3. Disable public API access
./scripts/disable-public-api.sh
```

## 🔧 Configuration

### Remote State References
All applications reference the infrastructure state stored in S3:
- **EKS Cluster**: `environments/non-prod/eks/cluster/terraform.tfstate`
- **VPC**: `environments/non-prod/vpc/terraform.tfstate`
- **IAM Roles**: `environments/non-prod/roles/eks-workloads/terraform.tfstate`

### State Storage
Application states are stored separately:
- **Pattern**: `applications/non-prod/{app-name}/terraform.tfstate`
- **Example**: `applications/non-prod/alb-controller/terraform.tfstate`

## 🛡️ Security

### API Access Management
- **Default**: EKS API is private-only
- **Deployment**: Temporarily enable public access
- **Production**: Always revert to private after deployment

### Best Practices
- Deploy applications only when needed
- Always use the provided scripts for API access management
- Verify deployments before disabling public access
- Use GitOps (ArgoCD) for ongoing application management

## 📋 Available Applications

### ✅ ALB Controller
- **Status**: Available
- **Purpose**: AWS Load Balancer Controller for ingress
- **Deployment**: `./applications/alb-controller/deploy.sh`

### 🚧 Coming Soon
- **ArgoCD**: GitOps platform for continuous deployment
- **Monitoring**: Prometheus, Grafana, AlertManager stack
- **Ingress**: NGINX or Traefik ingress controller

## 🆘 Troubleshooting

### Common Issues

#### Cannot Connect to Cluster
```bash
# Check API access
aws eks describe-cluster --name eks-security-non-prod --region us-west-2 \
  --query 'cluster.resourcesVpcConfig.endpointPublicAccess'

# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name eks-security-non-prod

# Test access
kubectl get nodes
```

#### Terraform State Issues
```bash
# Refresh remote state
terraform refresh

# Check remote state access
aws s3 ls s3://terraform-state-740047840996-us-west-2/environments/non-prod/
```

#### Application Not Starting
```bash
# Check pod status
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```
