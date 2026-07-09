# 🌍 Global Multi-Tenant SaaS Platform

**A production-grade, cloud-native SaaS reference architecture — built on AWS + Terraform, extended with a real Kubernetes/Helm multi-cloud path.**

[![Terraform CI](https://github.com/DChinthan/global-multi-tenant-saas-platform/actions/workflows/terraform-ci.yml/badge.svg)](https://github.com/DChinthan/global-multi-tenant-saas-platform/actions/workflows/terraform-ci.yml)
[![Docker Build and Push](https://github.com/DChinthan/global-multi-tenant-saas-platform/actions/workflows/docker-build-push.yml/badge.svg)](https://github.com/DChinthan/global-multi-tenant-saas-platform/actions/workflows/docker-build-push.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-844FBA?logo=terraform&logoColor=white)](infra/terraform)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Helm-326CE5?logo=kubernetes&logoColor=white)](helm/app5-fileservice)

This project simulates a real-world, multi-tenant SaaS system end to end: secure tenant isolation, event-driven microservices, infrastructure as code, CI/CD, observability, disaster recovery, and a Kubernetes/multi-cloud deployment path — all designed to be **safe and cheap to run** (most costly resources are disabled by default).

---

## Table of Contents

- [Highlights](#-highlights)
- [Architecture](#️-architecture)
- [Repository Structure](#-repository-structure)
- [Getting Started](#-getting-started)
- [Kubernetes / Multi-Cloud Demo](#-kubernetes--multi-cloud-demo)
- [Testing (Load & Chaos)](#-testing-load--chaos)
- [CI/CD](#-cicd)
- [Security](#-security)
- [Observability](#-observability)
- [Cost Optimization](#-cost-optimization)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [License](#-license)
- [Author](#-author)

---

## ✨ Highlights

- **Multi-tenancy** — logical isolation via `tenant_id` scoping, with an optional cell-based model (dedicated schema/cluster/KMS key) for premium/regulated tenants
- **Event-driven architecture** — EventBridge, SQS, Lambda, and Step Functions decouple services and drive async workflows
- **Kubernetes & multi-cloud** — a second service (`app5-fileservice`) ships as a Helm chart deployable to any Kubernetes cluster, with `terraform validate`-clean AWS EKS and Azure AKS modules proving the same compute pattern generalizes across clouds
- **Infrastructure as Code** — modular Terraform across `dev` / `stage` / `prod`, reusable modules per concern (VPC, IAM, compute, data, edge, observability, security, DR, analytics, event backbone…)
- **Security-first** — IAM least privilege, GitHub Actions → AWS via OIDC (no static credentials), KMS encryption, WAF, CloudTrail audit logging, and a documented threat model + tfsec scan report
- **Full CI/CD** — Terraform validate/plan matrix across environments, tflint + tfsec scanning, Docker build/push to ECR, and automated versioned releases via `release-please`
- **Observability** — CloudWatch logs/metrics/alarms, X-Ray distributed tracing, centralized audit logs
- **Disaster recovery** — documented DR design with deploy/rollback runbooks
- **Cost-safe by default** — NAT Gateway, Aurora, OpenSearch, Kinesis, and EKS are all feature-flagged off until you explicitly opt in

---

## 🏗️ Architecture

```
User → Route53 → CloudFront → ALB → ECS Fargate Services
                                        │
                                        ▼
                          EventBridge → SQS → Lambda
                                        │
                                        ▼
                        DynamoDB / S3 / Aurora (feature-flagged)
```

A second path proves the same workload runs on Kubernetes, on any cloud:

```
Docker image → Helm chart → kind / EKS / AKS
                                │
                     Deployment + HPA + probes
                                │
                        Load-tested (k6) + chaos-tested (pod-kill)
```

Full design docs:
- [`HLD.md`](HLD.md) — high-level design (product scope, multi-tenancy model, personas)
- [`LLD.md`](LLD.md) — low-level design
- [`docs/app5-multicloud-demo.md`](docs/app5-multicloud-demo.md) — the Kubernetes/Helm/multi-cloud demo, step by step
- [`docs/adr/`](docs/adr) — architecture decision records
- [`docs/security/`](docs/security) — threat model, IAM review checklist, tfsec report, WAF testing notes

---

## 📦 Repository Structure

```
infra/
 ├── terraform/
 │    ├── modules/        # vpc, iam, compute, data, edge, eks, azure_aks, observability, security, dr, ...
 │    ├── envs/            # dev / stage / prod root configs
 │    ├── Makefile
 │    └── main.tf
 └── scripts/

services/
 ├── app1-python/          # primary ECS Fargate service
 ├── app5-fileservice/     # second service, deployed to both ECS and Kubernetes
 └── reporting/            # scheduled reporting Lambda

helm/
 └── app5-fileservice/     # Helm chart (Deployment, HPA, probes, helm-test smoke hook)

loadtest/                  # k6 load test script
chaos/                     # pod-kill chaos script (Kubernetes self-heal proof)

docs/
 ├── architecture/         # HLD/LLD supporting material
 ├── adr/                  # architecture decision records
 ├── runbooks/             # deploy / rollback runbooks
 ├── security/             # threat model, IAM review, tfsec report, WAF testing
 └── standards/            # commit & branch naming conventions

shared/                    # shared libraries/utilities
tools/                     # aws-cli / java / python helper tooling
.github/workflows/         # Terraform CI, Docker build/push, release automation
```

---

## 🚀 Getting Started

### 1. Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform ≥ 1.6
- `make`
- (Optional, for CI/CD) a GitHub OIDC role — no static AWS credentials needed

### 2. Clone

```bash
git clone https://github.com/DChinthan/global-multi-tenant-saas-platform.git
cd global-multi-tenant-saas-platform
```

### 3. Initialize & validate an environment

```bash
make tf-init ENV=dev
make tf-validate ENV=dev
make tf-plan ENV=dev
```

### 4. (Optional) Apply infrastructure

> ⚠️ Only enable the minimal set of services you need — most expensive resources are disabled by default (see [Cost Optimization](#-cost-optimization)).

```bash
make tf-apply ENV=dev
```

### Example `dev.tfvars`

```hcl
aws_region  = "us-east-1"
project     = "global-multi-tenant-saas-platform"
environment = "dev"

enable_nat        = false
enable_rds        = false
enable_opensearch = false
enable_kinesis    = false
enable_eks        = false
```

---

## ☸️ Kubernetes / Multi-Cloud Demo

The core platform deploys to ECS Fargate, but `app5-fileservice` also ships as a **Helm chart** runnable on any Kubernetes cluster — proven locally with [`kind`](https://kind.sigs.k8s.io/), with `terraform validate`-clean **EKS** and **AKS** modules showing the same compute pattern ported to managed Kubernetes on two clouds.

```bash
brew install kind helm k6   # one-time

# Build & load the image
cd services/app5-fileservice && docker build -t app5-fileservice:latest .
kind create cluster --name app5-demo
kind load docker-image app5-fileservice:latest --name app5-demo

# Install and smoke-test
cd ../../
helm install app5 helm/app5-fileservice --wait --timeout 90s
helm test app5 --logs

# Prove the multi-cloud switch (same chart, one values file)
helm upgrade app5 helm/app5-fileservice -f helm/app5-fileservice/values-azure.yaml --wait --timeout 90s
helm test app5 --logs   # /presign now reports "cloud_provider":"azure"
```

Full walkthrough, including the k6 load test and the pod-kill chaos test: [`docs/app5-multicloud-demo.md`](docs/app5-multicloud-demo.md).

---

## 🧪 Testing (Load & Chaos)

- **Load testing** — [`loadtest/app5-loadtest.js`](loadtest/app5-loadtest.js) (k6) exercises the Helm-deployed service for real latency/error-rate numbers
- **Chaos testing** — [`chaos/app5-pod-kill.sh`](chaos/app5-pod-kill.sh) kills a pod and measures Kubernetes' real self-heal recovery time

---

## 🔁 CI/CD

| Workflow | Purpose |
|---|---|
| `terraform-ci.yml` | `terraform validate` matrix across dev/stage/prod on every PR/push |
| `terraform-plan.yml` | Generates and posts Terraform plans |
| `docker-build-push.yml` | Builds service images and pushes to ECR via OIDC (no static credentials) |
| `deploy-stage.yml` | Deploys to the stage environment |
| `release.yml` | Automated versioned releases via [release-please](https://github.com/googleapis/release-please) |

---

## 🔐 Security

- IAM least-privilege roles per service
- GitHub Actions → AWS via OIDC (zero static credentials in CI)
- KMS encryption for S3, logs, and secrets
- CloudTrail + centralized audit logging
- WAF with rate limiting
- `tfsec` static analysis on every Terraform change — see [`docs/security/tfsec-report.md`](docs/security/tfsec-report.md)
- Documented threat model — [`docs/security/threat-model.md`](docs/security/threat-model.md)

---

## 📊 Observability

- CloudWatch logs, metrics, and alarms for all services
- X-Ray distributed tracing for request-flow visibility
- Centralized audit logs in S3

---

## 💸 Cost Optimization

This project is designed to be **safe to run without incurring high AWS costs**.

| Feature | Default |
|---|---|
| NAT Gateway | ❌ Disabled |
| RDS (Aurora) | ❌ Disabled |
| OpenSearch | ❌ Disabled |
| Kinesis | ❌ Disabled |
| EKS | ❌ Disabled |

Serverless-first, pay-per-use services, configured log retention, no unnecessary always-on resources. The Kubernetes demo runs entirely on a free local [`kind`](https://kind.sigs.k8s.io/) cluster rather than a billed managed cluster.

---

## 🛣️ Roadmap

- [ ] Full production deployment
- [ ] Blue/green deployments
- [ ] Multi-region active-active setup
- [ ] Apply the EKS/AKS modules against real managed clusters
- [ ] React-based admin dashboard

---

## 🤝 Contributing

Contributions, issues, and suggestions are welcome — see [`CONTRIBUTING.md`](CONTRIBUTING.md) for how to get started, and [`docs/standards/`](docs/standards) for commit and branch naming conventions used in this repo.

This project follows a [Code of Conduct](CODE_OF_CONDUCT.md).

---

## 📄 License

Licensed under the [MIT License](LICENSE).

---

## 👤 Author

**Chinthan Dinesh**
AWS Certified Solutions Architect – Associate (Score: 945/1000)
