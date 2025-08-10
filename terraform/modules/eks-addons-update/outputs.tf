output "vpc_cni_addon" {
  description = "VPC CNI add-on details"
  value = {
    name    = aws_eks_addon.vpc_cni.addon_name
    version = aws_eks_addon.vpc_cni.addon_version
    arn     = aws_eks_addon.vpc_cni.arn
  }
}

output "ebs_csi_addon" {
  description = "EBS CSI add-on details"
  value = {
    name    = aws_eks_addon.ebs_csi_driver.addon_name
    version = aws_eks_addon.ebs_csi_driver.addon_version
    arn     = aws_eks_addon.ebs_csi_driver.arn
  }
}
