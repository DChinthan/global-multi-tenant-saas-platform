variable "env" {
  type    = string
  default = "dev"
}

variable "cidr_block" {
  type        = string
  description = "VPC CIDR block for this environment (e.g., 10.10.0.0/16)"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" { type = string }
variable "environment" { type = string }

# COST-SAFETY TOGGLES
variable "enable_nat" {
  type    = bool
  default = false
}
variable "enable_rds" {
  type    = bool
  default = false
}
variable "enable_opensearch" {
  type    = bool
  default = false
}
variable "enable_eks" {
  description = "Provision the real EKS cluster in modules/eks. Costs real money the moment this is true - see modules/eks/main.tf. Kept false; local kind is used for the runnable Helm/K8s demo instead."
  type        = bool
  default     = false
}
variable "enable_kinesis" {
  type    = bool
  default = false
}

# Example sizing knobs (keep tiny in dev)
variable "rds_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "opensearch_instance_type" {
  type    = string
  default = "t3.small.search"
}

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

variable "enable_identity" {
  type    = bool
  default = true
}

variable "cognito_domain_prefix" {
  type = string
}

variable "callback_urls" {
  type    = list(string)
  default = []
}

variable "logout_urls" {
  type    = list(string)
  default = []
}

variable "tags" {
  description = "Common tags for resources"
  type        = map(string)
  default     = {}
}

variable "secondary_region" {
  type        = string
  description = "Secondary DR region"
  default     = "us-west-2"
}

variable "enable_disaster_recovery" {
  type    = bool
  default = false
}

variable "enable_s3_replication" {
  type    = bool
  default = false
}

variable "enable_route53_failover" {
  type    = bool
  default = false
}

variable "enable_backup_plan" {
  type    = bool
  default = false
}

variable "enable_kms_multi_region" {
  type    = bool
  default = false
}

variable "hosted_zone_id" {
  type    = string
  default = null
}

variable "domain_name" {
  type    = string
  default = null
}

variable "secondary_alb_dns_name" {
  type    = string
  default = null
}

variable "secondary_alb_zone_id" {
  type    = string
  default = null
}

variable "replication_bucket_mappings" {
  type = map(object({
    source_bucket_name     = string
    source_bucket_arn      = string
    destination_bucket_arn = string
  }))
  default = {}
}

variable "dr_audit_logs_bucket_arn" {
  type    = string
  default = null
}

variable "dr_exports_bucket_arn" {
  type    = string
  default = null
}

variable "dr_tenant_reports_bucket_arn" {
  type    = string
  default = null
}
variable "alb_acm_certificate_arn" {
  description = "ACM certificate ARN for the ALB HTTPS listener (must be in the same region as the ALB)"
  type        = string
}
