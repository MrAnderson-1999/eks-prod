variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB controller will operate"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "alb_controller_role_arn" {
  description = "ARN of the ALB controller IRSA role"
  type        = string
}

variable "chart_version" {
  description = "Version of the ALB controller Helm chart"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}
