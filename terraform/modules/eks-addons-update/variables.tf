variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_cni_role_arn" {
  description = "ARN of the VPC CNI IRSA role"
  type        = string
}

variable "ebs_csi_role_arn" {
  description = "ARN of the EBS CSI IRSA role"
  type        = string
}

variable "vpc_cni_version" {
  description = "Version of VPC CNI add-on"
  type        = string
  default     = null
}

variable "ebs_csi_version" {
  description = "Version of EBS CSI add-on"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}
