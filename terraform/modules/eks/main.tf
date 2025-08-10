# Simple EKS Module - Official terraform-aws-modules/eks/aws
# Direct usage of official module following AWS best practices

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  # Minimal working configuration
  name              = var.cluster_name
  cluster_version = var.cluster_version

  # VPC Configuration  
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # EKS Managed Node Groups
  eks_managed_node_groups = var.eks_managed_node_groups

  tags = var.tags
}
