# Low-Level Design (LLD) — Global Multi-Tenant SaaS Platform (AWS)

> This LLD turns the HLD into buildable specs: APIs, data models, authZ rules, event contracts, deployment, and guardrails.

---

## 1) Key design decisions (LLD summary)

- **Compute:** ECS Fargate for microservices (stateless, easy scaling)
- **API front door:** API Gateway (auth, throttling) + optional ALB for web app
- **AuthN:** Cognito/OIDC; JWT contains `tenant_id`, `roles`, `plan`
- **AuthZ:** tenant-aware RBAC + resource-level checks
- **Data:** Aurora PostgreSQL + tenant scoping (RLS preferred for defense-in-depth)
- **Async:** EventBridge → SQS → Lambda workers (+ DLQs)
- **Observability:** CloudWatch Logs/Metrics + X-Ray/OTel traces
- **Security:** KMS everywhere, Secrets Manager rotation, CloudTrail/Config baseline

---

## 2) Tenant-aware identity, auth, and authorization

### 2.1 JWT claims (required)
- `sub` (user id)
- `tenant_id`
- `roles`: `["TENANT_ADMIN","USER"]`
- `plan`: `FREE | PRO | ENTERPRISE`
- `home_region`
- `exp` (short TTL)

### 2.2 Auth flow
- Browser → Cognito Hosted UI → JWT
- API Gateway Authorizer validates JWT
- Services validate `tenant_id` presence and enforce authorization rules

### 2.3 Authorization rules (examples)
- Tenant Admin can manage:
  - users, roles, integrations, workflows, billing
- Tenant User can manage:
  - their own profile, entities allowed by role
- Platform Admin:
  - tenant status, support tools, incident actions (break-glass)

**Break-glass access**
- Dedicated IAM role with MFA + approval workflow
- All break-glass activity logged and alerted

---

## 3) Service interfaces (REST API examples)

### 3.1 Tenant Service
**POST** `/tenants`
- Creates tenant, assigns `tenant_id`, sets home region

**GET** `/tenants/{tenant_id}`
- Requires platform admin OR tenant admin (same tenant)

**PATCH** `/tenants/{tenant_id}`
- Update plan, feature flags, status

### 3.2 User/Identity Service
**POST** `/tenants/{tenant_id}/users/invite`
- Body: `{ email, role }`

**GET** `/tenants/{tenant_id}/users`
- List users (tenant admin)

### 3.3 Entity Service (example business object)
**POST** `/tenants/{tenant_id}/entities`
- Body: `{ type, attributes }`

**GET** `/tenants/{tenant_id}/entities/{entity_id}`

**GET** `/tenants/{tenant_id}/entities?type=...&page=...`

### 3.4 File Service
**POST** `/tenants/{tenant_id}/files/presign`
- returns signed upload URL (S3)

**POST** `/tenants/{tenant_id}/files/complete`
- confirms upload; triggers scan/workflow event

### 3.5 Workflow Service
**POST** `/tenants/{tenant_id}/workflows`
- create rule: trigger + actions

**POST** `/tenants/{tenant_id}/workflows/{id}/enable`

---

## 4) Data model (Aurora PostgreSQL)

### 4.1 Core tables (minimal)
- `tenants(tenant_id PK, name, home_region, plan, status, created_at)`
- `users(user_id PK, tenant_id FK, email, role, status, created_at)`
- `entities(entity_id PK, tenant_id FK, type, attributes JSONB, created_at, updated_at)`
- `files(file_id PK, tenant_id FK, s3_key, mime_type, status, created_at)`
- `workflows(workflow_id PK, tenant_id FK, definition JSONB, status, created_at)`
- `audit_events(event_id PK, tenant_id, actor_user_id, action, resource, ts, ip, user_agent, details JSONB)`

### 4.2 Tenant scoping patterns
**Always include `tenant_id` in:**
- PK strategy or composite indexes
- Query WHERE clause
- Unique constraints (scoped to tenant)

**Indexes**
- `(tenant_id, created_at)`
- `(tenant_id, type, updated_at)`
- `(tenant_id, email)` unique

### 4.3 Row-Level Security (recommended)
Example policy idea (pseudo):
- enable RLS on tenant tables
- set `app.current_tenant_id` on connection
- policy: `tenant_id = current_setting('app.current_tenant_id')::uuid`

> If you don’t implement full RLS in v1, you must still enforce tenant scoping in code + add automated tests.

---

## 5) Tenant Registry (DynamoDB)

