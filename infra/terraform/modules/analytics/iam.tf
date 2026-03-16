data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "glue_crawler" {
  count = var.enable_glue_crawler ? 1 : 0

  name               = "${local.name_prefix}-glue-crawler-role"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "glue_crawler" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.analytics_bucket_name}",
      "arn:aws:s3:::${var.analytics_bucket_name}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:GetTable",
      "glue:GetTables",
      "glue:BatchCreatePartition",
      "glue:UpdatePartition",
      "glue:GetPartition",
      "glue:GetPartitions"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "glue_crawler" {
  count = var.enable_glue_crawler ? 1 : 0

  name   = "${local.name_prefix}-glue-crawler-policy"
  role   = aws_iam_role.glue_crawler[0].id
  policy = data.aws_iam_policy_document.glue_crawler.json
}