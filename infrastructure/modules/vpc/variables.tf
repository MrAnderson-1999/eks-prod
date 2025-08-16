# VPC Module Variables

variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, stg, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones must be provided for EKS."
  }
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  
  validation {
    condition     = length(var.private_subnets) >= 2
    error_message = "At least 2 private subnets must be provided for EKS."
  }
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  
  validation {
    condition     = length(var.public_subnets) >= 2
    error_message = "At least 2 public subnets must be provided for ALB."
  }
}

# EKS cluster name used for Kubernetes subnet discovery tags
variable "cluster_name" {
  description = "EKS cluster name used for kubernetes.io/cluster/* subnet tags"
  type        = string
}

variable "public_subnet_tags" {
  description = "Additional tags to apply to public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags to apply to private subnets"
  type        = map(string)
  default     = {}
}

variable "enable_nat_gateway" {
  description = "Should be true to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Should be true to provision a single shared NAT Gateway across all of your private networks"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Should be true to provision one NAT Gateway per availability zone"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group"
  type        = number
  default     = 14

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.flow_log_retention_days)
    error_message = "Flow log retention days must be one of the valid CloudWatch Logs retention periods."
  }
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used for encrypting EKS secrets (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
