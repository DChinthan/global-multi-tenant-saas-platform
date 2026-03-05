output "kms_key_arn" {
  value = aws_kms_key.security.arn
}

output "kms_alias" {
  value = aws_kms_alias.security.name
}

output "cloudtrail_bucket_name" {
  value = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail[0].bucket : null
}

output "cloudtrail_name" {
  value = var.enable_cloudtrail ? aws_cloudtrail.main[0].name : null
}

output "config_bucket_name" {
  value = var.enable_config ? aws_s3_bucket.config[0].bucket : null
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db_password.arn
}

output "app_env_param_name" {
  value = aws_ssm_parameter.app_env.name
}