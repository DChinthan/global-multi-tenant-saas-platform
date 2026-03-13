resource "aws_sns_topic" "notifications" {
  name              = local.topic_names.notifications
  kms_master_key_id = var.kms_key_arn

  tags = merge(local.common_tags, {
    Name = local.topic_names.notifications
    Type = "fanout"
  })
}

resource "aws_sns_topic" "alerts" {
  name              = local.topic_names.alerts
  kms_master_key_id = var.kms_key_arn

  tags = merge(local.common_tags, {
    Name = local.topic_names.alerts
    Type = "fanout"
  })
}

resource "aws_sns_topic_subscription" "alerts_to_report_queue" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.report_jobs.arn
}

resource "aws_sqs_queue_policy" "report_jobs_allow_sns" {
  queue_url = aws_sqs_queue.report_jobs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSNSSendMessage"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.report_jobs.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.alerts.arn
          }
        }
      }
    ]
  })
}