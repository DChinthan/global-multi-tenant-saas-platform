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

  # The single service (out of var.services) that the ALB forwards to by
  # default. Validated in variables.tf to always resolve to exactly one key.
  default_service_key = one([for k, v in var.services : k if v.is_default])

  # Distinct container ports across all services, used for the ECS service SG.
  service_ports = distinct([for v in var.services : v.container_port])
}