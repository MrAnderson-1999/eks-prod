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

variable "node_group_role_arn" {
  description = "EKS node group role ARN"
  type        = string
}

variable "additional_security_group_ids" {
  description = "Additional security group IDs"
  type        = list(string)
  default     = []
}

# Node group configuration
variable "node_instance_types" {
  description = "Instance types for node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "Capacity type for node group"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 3
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}