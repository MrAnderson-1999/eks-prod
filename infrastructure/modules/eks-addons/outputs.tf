#==============================================================================
# ALB CONTROLLER OUTPUTS
#==============================================================================

output "alb_security_group_id" {
  description = "Security group ID for ALB to nodes communication"
  value       = aws_security_group.alb_to_nodes.id
}

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = module.aws_load_balancer_controller_irsa.iam_role_arn
}

output "aws_load_balancer_controller_ready" {
  description = "Indicates when AWS Load Balancer Controller is ready"
  value       = time_sleep.wait_for_alb_controller.id
}

#==============================================================================
# IRSA ROLE OUTPUTS
#==============================================================================

output "vpc_cni_role_arn" {
  description = "ARN of the VPC CNI IAM role"
  value       = module.vpc_cni_irsa.iam_role_arn
}

output "ebs_csi_driver_role_arn" {
  description = "ARN of the EBS CSI driver IAM role"
  value       = var.enable_ebs_csi_driver ? module.ebs_csi_driver_irsa[0].iam_role_arn : null
}

output "external_dns_role_arn" {
  description = "ARN of the External DNS IAM role"
  value       = var.enable_external_dns ? module.external_dns_irsa[0].iam_role_arn : null
}

output "cert_manager_role_arn" {
  description = "ARN of the Cert Manager IAM role"
  value       = var.enable_cert_manager ? module.cert_manager_irsa[0].iam_role_arn : null
}

output "argocd_role_arn" {
  description = "ARN of the ArgoCD IAM role"
  value       = var.enable_argocd_ecr_access ? module.argocd_irsa[0].iam_role_arn : null
}

#==============================================================================
# ARGOCD OUTPUTS
#==============================================================================

output "argocd_namespace" {
  description = "ArgoCD namespace name"
  value       = var.enable_argocd_deployment ? kubernetes_namespace.argocd[0].metadata[0].name : null
}

output "argocd_ready" {
  description = "Indicates when ArgoCD is ready"
  value       = var.enable_argocd_deployment ? time_sleep.wait_for_argocd[0].id : null
}

#==============================================================================
# ADDON STATUS OUTPUTS
#==============================================================================

output "vpc_cni_addon_status" {
  description = "Status of VPC CNI addon with IRSA"
  value       = aws_eks_addon.vpc_cni_irsa.status
}

output "ebs_csi_driver_addon_status" {
  description = "Status of EBS CSI driver addon with IRSA"
  value       = var.enable_ebs_csi_driver ? aws_eks_addon.ebs_csi_driver_irsa[0].status : null
}