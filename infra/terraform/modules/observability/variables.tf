variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "region" {
  type = string
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "enable_xray" {
  type    = bool
  default = true
}

variable "enable_cloudtrail" {
  type    = bool
  default = true
}

variable "enable_athena" {
  type    = bool
  default = true
}

variable "audit_logs_bucket_name" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "alb_name" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "rds_instance_id" {
  type    = string
  default = null
}

variable "lambda_function_name" {
  type    = string
  default = null
}

variable "api_gateway_stage_name" {
  type    = string
  default = null
}

variable "api_gateway_id" {
  type    = string
  default = null
}

variable "sns_alert_topic_arn" {
  type    = string
  default = null
}

variable "vpc_id" {
  type    = string
  default = null
}