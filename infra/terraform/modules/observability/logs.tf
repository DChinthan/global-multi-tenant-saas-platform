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

############################################
# VPC Flow Logs (the log group above previously had nothing publishing to
# it - enable_vpc_flow_logs created an empty CloudWatch Logs group and
# stopped there. This is the actual aws_flow_log resource plus the IAM role
# flow-logs needs to assume in order to write into it.)
############################################

data "aws_iam_policy_document" "flow_logs_assume" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "flow_logs" {
  count              = var.enable_vpc_flow_logs ? 1 : 0
  name               = "${local.name_prefix}-vpc-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume[0].json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "flow_logs_publish" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = ["${aws_cloudwatch_log_group.vpc_flow_logs[0].arn}:*"]
  }
}

resource "aws_iam_role_policy" "flow_logs_publish" {
  count  = var.enable_vpc_flow_logs ? 1 : 0
  name   = "${local.name_prefix}-vpc-flow-logs-publish"
  role   = aws_iam_role.flow_logs[0].id
  policy = data.aws_iam_policy_document.flow_logs_publish[0].json
}

resource "aws_flow_log" "vpc" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  vpc_id = var.vpc_id

  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  iam_role_arn             = aws_iam_role.flow_logs[0].arn
  max_aggregation_interval = 60

  # Deliberately left as the AWS default (version 2) field layout rather
  # than a custom log_format - CloudWatch Logs Insights auto-recognizes the
  # default VPC Flow Log record shape, which is what insights_queries.tf's
  # saved queries rely on.

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc-flow-logs"
  })
}