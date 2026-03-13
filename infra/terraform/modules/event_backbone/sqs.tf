resource "aws_sqs_queue" "tenant_onboarding_dlq" {
  name                      = local.dlq_names.tenant_onboarding
  message_retention_seconds = 1209600
  kms_master_key_id         = var.kms_key_arn

  tags = merge(local.common_tags, {
    Name = local.dlq_names.tenant_onboarding
    Type = "dlq"
  })
}

resource "aws_sqs_queue" "anomaly_jobs_dlq" {
  name                      = local.dlq_names.anomaly_jobs
  message_retention_seconds = 1209600
  kms_master_key_id         = var.kms_key_arn

  tags = merge(local.common_tags, {
    Name = local.dlq_names.anomaly_jobs
    Type = "dlq"
  })
}

resource "aws_sqs_queue" "report_jobs_dlq" {
  name                      = local.dlq_names.report_jobs
  message_retention_seconds = 1209600
  kms_master_key_id         = var.kms_key_arn

  tags = merge(local.common_tags, {
    Name = local.dlq_names.report_jobs
    Type = "dlq"
  })
}

resource "aws_sqs_queue" "tenant_onboarding" {
  name                       = local.queue_names.tenant_onboarding
  visibility_timeout_seconds = 120
  receive_wait_time_seconds  = 20
  message_retention_seconds  = 345600
  kms_master_key_id          = var.kms_key_arn

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.tenant_onboarding_dlq.arn
    maxReceiveCount     = 5
  })

  tags = merge(local.common_tags, {
    Name = local.queue_names.tenant_onboarding
    Type = "worker"
  })
}

resource "aws_sqs_queue" "anomaly_jobs" {
  name                       = local.queue_names.anomaly_jobs
  visibility_timeout_seconds = 300
  receive_wait_time_seconds  = 20
  message_retention_seconds  = 345600
  kms_master_key_id          = var.kms_key_arn

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.anomaly_jobs_dlq.arn
    maxReceiveCount     = 5
  })

  tags = merge(local.common_tags, {
    Name = local.queue_names.anomaly_jobs
    Type = "worker"
  })
}

resource "aws_sqs_queue" "report_jobs" {
  name                       = local.queue_names.report_jobs
  visibility_timeout_seconds = 300
  receive_wait_time_seconds  = 20
  message_retention_seconds  = 345600
  kms_master_key_id          = var.kms_key_arn

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.report_jobs_dlq.arn
    maxReceiveCount     = 5
  })

  tags = merge(local.common_tags, {
    Name = local.queue_names.report_jobs
    Type = "worker"
  })
}