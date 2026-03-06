variable "project" { type = string }
variable "environment" { type = string }

variable "domain_name" {
  description = "Apex domain, e.g. example.com"
  type        = string
}

variable "app_subdomain" {
  description = "Subdomain for the app, e.g. app"
  type        = string
  default     = "app"
}

variable "enable_waf" {
  type    = bool
  default = true
}

variable "enable_geo_block" {
  type    = bool
  default = false
}

variable "geo_block_countries" {
  description = "ISO 3166-1 alpha-2 country codes (e.g. [\"RU\",\"CN\"])"
  type        = list(string)
  default     = []
}

variable "rate_limit_requests_per_5min" {
  description = "WAF rate limit threshold per IP over 5 minutes"
  type        = number
  default     = 2000
}

variable "origin_domain_name" {
  description = "Origin for CloudFront (ALB DNS, API GW, or placeholder)"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}