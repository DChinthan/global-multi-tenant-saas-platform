resource "aws_secretsmanager_secret" "db_password" {
  name       = "${local.name_prefix}-db-password"
  kms_key_id = aws_kms_key.security.arn

  tags = local.common_tags
}

resource "aws_ssm_parameter" "app_env" {
  name  = "/${local.name_prefix}/app/env"
  type  = "String"
  value = var.environment

  tags = local.common_tags
}