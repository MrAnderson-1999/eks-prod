# EKS Module Variables

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

# Cluster Configuration
variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

# Network Configuration
variable "vpc_id" {
  description = "ID of the VPC where the cluster and its nodes will be provisioned"
  type        = string
}

variable "cluster_subnet_ids" {
  description = "List of subnet IDs where the cluster control plane (ENIs) will be provisioned"
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "List of subnet IDs where the cluster control plane (ENIs) will be provisioned. If not specified, cluster_subnet_ids will be used"
  type        = list(string)
  default     = []
}

variable "node_group_subnet_ids" {
  description = "List of subnet IDs where the nodes/node groups will be provisioned"
  type        = list(string)
}

# Cluster Access Configuration
variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = []
}

# Security Configuration
variable "create_kms_key" {
  description = "Controls if a KMS key for cluster encryption should be created"
  type        = bool
  default     = true
}

variable "external_kms_key_arn" {
  description = "ARN of external KMS key to use for cluster encryption (if create_kms_key is false)"
  type        = string
  default     = null
}

variable "kms_key_deletion_window" {
  description = "The waiting period, specified in number of days (7-30), after which the KMS key is deleted"
  type        = number
  default     = 7

  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}

# IAM Role Configuration
variable "cluster_service_role_arn" {
  description = "ARN of the EKS cluster service role. If not provided, a new role will be created"
  type        = string
  default     = null
}

variable "node_group_role_arn" {
  description = "ARN of the EKS node group role. If not provided, a new role will be created"
  type        = string
  default     = null
}

variable "create_iam_role" {
  description = "Whether to create IAM role for the cluster service account"
  type        = bool
  default     = true
}

variable "create_node_group_role" {
  description = "Whether to create IAM role for node groups"
  type        = bool
  default     = true
}

# Security-focused Node Group Configuration
variable "enable_system_node_group" {
  description = "Whether to create a dedicated system node group"
  type        = bool
  default     = true
}

variable "enable_workload_node_group" {
  description = "Whether to create a dedicated workload node group"
  type        = bool
  default     = true
}

variable "create_additional_node_security_group" {
  description = "Whether to create additional security group for node groups"
  type        = bool
  default     = true
}

# System Node Group Configuration
variable "system_node_group_min_size" {
  description = "Minimum number of nodes in system node group"
  type        = number
  default     = 2
}

variable "system_node_group_max_size" {
  description = "Maximum number of nodes in system node group"
  type        = number
  default     = 6
}

variable "system_node_group_desired_size" {
  description = "Desired number of nodes in system node group"
  type        = number
  default     = 3
}

variable "system_node_group_instance_types" {
  description = "List of instance types for system node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "system_node_group_capacity_type" {
  description = "Capacity type for system node group"
  type        = string
  default     = "ON_DEMAND"
}

variable "system_node_group_disk_size" {
  description = "Disk size for system node group"
  type        = number
  default     = 50
}

variable "system_node_group_taints" {
  description = "Taints to apply to system node group"
  type        = map(object({
    key    = string
    value  = string
    effect = string
  }))
  default = {
    system = {
      key    = "node.kubernetes.io/system"
      value  = "true"
      effect = "NO_SCHEDULE"
    }
  }
}

variable "system_node_group_labels" {
  description = "Additional labels for system node group"
  type        = map(string)
  default     = {}
}

# Workload Node Group Configuration
variable "workload_node_group_min_size" {
  description = "Minimum number of nodes in workload node group"
  type        = number
  default     = 1
}

variable "workload_node_group_max_size" {
  description = "Maximum number of nodes in workload node group"
  type        = number
  default     = 10
}

variable "workload_node_group_desired_size" {
  description = "Desired number of nodes in workload node group"
  type        = number
  default     = 2
}

variable "workload_node_group_instance_types" {
  description = "List of instance types for workload node group"
  type        = list(string)
  default     = ["t3.large"]
}

variable "workload_node_group_capacity_type" {
  description = "Capacity type for workload node group"
  type        = string
  default     = "SPOT"
}

variable "workload_node_group_disk_size" {
  description = "Disk size for workload node group"
  type        = number
  default     = 100
}

