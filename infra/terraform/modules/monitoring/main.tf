# ==============================================================================
# Terraform-managed kube-prometheus-stack install - the "long-lived cluster"
# counterpart to the `helm install` path documented in
# docs/observability-demo.md, which targets a disposable local kind cluster
# instead. This module is only meaningful once a real cluster exists, so
# it's wired into envs/*/main.tf behind the same `enable_eks` flag as
# modules/eks and is NOT applied as part of this repo's normal plan/apply.
#
# COST NOTE: this module itself creates no billable AWS resources (it only
# talks to the Kubernetes API of a cluster that must already exist). Its
# real cost is inherited entirely from modules/eks being enabled - see the
# warning at the top of modules/eks/main.tf.
# ==============================================================================

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name   = var.namespace
    labels = local.common_tags
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name

  # Same override file the CLI path uses, so the two installation methods
  # (helm install locally, helm_release here) can never silently drift into
  # two different configurations of "the same" monitoring stack.
  values = [
    file("${path.module}/../../../../helm/monitoring/kube-prometheus-stack-values.yaml")
  ]

  set_sensitive {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  # Prometheus Operator's CRDs (ServiceMonitor, PodMonitor, ...) are large
  # and chart upgrades don't always reconcile them cleanly - a common
  # kube-prometheus-stack gotcha. wait = true makes Helm/Terraform block
  # until the release is actually healthy instead of reporting success the
  # moment the API objects are created.
  wait    = true
  timeout = 600
}

# Terraform-native equivalent of the sidecar-discovered ConfigMap in
# helm/monitoring/dashboards/ - same JSON file, same grafana_dashboard label,
# just applied as a first-class Terraform resource instead of a raw
# `kubectl apply` in this path.
resource "kubernetes_config_map_v1" "app5_fileservice_dashboard" {
  metadata {
    name      = "app5-fileservice-dashboard"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "app5-fileservice-dashboard.json" = file("${path.module}/../../../../helm/monitoring/dashboards/app5-fileservice-dashboard.json")
  }

  depends_on = [helm_release.kube_prometheus_stack]
}
