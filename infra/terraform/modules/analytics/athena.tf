resource "aws_athena_workgroup" "analytics" {
  count = var.enable_athena ? 1 : 0

  name = "${local.name_prefix}-analytics-wg"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.athena_results_bucket_name}/athena-results/"
    }
  }

  tags = local.common_tags
}

resource "aws_athena_named_query" "tenant_request_summary" {
  count = var.enable_athena ? 1 : 0

  name      = "${local.name_prefix}-tenant-request-summary"
  database  = local.glue_database_name
  workgroup = aws_athena_workgroup.analytics[0].name

  query = <<-SQL
    SELECT
      tenant_id,
      date_trunc('day', from_iso8601_timestamp(request_timestamp)) AS request_day,
      count(*) AS total_requests
    FROM api_events
    GROUP BY 1, 2
    ORDER BY 2 DESC, 3 DESC;
  SQL
}

resource "aws_athena_named_query" "error_rate_by_tenant" {
  count = var.enable_athena ? 1 : 0

  name      = "${local.name_prefix}-error-rate-by-tenant"
  database  = local.glue_database_name
  workgroup = aws_athena_workgroup.analytics[0].name

  query = <<-SQL
    SELECT
      tenant_id,
      count_if(status_code >= 500) AS server_errors,
      count(*) AS total_requests,
      CAST(count_if(status_code >= 500) AS double) / NULLIF(count(*), 0) AS error_rate
    FROM api_events
    GROUP BY 1
    ORDER BY error_rate DESC;
  SQL
}

resource "aws_athena_named_query" "active_users_daily" {
  count = var.enable_athena ? 1 : 0

  name      = "${local.name_prefix}-active-users-daily"
  database  = local.glue_database_name
  workgroup = aws_athena_workgroup.analytics[0].name

  query = <<-SQL
    SELECT
      date_trunc('day', from_iso8601_timestamp(event_timestamp)) AS event_day,
      approx_distinct(user_id) AS active_users
    FROM user_activity_events
    GROUP BY 1
    ORDER BY 1 DESC;
  SQL
}