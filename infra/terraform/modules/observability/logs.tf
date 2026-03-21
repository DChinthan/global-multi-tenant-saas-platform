resource "aws_cloudwatch_log_group" "ecs_app" {
  name              = local.log_group_names.ecs_app
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda_webhook" {
  count             = var.lambda_function_name != null ? 1 : 0
  name              = local.log_group_names.lambda_webhook
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "apigw_access" {
  count             = var.enable_apigw_access_logs ? 1 : 0
  name              = local.log_group_names.apigw_access
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "stepfunctions" {
  name              = local.log_group_names.sfn_onboarding
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count             = var.enable_vpc_flow_logs ? 1 : 0
  name              = local.log_group_names.vpc_flow_logs
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = local.common_tags
}