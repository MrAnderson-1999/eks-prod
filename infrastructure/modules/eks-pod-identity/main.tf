# EKS Pod Identity Module
# This module manages Pod Identity associations for EKS add-ons
# Pod Identity is the modern replacement for IRSA

# Create Pod Identity associations for EKS add-ons
resource "aws_eks_pod_identity_association" "vpc_cni" {
  count = var.vpc_cni_enabled ? 1 : 0
  
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "aws-node"
  role_arn        = var.vpc_cni_role_arn

  tags = merge(var.tags, {
    Name        = "${var.cluster_name}-vpc-cni-pod-identity"
    Purpose     = "VPC CNI Pod Identity"
    Component   = "networking"
  })
}

resource "aws_eks_pod_identity_association" "aws_load_balancer_controller" {
  count = var.alb_controller_enabled ? 1 : 0
  
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = var.alb_controller_role_arn

  tags = merge(var.tags, {
    Name        = "${var.cluster_name}-alb-controller-pod-identity"
    Purpose     = "ALB Controller Pod Identity"
    Component   = "ingress"
  })
}

# Optional: CoreDNS Pod Identity (for enhanced logging/monitoring)
resource "aws_eks_pod_identity_association" "coredns" {
  count = var.coredns_enhanced_enabled ? 1 : 0
  
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "coredns"
  role_arn        = var.coredns_role_arn

  tags = merge(var.tags, {
    Name        = "${var.cluster_name}-coredns-pod-identity"
    Purpose     = "CoreDNS Enhanced Logging"
    Component   = "dns"
  })
}

# Optional: kube-proxy Pod Identity (for enhanced monitoring)
resource "aws_eks_pod_identity_association" "kube_proxy" {
  count = var.kube_proxy_enhanced_enabled ? 1 : 0
  
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "kube-proxy"
  role_arn        = var.kube_proxy_role_arn

  tags = merge(var.tags, {
    Name        = "${var.cluster_name}-kube-proxy-pod-identity"
    Purpose     = "kube-proxy Enhanced Monitoring"
    Component   = "networking"
  })
}

# Generic Pod Identity association for custom workloads
resource "aws_eks_pod_identity_association" "custom" {
  for_each = var.custom_pod_identities

  cluster_name    = var.cluster_name
  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = each.value.role_arn

  tags = merge(var.tags, each.value.tags, {
    Name = "${var.cluster_name}-${each.key}-pod-identity"
  })
}
