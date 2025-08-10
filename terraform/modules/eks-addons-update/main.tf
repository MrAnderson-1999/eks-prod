# Update VPC CNI add-on with IRSA role
resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = var.cluster_name
  addon_name              = "vpc-cni"
  addon_version           = var.vpc_cni_version
  service_account_role_arn = var.vpc_cni_role_arn
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

# Update EBS CSI Driver add-on with IRSA role
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = var.cluster_name
  addon_name              = "aws-ebs-csi-driver"
  addon_version           = var.ebs_csi_version
  service_account_role_arn = var.ebs_csi_role_arn
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}
