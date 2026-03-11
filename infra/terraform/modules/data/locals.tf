locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
      Layer       = "data"
    },
    var.tags
  )

  bucket_names = {
    audit_logs     = "${local.name_prefix}-audit-logs"
    exports        = "${local.name_prefix}-exports"
    tenant_reports = "${local.name_prefix}-tenant-reports"
  }
}