# ================================
# Core Project Config
# ================================
aws_region  = "us-east-1"
project     = "global-multi-tenant-saas-platform"
environment = "prod"

tags = {
  Owner       = "Chinthan"
  Environment = "prod"
  Project     = "global-multi-tenant-saas-platform"
}

cidr_block = "10.10.0.0/16"


# ================================
# Cost Safety Toggles (still OFF for your project)
# ================================
enable_nat        = false
enable_rds        = false
enable_opensearch = false
enable_kinesis    = false


# ================================
# Identity (Cognito)
# ================================
enable_identity       = true
cognito_domain_prefix = "mt-saas-prod-auth-chinthan"

callback_urls = [
  "https://app.example.com/callback"
]

logout_urls = [
  "https://app.example.com/logout"
]


# ================================
# Disaster Recovery (Phase 12)
# ================================
secondary_region = "us-west-2"

enable_disaster_recovery = false # keep OFF for cost safety
enable_s3_replication    = false
enable_route53_failover  = false
enable_backup_plan       = false
enable_kms_multi_region  = false


# ================================
# Route53 / Failover Inputs
# ================================
hosted_zone_id         = null
domain_name            = null
secondary_alb_dns_name = null
secondary_alb_zone_id  = null


# ================================
# S3 Replication Mapping (PREPARED)
# ================================
replication_bucket_mappings = {
  audit = {
    source_bucket_name     = "prod-audit-logs"
    source_bucket_arn      = "arn:aws:s3:::prod-audit-logs"
    destination_bucket_arn = "arn:aws:s3:::prod-audit-logs-dr"
  }

  exports = {
    source_bucket_name     = "prod-exports"
    source_bucket_arn      = "arn:aws:s3:::prod-exports"
    destination_bucket_arn = "arn:aws:s3:::prod-exports-dr"
  }

  tenant_reports = {
    source_bucket_name     = "prod-tenant-reports"
    source_bucket_arn      = "arn:aws:s3:::prod-tenant-reports"
    destination_bucket_arn = "arn:aws:s3:::prod-tenant-reports-dr"
  }
}
