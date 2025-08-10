output "service_account" {
  description = "ALB controller service account details"
  value = {
    name      = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
    namespace = kubernetes_service_account.aws_load_balancer_controller.metadata[0].namespace
  }
}

output "helm_release" {
  description = "ALB controller Helm release details"
  value = {
    name      = helm_release.aws_load_balancer_controller.name
    chart     = helm_release.aws_load_balancer_controller.chart
    version   = helm_release.aws_load_balancer_controller.version
    namespace = helm_release.aws_load_balancer_controller.namespace
    status    = helm_release.aws_load_balancer_controller.status
  }
}
