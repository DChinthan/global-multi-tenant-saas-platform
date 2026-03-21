resource "aws_cloudwatch_event_bus" "domain" {
  name = "${local.name_prefix}-domain-bus"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-domain-bus"
    Type = "domain-events"
  })
}

resource "aws_cloudwatch_event_rule" "tenant_onboarding_requested" {
  name           = "${local.short_prefix}-tenant-onboard-req"
  event_bus_name = aws_cloudwatch_event_bus.domain.name

  event_pattern = jsonencode({
    source      = ["saas.platform"]
    detail-type = ["tenant.onboarding.requested"]
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_rule" "anomaly_detected" {
  name           = "${local.name_prefix}-anomaly-detected"
  event_bus_name = aws_cloudwatch_event_bus.domain.name

  event_pattern = jsonencode({
    source      = ["saas.platform"]
    detail-type = ["iam.anomaly.detected"]
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_rule" "report_requested" {
  name           = "${local.name_prefix}-report-requested"
  event_bus_name = aws_cloudwatch_event_bus.domain.name

  event_pattern = jsonencode({
    source      = ["saas.platform"]
    detail-type = ["report.generation.requested"]
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "tenant_onboarding_queue" {
  rule           = aws_cloudwatch_event_rule.tenant_onboarding_requested.name
  event_bus_name = aws_cloudwatch_event_bus.domain.name
  arn            = aws_sqs_queue.tenant_onboarding.arn
  role_arn       = aws_iam_role.eventbridge_invoke_targets.arn
}

resource "aws_cloudwatch_event_target" "anomaly_state_machine" {
  rule           = aws_cloudwatch_event_rule.anomaly_detected.name
  event_bus_name = aws_cloudwatch_event_bus.domain.name
  arn            = aws_sfn_state_machine.anomaly_detection.arn
  role_arn       = aws_iam_role.eventbridge_invoke_targets.arn
}

resource "aws_cloudwatch_event_target" "report_state_machine" {
  rule           = aws_cloudwatch_event_rule.report_requested.name
  event_bus_name = aws_cloudwatch_event_bus.domain.name
  arn            = aws_sfn_state_machine.report_generation.arn
  role_arn       = aws_iam_role.eventbridge_invoke_targets.arn
}