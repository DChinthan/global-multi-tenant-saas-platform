resource "aws_apigatewayv2_api" "webhook" {
  count = var.enable_api_gateway ? 1 : 0

  name          = "${local.compute_name_prefix}-webhook-api"
  protocol_type = "HTTP"

  tags = local.common_tags
}

resource "aws_apigatewayv2_integration" "webhook_handler" {
  count = var.enable_api_gateway ? 1 : 0

  api_id                 = aws_apigatewayv2_api.webhook[0].id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.webhook_handler[0].invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "webhook_handler" {
  count = var.enable_api_gateway ? 1 : 0

  api_id    = aws_apigatewayv2_api.webhook[0].id
  route_key = "POST /webhooks/events"
  target    = "integrations/${aws_apigatewayv2_integration.webhook_handler[0].id}"
}

resource "aws_apigatewayv2_stage" "webhook" {
  count = var.enable_api_gateway ? 1 : 0

  api_id      = aws_apigatewayv2_api.webhook[0].id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 10
    throttling_rate_limit  = 5
  }

  tags = local.common_tags
}

resource "aws_lambda_permission" "allow_apigw_invoke_webhook" {
  count = var.enable_api_gateway ? 1 : 0

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webhook_handler[0].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.webhook[0].execution_arn}/*/*"
}