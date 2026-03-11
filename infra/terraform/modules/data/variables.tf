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

variable "vpc_id" {
  description = "VPC ID for the data layer"
  type        = string
}

variable "private_data_subnet_ids" {
  description = "Private subnets for Aurora"
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Security group ID of the application/ECS service allowed to access Aurora"
  type        = string
}

variable "enable_aurora" {
  description = "Whether to deploy Aurora PostgreSQL"
  type        = bool
  default     = false
}

variable "aurora_engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "aurora_database_name" {
  description = "Initial Aurora database name"
  type        = string
  default     = "appdb"
}

variable "aurora_master_username" {
  description = "Aurora master username"
  type        = string
  default     = "dbadmin"
}

variable "aurora_instance_count" {
  description = "Number of Aurora instances"
  type        = number
  default     = 1
}

variable "aurora_min_capacity" {
  description = "Aurora Serverless v2 min ACU"
  type        = number
  default     = 0.5
}

variable "aurora_max_capacity" {
  description = "Aurora Serverless v2 max ACU"
  type        = number
  default     = 2
}

variable "backup_retention_period" {
  description = "Aurora backup retention period"
  type        = number
  default     = 7
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for critical resources"
  type        = bool
  default     = false
}

variable "enable_s3_access_points" {
  description = "Whether to create S3 access points for data buckets"
  type        = bool
  default     = false
}