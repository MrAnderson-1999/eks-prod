output "alb_controller_role_arn" {
  value = aws_iam_role.alb_controller.arn
}

output "service_account_name" {
  value = kubernetes_service_account.alb_controller.metadata[0].name
}

output "service_account_namespace" {
  value = kubernetes_service_account.alb_controller.metadata[0].namespace
}

output "service_account_secret_name" {
  value = kubernetes_service_account.alb_controller.default_secret_name
}