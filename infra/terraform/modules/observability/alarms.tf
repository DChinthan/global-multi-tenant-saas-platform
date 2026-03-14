resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${local.name_prefix}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "ALB is returning too many 5XX responses"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = var.sns_alert_topic_arn != null ? [var.sns_alert_topic_arn] : []
  ok_actions    = var.sns_alert_topic_arn != null ? [var.sns_alert_topic_arn] : []

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${local.name_prefix}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS service CPU too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = var.sns_alert_topic_arn != null ? [var.sns_alert_topic_arn] : []
  ok_actions    = var.sns_alert_topic_arn != null ? [var.sns_alert_topic_arn] : []

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "${local.name_prefix}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS service memory too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = var.sns_alert_topic_arn != null ? [var.sns_alert_topic_arn] : []
  ok_actions    = var.sns_alert_topic_arn != null ? [var.sns_alert_topic_arn] : []

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  count               = var.rds_instance_id != null ? 1 : 0
  alarm_name          = "${local.name_prefix}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = var.sns_alert_topic_arn != null ? [var.sns_alert_topic_arn] : []
  ok_actions    = var.sns_alert_topic_arn != null ? [var.sns_alert_topic_arn] : []

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count               = var.lambda_function_name != null ? 1 : 0
  alarm_name          = "${local.name_prefix}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Lambda has errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions = var.sns_alert_topic_arn != null ? [var.sns_alert_topic_arn] : []
  ok_actions    = var.sns_alert_topic_arn != null ? [var.sns_alert_topic_arn] : []

  tags = local.common_tags
}