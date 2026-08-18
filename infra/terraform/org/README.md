# AWS Organizations + SCPs

Terraform root for a minimal multi-account landing zone: an Organization,
a `Workloads` OU containing `Dev` and `Prod` child OUs, and three Service
Control Policies attached to `Workloads`:

| SCP | Enforces |
|---|---|
| `deny-root-user-actions` | No action may be taken as the account root user in any Workloads-OU account |
| `region-restriction` | Deny everything outside `var.allowed_regions` (default `us-east-1`, `us-west-2`), except inherently-global services (IAM, Organizations, Route 53, CloudFront, WAF, Support, STS, Billing) |
| `mandatory-project-tag` | Deny `ec2:RunInstances`, `s3:CreateBucket`, `rds:CreateDBInstance`/`CreateDBCluster` unless the create request carries a `Project` tag |

## This is a separate account context from `envs/`

`infra/terraform/envs/{dev,stage,prod}` are **workload** environments living
inside a single AWS account today. This config operates one layer up, at
the **AWS Organizations management account**. Do not point it at the same
account/credentials used for `envs/*` — Organizations resources are created
in whichever account you run `terraform apply` from, and that account
becomes (or already is) the org's management account.

## Running this safely

```bash
cd infra/terraform/org
terraform init
terraform plan   # create_member_accounts defaults to false - read the plan
```

- `create_member_accounts = false` (default): only the Organization, OUs,
  and SCPs are created/planned. No new AWS accounts.
- `create_member_accounts = true`: also creates real `<project>-dev` and
  `<project>-prod` member accounts under their OUs. **Account creation is
  real, billed, and not cleanly reversible** — a closed account is only
  recoverable for 90 days, then it's gone, and Terraform cannot delete an
  account it created (both account resources carry
  `lifecycle.prevent_destroy` on top of that). Only flip this on against a
  real or sandbox Organizations management account you control, after
  reading `terraform plan` line by line, and after setting
  `dev_account_email` / `prod_account_email` to email addresses not already
  used by any AWS account.

This repo's own CI/CD (`.github/workflows/`) never applies this root — it's
authored for manual, reviewed application only.

## Verifying an SCP once applied

```bash
# From a Dev/Prod member account, root-user calls now fail with
# AccessDenied ("... explicit deny in a service control policy"):
aws sts get-caller-identity   # works (not a root/console-only check)

# Attempt an action outside the allowed regions:
aws ec2 describe-instances --region eu-west-1
# -> An error occurred (UnauthorizedOperation) ... explicit deny in SCP "region-restriction"

# Attempt an untagged bucket create:
aws s3api create-bucket --bucket some-test-bucket --region us-east-1
# -> An error occurred (AccessDenied) ... explicit deny in SCP "mandatory-project-tag"
```
