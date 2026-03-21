locals {
  compute_name_prefix = "${var.project}-${var.environment}"
  short_prefix        = "gmtsp-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Layer       = "compute"
  })
}