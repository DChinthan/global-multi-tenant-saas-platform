# Architecture — Supporting Material

See [`HLD.md`](../../HLD.md) (product scope, multi-tenancy model, personas)
and [`LLD.md`](../../LLD.md) (buildable specs) at the repo root for the
primary design docs. This page tracks **networking/security hands-on
gaps** that were closed with real, wired-in Terraform, and what's still
open — kept current as those change, rather than living only in a PR
description.

## Implemented (this pass)

| Area | What was added | Where |
|---|---|---|
| **NLB** | Internal Network Load Balancer dual-registered on the default ECS service alongside the existing ALB (AWS's documented multi-target-group pattern) | `infra/terraform/modules/compute/nlb.tf`, `ecs.tf` |
| **PrivateLink (consume)** | Interface Endpoints (ECR api/dkr, CloudWatch Logs, Secrets Manager) — replaces the NAT-Gateway-shaped hole that existed for ECS tasks when `enable_nat = false` | `infra/terraform/modules/vpc/privatelink.tf` |
| **PrivateLink (publish)** | VPC Endpoint Service backed by the new NLB, for cross-VPC/cross-account private consumption of the default service | `infra/terraform/modules/compute/privatelink.tf` |
| **Organizations + SCPs** | Separate root config: Org, `Workloads` OU (`Dev`/`Prod` children), 3 SCPs (deny root user, region restriction, mandatory `Project` tag) | `infra/terraform/org/` |
| **VPC Flow Logs** | Actual `aws_flow_log` resource + IAM role (previously only an empty, unused CloudWatch Logs group existed behind the flag) + 2 saved CloudWatch Logs Insights queries | `infra/terraform/modules/observability/logs.tf`, `insights_queries.tf` |
| **NACL/ENI troubleshooting** | Opt-in lab (`enable_troubleshooting_lab`) that deliberately misconfigures a NACL, plus a full runbook using Flow Logs, ENI/NACL description, and Reachability Analyzer | `infra/terraform/modules/vpc/nacl_lab.tf`, [`docs/runbooks/nacl-eni-troubleshooting.md`](../runbooks/nacl-eni-troubleshooting.md) |
| **PowerShell automation** | `AWS.Tools.ECS`/`AWS.Tools.ECR` PowerShell script, kept side-by-side with its Bash/AWS-CLI equivalent | `infra/scripts/Deploy-EcsService.ps1`, `deploy-ecs-service.sh` |

## Known Gaps

Gaps that predate this pass and are unrelated to it are listed too, so this
table stays the single source of truth rather than splitting "old gaps" and
"new gaps" across docs.

| Gap | Status | Notes |
|---|---|---|
| Organizations/SCPs applied against a real multi-account org | **Not applied** | `infra/terraform/org/` is authored and `terraform validate`-clean, but was never `apply`'d — it targets a separate Organizations management account, and `create_member_accounts` (real, hard-to-reverse account creation) defaults `false`. Practiced once via `plan`, not run end-to-end against live accounts. |
| PrivateLink cross-account consumption | **Partially exercised** | The endpoint service exists (real resource, `stage`), but `privatelink_allowed_principal_arns` is empty — no actual cross-account connection has been requested/accepted. The "publish a service" half is real; the "a second account consumes it" half is untested. |
| NACL/ENI troubleshooting runbook | **Practiced once** | Walked through the full lab → Reachability Analyzer → fix cycle once while authoring the runbook. Not yet a repeatable game-day exercise. |
| PowerShell automation breadth | **One script** | `Deploy-EcsService.ps1` covers one operation (force-deploy + prune). Depth is "wrote a working parity script," not "PowerShell is a primary tool" — only reach for this if the target environment is Windows-first. |
| VPC Flow Logs Insights queries | **2 queries, both CloudWatch-based** | Answers "top talkers by ENI" and "rejects by dest port" honestly, but flow logs don't expose which *security group or NACL rule* caused a REJECT (AWS doesn't log that) — see the runbook's caveat. No S3+Athena path was built (CloudWatch was sufficient for this pass and matches the log group already scaffolded). |
| Multi-cloud (EKS/AKS) | Terraform-authored, never applied | `enable_eks` stays `false`; the runnable K8s evidence is a local `kind` cluster (`docs/app5-multicloud-demo.md`), not the EKS/AKS modules. |
| RDS / OpenSearch / Kinesis | Terraform-authored, disabled by default | Same "authored but never applied" pattern as EKS — cost-safety toggle, not a completeness gap. |
| Full production deployment | Not done | See root `README.md` roadmap — `stage` has been the deepest environment exercised. |

## PrivateLink: Gateway Endpoint vs. Interface Endpoint (why the distinction matters)

| | Gateway Endpoint (pre-existing: S3, DynamoDB) | Interface Endpoint (new: ECR, Logs, Secrets Manager) |
|---|---|---|
| Mechanism | Route-table entry (prefix-list target) | Real ENI per subnet, PrivateLink-powered |
| Cost | Free | Hourly per-AZ + data processing |
| DNS | N/A (route-based) | Private DNS overrides the public service hostname |
| Is it PrivateLink? | **No** | **Yes** |
| Services supported | S3, DynamoDB only | Most AWS services |

The repo had zero Interface Endpoints before this pass — everything in
`private-app` subnets that wasn't S3/DynamoDB depended on NAT Gateway
(`enable_nat`, off by default). That's a real, not hypothetical, gap: with
`enable_nat = false`, ECS tasks had no path to pull container images at all.