variable "workload_node_group_labels" {
  description = "Additional labels for workload node group"
  type        = map(string)
  default     = {}
}

variable "enable_irsa" {
  description = "Determines whether to create an OpenID Connect Provider for EKS to enable IRSA"
  type        = bool
  default     = true
}

variable "additional_security_group_ids" {
  description = "List of additional security group IDs to attach to the cluster"
  type        = list(string)
  default     = []
}

# Logging Configuration
variable "enable_cluster_logging" {
  description = "Determines whether to enable cluster logging"
  type        = bool
  default     = true
}

variable "cluster_log_types" {
  description = "List of cluster log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  validation {
    condition = alltrue([
      for log_type in var.cluster_log_types :
      contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "Valid log types are: api, audit, authenticator, controllerManager, scheduler."
  }
}

variable "cluster_log_retention_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group"
  type        = number
  default     = 7

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.cluster_log_retention_days)
    error_message = "Log retention days must be one of the valid CloudWatch Logs retention periods."
  }
}

# Node Group Configuration
variable "default_node_group_instance_types" {
  description = "List of instance types for the default node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "default_node_group_ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the default node group"
  type        = string
  default     = "AL2_x86_64"

  validation {
    condition = contains([
      "AL2_x86_64", "AL2_x86_64_GPU", "AL2_ARM_64", "CUSTOM", 
      "BOTTLEROCKET_ARM_64", "BOTTLEROCKET_x86_64", "BOTTLEROCKET_ARM_64_NVIDIA", "BOTTLEROCKET_x86_64_NVIDIA"
    ], var.default_node_group_ami_type)
    error_message = "AMI type must be one of the supported values."
  }
}

variable "default_node_group_capacity_type" {
  description = "Type of capacity associated with the default node group. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.default_node_group_capacity_type)
    error_message = "Capacity type must be either ON_DEMAND or SPOT."
  }
}

variable "default_node_group_min_size" {
  description = "Minimum number of instances in default node group"
  type        = number
  default     = 1
}

variable "default_node_group_max_size" {
  description = "Maximum number of instances in default node group"
  type        = number
  default     = 3
}

variable "default_node_group_desired_size" {
  description = "Desired number of instances in default node group"
  type        = number
  default     = 2
}

variable "default_node_group_disk_size" {
  description = "Disk size in GiB for worker nodes in default node group"
  type        = number
  default     = 50
}

variable "custom_node_groups" {
  description = "Map of custom node group configurations"
  type = map(object({
    name           = string
    instance_types = list(string)
    ami_type       = optional(string, "AL2_x86_64")
    capacity_type  = optional(string, "ON_DEMAND")
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = optional(number, 50)
    k8s_labels     = optional(map(string), {})
    tags           = optional(map(string), {})
  }))
  default = {}
}

variable "force_update_version" {
  description = "Force version update if existing pods are unable to be drained due to a pod disruption budget issue"
  type        = bool
  default     = false
}

variable "node_group_max_unavailable_percentage" {
  description = "Maximum percentage of nodes unavailable during update"
  type        = number
  default     = 25

  validation {
    condition     = var.node_group_max_unavailable_percentage > 0 && var.node_group_max_unavailable_percentage <= 100
    error_message = "Max unavailable percentage must be between 1 and 100."
  }
}

# Additional Security Group Rules
variable "additional_node_security_group_rules" {
  description = "Map of additional security group rules to add to the node security group"
  type = map(object({
    type                     = string
    from_port               = number
    to_port                 = number
    protocol                = string
    description             = string
    cidr_blocks             = optional(list(string))
    ipv6_cidr_blocks        = optional(list(string))
    prefix_list_ids         = optional(list(string))
    source_security_group_id = optional(string)
  }))
  default = {}
}

# EKS Add-ons
variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the cluster"
  type = map(object({
    addon_version            = optional(string)
    configuration_values     = optional(string)
    preserve                = optional(bool, true)
    resolve_conflicts        = optional(string, "OVERWRITE")
    service_account_role_arn = optional(string)
    tags                    = optional(map(string), {})
  }))
  default = {
    coredns = {
      preserve = true
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      preserve = true
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      preserve = true
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      preserve = true
      resolve_conflicts = "OVERWRITE"
    }
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
