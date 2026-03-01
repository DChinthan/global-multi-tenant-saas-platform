output "context" {
  description = "Temporary output for CI hygiene until RDS is implemented"
  value = {
    project        = var.project
    environment    = var.environment
    vpc_id         = var.vpc_id
    instance_class = var.instance_class
  }
}