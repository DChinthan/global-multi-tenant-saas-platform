resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-ops"

  dashboard_body = jsonencode({
    widgets = [
      {
        "type"   = "metric",
        "x"      = 0,
        "y"      = 0,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "title"   = "ALB Requests / 5XX",
          "view"    = "timeSeries",
          "stacked" = false,
          "region"  = var.region,
          "metrics" = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            [".", "HTTPCode_ELB_5XX_Count", ".", "."]
          ],
          "period" = 60,
          "stat"   = "Sum"
        }
      },
      {
        "type"   = "metric",
        "x"      = 12,
        "y"      = 0,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "title"  = "ECS CPU / Memory",
          "view"   = "timeSeries",
          "region" = var.region,
          "metrics" = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ],
          "period" = 60,
          "stat"   = "Average"
        }
      },
      {
        "type"   = "metric",
        "x"      = 0,
        "y"      = 6,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "title"  = "RDS CPU",
          "view"   = "timeSeries",
          "region" = var.region,
          "metrics" = var.rds_instance_id != null ? [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id]
          ] : [],
          "period" = 300,
          "stat"   = "Average"
        }
      },
      {
        "type"   = "alarm",
        "x"      = 12,
        "y"      = 6,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "title" = "Critical Alarms",
          "alarms" = compact([
            aws_cloudwatch_metric_alarm.alb_5xx.arn,
            aws_cloudwatch_metric_alarm.ecs_cpu_high.arn,
            aws_cloudwatch_metric_alarm.ecs_memory_high.arn,
            try(aws_cloudwatch_metric_alarm.rds_cpu_high[0].arn, null),
            try(aws_cloudwatch_metric_alarm.lambda_errors[0].arn, null)
          ])
        }
      }
    ]
  })
}