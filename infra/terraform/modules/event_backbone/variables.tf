variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting messaging resources"
  type        = string
}

variable "enable_kinesis" {
  description = "Whether to enable Kinesis stream for high-volume logs"
  type        = bool
  default     = false
}

variable "tenant_onboarding_definition" {
  description = "Base ASL definition for tenant onboarding"
  type        = string
}

variable "anomaly_detection_definition" {
  description = "Base ASL definition for anomaly detection"
  type        = string
}

variable "report_generation_definition" {
  description = "Base ASL definition for report generation"
  type        = string
}