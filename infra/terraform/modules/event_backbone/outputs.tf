output "event_bus_name" {
  value = aws_cloudwatch_event_bus.domain.name
}

output "event_bus_arn" {
  value = aws_cloudwatch_event_bus.domain.arn
}

output "tenant_onboarding_queue_url" {
  value = aws_sqs_queue.tenant_onboarding.url
}

output "anomaly_jobs_queue_url" {
  value = aws_sqs_queue.anomaly_jobs.url
}

output "report_jobs_queue_url" {
  value = aws_sqs_queue.report_jobs.url
}

output "notifications_topic_arn" {
  value = aws_sns_topic.notifications.arn
}

output "alerts_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "tenant_onboarding_state_machine_arn" {
  value = aws_sfn_state_machine.tenant_onboarding.arn
}

output "anomaly_detection_state_machine_arn" {
  value = aws_sfn_state_machine.anomaly_detection.arn
}

output "report_generation_state_machine_arn" {
  value = aws_sfn_state_machine.report_generation.arn
}

output "kinesis_stream_name" {
  value = var.enable_kinesis ? aws_kinesis_stream.high_volume_logs[0].name : null
}