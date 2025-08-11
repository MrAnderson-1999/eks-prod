output "cluster_name" {
  description = "EKS cluster name"
  value       = local.cluster_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = local.vpc_id
}

output "aws_region" {
  description = "AWS region"
  value       = local.aws_region
}

output "alb_controller_role_arn" {
  description = "ALB Controller IAM role ARN"
  value       = local.alb_controller_role_arn
}

output "common_tags" {
  description = "Common tags for all resources"
  value       = local.common_tags
}
