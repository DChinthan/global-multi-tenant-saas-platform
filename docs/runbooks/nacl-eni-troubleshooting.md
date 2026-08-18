# Runbook: ENI/NACL Connectivity Troubleshooting

A walkthrough for diagnosing "security group looks correct but the target is
still unreachable" incidents, using a deliberately-broken lab environment
built into this repo's Terraform (`infra/terraform/modules/vpc/nacl_lab.tf`).

## The lab

`var.enable_troubleshooting_lab` (default `false`, wired through every env's
`main.tf` → `module.vpc`) attaches a custom NACL to the first AZ's
private-app subnet with one explicit rule: **deny inbound TCP on
`var.app_container_port` (8080) from anywhere**. Every ECS security group in
`modules/compute/network.tf` is left untouched and still correctly allows
port 8080 from the ALB/NLB — which is exactly what makes this realistic. The
symptom won't point at the SG at all.

**Enable it (dev only — never stage/prod):**

```bash
cd infra/terraform/envs/dev
# in dev.tfvars or -var:
#   enable... is set inside modules/vpc block in main.tf directly; to enable
#   the lab, flip enable_troubleshooting_lab = true in envs/dev/main.tf's
#   module "vpc" block, then:
terraform plan
terraform apply
```

## Symptom

- ALB/NLB target-group health checks report targets in one AZ as
  `unhealthy`, while the same AZ's targets were healthy moments before.
- Security group rules for the ECS service (`aws ec2 describe-security-
  groups`) show port 8080 correctly allowed from the ALB/NLB security group.
- Only tasks scheduled into the affected AZ's private-app subnet are
  impacted — tasks in other AZs behave normally.

## Diagnosis, step by step

### 1. Confirm the target-group symptom

```bash
aws elbv2 describe-target-health \
  --target-group-arn <default-service-target-group-arn> \
  --query 'TargetHealthDescriptions[].{Target:Target.Id,Port:Target.Port,AZ:Target.AvailabilityZone,State:TargetHealth.State,Reason:TargetHealth.Reason}' \
  --output table
```

Targets in the affected AZ show `State: unhealthy`, `Reason:
Target.Timeout` (a NACL DENY produces a connection timeout, not an active
RST like a security-group deny would — this distinction is itself a clue
about which layer is at fault).

### 2. Rule out the security group

```bash
aws ec2 describe-security-groups \
  --group-ids <ecs-service-sg-id> \
  --query 'SecurityGroups[].IpPermissions'
```

Confirm port 8080 is allowed from the ALB/NLB SG. If it is (as in this lab),
the SG is not the cause — move down a layer to the NACL and the ENI itself.

### 3. Find the affected task's ENI

```bash
TASK_ARN=$(aws ecs list-tasks --cluster <cluster-name> --service-name <service-name> --query 'taskArns[0]' --output text)

aws ecs describe-tasks --cluster <cluster-name> --tasks "$TASK_ARN" \
  --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
  --output text
```

### 4. Inspect the ENI and its subnet

```bash
aws ec2 describe-network-interfaces --network-interface-ids <eni-id> \
  --query 'NetworkInterfaces[0].{SubnetId:SubnetId,AZ:AvailabilityZone,PrivateIp:PrivateIpAddress,Groups:Groups[].GroupId}'
```

Take the `SubnetId` from this output — that's what you cross-reference next.

### 5. Find the NACL attached to that subnet

```bash
aws ec2 describe-network-acls \
  --filters "Name=association.subnet-id,Values=<subnet-id>" \
  --query 'NetworkAcls[0].Entries'
```

