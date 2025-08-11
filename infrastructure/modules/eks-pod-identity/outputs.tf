# EKS Pod Identity Module Outputs

output "vpc_cni_association_arn" {
  description = "ARN of the VPC CNI Pod Identity association"
  value       = var.vpc_cni_enabled ? aws_eks_pod_identity_association.vpc_cni[0].association_arn : null
}

output "vpc_cni_association_id" {
  description = "ID of the VPC CNI Pod Identity association"
  value       = var.vpc_cni_enabled ? aws_eks_pod_identity_association.vpc_cni[0].association_id : null
}

output "alb_controller_association_arn" {
  description = "ARN of the ALB Controller Pod Identity association"
  value       = var.alb_controller_enabled ? aws_eks_pod_identity_association.aws_load_balancer_controller[0].association_arn : null
}

output "alb_controller_association_id" {
  description = "ID of the ALB Controller Pod Identity association"
  value       = var.alb_controller_enabled ? aws_eks_pod_identity_association.aws_load_balancer_controller[0].association_id : null
}

output "coredns_association_arn" {
  description = "ARN of the CoreDNS Pod Identity association"
  value       = var.coredns_enhanced_enabled ? aws_eks_pod_identity_association.coredns[0].association_arn : null
}

output "coredns_association_id" {
  description = "ID of the CoreDNS Pod Identity association"
  value       = var.coredns_enhanced_enabled ? aws_eks_pod_identity_association.coredns[0].association_id : null
}

output "kube_proxy_association_arn" {
  description = "ARN of the kube-proxy Pod Identity association"
  value       = var.kube_proxy_enhanced_enabled ? aws_eks_pod_identity_association.kube_proxy[0].association_arn : null
}

output "kube_proxy_association_id" {
  description = "ID of the kube-proxy Pod Identity association"
  value       = var.kube_proxy_enhanced_enabled ? aws_eks_pod_identity_association.kube_proxy[0].association_id : null
}

output "custom_associations" {
  description = "Map of custom Pod Identity associations"
  value = {
    for key, association in aws_eks_pod_identity_association.custom : key => {
      association_arn = association.association_arn
      association_id  = association.association_id
    }
  }
}

output "all_associations" {
  description = "All Pod Identity associations created by this module"
  value = {
    vpc_cni = {
      enabled         = var.vpc_cni_enabled
      association_arn = var.vpc_cni_enabled ? aws_eks_pod_identity_association.vpc_cni[0].association_arn : null
      association_id  = var.vpc_cni_enabled ? aws_eks_pod_identity_association.vpc_cni[0].association_id : null
    }
    alb_controller = {
      enabled         = var.alb_controller_enabled
      association_arn = var.alb_controller_enabled ? aws_eks_pod_identity_association.aws_load_balancer_controller[0].association_arn : null
      association_id  = var.alb_controller_enabled ? aws_eks_pod_identity_association.aws_load_balancer_controller[0].association_id : null
    }
    coredns = {
      enabled         = var.coredns_enhanced_enabled
      association_arn = var.coredns_enhanced_enabled ? aws_eks_pod_identity_association.coredns[0].association_arn : null
      association_id  = var.coredns_enhanced_enabled ? aws_eks_pod_identity_association.coredns[0].association_id : null
    }
    kube_proxy = {
      enabled         = var.kube_proxy_enhanced_enabled
      association_arn = var.kube_proxy_enhanced_enabled ? aws_eks_pod_identity_association.kube_proxy[0].association_arn : null
      association_id  = var.kube_proxy_enhanced_enabled ? aws_eks_pod_identity_association.kube_proxy[0].association_id : null
    }
  }
}
