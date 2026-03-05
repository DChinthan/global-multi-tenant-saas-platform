data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# AWS Config needs a service role (only if enabled)
data "aws_iam_policy_document" "config_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "config_role" {
  count              = var.enable_config ? 1 : 0
  name               = "${local.name_prefix}-aws-config-role"
  assume_role_policy = data.aws_iam_policy_document.config_assume.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "config_managed" {
  count      = var.enable_config ? 1 : 0
  role       = aws_iam_role.config_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}