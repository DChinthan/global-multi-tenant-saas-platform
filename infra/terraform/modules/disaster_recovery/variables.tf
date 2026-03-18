variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "Primary AWS region"
  type        = string
}

variable "secondary_region" {
  description = "Secondary AWS region for DR"
  type        = string
}

variable "enable_disaster_recovery" {
  description = "Enable disaster recovery resources"
  type        = bool
  default     = false
}

variable "enable_s3_replication" {
  description = "Enable S3 cross-region replication"
  type        = bool
  default     = false
}

variable "enable_route53_failover" {
  description = "Enable Route53 failover records"
  type        = bool
  default     = false
}

variable "enable_backup_plan" {
  description = "Enable AWS Backup plan"
  type        = bool
  default     = false
}

variable "enable_kms_multi_region" {
  description = "Enable KMS multi-region key"
  type        = bool
  default     = false
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
  default     = null
}

variable "domain_name" {
  description = "Application domain name"
  type        = string
  default     = null
}

variable "primary_alb_dns_name" {
  description = "Primary region ALB DNS name"
  type        = string
  default     = null
}

variable "primary_alb_zone_id" {
  description = "Primary region ALB hosted zone ID"
  type        = string
  default     = null
}

variable "secondary_alb_dns_name" {
  description = "Secondary region ALB DNS name"
  type        = string
  default     = null
}

variable "secondary_alb_zone_id" {
  description = "Secondary region ALB hosted zone ID"
  type        = string
  default     = null
}

variable "replication_bucket_mappings" {
  description = "Map of source bucket name => destination bucket ARN for replication"
  type = map(object({
    source_bucket_name      = string
    source_bucket_arn       = string
    destination_bucket_arn  = string
  }))
  default = {}
}

variable "backup_resource_arns" {
  description = "List of resource ARNs to include in AWS Backup"
  type        = list(string)
  default     = []
}