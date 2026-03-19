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
# DR Destination Bucket ARNs
# ================================
dr_audit_logs_bucket_arn     = null
dr_exports_bucket_arn        = null
dr_tenant_reports_bucket_arn = null