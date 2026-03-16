data "aws_iam_policy_document" "scheduler_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "scheduler_invoke_lambda" {
  count = var.enable_scheduled_reports ? 1 : 0

  name               = "${local.name_prefix}-scheduler-invoke-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume_role.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "scheduler_invoke_lambda" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      aws_lambda_function.reporting[0].arn
    ]
  }
}

resource "aws_iam_role_policy" "scheduler_invoke_lambda" {
  count = var.enable_scheduled_reports ? 1 : 0

  name   = "${local.name_prefix}-scheduler-invoke-lambda-policy"
  role   = aws_iam_role.scheduler_invoke_lambda[0].id
  policy = data.aws_iam_policy_document.scheduler_invoke_lambda.json
}

resource "aws_scheduler_schedule" "daily_report" {
  count = var.enable_scheduled_reports ? 1 : 0

  name                         = "${local.name_prefix}-daily-report"
  group_name                   = "default"
  schedule_expression          = var.report_schedule_expression
  schedule_expression_timezone = var.report_timezone
  state                        = "ENABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.reporting[0].arn
    role_arn = aws_iam_role.scheduler_invoke_lambda[0].arn

    input = jsonencode({
      report_type = "tenant-summary"
      environment = var.environment
    })
  }
}