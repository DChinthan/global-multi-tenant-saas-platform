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

resource "aws_iam_role" "lambda_exec" {
  count              = var.enable_lambda ? 1 : 0
  name               = "${local.compute_name_prefix}-lambda-exec-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count      = var.enable_lambda ? 1 : 0
  role       = aws_iam_role.lambda_exec[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "webhook_handler" {
  count             = var.enable_lambda ? 1 : 0
  name              = "/aws/lambda/${local.compute_name_prefix}-webhook-handler"
  retention_in_days = 14
  tags              = local.common_tags
}

resource "aws_lambda_function" "webhook_handler" {
  count = var.enable_lambda ? 1 : 0

  function_name = "${local.compute_name_prefix}-webhook-handler"
  role          = aws_iam_role.lambda_exec[0].arn

  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  handler     = "index.handler"
  runtime     = "nodejs20.x"
  timeout     = 10
  memory_size = 128

  environment {
    variables = {
      ENVIRONMENT = var.environment
      PROJECT     = var.project
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.webhook_handler
  ]

  ############################################
  # Enable X-Ray Tracing
  ############################################
  tracing_config {
    mode = "Active"
  }


  tags = local.common_tags
}