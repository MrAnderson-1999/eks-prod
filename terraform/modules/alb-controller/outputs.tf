output "role_arn" {
  description = "ARN of the IAM role for ALB controller"
  value       = aws_iam_role.alb_controller.arn
}

output "role_name" {
  description = "Name of the IAM role for ALB controller"
  value       = aws_iam_role.alb_controller.name
}

output "policy_arn" {
  description = "ARN of the IAM policy for ALB controller"
  value       = aws_iam_policy.alb_controller.arn
}

output "policy_name" {
  description = "Name of the IAM policy for ALB controller"
  value       = aws_iam_policy.alb_controller.name
}