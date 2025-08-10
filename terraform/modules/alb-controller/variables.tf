variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "oidc_issuer" {
  description = "OIDC issuer URL for the EKS cluster"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}