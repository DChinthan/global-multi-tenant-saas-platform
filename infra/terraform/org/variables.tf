variable "project" {
  type    = string
  default = "global-multi-tenant-saas-platform"
}

variable "create_member_accounts" {
  description = <<-EOT
    Actually create dev/prod member AWS accounts under the Workloads OU.
    Account creation is real, billed, and NOT cleanly reversible - a
    "closed" AWS account is only reclaimable for 90 days and then it's gone
    for good, and Terraform cannot delete an account it created (AWS
    requires closing accounts through the Organizations console/API
    directly, which is why the accounts below also carry
    lifecycle.prevent_destroy).

    Keep this false until you've reviewed `terraform plan` line by line and
    are deliberately running it against a real Organizations management
    account (ideally a fresh sandbox org, not one with production accounts
    in it). Never point this at the same AWS account that hosts
    infra/terraform/envs/* - those already assume a single-account setup.
  EOT
  type        = bool
  default     = false
}

variable "dev_account_email" {
  description = "Root email for the dev member account. Must not already be in use by any AWS account. Only required when create_member_accounts = true."
  type        = string
  default     = ""
}

variable "prod_account_email" {
  description = "Root email for the prod member account. Only required when create_member_accounts = true."
  type        = string
  default     = ""
}

variable "allowed_regions" {
  description = "Regions member accounts under the Workloads OU are allowed to operate in - enforced by the region-restriction SCP in scp.tf."
  type        = list(string)
  default     = ["us-east-1", "us-west-2"]
}
