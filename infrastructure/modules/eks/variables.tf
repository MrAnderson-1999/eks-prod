#==============================================================================
# CORE EKS CLUSTER VARIABLES
#==============================================================================

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
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS cluster and nodes"
  type        = list(string)
}

#==============================================================================
# CLUSTER ENDPOINT CONFIGURATION
#==============================================================================

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

#==============================================================================
# ENCRYPTION CONFIGURATION
#==============================================================================

variable "create_kms_key" {
  description = "Create a KMS key for EKS cluster encryption"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "ARN of KMS key for EKS cluster encryption"
  type        = string
  default     = null
}

#==============================================================================
# LOGGING CONFIGURATION
#==============================================================================

variable "cluster_enabled_log_types" {
  description = "List of control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events"
  type        = number
  default     = 7
}

#==============================================================================
# NODE GROUPS CONFIGURATION
#==============================================================================

variable "node_groups" {
  description = "Map of node group configurations"
  type = map(object({
    min_size                   = number
    max_size                   = number
    desired_size               = number
    instance_types             = list(string)
    capacity_type              = string
    ami_type                   = optional(string)
    disk_size                  = optional(number)
    labels                     = optional(map(string))
    taints                     = optional(list(object({
      key    = string
      value  = string
      effect = string
    })))
    max_unavailable_percentage = optional(number)
  }))
  default = {
    general = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
    }
  }
}

#==============================================================================
# CORE ADDON VERSIONS
#==============================================================================

variable "coredns_version" {
  description = "CoreDNS addon version"
  type        = string
  default     = null
}

variable "kube_proxy_version" {
  description = "Kube-proxy addon version"
  type        = string
  default     = null
}

variable "vpc_cni_version" {
  description = "VPC CNI addon version"
  type        = string
  default     = null
}

#==============================================================================
# ACCESS CONFIGURATION
#==============================================================================

variable "admin_role_arns" {
  description = "List of IAM role ARNs to grant admin access to the cluster"
  type        = list(string)
  default     = []
}

#==============================================================================
# TAGS
#==============================================================================

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
