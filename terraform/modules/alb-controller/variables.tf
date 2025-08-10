variable "project_name" {
  type        = string
  description = "The name of the project"
}

variable "environment" {
  type        = string
  description = "The environment of the project"
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster"
}

variable "oidc_provider_arn" {
  type        = string
  description = "The ARN of the OIDC provider"
}

variable "oidc_issuer" {
  type        = string
  description = "The issuer of the OIDC provider"
}