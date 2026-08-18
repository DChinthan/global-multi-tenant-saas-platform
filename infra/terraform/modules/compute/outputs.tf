output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Name of the default service's ECS service (see var.services is_default)"
  value       = aws_ecs_service.this[local.default_service_key].name
}

output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "target_group_arn" {
  description = "Target group ARN of the default service"
  value       = aws_lb_target_group.this[local.default_service_key].arn
}

output "ecr_repository_url" {
  description = "ECR repository URL of the default service"
  value       = aws_ecr_repository.this[local.default_service_key].repository_url
}

output "ecr_repository_urls" {
  description = "ECR repository URL for every service, keyed by service name"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "ecs_service_names" {
  description = "ECS service name for every service, keyed by service name"
  value       = { for k, v in aws_ecs_service.this : k => v.name }
}

output "target_group_arns" {
  description = "ALB target group ARN for every service, keyed by service name"
  value       = { for k, v in aws_lb_target_group.this : k => v.arn }
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

output "nlb_arn" {
  value = try(aws_lb.nlb[0].arn, null)
}

output "nlb_dns_name" {
  value = try(aws_lb.nlb[0].dns_name, null)
}

output "nlb_target_group_arn" {
  value = try(aws_lb_target_group.nlb_default[0].arn, null)
}

output "privatelink_endpoint_service_name" {
  description = "service_name a consumer passes to their own aws_vpc_endpoint resource to connect (e.g. com.amazonaws.vpce.us-east-1.vpce-svc-xxxxxxxx)"
  value       = try(aws_vpc_endpoint_service.app[0].service_name, null)
}

output "privatelink_endpoint_service_id" {
  value = try(aws_vpc_endpoint_service.app[0].id, null)
}

