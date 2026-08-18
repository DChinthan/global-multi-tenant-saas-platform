############################################
# AWS Organizations: multi-account structure
#
# Root
#  └─ Workloads (OU)          <- SCPs in scp.tf attach here
#      ├─ Dev (OU)
#      │   └─ <project>-dev account (optional, gated by create_member_accounts)
#      └─ Prod (OU)
#          └─ <project>-prod account (optional, gated by create_member_accounts)
#
# SCPs are attached to the Workloads OU rather than the Root, so the
# management account and any future Security/Log-Archive OUs aren't subject
# to the same restrictions as workload accounts - a standard AWS landing
# zone pattern. Note SCPs never affect the Organizations management account
# itself regardless of where they're attached; that's an AWS Organizations
# invariant, not something this config controls.
############################################

resource "aws_organizations_organization" "this" {
  feature_set = "ALL"

  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "sso.amazonaws.com",
    "guardduty.amazonaws.com",
  ]

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
  ]
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "dev" {
  name      = "Dev"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_organizational_unit" "prod" {
  name      = "Prod"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_account" "dev" {
  count = var.create_member_accounts ? 1 : 0

  name              = "${var.project}-dev"
  email             = var.dev_account_email
  parent_id         = aws_organizations_organizational_unit.dev.id
  role_name         = "OrganizationAccountAccessRole"
  close_on_deletion = false

  tags = {
    Project     = var.project
    Environment = "dev"
    ManagedBy   = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "prod" {
  count = var.create_member_accounts ? 1 : 0

  name              = "${var.project}-prod"
  email             = var.prod_account_email
  parent_id         = aws_organizations_organizational_unit.prod.id
  role_name         = "OrganizationAccountAccessRole"
  close_on_deletion = false

  tags = {
    Project     = var.project
    Environment = "prod"
    ManagedBy   = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}
