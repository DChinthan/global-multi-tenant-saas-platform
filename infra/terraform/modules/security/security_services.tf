resource "aws_guardduty_detector" "main" {
  count  = var.enable_security_services ? 1 : 0
  enable = true
  tags   = local.common_tags
}

resource "aws_securityhub_account" "main" {
  count = var.enable_security_services ? 1 : 0
}

# Inspector v2: enable for EC2 (you can add ECR/Lambda later)
resource "aws_inspector2_enabler" "main" {
  count = var.enable_security_services ? 1 : 0

  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["EC2"]
}