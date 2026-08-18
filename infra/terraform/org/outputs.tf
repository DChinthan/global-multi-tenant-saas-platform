output "organization_id" {
  value = aws_organizations_organization.this.id
}

output "organization_root_id" {
  value = aws_organizations_organization.this.roots[0].id
}

output "workloads_ou_id" {
  value = aws_organizations_organizational_unit.workloads.id
}

output "dev_ou_id" {
  value = aws_organizations_organizational_unit.dev.id
}

output "prod_ou_id" {
  value = aws_organizations_organizational_unit.prod.id
}

output "dev_account_id" {
  value = try(aws_organizations_account.dev[0].id, null)
}

output "prod_account_id" {
  value = try(aws_organizations_account.prod[0].id, null)
}

output "scp_ids" {
  value = {
    deny_root_user     = aws_organizations_policy.deny_root_user.id
    region_restriction = aws_organizations_policy.region_restriction.id
    mandatory_tagging  = aws_organizations_policy.mandatory_tagging.id
  }
}
