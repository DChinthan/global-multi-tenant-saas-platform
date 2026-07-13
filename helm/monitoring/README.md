# Monitoring stack (Prometheus + Grafana + Alertmanager)

Installs the community `kube-prometheus-stack` chart into a `monitoring`
namespace on top of the same cluster used for the
[Kubernetes/multi-cloud demo](../../docs/app5-multicloud-demo.md) - a local
`kind` cluster by default, zero cost. See
[docs/observability-demo.md](../../docs/observability-demo.md) for the full
step-by-step, what each command proves, and real captured output.

## What's here

- `kube-prometheus-stack-values.yaml` - values override for the third-party
  chart, trimmed for a laptop `kind` cluster (short retention, no PVCs,
  modest resource requests, noisy kind-only-broken targets disabled).
- `dashboards/app5-fileservice-dashboard.json` - a small custom Grafana
  dashboard (request rate, error rate, p95/p99 latency, HPA replica count)
  for `app5-fileservice` specifically.
- `dashboards/app5-fileservice-dashboard-configmap.yaml` - wraps the JSON
  above in a ConfigMap labelled `grafana_dashboard: "1"`, which Grafana's
  sidecar (shipped by kube-prometheus-stack, watches its own namespace by
  default) auto-loads with no manual import step.

## Why this is `helm install`, not a Terraform `helm_release`, here

The cluster this targets is a local, disposable `kind` cluster created and
destroyed per demo session - Terraform-managed state has nothing durable to
track. See `infra/terraform/modules/monitoring/` for the Terraform
`helm_release` version of the same install, written for the case that
actually fits it: a long-lived EKS/AKS cluster. That module is real,
`terraform validate`-clean code, gated behind the same `enable_eks` flag as
the `eks` module, and is **not applied** as part of this repo's normal
plan/apply - same IaC-not-applied posture as `modules/eks` itself.