This surfaces the lab's rule: `RuleNumber: 100, Protocol: 6 (tcp), PortRange:
{From: 8080, To: 8080}, RuleAction: deny, CidrBlock: 0.0.0.0/0, Egress:
false`. **This is the root cause** — a custom NACL denying the exact port
the target group health-checks on, on exactly the subnet the unhealthy
task's ENI lives in.

### 6. Cross-check against VPC Flow Logs

With `enable_vpc_flow_logs = true` (see `modules/observability/logs.tf`),
run the saved CloudWatch Logs Insights query
`<project>-<env>/vpc-flow-logs/rejected-connections-by-dest-port`
(`modules/observability/insights_queries.tf`) and filter/eyeball for the
affected `interface_id`:

```
fields @timestamp, @message
| parse @message "* * * * * * * * * * * * * *" as version, account_id, interface_id, srcaddr, dstaddr, srcport, dstport, protocol, packets, bytes, start, end, action, log_status
| filter action = "REJECT" and interface_id = "<eni-id>" and dstport = 8080
| sort @timestamp desc
```

This confirms *when* and *how often* the rejects are happening and from
which source IPs (the ALB/NLB's ENIs), corroborating step 5's finding.
**Caveat:** flow logs tell you a packet was rejected, not which construct
(NACL vs SG) rejected it — that attribution only comes from steps 2–5, or
from Reachability Analyzer below.

### 7. Confirm with VPC Reachability Analyzer

Reachability Analyzer is the fastest way to get AWS to name the exact
blocking rule, rather than inferring it manually:

```bash
PATH_ID=$(aws ec2 create-network-insights-path \
  --source <alb-or-nlb-eni-id> \
  --destination <ecs-task-eni-id> \
  --destination-port 8080 \
  --protocol tcp \
  --query 'NetworkInsightsPath.NetworkInsightsPathId' --output text)

ANALYSIS_ID=$(aws ec2 start-network-insights-analysis \
  --network-insights-path-id "$PATH_ID" \
  --query 'NetworkInsightsAnalysis.NetworkInsightsAnalysisId' --output text)

# Poll until Status is succeeded (usually a few seconds)
aws ec2 describe-network-insights-analyses \
  --network-insights-analysis-ids "$ANALYSIS_ID" \
  --query 'NetworkInsightsAnalyses[0].{Status:Status,Reachable:NetworkPathFound,ExplanationCount:length(Explanations)}'

aws ec2 describe-network-insights-analyses \
  --network-insights-analysis-ids "$ANALYSIS_ID" \
  --query 'NetworkInsightsAnalyses[0].Explanations[?contains(to_string(@),`Acl`)]'
```

`NetworkPathFound: false`, with an explanation entry naming the specific
NACL, rule number, and subnet blocking the path — no manual cross-
referencing required. This is the tool to reach for first in a real
incident; steps 3–6 above are what you do by hand when you want to verify
Reachability Analyzer's finding or don't have it enabled for the resource.

## Fix

```bash
cd infra/terraform/envs/dev
# flip enable_troubleshooting_lab back to false in main.tf's module "vpc" block
terraform apply
```

Re-run step 1 (`describe-target-health`) — targets in the previously-affected
AZ return to `healthy`. Re-run the Reachability Analyzer path from step 7 —
`NetworkPathFound` flips to `true`.

## Root cause and prevention

- **Root cause:** a NACL is a stateless, subnet-wide firewall that sits
  below the security group layer and is easy to forget about once an
  environment is stable — most day-to-day AWS work is 100% security groups,
  so NACLs fall out of institutional memory until something like this
  happens.
- **Prevention:**
  - Prefer leaving subnets on the default "allow all" main VPC NACL unless
    there's a specific reason for a custom one (defense-in-depth for a
    specific compliance requirement, etc.) — every custom NACL is one more
    place a rule can silently diverge from intent.
  - If a custom NACL is necessary, keep it under Terraform (as this lab
    does) so drift is visible in `terraform plan`, and add an automated
    check (e.g., a CI job that runs Reachability Analyzer against the
    ALB/NLB → ECS task path) so a bad rule fails a pipeline instead of
    paging someone.
  - Alarm on target-group `UnHealthyHostCount` scoped by AZ — a single-AZ
    pattern like this lab produces is a strong signal to check the NACL
    layer specifically, since a security-group misconfiguration would
    almost always affect all AZs at once (SGs aren't AZ-scoped; NACLs are
    subnet-, and therefore effectively AZ-, scoped).
