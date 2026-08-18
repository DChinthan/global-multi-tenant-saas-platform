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
  description = "VPC ID where compute resources will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "private_app_subnet_ids" {
  description = "Private subnet IDs for ECS tasks and Lambda ENIs if needed"
  type        = list(string)
}

variable "services" {
  description = <<-EOT
    ECS services to run behind the shared cluster/ALB, keyed by service name.

    The map key is used verbatim in resource names (ECR repo, ECS task family,
    container name, ECS service name, ALB target group name, CloudWatch log
    stream prefix, autoscaling target) — renaming a key forces replacement of
    that service's resources, so treat keys as stable identifiers.

    Exactly one entry must set is_default = true; that service becomes the
    HTTPS listener's default forwarding target (no path condition needed).
    Every other entry gets its own ALB listener rule matched on path_patterns.
  EOT

  type = map(object({
    container_port     = number
    cpu                = number
    memory             = number
    desired_count      = number
    image_tag          = string
    health_check_path  = string
    is_default         = optional(bool, false)
    path_patterns      = optional(list(string), [])
    listener_priority  = optional(number)
    min_capacity       = optional(number, 2)
    max_capacity       = optional(number, 6)
    autoscaling_target = optional(number, 60)

    # Only needed to keep a pre-existing autoscaling policy name stable across
    # a migration (see envs/*/main.tf "app" entry). New services should leave
    # this unset.
    autoscaling_policy_name = optional(string)
  }))

  validation {
    condition     = length([for k, v in var.services : k if v.is_default]) == 1
    error_message = "Exactly one entry in var.services must have is_default = true."
  }

  validation {
    condition     = alltrue([for k, v in var.services : v.is_default || length(v.path_patterns) > 0])
    error_message = "Every non-default service must set at least one path_patterns entry so the ALB can route to it."
  }
}

variable "enable_lambda" {
  description = "Enable Lambda resources"
  type        = bool
  default     = true
}

variable "enable_api_gateway" {
  description = "Enable API Gateway for Lambda public endpoints"
  type        = bool
  default     = true
}

variable "lambda_zip_path" {
  description = "Path to the Lambda deployment package zip file"
  type        = string
  default     = "artifacts/webhook-handler.zip"
}

variable "ecs_log_group_name" {
  description = "CloudWatch log group for ECS container logs"
  type        = string
}

variable "apigw_log_group_arn" {
  description = "CloudWatch log group ARN for API Gateway access logs"
  type        = string
  default     = null
}
variable "alb_acm_certificate_arn" {
  description = "ACM certificate ARN for the ALB HTTPS listener (must be in the same region as the ALB)"
  type        = string
}

variable "enable_nlb" {
  description = "Create an internal Network Load Balancer fronting the default ECS service alongside the existing ALB (see nlb.tf for why NLB vs ALB). Required for enable_privatelink_endpoint_service."
  type        = bool
  default     = true
}

variable "enable_privatelink_endpoint_service" {
  description = "Publish the NLB as an AWS PrivateLink VPC Endpoint Service so other VPCs/accounts can reach the default service privately (see privatelink.tf). Requires enable_nlb = true. The endpoint service itself has no hourly cost - billing only starts on the consumer side once someone attaches an Interface Endpoint to it."
  type        = bool
  default     = false
}

variable "privatelink_allowed_principal_arns" {
  description = "IAM principal ARNs (e.g. arn:aws:iam::123456789012:root for an entire account, or a specific role/user ARN) allowed to request a connection to the PrivateLink endpoint service. Each request still requires manual acceptance since acceptance_required = true."
  type        = list(string)
  default     = []
}
