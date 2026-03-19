output "kms_key_arn" {
  description = "KMS key ARN for the data layer"
  value       = aws_kms_key.data.arn
}

output "aurora_cluster_endpoint" {
  description = "Aurora cluster endpoint"
  value       = var.enable_aurora ? aws_rds_cluster.aurora[0].endpoint : null
}

output "aurora_reader_endpoint" {
  description = "Aurora reader endpoint"
  value       = var.enable_aurora ? aws_rds_cluster.aurora[0].reader_endpoint : null
}

output "aurora_security_group_id" {
  description = "Aurora security group ID"
  value       = var.enable_aurora ? aws_security_group.aurora[0].id : null
}

output "tenant_config_table_name" {
  value = aws_dynamodb_table.tenant_config.name
}

output "session_store_table_name" {
  value = aws_dynamodb_table.session_store.name
}

output "rate_limit_table_name" {
  value = aws_dynamodb_table.rate_limit.name
}

output "audit_logs_bucket_name" {
  value = aws_s3_bucket.audit_logs.bucket
}

output "exports_bucket_name" {
  value = aws_s3_bucket.exports.bucket
}

output "tenant_reports_bucket_name" {
  value = aws_s3_bucket.tenant_reports.bucket
}

output "audit_logs_bucket_id" {
  value = aws_s3_bucket.audit_logs.id
}

output "rds_instance_id" {
  value = try(aws_rds_cluster.aurora[0].id, null)
}

output "audit_logs_bucket_arn" {
  value = aws_s3_bucket.audit_logs.arn
}

output "exports_bucket_arn" {
  value = aws_s3_bucket.exports.arn
}

output "tenant_reports_bucket_arn" {
  value = aws_s3_bucket.tenant_reports.arn
}