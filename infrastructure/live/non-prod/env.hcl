# Non-Production Environment Configuration
locals {
  name   = "eks-sec-${local.stage}"
  region = "us-west-2"
  stage  = "non-prod"

  cluster_name = "eks-sec-${local.stage}"
}