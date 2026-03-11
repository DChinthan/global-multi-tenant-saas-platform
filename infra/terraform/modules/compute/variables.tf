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

variable "container_port" {
  description = "Application container port"
  type        = number
  default     = 8080
}

variable "desired_count" {
  description = "Desired ECS service count"
  type        = number
  default     = 2
}

variable "cpu" {
  description = "CPU units for ECS task"
  type        = number
  default     = 512
}

variable "memory" {
  description = "Memory for ECS task in MiB"
  type        = number
  default     = 1024
}

variable "app_image_tag" {
  description = "Container image tag to deploy"
  type        = string
  default     = "latest"
}

variable "health_check_path" {
  description = "Health check path for ALB target group"
  type        = string
  default     = "/health"
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

