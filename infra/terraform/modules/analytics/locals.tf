locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "analytics"
  })

  glue_database_name = var.glue_database_name != null ? var.glue_database_name : replace("${local.name_prefix}_analytics", "-", "_")
}