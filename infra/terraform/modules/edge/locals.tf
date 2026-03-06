locals {
  name_prefix = "${var.project}-${var.environment}"
  fqdn        = "${var.app_subdomain}.${var.domain_name}"

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}