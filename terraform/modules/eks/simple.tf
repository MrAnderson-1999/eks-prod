# Simple EKS Module - Official terraform-aws-modules/eks/aws
# Direct usage of official module following AWS best practices

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # VPC Configuration
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Cluster endpoint configuration
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Enable cluster creator admin permissions
  enable_cluster_creator_admin_permissions = true

  # EKS Managed Node Groups
  eks_managed_node_groups = var.eks_managed_node_groups

  # Cluster add-ons
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy            = {}
    vpc-cni               = {}
    aws-ebs-csi-driver    = {}
  }

  tags = var.tags
}
