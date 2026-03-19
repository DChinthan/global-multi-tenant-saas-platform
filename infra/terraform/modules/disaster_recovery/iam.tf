data "aws_iam_policy_document" "s3_replication_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "s3_replication" {
  count = local.dr_enabled && var.enable_s3_replication ? 1 : 0

  name               = "${local.name_prefix}-s3-replication-role"
  assume_role_policy = data.aws_iam_policy_document.s3_replication_assume_role.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "s3_replication" {
  count = local.dr_enabled && var.enable_s3_replication ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]

    resources = [
      for bucket in values(var.replication_bucket_mappings) : bucket.source_bucket_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectRetention",
      "s3:GetObjectLegalHold"
    ]

    resources = flatten([
      for bucket in values(var.replication_bucket_mappings) : [
        "${bucket.source_bucket_arn}/*"
      ]
    ])
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]

    resources = flatten([
      for bucket in values(var.replication_bucket_mappings) : [
        "${bucket.destination_bucket_arn}/*"
      ]
    ])
  }
}

resource "aws_iam_policy" "s3_replication" {
  count = local.dr_enabled && var.enable_s3_replication ? 1 : 0

  name   = "${local.name_prefix}-s3-replication-policy"
  policy = data.aws_iam_policy_document.s3_replication[0].json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "s3_replication" {
  count = local.dr_enabled && var.enable_s3_replication ? 1 : 0

  role       = aws_iam_role.s3_replication[0].name
  policy_arn = aws_iam_policy.s3_replication[0].arn
}

data "aws_iam_policy_document" "backup_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "backup" {
  count = local.dr_enabled && var.enable_backup_plan ? 1 : 0

  name               = "${local.name_prefix}-backup-role"
  assume_role_policy = data.aws_iam_policy_document.backup_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "backup_service" {
  count = local.dr_enabled && var.enable_backup_plan ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore" {
  count = local.dr_enabled && var.enable_backup_plan ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}