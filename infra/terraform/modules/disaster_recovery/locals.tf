locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "disaster_recovery"
  }

  dr_enabled = var.enable_disaster_recovery
}