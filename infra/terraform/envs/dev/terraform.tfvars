# ================================
# Core Project Config
# ================================
aws_region  = "us-east-1"
project     = "global-mt-saas"
environment = "dev"

tags = {
  Owner       = "Chinthan"
  Environment = "dev"
  Project     = "global-mt-saas"
}

cidr_block = "10.10.0.0/16"

# ================================
# Cost Safety Toggles (OFF by default)
# ================================
enable_nat        = false
enable_rds        = false
enable_opensearch = false
enable_kinesis    = false

# ================================
# Sizing Config
# ================================
rds_instance_class       = "db.t4g.micro"
opensearch_instance_type = "t3.small.search"

# ================================
# Identity (Cognito)
# ================================
enable_identity       = true
cognito_domain_prefix = "mt-saas-dev-auth-chinthan"

callback_urls = [
  "http://localhost:3000/callback"
]

logout_urls = [
  "http://localhost:3000/logout"
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