output "backup_vault_name" {
  value       = try(aws_backup_vault.platform[0].name, null)
  description = "AWS Backup vault name"
}

output "backup_plan_id" {
  value       = try(aws_backup_plan.platform[0].id, null)
  description = "AWS Backup plan ID"
}

output "s3_replication_role_arn" {
  value       = try(aws_iam_role.s3_replication[0].arn, null)
  description = "S3 replication IAM role ARN"
}

output "backup_role_arn" {
  value       = try(aws_iam_role.backup[0].arn, null)
  description = "AWS Backup IAM role ARN"
}

output "kms_key_arn" {
  value       = try(aws_kms_key.dr[0].arn, null)
  description = "DR KMS key ARN"
}

output "route53_health_check_id" {
  value       = try(aws_route53_health_check.primary[0].id, null)
  description = "Primary Route53 health check ID"
}