variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "namespace" {
  description = "Kubernetes namespace the monitoring stack and dashboard ConfigMap are installed into."
  type        = string
  default     = "monitoring"
}

variable "chart_version" {
  description = "prometheus-community/kube-prometheus-stack chart version. Pinned deliberately - this chart's defaults change enough between minors to break a values file silently otherwise."
  type        = string
  default     = "87.15.1"
}

variable "grafana_admin_password" {
  description = "Demo-only plaintext password. A real environment sources this from Secrets Manager/SSM via an existingSecret reference instead - see helm/monitoring/kube-prometheus-stack-values.yaml."
  type        = string
  sensitive   = true
  default     = "demo-admin-only"
}
