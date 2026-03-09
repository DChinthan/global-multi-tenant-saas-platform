output "user_pool_id" {
  value = var.enable_identity ? aws_cognito_user_pool.this[0].id : null
}

output "user_pool_arn" {
  value = var.enable_identity ? aws_cognito_user_pool.this[0].arn : null
}

output "user_pool_client_id" {
  value = var.enable_identity ? aws_cognito_user_pool_client.app[0].id : null
}

output "user_pool_domain" {
  value = var.enable_identity ? aws_cognito_user_pool_domain.this[0].domain : null
}

output "tenant_table_name" {
  value = var.enable_identity ? aws_dynamodb_table.tenants[0].name : null
}

output "tenant_table_arn" {
  value = var.enable_identity ? aws_dynamodb_table.tenants[0].arn : null
}

output "pre_token_lambda_arn" {
  value = var.enable_identity ? aws_lambda_function.pre_token_generation[0].arn : null
}