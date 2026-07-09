locals {
  name_prefix = "${var.project}-${var.environment}"

  # Storage account names must be globally unique, lowercase alphanumeric,
  # 3-24 chars - no room for a readable prefix + hyphens, hence the random
  # suffix and stripped separators.
  storage_account_name = lower(substr(replace("${var.project}${var.environment}app5${random_string.storage_suffix.result}", "-", ""), 0, 24))

  common_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Layer       = "azure_aks"
  })
}

resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}
