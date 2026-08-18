############################################
# Service Control Policies, attached to the Workloads OU (covers both Dev
# and Prod member accounts underneath it).
############################################

# 1) Deny root user actions -----------------------------------------------
# The account root user bypasses IAM entirely, so the only way to constrain
# it is an SCP. This denies every action taken directly as root in any
# Workloads-OU member account, forcing all real operations through IAM
# roles/users instead.
data "aws_iam_policy_document" "deny_root_user" {
  statement {
    sid       = "DenyRootUser"
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:root"]
    }
  }
}

resource "aws_organizations_policy" "deny_root_user" {
  name        = "deny-root-user-actions"
  description = "Denies all actions taken directly as the account root user."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.deny_root_user.json
}

# 2) Region restriction -----------------------------------------------------
# Denies everything outside var.allowed_regions, except the services that
# are inherently global (IAM, Organizations, Route 53, CloudFront, WAF,
# Support, STS, Billing/Cost Explorer, Global Accelerator, Shield) - denying
# those by region would break normal account operation since they have no
# regional endpoint to restrict.
data "aws_iam_policy_document" "region_restriction" {
  statement {
    sid    = "DenyOutsideAllowedRegions"
    effect = "Deny"
    not_actions = [
      "iam:*",
      "organizations:*",
      "route53:*",
      "route53domains:*",
      "cloudfront:*",
      "waf:*",
      "wafv2:*",
      "support:*",
      "trustedadvisor:*",
      "sts:*",
      "budgets:*",
      "ce:*",
      "health:*",
      "globalaccelerator:*",
      "shield:*",
    ]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }
  }
}

resource "aws_organizations_policy" "region_restriction" {
  name        = "region-restriction"
  description = "Denies actions outside ${join(", ", var.allowed_regions)}, except inherently-global services."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.region_restriction.json
}

# 3) Mandatory tagging -------------------------------------------------------
# Denies creating the resource types most likely to leak cost/ownership if
# untagged (EC2 instances, S3 buckets, RDS instances/clusters) unless the
# create request itself carries a Project tag. Uses the request-time
# aws:RequestTag condition, not a resource-tag lookup, so it blocks
# creation rather than trying to catch it after the fact.
data "aws_iam_policy_document" "mandatory_tagging" {
  statement {
    sid       = "DenyRunInstancesWithoutProjectTag"
    effect    = "Deny"
    actions   = ["ec2:RunInstances"]
    resources = ["arn:aws:ec2:*:*:instance/*"]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/Project"
      values   = ["true"]
    }
  }

  statement {
    sid       = "DenyCreateBucketWithoutProjectTag"
    effect    = "Deny"
    actions   = ["s3:CreateBucket"]
    resources = ["*"]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/Project"
      values   = ["true"]
    }
  }

  statement {
    sid       = "DenyRDSCreateWithoutProjectTag"
    effect    = "Deny"
    actions   = ["rds:CreateDBInstance", "rds:CreateDBCluster"]
    resources = ["*"]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/Project"
      values   = ["true"]
    }
  }
}

resource "aws_organizations_policy" "mandatory_tagging" {
  name        = "mandatory-project-tag"
  description = "Denies creating EC2 instances, S3 buckets, or RDS instances/clusters without a Project tag on the create request."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.mandatory_tagging.json
}

# Attachments ----------------------------------------------------------------

resource "aws_organizations_policy_attachment" "deny_root_user" {
  policy_id = aws_organizations_policy.deny_root_user.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy_attachment" "region_restriction" {
  policy_id = aws_organizations_policy.region_restriction.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy_attachment" "mandatory_tagging" {
  policy_id = aws_organizations_policy.mandatory_tagging.id
  target_id = aws_organizations_organizational_unit.workloads.id
}
