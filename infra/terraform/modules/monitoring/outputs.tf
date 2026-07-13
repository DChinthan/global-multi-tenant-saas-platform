output "namespace" {
  value = kubernetes_namespace_v1.monitoring.metadata[0].name
}

output "grafana_service_name" {
  description = "For `kubectl port-forward svc/<this> 3000:80 -n <namespace>`."
  value       = "kube-prometheus-stack-grafana"
}

output "prometheus_service_name" {
  description = "For `kubectl port-forward svc/<this> 9090:9090 -n <namespace>`."
  value       = "kube-prometheus-stack-prometheus"
}
