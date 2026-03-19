resource "aws_backup_vault" "platform" {
  count = local.dr_enabled && var.enable_backup_plan ? 1 : 0

  name = "${local.name_prefix}-backup-vault"

  tags = local.common_tags
}

resource "aws_backup_plan" "platform" {
  count = local.dr_enabled && var.enable_backup_plan ? 1 : 0

  name = "${local.name_prefix}-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.platform[0].name
    schedule          = "cron(0 3 * * ? *)"

    lifecycle {
      delete_after = 30
    }
  }

  rule {
    rule_name         = "weekly-backup"
    target_vault_name = aws_backup_vault.platform[0].name
    schedule          = "cron(0 4 ? * SUN *)"

    lifecycle {
      delete_after = 90
    }
  }

  tags = local.common_tags
}

resource "aws_backup_selection" "platform" {
  count = local.dr_enabled && var.enable_backup_plan && length(var.backup_resource_arns) > 0 ? 1 : 0

  iam_role_arn = aws_iam_role.backup[0].arn
  name         = "${local.name_prefix}-backup-selection"
  plan_id      = aws_backup_plan.platform[0].id

  resources = var.backup_resource_arns
}