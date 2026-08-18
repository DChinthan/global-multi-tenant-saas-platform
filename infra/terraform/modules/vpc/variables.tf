variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "enable_nat" {
  type    = bool
  default = false
}

# How many AZs to use (2 or 3)
variable "az_count" {
  type    = number
  default = 2
  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

# Gateway endpoints (no hourly cost)
variable "enable_gateway_endpoints" {
  type    = bool
  default = true
}

# Interface endpoints (AWS PrivateLink, hourly + per-GB cost - see privatelink.tf)
variable "enable_interface_endpoints" {
  description = <<-EOT
    Create Interface VPC Endpoints (AWS PrivateLink) for ECR (api+dkr),
    CloudWatch Logs, and Secrets Manager, so ECS Fargate tasks in the
    private-app subnets can pull images, ship logs, and read secrets without
    NAT Gateway egress. This closes a real gap in this repo: with
    enable_nat = false (the cost-safe default), private-app subnets have NO
    route to the internet and previously only had Gateway Endpoints for
    S3/DynamoDB - ECR image pulls had no path at all.

    Unlike Gateway Endpoints (free, route-table based, S3/DynamoDB only),
    Interface Endpoints are billed per-AZ per-hour (~$0.01/hr each) plus
    data processing - see docs/architecture/README.md "Known Gaps" for the
    cost comparison against just turning on NAT.
  EOT
  type        = bool
  default     = false
}

# Deliberately-broken NACL for the ENI/NACL troubleshooting runbook
# (docs/runbooks/nacl-eni-troubleshooting.md). NEVER enable this against an
# environment carrying real traffic - it intentionally breaks connectivity.
variable "enable_troubleshooting_lab" {
  description = "DANGER (dev-only lab toggle): attaches a custom NACL to the first private-app subnet that denies inbound TCP on var.app_container_port, so the NACL/ENI troubleshooting runbook has something real to diagnose. Defaults off."
  type        = bool
  default     = false
}

variable "app_container_port" {
  description = "Container port the troubleshooting-lab NACL blocks. Should match the default ECS service's container_port (modules/compute var.services)."
  type        = number
  default     = 8080
}

# Optional: tags
variable "tags" {
  type    = map(string)
  default = {}
}