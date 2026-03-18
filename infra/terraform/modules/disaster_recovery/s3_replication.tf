resource "aws_s3_bucket_versioning" "source" {
  for_each = local.dr_enabled && var.enable_s3_replication ? var.replication_bucket_mappings : {}

  bucket = each.value.source_bucket_name

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  for_each = local.dr_enabled && var.enable_s3_replication ? var.replication_bucket_mappings : {}

  depends_on = [
    aws_s3_bucket_versioning.source,
    aws_iam_role_policy_attachment.s3_replication
  ]

  role   = aws_iam_role.s3_replication[0].arn
  bucket = each.value.source_bucket_name

  rule {
    id     = "replicate-${each.key}"
    status = "Enabled"

    filter {
      prefix = ""
    }

    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = each.value.destination_bucket_arn
      storage_class = "STANDARD"
    }
  }
}