# Resume Bullets — Networking/Security Hands-On Gaps

Generated from the Terraform actually added in this pass (all `terraform
validate`-clean across `envs/dev`, `envs/stage`, `envs/prod`, and
`infra/terraform/org`). Each bullet is paired with an honest depth note —
use the bullet on a resume/LinkedIn; read the depth note before claiming
more than that in an interview.

---

### 1. Network Load Balancer

> Implemented a Network Load Balancer alongside an existing Application
> Load Balancer for an ECS Fargate service, using AWS's dual-target-group
> pattern to add L4/TCP capability without disrupting existing L7 path-based
> routing.

**Depth: used once, in one repo.** Real, validated Terraform wiring the NLB
into the actual ECS service (`infra/terraform/modules/compute/nlb.tf`,
`ecs.tf`). Never applied against live traffic or load-tested — you can
speak to *why* NLB vs ALB and how ECS multi-target-group registration
works, but not to production behavior under load.

### 2. AWS PrivateLink (both directions)

> Implemented AWS PrivateLink in both directions: Interface VPC Endpoints
> for ECR, CloudWatch Logs, and Secrets Manager to remove a NAT Gateway
> dependency for private-subnet workloads, and a VPC Endpoint Service backed
> by a Network Load Balancer to publish an internal service for cross-VPC/
> cross-account private consumption.

**Depth: split.** The consuming side (Interface Endpoints) closes a real,
concrete gap — dev's ECS tasks previously had no path to pull container
images at all with NAT disabled — and is wired into all three environments.
The publishing side (VPC Endpoint Service) is a real resource in `stage`,
but `privatelink_allowed_principal_arns` is empty: no second AWS account has
actually requested/accepted a connection. **Don't claim you've validated
cross-account PrivateLink consumption — you've built the publisher side
only.**

### 3. AWS Organizations + Service Control Policies

> Authored a multi-account AWS Organizations structure (a `Workloads` OU
> with `Dev`/`Prod` child OUs) and three Service Control Policies — deny
> root-user actions, region restriction, and mandatory resource tagging —
> using the Terraform AWS Organizations provider.

**Depth: design/IaC only, never applied.** `infra/terraform/org/` is a
separate, `terraform validate`-clean root, but it targets an Organizations
management account this work never had access to apply against — no SCP
here has ever actually denied a real API call. Frame this as "designed and
Terraform'd," not "operated" or "enforced in production." Getting one real
`AccessDenied ... explicit deny in a service control policy` in a sandbox
org would upgrade this bullet meaningfully.

### 4. VPC Flow Logs

> Enabled VPC Flow Logs to CloudWatch Logs (with a dedicated IAM role) and
> authored two CloudWatch Logs Insights queries answering concrete
> operational questions — top bandwidth consumers by ENI, and rejected
> connections grouped by destination port/source.

**Depth: real and repeatable.** Wired into the observability module, used
in `stage`/`prod` (and available to flip on in `dev`), with saved,
reusable `aws_cloudwatch_query_definition` resources rather than one-off
console queries. Flag honestly: flow logs can't attribute a REJECT to a
specific security group or NACL — that limitation is documented, not
glossed over — so don't claim the queries "identify the blocking security
group," only that they identify *when/where* rejects concentrate.

### 5. ENI/NACL Troubleshooting Runbook

> Built a deliberately-misconfigured NACL lab and wrote a full
> incident-response runbook: diagnosed a single-AZ outage via CloudWatch
> Logs Insights, ENI/NACL inspection (AWS CLI), and AWS VPC Reachability
> Analyzer, then documented root cause and prevention.

**Depth: walked through once.** Practiced the full loop — break it, find
it, fix it, confirm via Reachability Analyzer — exactly once while writing
the runbook. Real and reusable (the lab is a Terraform toggle, not a
one-time manual edit), but this is "have the runbook and know the
commands," not "have run this as a repeated game-day drill."

### 6. PowerShell / AWS Tools for PowerShell

> Wrote a PowerShell automation script using AWS Tools for PowerShell
> (`AWS.Tools.ECS`, `AWS.Tools.ECR`) for ECS deployment and stale image
> cleanup, as a working side-by-side comparison to the existing Bash/AWS
> CLI version of the same operation.

**Depth: one script, one operation.** This proves you can read AWS.Tools
cmdlet references and translate an existing Bash/CLI workflow into
PowerShell correctly (verified cmdlet names/parameters against AWS docs
rather than guessed) — it is not evidence of broad PowerShell fluency.
Reach for this only if a target role is explicitly Windows/PowerShell-first,
and be ready to say "one comparable example," not "I use PowerShell for AWS
automation."
