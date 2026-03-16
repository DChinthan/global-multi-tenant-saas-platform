data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "reporting_lambda" {
  count = var.enable_scheduled_reports ? 1 : 0

  name               = "${local.name_prefix}-reporting-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "reporting_lambda" {
  statement {
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartitions"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.athena_results_bucket_name}",
      "arn:aws:s3:::${var.athena_results_bucket_name}/*",
      "arn:aws:s3:::${var.analytics_bucket_name}",
      "arn:aws:s3:::${var.analytics_bucket_name}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "reporting_lambda" {
  count = var.enable_scheduled_reports ? 1 : 0

  name   = "${local.name_prefix}-reporting-lambda-policy"
  role   = aws_iam_role.reporting_lambda[0].id
  policy = data.aws_iam_policy_document.reporting_lambda.json
}

data "archive_file" "reporting_lambda" {
  count = var.enable_scheduled_reports ? 1 : 0

  type        = "zip"
  source_file = "${path.root}/../../../../services/reporting/scheduled_report_lambda.py"
  output_path = "${path.root}/reporting_lambda.zip"
}

resource "aws_lambda_function" "reporting" {
  count = var.enable_scheduled_reports ? 1 : 0

  function_name = "${local.name_prefix}-scheduled-reporting"
  role          = aws_iam_role.reporting_lambda[0].arn
  runtime       = var.lambda_runtime
  handler       = var.lambda_handler
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  filename         = data.archive_file.reporting_lambda[0].output_path
  source_code_hash = data.archive_file.reporting_lambda[0].output_base64sha256

  environment {
    variables = {
      ATHENA_DATABASE       = local.glue_database_name
      ATHENA_WORKGROUP      = aws_athena_workgroup.analytics[0].name
      ATHENA_OUTPUT_S3      = "s3://${var.athena_results_bucket_name}/athena-results/"
      REPORT_BUCKET         = var.analytics_bucket_name
      REPORT_PREFIX         = var.report_output_prefix
      TENANT_SUMMARY_QUERY  = "SELECT tenant_id, count(*) AS total_requests FROM api_events GROUP BY tenant_id ORDER BY total_requests DESC"
    }
  }

  tags = local.common_tags
}