# Provider Version Standards

This document defines the standardized provider versions used across all Terraform modules in this project.

## Version Strategy

- **Terraform**: `>= 1.0` (minimum required version)
- **Provider Constraints**: Use `~> X.Y` format for minor version flexibility with major version lock
- **Lock Files**: Always commit `.terraform.lock.hcl` files to ensure consistent provider versions

## Standardized Provider Versions

### Core Providers

| Provider | Version Constraint | Latest Tested | Usage |
|----------|-------------------|---------------|-------|
| `hashicorp/aws` | `~> 6.0` | `6.8.0` | All AWS resources |
| `hashicorp/random` | `~> 3.5` | `3.5.x` | Bootstrap (random suffixes) |
| `hashicorp/tls` | `~> 4.0` | `4.1.0` | IAM roles (for RSA keys) |

### Kubernetes/Helm Providers (EKS Module Only)

| Provider | Version Constraint | Latest Tested | Usage |
|----------|-------------------|---------------|-------|
| `hashicorp/kubernetes` | `~> 2.30` | `2.30.x` | EKS cluster configuration |
| `hashicorp/helm` | `~> 2.10` | `2.10.x` | Helm chart deployments |

### External Module Versions

| Module | Version Constraint | Purpose |
|--------|-------------------|---------|
| `terraform-aws-modules/vpc/aws` | `~> 5.0` | VPC infrastructure |
| `terraform-aws-modules/eks/aws` | `~> 20.0` | EKS cluster |

## Module-Specific Versions

### Bootstrap Module
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
    random = { source = "hashicorp/random", version = "~> 3.5" }
  }
}
```

### VPC Module
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}
```

### Security Groups Module
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}
```

### IAM Roles Module
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
    tls = { source = "hashicorp/tls", version = "~> 4.0" }
  }
}
```

### EKS Module
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.30" }
    helm = { source = "hashicorp/helm", version = "~> 2.10" }
  }
}
```

### ALB Controller Module
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}
```

## Version Update Policy

1. **Major Version Updates**: Require thorough testing and coordinated updates across all modules
2. **Minor Version Updates**: Allowed automatically within constraints (e.g., `~> 6.0` allows `6.1`, `6.2`, etc.)
3. **Patch Version Updates**: Handled automatically by Terraform lock files

## Verification Commands

```bash
# Check all provider versions across modules
find . -name "versions.tf" -exec echo "=== {} ===" \; -exec cat {} \;

# Verify lock file consistency
find . -name ".terraform.lock.hcl" -exec echo "=== {} ===" \; -exec grep -A 3 "provider.*aws" {} \;

# Clean and re-initialize to test version constraints
find . -name ".terragrunt-cache" -exec rm -rf {} + 2>/dev/null
find . -name ".terraform" -exec rm -rf {} + 2>/dev/null
terragrunt run-all init
```

Last Updated: $(date)
