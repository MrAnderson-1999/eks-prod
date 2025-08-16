#==============================================================================
# CLUSTER INFORMATION VARIABLES (FROM EKS MODULE)
#==============================================================================

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider for IRSA"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster is deployed"
  type        = string
}

variable "node_security_group_id" {
  description = "ID of the node shared security group"
  type        = string
}

#==============================================================================
# EKS ADDON CONFIGURATIONS
#==============================================================================

variable "enable_ebs_csi_driver" {
  description = "Enable EBS CSI driver addon"
  type        = bool
  default     = true
}

variable "vpc_cni_version" {
  description = "VPC CNI addon version"
  type        = string
  default     = null
}

variable "ebs_csi_driver_version" {
  description = "EBS CSI driver addon version"
  type        = string
  default     = null
}

#==============================================================================
# AWS LOAD BALANCER CONTROLLER CONFIGURATION
#==============================================================================

variable "aws_load_balancer_controller_chart_version" {
  description = "AWS Load Balancer Controller Helm chart version"
  type        = string
  default     = "1.13.0"
}

variable "aws_load_balancer_controller_log_level" {
  description = "AWS Load Balancer Controller log level"
  type        = string
  default     = "info"
}

#==============================================================================
# EXTERNAL DNS CONFIGURATION
#==============================================================================

variable "enable_external_dns" {
  description = "Enable External DNS IRSA role"
  type        = bool
  default     = false
}

variable "external_dns_hosted_zone_arns" {
  description = "List of Route53 hosted zone ARNs for External DNS"
  type        = list(string)
  default     = []
}

#==============================================================================
# CERT MANAGER CONFIGURATION
#==============================================================================

variable "enable_cert_manager" {
  description = "Enable Cert Manager IRSA role"
  type        = bool
  default     = false
}

variable "cert_manager_hosted_zone_arns" {
  description = "List of Route53 hosted zone ARNs for Cert Manager"
  type        = list(string)
  default     = []
}

#==============================================================================
# ARGOCD CONFIGURATION
#==============================================================================

variable "enable_argocd_ecr_access" {
  description = "Enable ArgoCD ECR access IRSA role"
  type        = bool
  default     = false
}

variable "enable_argocd_deployment" {
  description = "Enable ArgoCD Helm deployment"
  type        = bool
  default     = false
}

variable "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "7.6.12"
}

variable "argocd_domain" {
  description = "Domain name for ArgoCD server"
  type        = string
  default     = "argocd.example.com"
}

variable "enable_argocd_ingress" {
  description = "Enable ArgoCD ingress with ALB"
  type        = bool
  default     = false
}

variable "argocd_certificate_arn" {
  description = "ARN of SSL certificate for ArgoCD"
  type        = string
  default     = null
}

#==============================================================================
# TAGS
#==============================================================================

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}