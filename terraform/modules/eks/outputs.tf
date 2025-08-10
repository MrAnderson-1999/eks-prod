# EKS Module Outputs

# Cluster Information
output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_id" {
  description = "The ID of the EKS cluster. Note: currently a value is returned only for local EKS clusters created on Outposts"
  value       = module.eks.cluster_id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_platform_version" {
  description = "Platform version for the EKS cluster"
  value       = module.eks.cluster_platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = module.eks.cluster_status
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = module.eks.cluster_primary_security_group_id
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = module.eks.cluster_version
}

# IRSA
output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if `enable_irsa = true`"
  value       = module.eks.oidc_provider_arn
}

output "cluster_tls_certificate_sha1_fingerprint" {
  description = "The SHA1 fingerprint of the public key of the cluster's certificate"
  value       = module.eks.cluster_tls_certificate_sha1_fingerprint
}

# Node Groups
output "eks_managed_node_groups" {
  description = "Map of attribute maps for all EKS managed node groups created"
  value       = module.eks.eks_managed_node_groups
}

output "eks_managed_node_groups_autoscaling_group_names" {
  description = "List of the autoscaling group names created by EKS managed node groups"
  value       = module.eks.eks_managed_node_groups_autoscaling_group_names
}

output "node_security_group_arn" {
  description = "Amazon Resource Name (ARN) of the node shared security group"
  value       = module.eks.node_security_group_arn
}

output "node_security_group_id" {
  description = "ID of the node shared security group"
  value       = module.eks.node_security_group_id
}

# Security
output "cluster_security_group_arn" {
  description = "Amazon Resource Name (ARN) of the cluster security group"
  value       = module.eks.cluster_security_group_arn
}

output "cluster_security_group_id" {
  description = "ID of the cluster security group"
  value       = module.eks.cluster_security_group_id
}

# IAM Role
output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = module.eks.cluster_iam_role_name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "cluster_iam_role_unique_id" {
  description = "Stable and unique string identifying the IAM role associated with EKS cluster"
  value       = module.eks.cluster_iam_role_unique_id
}

# KMS
output "kms_key_arn" {
  description = "The Amazon Resource Name (ARN) of the KMS key used for EKS secret encryption"
  value       = var.create_kms_key ? aws_kms_key.eks[0].arn : var.external_kms_key_arn
}

output "kms_key_id" {
  description = "The globally unique identifier for the KMS key used for EKS secret encryption"
  value       = var.create_kms_key ? aws_kms_key.eks[0].key_id : null
}

# CloudWatch
output "cloudwatch_log_group_name" {
  description = "Name of cloudwatch log group created"
  value       = var.enable_cluster_logging ? aws_cloudwatch_log_group.eks_cluster[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "Arn of cloudwatch log group created"
  value       = var.enable_cluster_logging ? aws_cloudwatch_log_group.eks_cluster[0].arn : null
}

# Add-ons
output "cluster_addons" {
  description = "Map of attribute maps for all EKS cluster addons enabled"
  value       = module.eks.cluster_addons
}

# Additional Security Resources
output "additional_node_security_group_id" {
  description = "The ID of the additional node security group"
  value       = var.create_additional_node_security_group ? aws_security_group.additional_node_sg[0].id : null
}

output "ebs_csi_driver_irsa_role_arn" {
  description = "The ARN of the EBS CSI driver IRSA role"
  value       = module.ebs_csi_driver_irsa.iam_role_arn
}

# For kubectl configuration
output "cluster_ca_certificate" {
  description = "Cluster CA certificate for kubectl configuration"
  value       = base64decode(module.eks.cluster_certificate_authority_data)
  sensitive   = true
}

# Helper output for kubeconfig
output "kubeconfig_update_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