### 5.1 Table: `tenant_registry`
Partition key: `tenant_id` (string/uuid)

Attributes:
- `home_region`
- `data_residency`
- `plan`
- `status`
- `kms_key_arn` (optional)
- `created_at`

### 5.2 Why DynamoDB here?
- fast lookups for routing / feature flags
- global table option for multi-region reads
- easy operational scaling

---

## 6) Event-driven workflows

### 6.1 EventBridge event envelope (standard)
```json
{
  "version": "1.0",
  "id": "uuid",
  "source": "svc.entity",
  "detail-type": "EntityCreated",
  "time": "2026-02-26T00:00:00Z",
  "region": "us-east-1",
  "detail": {
    "tenant_id": "t-123",
    "entity_id": "e-456",
    "actor_user_id": "u-789",
    "payload": {}
  }
}
```

### 6.2 Routing
- EventBridge rules route events by:
  - `detail-type`
  - `detail.tenant_id` (optional)
  - `detail.plan` (optional)

### 6.3 Queues & DLQs
- Each worker has:
  - main queue
  - DLQ
- Redrive policy on max receives
- Idempotency key stored in DynamoDB to prevent double-processing

---

## 7) Observability (LLD)

### 7.1 Logs
- JSON logs with fields:
  - `trace_id`, `span_id`, `tenant_id`, `user_id`, `service`, `path`, `status`, `latency_ms`
- Centralized retention policy; export to S3 for long-term retention

### 7.2 Metrics
- API latency p50/p95/p99
- error rate, throttles
- queue depth, DLQ count
- DB CPU, connections, slow queries

### 7.3 Tracing
- OpenTelemetry instrumentation in services
- X-Ray trace propagation end-to-end
- Correlate traces with tenant_id for debugging

---

## 8) Security controls (LLD)

- **WAF managed rules** + rate limiting
- **API Gateway throttling** per tenant plan
- **Least privilege IAM**:
  - separate task roles per service
  - no wildcard access to S3/Aurora
- **Secrets Manager rotation** for DB creds
- **KMS**:
  - env key for shared
  - optional per-tenant key for premium
- **S3**:
  - block public access
  - bucket policy to require TLS
  - object ownership enforced
- **CloudTrail + Config**:
  - config rules for “no public S3”, “encrypted volumes”, etc.
- **GuardDuty + Security Hub**:
  - alerting pipeline to PagerDuty/Slack (later)

---

## 9) Deployment (LLD)

### 9.1 Environments
- `dev` / `staging` / `prod`
- Separate AWS accounts recommended (Organizations) — authored as a
  separate Terraform root (`infra/terraform/org/`: Organization, `Workloads`
  OU with `Dev`/`Prod` children, SCPs for root-user denial, region
  restriction, and mandatory tagging). Not yet applied against a real
  multi-account org — `envs/{dev,stage,prod}` still run in a single account
  today. See `docs/architecture/README.md` "Known Gaps".

### 9.2 CI/CD (repo-friendly)
- GitHub Actions:
  - lint, tests, terraform fmt/validate
- Deployment (later):
  - Terraform apply gated to manual approval for prod
  - blue/green or rolling deploy for ECS services

### 9.3 Networking
- Private subnets for services & data
- VPC endpoints where possible to reduce NAT costs: Gateway Endpoints for
  S3/DynamoDB (free, route-table based, not PrivateLink) plus Interface
  Endpoints (AWS PrivateLink, ENI-based) for ECR/CloudWatch Logs/Secrets
  Manager (`modules/vpc/privatelink.tf`)
- Internal NLB dual-registered on the default ECS service alongside the ALB
  (`modules/compute/nlb.tf`), also the backing load balancer for a
  PrivateLink VPC Endpoint Service that publishes the service for cross-VPC/
  cross-account private consumption (`modules/compute/privatelink.tf`)
- VPC Flow Logs to CloudWatch Logs with saved Logs Insights queries
  (`modules/observability/logs.tf`, `insights_queries.tf`)

---

## 10) Testing strategy (tenant isolation is the #1 test)
- Unit tests: authZ rules for each endpoint
- Integration tests:
  - request with `tenant_id=A` must never return `tenant_id=B`
- Contract tests for events (schema validation)
- Chaos drills:
  - kill task, simulate queue backlog, DB failover game day

---

## 11) Backlog (next design docs you can add later)
- ADRs: tenancy strategy, DB RLS choice, event envelope standard
- Threat model (STRIDE)
- Runbooks: incident response, failover, restore
- Cost model: per-tenant unit economics

