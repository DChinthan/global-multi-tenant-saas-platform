############################################
# Security Outputs
############################################

output "security_kms_key_arn" {
  description = "KMS key used for encryption"
  value       = module.security.kms_key_arn
}

output "cloudtrail_bucket_name" {
  description = "S3 bucket storing CloudTrail logs"
  value       = module.security.cloudtrail_bucket_name
}

output "cloudtrail_name" {
  description = "CloudTrail trail name"
  value       = module.security.cloudtrail_name
}

output "config_bucket_name" {
  description = "AWS Config logs bucket"
  value       = module.security.config_bucket_name
}

output "db_secret_arn" {
  description = "Secrets Manager DB password secret"
  value       = module.security.db_secret_arn
}

output "app_env_parameter" {
  description = "SSM Parameter storing environment"
  value       = module.security.app_env_param_name
}