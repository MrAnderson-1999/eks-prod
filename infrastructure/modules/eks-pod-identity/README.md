# EKS Pod Identity Module

This module manages EKS Pod Identity associations, which is the modern replacement for IRSA (IAM Roles for Service Accounts). Pod Identity provides a more efficient and secure way to associate IAM roles with Kubernetes service accounts.

## Features

- **VPC CNI Pod Identity**: Manages networking permissions for the VPC CNI add-on
- **ALB Controller Pod Identity**: Manages load balancer permissions for the AWS Load Balancer Controller
- **CoreDNS Enhanced**: Optional enhanced logging capabilities for CoreDNS
- **kube-proxy Enhanced**: Optional enhanced monitoring for kube-proxy
- **Custom Pod Identities**: Support for custom workload Pod Identity associations

## Prerequisites

- EKS cluster with Kubernetes version 1.24 or later
- EKS Pod Identity Agent add-on installed on the cluster
- IAM roles with appropriate trust policies for Pod Identity

## Usage

```hcl
module "pod_identity" {
  source = "../modules/eks-pod-identity"

  cluster_name = "my-eks-cluster"

  # VPC CNI Pod Identity
  vpc_cni_enabled  = true
  vpc_cni_role_arn = "arn:aws:iam::123456789012:role/vpc-cni-role"

  # ALB Controller Pod Identity
  alb_controller_enabled  = true
  alb_controller_role_arn = "arn:aws:iam::123456789012:role/alb-controller-role"

  # Optional: Enhanced add-ons
  coredns_enhanced_enabled = true
  coredns_role_arn        = "arn:aws:iam::123456789012:role/coredns-role"

  kube_proxy_enhanced_enabled = true
  kube_proxy_role_arn         = "arn:aws:iam::123456789012:role/kube-proxy-role"

  # Custom Pod Identities
  custom_pod_identities = {
    my_app = {
      namespace       = "default"
      service_account = "my-app-sa"
      role_arn        = "arn:aws:iam::123456789012:role/my-app-role"
      tags = {
        Application = "my-app"
      }
    }
  }

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

## Benefits over IRSA

| **Aspect** | **IRSA** | **Pod Identity** |
|------------|----------|------------------|
| **Token Management** | Manual token exchange | Automatic by EKS |
| **Performance** | Token refresh overhead | Direct AWS API calls |
| **Setup Complexity** | Complex OIDC setup | Simple association |
| **Troubleshooting** | Complex token issues | Clear error messages |
| **Dependencies** | Circular dependencies | Linear dependencies |

## Outputs

- `vpc_cni_association_arn/id`: VPC CNI Pod Identity association details
- `alb_controller_association_arn/id`: ALB Controller Pod Identity association details
- `coredns_association_arn/id`: CoreDNS Pod Identity association details (if enabled)
- `kube_proxy_association_arn/id`: kube-proxy Pod Identity association details (if enabled)
- `custom_associations`: Map of all custom Pod Identity associations
- `all_associations`: Complete summary of all associations

## Notes

- Pod Identity requires the EKS Pod Identity Agent add-on to be installed
- Service accounts must exist in the cluster before creating associations
- IAM roles must have appropriate trust policies for Pod Identity
- This module replaces the need for IRSA and OIDC providers
