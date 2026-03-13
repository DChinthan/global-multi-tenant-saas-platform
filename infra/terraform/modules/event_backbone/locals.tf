locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Layer       = "event-backbone"
    ManagedBy   = "terraform"
  })

  queue_names = {
    tenant_onboarding = "${local.name_prefix}-tenant-onboarding-queue"
    anomaly_jobs      = "${local.name_prefix}-anomaly-jobs-queue"
    report_jobs       = "${local.name_prefix}-report-jobs-queue"
  }

  dlq_names = {
    tenant_onboarding = "${local.name_prefix}-tenant-onboarding-dlq"
    anomaly_jobs      = "${local.name_prefix}-anomaly-jobs-dlq"
    report_jobs       = "${local.name_prefix}-report-jobs-dlq"
  }

  topic_names = {
    notifications = "${local.name_prefix}-notifications"
    alerts        = "${local.name_prefix}-alerts"
  }

  sfn_names = {
    tenant_onboarding = "${local.name_prefix}-tenant-onboarding"
    anomaly_detection = "${local.name_prefix}-anomaly-detection"
    report_generation = "${local.name_prefix}-report-generation"
  }
}