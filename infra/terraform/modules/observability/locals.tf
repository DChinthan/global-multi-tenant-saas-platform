locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "observability"
  })

  log_group_names = {
    ecs_app        = "/aws/ecs/${local.name_prefix}/app"
    lambda_webhook = "/aws/lambda/${local.name_prefix}-webhook"
    apigw_access   = "/aws/apigateway/${local.name_prefix}/access"
    sfn_onboarding = "/aws/vendedlogs/states/${local.name_prefix}-tenant-onboarding"
    vpc_flow_logs  = "/aws/vpc/${local.name_prefix}/flowlogs"
  }
}