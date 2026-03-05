variable "project" { type = string }
variable "environment" { type = string }

variable "tags" {
  type    = map(string)
  default = {}
}

# Toggles (cost safety)
variable "enable_cloudtrail" {
  type    = bool
  default = true
}

variable "enable_config" {
  type    = bool
  default = false
}

variable "enable_security_services" {
  type    = bool
  default = false
}