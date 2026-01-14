resource "helm_release" "prometheus" {
  name             = var.prometheus_resource
  namespace        = var.monitoring_namespace
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "80.13.3"
}
