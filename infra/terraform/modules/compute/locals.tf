locals {
  # Standard naming for compute resources
  compute_name_prefix = "${var.project}-${var.environment}"

  # Optional shorter prefix (useful for resource name limits like ALB, ECS, etc.)
  short_prefix = "gmtsp-${var.environment}"

  # Common tags applied to all compute resources
  common_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Layer       = "compute"
  })
}