variable "chart_version" {
  description = "Version of the ALB controller Helm chart"
  type        = string
  default     = "1.13.4"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster resides"
  type        = string
}

variable "alb_controller_role_arn" {
  description = "IAM role ARN for the ALB Controller service account"
  type        = string
}

variable "enable_waf" {
  description = "Enable AWS WAF v2 support"
  type        = bool
  default     = false
}

variable "enable_shield" {
  description = "Enable AWS Shield Advanced support"
  type        = bool
  default     = false
}

variable "log_level" {
  description = "Log level for ALB controller"
  type        = string
  default     = "info"
  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "Log level must be one of: debug, info, warn, error."
  }
}
