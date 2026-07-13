# Observability: Prometheus + Grafana + Alertmanager on Kubernetes

This doc covers a self-contained addition layered on top of the
[Kubernetes/multi-cloud demo](app5-multicloud-demo.md): a full
`kube-prometheus-stack` install (Prometheus + Grafana + Alertmanager) plus
`/metrics` instrumentation on `app5-fileservice`, built to demonstrate
production-grade observability on Kubernetes.

## What was added, and why

1. **`services/app5-fileservice/main.py`** - instrumented with
   [`prometheus-fastapi-instrumentator`](https://github.com/trallnag/prometheus-fastapi-instrumentator),
   which adds a `GET /metrics` endpoint exposing request count, a
   request-duration histogram, and in-progress requests - no custom metric
   code required.
2. **`helm/app5-fileservice/templates/servicemonitor.yaml`** - a
   `ServiceMonitor` custom resource, off by default
   (`serviceMonitor.enabled=false`), that tells the Prometheus Operator to
   scrape that `/metrics` endpoint every 15s.
3. **`helm/monitoring/`** - a trimmed values file for the community
   `prometheus-community/kube-prometheus-stack` chart (short retention, no
   PVCs, modest resource requests, kind-only-broken control-plane targets
   disabled), plus a custom 4-panel Grafana dashboard shipped as a
   sidecar-discovered ConfigMap - dashboards as code, not a manual import.
4. **`infra/terraform/modules/monitoring/`** - the Terraform `helm_release`
   equivalent of the same install, for the case where it actually belongs in
   Terraform: a long-lived EKS/AKS cluster. Gated behind `enable_eks`
   (default `false`) in all three envs, same as `modules/eks` itself - real,
   `terraform validate`-clean code, **not applied**. The runnable evidence
   for this demo comes from a local **kind** cluster instead, same pattern
   as the multi-cloud demo.

## Prerequisites

```
brew install kind helm kubectl   # one-time
```

Docker must be running.

## Step-by-step: reproduce the whole demo

```bash
# 1. Build the image (now includes prometheus-fastapi-instrumentator)
cd services/app5-fileservice
docker build -t app5-fileservice:latest .

# 2. Create a local cluster and load the image into it
kind create cluster --name obs-demo
kind load docker-image app5-fileservice:latest --name obs-demo
cd ../..

# 3. Add the chart repo and install kube-prometheus-stack into `monitoring`
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --version 87.15.1 \
  -n monitoring --create-namespace \
  -f helm/monitoring/kube-prometheus-stack-values.yaml \
  --wait --timeout 5m

# 4. Load the custom Grafana dashboard (sidecar auto-discovers it - no UI import)
kubectl apply -f helm/monitoring/dashboards/app5-fileservice-dashboard-configmap.yaml

# 5. Install app5-fileservice with its ServiceMonitor turned on
helm install app5 helm/app5-fileservice --set serviceMonitor.enabled=true --wait --timeout 90s

# 6. Generate some traffic so there's something to see
kubectl port-forward svc/app5-app5-fileservice 8098:8080 &
for i in $(seq 1 150); do curl -s http://127.0.0.1:8098/work > /dev/null; done

# 7. Verify Prometheus is actually scraping it (see below for exact output)
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring &
curl -s http://127.0.0.1:9090/api/v1/targets | grep -A2 app5-app5-fileservice

# 8. Open Grafana and look at the dashboard
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring &
kubectl get secret --namespace monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode; echo
# open http://127.0.0.1:3000 -> login admin / <password above>
# -> Dashboards -> "app5-fileservice — golden signals"

# 9. Tear down when done (kind is local - no cost, just local CPU/RAM while up)
kind delete cluster --name obs-demo
```

## What each step actually verifies, and what it produced when run for this doc

| Step | Command | What it proves | Metric it produces |
|---|---|---|---|
| Install | `helm install kube-prometheus-stack` | Chart installs clean on `kind`, all 6 pods (Prometheus, Grafana, Alertmanager, kube-state-metrics, node-exporter, operator) reach `Running` | `kubectl get pods -n monitoring` |
| Dashboard load | `kubectl apply -f .../*-configmap.yaml` | Grafana's sidecar picks up a labelled ConfigMap with no manual import | Sidecar log line, dashboard visible via Grafana API |
| Scrape discovery | `helm install app5 --set serviceMonitor.enabled=true` | Prometheus Operator turns the `ServiceMonitor` CRD into a real scrape target within seconds, no Prometheus restart | Target `health: up` in Prometheus's target list |
| Golden signals | traffic + PromQL queries | Request rate, error rate, and latency percentiles all computable from the exposed metrics | See real output below |

Real output captured running this exact sequence in this session (all
numbers below came from the commands above, not from hand-editing):

**Targets, before and after the first scrape:**
```
$ curl -s http://127.0.0.1:9090/api/v1/targets | ...
app5-app5-fileservice | unknown | http://10.244.0.12:8080/metrics |        <- t+0s
app5-app5-fileservice | unknown | http://10.244.0.13:8080/metrics |
...
app5-app5-fileservice | up      | http://10.244.0.12:8080/metrics |       <- t+18s
app5-app5-fileservice | up      | http://10.244.0.13:8080/metrics |
```
`unknown` isn't a failure - it's the state before the first scrape interval
(15s) has elapsed. Real target discovery, real scrape, fifteen-ish seconds
apart.

**Raw counters after 150 requests to `/work`:**
```
http_requests_total{handler="/work",method="GET",status="2xx"} 148.0
http_requests_total{handler="/work",method="GET",status="5xx"} 2.0
```
2 failures out of 150 (1.3%) - lines up with the ~1% synthetic error rate
hardcoded into `/work` for load-testing realism, same as the k6 demo in
[app5-multicloud-demo.md](app5-multicloud-demo.md).

**Custom Grafana dashboard, confirmed live via Grafana's own API:**
```
GET /api/dashboards/uid/app5-fileservice-golden-signals
title: app5-fileservice — golden signals
panels: ['Request rate (req/s)', 'Error rate (% of requests, 5xx)',
         'Latency p95 / p99 by handler', 'HPA replicas — current vs min/max']
```
And confirmed the panels actually resolve data through Grafana's own
datasource proxy (not just Prometheus directly), e.g.:
```
GET /api/datasources/proxy/uid/prometheus/api/v1/query?query=sum(rate(http_requests_total[1m]))by(handler)
{"handler":"/work","value":"1.19..."}   <- ~1.2 req/s during the burst
```

## Known gaps / honest caveats

- **The p95 number was misleading at first, and that's worth knowing.**
  `/work` sleeps `random.uniform(0.02, 0.15)` seconds, so the true p95
  should sit close to 0.145s. The first query against
  `http_request_duration_seconds_bucket` (the instrumentator's *default*,
  coarse-bucketed, per-handler histogram) returned **p95 = 0.46s** - way
  off. The bucket boundaries for that histogram are `[0.1, 0.5, 1, +Inf, ...]`;
  since 95% of real requests land in the `(0.1, 0.5]` bucket,
  `histogram_quantile` has nothing finer than those two boundaries to
  interpolate between, and its linear-interpolation assumption produces a
  skewed estimate. Querying `http_request_duration_highr_seconds_bucket`
  instead (finer buckets, but *no* `handler` label) gave **p95 = 0.23s** -
  much closer to reality, at the cost of no longer being able to break the
  number down per endpoint. That's the real trade-off `prometheus-fastapi-
  instrumentator` ships two histograms to manage, and it's a genuinely
  common way real dashboards quietly lie: a percentile is only as accurate
  as the bucket boundaries it was computed from. Fixing it for real means
  passing custom `buckets=[...]` tuned to the actual latency distribution
  instead of accepting either default.
- **HPA panel needs `metrics-server`**: same gap as the multi-cloud demo -
  `kind` doesn't ship it by default, so the HPA stays at
  `cpu: <unknown>/60%` and the "HPA replicas" panel only shows the static
  min/max/current-replica-count series, not a live CPU-driven scaling
  event. The panel and the underlying `kube_horizontalpodautoscaler_*`
  metrics are real either way.
- **EKS/AKS + Terraform `helm_release` are unapplied**: `modules/monitoring`
  is real, `terraform validate`-clean Terraform, wired in behind
  `enable_eks`, but nobody has run `terraform apply` against it - that
  requires a real EKS cluster first (see the cost warning in
  `modules/eks/main.tf`). If asked in an interview "have you run this
  against a real cluster," the honest answer is: not yet - the `kind`
  install above is the substitute, and it's the exact same Helm chart and
  values file either way.
- **Grafana admin password is plaintext in `helm/monitoring/kube-prometheus-
  stack-values.yaml`** (`demo-admin-only`) - fine for a disposable local
  cluster, not something to carry into a real environment. The Terraform
  module takes it as a `sensitive` variable instead, and a real install
  should source it from Secrets Manager/SSM via `grafana.admin.existingSecret`.

## Related docs

- [app5-multicloud-demo.md](app5-multicloud-demo.md) - the Kubernetes/Helm/
  multi-cloud demo this one builds on
- [HLD.md](../HLD.md) / [LLD.md](../LLD.md) - core AWS architecture
