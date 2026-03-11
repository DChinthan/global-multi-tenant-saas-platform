resource "aws_s3_bucket" "audit_logs" {
  bucket = local.bucket_names.audit_logs

  tags = merge(local.common_tags, {
    Name     = local.bucket_names.audit_logs
    DataType = "audit-logs"
  })
}

resource "aws_s3_bucket" "exports" {
  bucket = local.bucket_names.exports

  tags = merge(local.common_tags, {
    Name     = local.bucket_names.exports
    DataType = "exports"
  })
}

resource "aws_s3_bucket" "tenant_reports" {
  bucket = local.bucket_names.tenant_reports

  tags = merge(local.common_tags, {
    Name     = local.bucket_names.tenant_reports
    DataType = "tenant-reports"
  })
}

resource "aws_s3_bucket_versioning" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "exports" {
  bucket = aws_s3_bucket.exports.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "tenant_reports" {
  bucket = aws_s3_bucket.tenant_reports.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.data.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "exports" {
  bucket = aws_s3_bucket.exports.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.data.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tenant_reports" {
  bucket = aws_s3_bucket.tenant_reports.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.data.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "audit_logs" {
  bucket                  = aws_s3_bucket.audit_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "exports" {
  bucket                  = aws_s3_bucket.exports.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "tenant_reports" {
  bucket                  = aws_s3_bucket.tenant_reports.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "deny_insecure_transport_audit" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.audit_logs.arn,
      "${aws_s3_bucket.audit_logs.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "deny_insecure_transport_exports" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.exports.arn,
      "${aws_s3_bucket.exports.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "deny_insecure_transport_reports" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.tenant_reports.arn,
      "${aws_s3_bucket.tenant_reports.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  policy = data.aws_iam_policy_document.deny_insecure_transport_audit.json
}

resource "aws_s3_bucket_policy" "exports" {
  bucket = aws_s3_bucket.exports.id
  policy = data.aws_iam_policy_document.deny_insecure_transport_exports.json
}

resource "aws_s3_bucket_policy" "tenant_reports" {
  bucket = aws_s3_bucket.tenant_reports.id
  policy = data.aws_iam_policy_document.deny_insecure_transport_reports.json
}

resource "aws_s3_access_point" "audit_logs" {
  count  = var.enable_s3_access_points ? 1 : 0
  bucket = aws_s3_bucket.audit_logs.id
  name   = "${var.environment}-audit-ap"

  vpc_configuration {
    vpc_id = var.vpc_id
  }
}

resource "aws_s3_access_point" "exports" {
  count  = var.enable_s3_access_points ? 1 : 0
  bucket = aws_s3_bucket.exports.id
  name   = "${var.environment}-exports-ap"

  vpc_configuration {
    vpc_id = var.vpc_id
  }
}

resource "aws_s3_access_point" "tenant_reports" {
  count  = var.enable_s3_access_points ? 1 : 0
  bucket = aws_s3_bucket.tenant_reports.id
  name   = "${var.environment}-reports-ap"

  vpc_configuration {
    vpc_id = var.vpc_id
  }
}