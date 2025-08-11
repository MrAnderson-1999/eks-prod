# Variables for EKS Module
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS cluster and nodes"
  type        = list(string)
}

variable "vpc_cidr_blocks" {
  description = "VPC CIDR blocks for security group rules"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
}

variable "cluster_service_role_arn" {
  description = "EKS cluster service role ARN"
  type        = string
}

variable "fargate_profile_role_arn" {
  description = "EKS Fargate profile role ARN"
  type        = string
}

variable "additional_security_group_ids" {
  description = "Additional security group IDs"
  type        = list(string)
  default     = []
}

# Optional: ALB Security Group ID to allow inbound HTTP to pod ENIs (cluster primary SG)
variable "alb_security_group_id" {
  description = "Security group ID of the ALB used to allow inbound traffic to pods"
  type        = string
  default     = null
}

# Fargate configuration
variable "enable_fargate" {
  description = "Enable Fargate profiles for serverless container hosting"
  type        = bool
  default     = true
}

variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts (IRSA) on the cluster"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}



