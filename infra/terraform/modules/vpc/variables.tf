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
  type        = number
  default     = 2
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

# Optional: tags
variable "tags" {
  type    = map(string)
  default = {}
}