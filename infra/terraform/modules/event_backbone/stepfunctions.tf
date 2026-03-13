resource "aws_sfn_state_machine" "tenant_onboarding" {
  name     = local.sfn_names.tenant_onboarding
  role_arn = aws_iam_role.step_functions.arn
  type     = "STANDARD"

  definition = jsonencode({
    Comment = "Tenant onboarding workflow"
    StartAt = "SendWelcomeEvent"
    States = {
      SendWelcomeEvent = {
        Type     = "Task"
        Resource = "arn:aws:states:::events:putEvents"
        Arguments = {
          Entries = [
            {
              Source       = "saas.platform"
              DetailType   = "tenant.created"
              EventBusName = aws_cloudwatch_event_bus.domain.name
              Detail = {
                stage = "tenant-created"
              }
            }
          ]
        }
        Next = "QueueProvisioningTask"
      }

      QueueProvisioningTask = {
        Type     = "Task"
        Resource = "arn:aws:states:::sqs:sendMessage"
        Arguments = {
          QueueUrl = aws_sqs_queue.tenant_onboarding.url
          MessageBody = {
            action = "provision-tenant-resources"
          }
        }
        End = true
      }
    }
  })

  tags = local.common_tags
}

resource "aws_sfn_state_machine" "anomaly_detection" {
  name     = local.sfn_names.anomaly_detection
  role_arn = aws_iam_role.step_functions.arn
  type     = "STANDARD"

  definition = jsonencode({
    Comment = "Anomaly detection pipeline"
    StartAt = "QueueDetectionJob"
    States = {
      QueueDetectionJob = {
        Type     = "Task"
        Resource = "arn:aws:states:::sqs:sendMessage"
        Arguments = {
          QueueUrl = aws_sqs_queue.anomaly_jobs.url
          MessageBody = {
            action = "run-anomaly-detection"
          }
        }
        Next = "PublishAlert"
      }

      PublishAlert = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Arguments = {
          TopicArn = aws_sns_topic.alerts.arn
          Message = {
            category = "iam-anomaly"
            severity = "high"
          }
        }
        End = true
      }
    }
  })

  tags = local.common_tags
}

resource "aws_sfn_state_machine" "report_generation" {
  name     = local.sfn_names.report_generation
  role_arn = aws_iam_role.step_functions.arn
  type     = "STANDARD"

  definition = jsonencode({
    Comment = "Report generation workflow"
    StartAt = "QueueReportJob"
    States = {
      QueueReportJob = {
        Type     = "Task"
        Resource = "arn:aws:states:::sqs:sendMessage"
        Arguments = {
          QueueUrl = aws_sqs_queue.report_jobs.url
          MessageBody = {
            action = "generate-report"
          }
        }
        Next = "NotifyRequested"
      }

      NotifyRequested = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Arguments = {
          TopicArn = aws_sns_topic.notifications.arn
          Message = {
            category = "report"
            status   = "requested"
          }
        }
        End = true
      }
    }
  })

  tags = local.common_tags
}