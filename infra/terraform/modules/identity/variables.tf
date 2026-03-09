############################################################
# Project / Environment Context
############################################################

# Name of the project. Used in resource naming so that
# all infrastructure resources are grouped under the same project.
# Example: mt-saas
variable "project" {
  description = "Project name"
  type        = string
}

# Environment where this infrastructure is deployed.
# Usually one of: dev, stage, prod.
# Helps us create environment-specific resources like:
# mt-saas-dev-user-pool
variable "environment" {
  description = "Environment name"
  type        = string
}

############################################################
# Resource Tagging
############################################################

# Additional AWS tags that can be attached to resources.
# Tags are useful for cost tracking, ownership, and governance.
# Example:
# tags = {
#   Owner = "platform-team"
#   CostCenter = "engineering"
# }
variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

############################################################
# Feature Toggle
############################################################

# Toggle that enables or disables creation of identity resources.
# Useful for environments where we may not want to deploy Cognito.
# When false, Terraform will skip creating identity resources.
variable "enable_identity" {
  description = "Toggle to create identity resources"
  type        = bool
  default     = true
}

############################################################
# Cognito Hosted UI Configuration
############################################################

# Unique domain prefix for Cognito hosted authentication UI.
# Cognito requires globally unique domain names.
#
# Example resulting login URL:
# https://mt-saas-dev-auth.auth.us-east-1.amazoncognito.com
variable "cognito_domain_prefix" {
  description = "Unique Cognito domain prefix"
  type        = string
}

# List of allowed callback URLs after successful login.
# Cognito will redirect users back to one of these URLs
# after authentication is complete.
#
# Example:
# ["http://localhost:3000/callback"]
variable "callback_urls" {
  description = "Allowed callback URLs for the app client"
  type        = list(string)
  default     = []
}

# List of URLs users can be redirected to after logout.
# These must be explicitly allowed for security reasons.
#
# Example:
# ["http://localhost:3000/logout"]
variable "logout_urls" {
  description = "Allowed logout URLs for the app client"
  type        = list(string)
  default     = []
}

############################################################
# RBAC (Role Based Access Control) Groups
############################################################

# Name of the Cognito group representing platform administrators.
# Platform admins have full control across all tenants.
variable "platform_admin_group_name" {
  type    = string
  default = "platform-admin"
}

# Name of the Cognito group representing tenant administrators.
# Tenant admins manage users and resources within a specific tenant.
variable "tenant_admin_group_name" {
  type    = string
  default = "tenant-admin"
}

# Name of the Cognito group representing normal tenant users.
# These users have limited access to application functionality.
variable "tenant_user_group_name" {
  type    = string
  default = "tenant-user"
}