output "ecs_log_group_name" {
  value = aws_cloudwatch_log_group.ecs_app.name
}

output "ecs_log_group_arn" {
  value = aws_cloudwatch_log_group.ecs_app.arn
}

output "apigw_log_group_arn" {
  value = try(aws_cloudwatch_log_group.apigw_access[0].arn, null)
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.main.dashboard_name
}

output "cloudtrail_name" {
  value = try(aws_cloudtrail.platform_audit[0].name, null)
}

output "vpc_flow_log_id" {
  value = try(aws_flow_log.vpc[0].id, null)
}

output "vpc_flow_logs_log_group_name" {
  value = try(aws_cloudwatch_log_group.vpc_flow_logs[0].name, null)
}