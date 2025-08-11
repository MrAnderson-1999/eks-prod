# EKS Pod Identity Module Variables

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

# VPC CNI Configuration
variable "vpc_cni_enabled" {
  description = "Enable Pod Identity for VPC CNI"
  type        = bool
  default     = true
}

variable "vpc_cni_role_arn" {
  description = "IAM role ARN for VPC CNI Pod Identity"
  type        = string
  default     = ""
}

# ALB Controller Configuration
variable "alb_controller_enabled" {
  description = "Enable Pod Identity for AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "alb_controller_role_arn" {
  description = "IAM role ARN for ALB Controller Pod Identity"
  type        = string
  default     = ""
}

# CoreDNS Enhanced Configuration (optional)
variable "coredns_enhanced_enabled" {
  description = "Enable Pod Identity for CoreDNS enhanced logging"
  type        = bool
  default     = false
}

variable "coredns_role_arn" {
  description = "IAM role ARN for CoreDNS Pod Identity"
  type        = string
  default     = ""
}

# kube-proxy Enhanced Configuration (optional)
variable "kube_proxy_enhanced_enabled" {
  description = "Enable Pod Identity for kube-proxy enhanced monitoring"
  type        = bool
  default     = false
}

variable "kube_proxy_role_arn" {
  description = "IAM role ARN for kube-proxy Pod Identity"
  type        = string
  default     = ""
}

# Custom Pod Identities
variable "custom_pod_identities" {
  description = "Map of custom Pod Identity associations"
  type = map(object({
    namespace       = string
    service_account = string
    role_arn        = string
    tags            = map(string)
  }))
  default = {}
}

# Common Tags
variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
