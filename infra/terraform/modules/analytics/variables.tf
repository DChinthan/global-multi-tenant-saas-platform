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

variable "region" {
  description = "AWS region"
  type        = string
}

variable "analytics_bucket_name" {
  description = "S3 bucket holding analytics source data"
  type        = string
}

variable "athena_results_bucket_name" {
  description = "S3 bucket for Athena query results"
  type        = string
}

variable "glue_database_name" {
  description = "Glue catalog database name"
  type        = string
  default     = null
}

variable "crawler_s3_target_path" {
  description = "S3 prefix to crawl"
  type        = string
}

variable "crawler_schedule" {
  description = "Optional Glue crawler cron schedule"
  type        = string
  default     = null
}

variable "enable_glue_crawler" {
  description = "Enable Glue crawler"
  type        = bool
  default     = true
}

variable "enable_athena" {
  description = "Enable Athena resources"
  type        = bool
  default     = true
}

variable "enable_scheduled_reports" {
  description = "Enable scheduled report lambda and scheduler"
  type        = bool
  default     = true
}

variable "report_schedule_expression" {
  description = "EventBridge Scheduler cron/rate expression"
  type        = string
  default     = "cron(0 8 * * ? *)"
}

variable "report_timezone" {
  description = "Timezone for scheduler"
  type        = string
  default     = "America/Toronto"
}

variable "report_output_prefix" {
  description = "S3 prefix where scheduled reports are stored"
  type        = string
  default     = "scheduled-reports/"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

variable "lambda_handler" {
  description = "Lambda handler"
  type        = string
  default     = "scheduled_report_lambda.lambda_handler"
}

variable "lambda_timeout" {
  description = "Lambda timeout seconds"
  type        = number
  default     = 60
}

variable "lambda_memory_size" {
  description = "Lambda memory size"
  type        = number
  default     = 256
}