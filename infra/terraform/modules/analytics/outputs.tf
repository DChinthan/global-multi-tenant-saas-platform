output "glue_database_name" {
  value = var.enable_glue_crawler ? aws_glue_catalog_database.analytics[0].name : null
}

output "glue_crawler_name" {
  value = var.enable_glue_crawler ? aws_glue_crawler.analytics[0].name : null
}

output "athena_workgroup_name" {
  value = var.enable_athena ? aws_athena_workgroup.analytics[0].name : null
}

output "scheduled_reporting_lambda_name" {
  value = var.enable_scheduled_reports ? aws_lambda_function.reporting[0].function_name : null
}

output "scheduled_report_schedule_name" {
  value = var.enable_scheduled_reports ? aws_scheduler_schedule.daily_report[0].name : null
}