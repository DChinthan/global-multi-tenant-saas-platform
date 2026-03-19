# ================================
# Core Project Config
# ================================
aws_region  = "us-east-1"
project     = "global-multi-tenant-saas-platform"
environment = "stage"

tags = {
  Owner       = "Chinthan"
  Environment = "stage"
  Project     = "global-multi-tenant-saas-platform"
}

cidr_block = "10.10.0.0/16"


# ================================
# Cost Safety Toggles
# ================================
enable_nat        = false
enable_rds        = false
enable_opensearch = false
enable_kinesis    = false


# ================================
# Identity (Cognito)
# ================================
enable_identity       = true
cognito_domain_prefix = "mt-saas-stage-auth-chinthan"

callback_urls = [
  "https://stage.example.com/callback"
]

logout_urls = [
  "https://stage.example.com/logout"
]


# ================================
# Disaster Recovery (Phase 12)
# ================================
secondary_region = "us-west-2"

enable_disaster_recovery = false
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
# S3 Replication Mapping (SAFE - NOT ACTIVE)
# ================================
replication_bucket_mappings = {
  audit = {
    source_bucket_name     = "stage-audit-logs"
    source_bucket_arn      = "arn:aws:s3:::stage-audit-logs"
    destination_bucket_arn = "arn:aws:s3:::stage-audit-logs-dr"
  }

  exports = {
    source_bucket_name     = "stage-exports"
    source_bucket_arn      = "arn:aws:s3:::stage-exports"
    destination_bucket_arn = "arn:aws:s3:::stage-exports-dr"
  }

  tenant_reports = {
    source_bucket_name     = "stage-tenant-reports"
    source_bucket_arn      = "arn:aws:s3:::stage-tenant-reports"
    destination_bucket_arn = "arn:aws:s3:::stage-tenant-reports-dr"
  }
}
