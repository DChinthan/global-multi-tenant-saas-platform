# app5-fileservice: Multi-Cloud + Kubernetes/Helm Demo

This doc covers a self-contained addition layered on top of the core AWS
architecture in [HLD.md](../HLD.md) / [LLD.md](../LLD.md): a second
microservice (`app5-fileservice`) plus a Kubernetes/Helm deployment path,
built specifically to demonstrate multi-cloud + Kubernetes/Helm skills that
the original ECS-only setup couldn't show on its own.

## What was added, and why

The rest of this repo deploys exactly one service (`app1-python`) to ECS
Fargate, via a compute module that was hardcoded for a single service. That's
a real, working AWS pattern, but it can't demonstrate Kubernetes, Helm, or
running the same workload on a second cloud - all explicitly required for the
target role. So, in order:

1. **`infra/terraform/modules/compute`** was parameterized to run N ECS
   services off one shared cluster/ALB (map-keyed `services` variable,
   `for_each` everywhere, `moved` blocks so the existing `app1-python`
   service wasn't disrupted). This is what let a second service exist without
   touching the first. See `modules/compute/variables.tf` and `moved.tf`.
2. **`services/app5-fileservice`** - a small FastAPI service with `/healthz`,
   `/readyz`, `/presign` (mocked, shaped by a `CLOUD_PROVIDER` env var), and
   `/work` (real ~20-150ms simulated latency + ~1% error rate, so there's
   something realistic to load-test). Deployed to ECS the same way as app1,
   behind the ALB at `/app5/*`.
3. **`helm/app5-fileservice`** - a Helm chart for the *same* image, deployable
   to any Kubernetes cluster: real liveness/readiness probes, an HPA mirroring
   the ECS autoscaling shape (min 2 / max 6 / 60% CPU), a `helm test` hook that
   smoke-tests the live service, and a `values-azure.yaml` overlay that proves
   the same chart retargets clouds by changing one field.
4. **`infra/terraform/modules/eks`** and **`infra/terraform/modules/azure_aks`**
   - real, `terraform validate`-clean modules for AWS EKS and Azure AKS
   respectively. Neither is applied: `eks` is wired into `envs/*/main.tf`
   behind `enable_eks` (default `false`); `azure_aks` is deliberately
   standalone (different provider, different cloud, not part of this repo's
   AWS state). Both have cost-warning comments at the top of their `main.tf`.
   The actual runnable Kubernetes evidence for this demo comes from a local
   **kind** cluster instead - free, and something you can genuinely re-run.
5. **`loadtest/app5-loadtest.js`** (k6) and **`chaos/app5-pod-kill.sh`** -
   exercise the Helm-deployed service for real latency/error-rate numbers and
   a real Kubernetes self-heal recovery time.

## Prerequisites

```
brew install kind helm k6   # one-time; kubectl usually already present
```

Docker must be running (kind runs Kubernetes nodes as containers).

## Step-by-step: reproduce the whole demo

```bash
# 1. Build the image
cd services/app5-fileservice
docker build -t app5-fileservice:latest .

# 2. Create a local cluster and load the image into it
kind create cluster --name app5-demo
kind load docker-image app5-fileservice:latest --name app5-demo

# 3. Install the chart (defaults to CLOUD_PROVIDER=aws)
cd ../../
helm install app5 helm/app5-fileservice --wait --timeout 90s

# 4. Smoke-test it (real curl checks against the live pods, via the helm test hook)
helm test app5 --logs

# 5. Prove the multi-cloud switch: same chart, one value changed
helm upgrade app5 helm/app5-fileservice -f helm/app5-fileservice/values-azure.yaml --wait --timeout 90s
helm test app5 --logs   # /presign now reports "cloud_provider":"azure"
helm upgrade app5 helm/app5-fileservice --reset-values --wait --timeout 90s   # back to aws
# note: --reset-values is required here - a plain `helm upgrade` with no -f
# reuses the previous release's user-supplied values (azure), it does not
# fall back to the chart's values.yaml on its own.

# 6. Load test (needs the Service reachable from your host)
kubectl port-forward svc/app5-app5-fileservice 8099:8080 &
BASE_URL=http://127.0.0.1:8099 k6 run loadtest/app5-loadtest.js

# 7. Chaos test (kills a pod, times real recovery)
bash chaos/app5-pod-kill.sh

# 8. Tear down when done (stops all cost/resource usage - kind is local so
# there's no billing, just local CPU/RAM while it's up)
kind delete cluster --name app5-demo
```

## What each step actually verifies, and what it produced when run for this doc

| Step | Command | What it proves | Metric it produces |
|---|---|---|---|
| Deploy | `helm install` | Chart is valid, probes pass, HPA/Service/Deployment reconcile on a real cluster | Pod `READY 2/2`, `STATUS Running` |
| Smoke test | `helm test app5 --logs` | `/healthz`, `/readyz`, `/presign` all respond correctly from inside the cluster | Pass/fail + the actual JSON bodies returned |
| Multi-cloud switch | `helm upgrade -f values-azure.yaml` + `helm test` | One chart/image, re-pointed at a different cloud via `CLOUD_PROVIDER`, no code or template change | `/presign` response's `cloud_provider` + provider-shaped URL |
| Load test | `k6 run loadtest/app5-loadtest.js` | Service behavior under ramping concurrent load | p95 latency, error rate (thresholds: p95 < 500ms, error rate < 5%) |
| Chaos test | `chaos/app5-pod-kill.sh` | Kubernetes actually replaces a killed pod and the Deployment self-heals | Wall-clock seconds from pod delete to `availableReplicas` back to desired count |

Real output captured running this exact sequence in this session (all
timestamps/numbers below came from the commands above, not from hand-editing):

**Smoke test (`aws`):**
```
GET http://app5-app5-fileservice:8080/healthz
{"status":"ok"}
GET http://app5-app5-fileservice:8080/readyz
{"status":"ready","uptime_seconds":64.17}
GET http://app5-app5-fileservice:8080/presign
{"cloud_provider":"aws","bucket":"demo-bucket","key":"demo-object.txt","url":"https://demo-bucket.s3.amazonaws.com/demo-object.txt?X-Amz-Signature=mock","expires_in":900,"mocked":true}
All smoke checks passed.
```

**Smoke test after `-f values-azure.yaml` (same chart, one overlay field):**
```
GET http://app5-app5-fileservice:8080/presign
{"cloud_provider":"azure","bucket":"demo-bucket","key":"demo-object.txt","url":"https://demoaccount.blob.core.windows.net/demo-bucket/demo-object.txt?sig=mock","expires_in":900,"mocked":true}
All smoke checks passed.
```

**k6 load test** (20 max VUs, 40s ramp):
```
✓ 'p(95)<500' p(95)=153ms
✓ 'rate<0.05' rate=1.02%
http_reqs: 4603, 115.06/s
checks_succeeded: 98.97% (4556/4603)
```
The 1.02% failure rate lines up with the ~1% synthetic error rate hardcoded
in `services/app5-fileservice/main.py`'s `/work` handler - this is the
service behaving as designed under load, not a bug.

**Chaos test:**
```
Killing pod: app5-app5-fileservice-549b999db-dlzkw (desired replica count: 2)
  [+0s] availableReplicas=1/2
  ...
  [+8s] availableReplicas=2/2
Real self-heal recovery time: 8s
```

Re-running any of these will produce different (still real) numbers -
scheduling, host load, and kind's overlay networking all introduce variance.
The point is the mechanism, not a specific millisecond figure.

## Known gaps / honest caveats

- **HPA metrics**: kind doesn't ship `metrics-server` by default, so
  `kubectl get hpa` shows `cpu: <unknown>/60%` until one is installed
  (`kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`,
  then patch in `--kubelet-insecure-tls` for kind's self-signed kubelets).
  The HPA object itself is real and would work correctly on EKS/AKS, which
  both ship metrics-server-compatible metrics out of the box.
- **EKS/AKS modules are unapplied**: `modules/eks` and `modules/azure_aks`
  are real, `terraform validate`-clean Terraform, but nobody has run
  `terraform apply` against them (that's real AWS/Azure cost - see the
  warning comments at the top of each module's `main.tf`). If asked in an
  interview "have you actually run this on EKS," the honest answer is: not
  yet, the local kind cluster is the substitute, and turning `enable_eks` on
  in `envs/dev` is a one-line, one-command way to actually do it.
- **ALB path routing doesn't rewrite paths**: the ECS-fronting ALB routes
  `/app5/*` without stripping the prefix, so `services/app5-fileservice/main.py`
  mounts every route twice (root, and again under `/app5`) to handle both
  the direct-access case (local, Kubernetes) and the shared-ALB case (ECS).
  See the comment in `main.py` above `app.include_router`.

## Related docs

- [HLD.md](../HLD.md) / [LLD.md](../LLD.md) - core AWS architecture app5 sits alongside
- [docs/cicd.md](cicd.md) - existing CI/CD pipeline docs; `docker-build-push.yml` now has a second job for app5
- [docs/runbooks/deploy.md](runbooks/deploy.md) - ECS deploy runbook (app5 follows the same path as app1 for its ECS deployment)
