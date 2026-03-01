output "context" {
  description = "Module context (used for CI hygiene until resources are implemented)."
  value = {
    project       = var.project
    environment   = var.environment
    vpc_id        = var.vpc_id
    instance_type = var.instance_type
  }
}