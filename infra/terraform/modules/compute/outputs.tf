output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "lambda_webhook_handler_name" {
  value = var.enable_lambda ? aws_lambda_function.webhook_handler[0].function_name : null
}

output "lambda_webhook_handler_arn" {
  value = var.enable_lambda ? aws_lambda_function.webhook_handler[0].arn : null
}

output "webhook_api_id" {
  value = var.enable_api_gateway ? aws_apigatewayv2_api.webhook[0].id : null
}

output "webhook_api_endpoint" {
  value = var.enable_api_gateway ? aws_apigatewayv2_api.webhook[0].api_endpoint : null
}

output "webhook_events_url" {
  value = var.enable_api_gateway ? "${aws_apigatewayv2_api.webhook[0].api_endpoint}/webhooks/events" : null
}

output "app_security_group_id" {
  value = aws_security_group.ecs_service.id
}

output "alb_name" {
  value = aws_lb.app.name
}

output "alb_arn_suffix" {
  value = aws_lb.app.arn_suffix
}

output "alb_zone_id" {
  value = aws_lb.app.zone_id
}

output "efs_file_system_arn" {
  value = aws_efs_file_system.main.arn
}