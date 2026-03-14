data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_versioning" "audit_logs" {
  bucket = var.audit_logs_bucket_name

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_cloudtrail" "platform_audit" {
  count                         = var.enable_cloudtrail ? 1 : 0
  name                          = "${local.name_prefix}-trail"
  s3_bucket_name                = var.audit_logs_bucket_name
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${var.audit_logs_bucket_name}/"]
    }
  }

  tags = local.common_tags
}

resource "aws_athena_workgroup" "audit" {
  count = var.enable_athena ? 1 : 0
  name  = "${local.name_prefix}-audit-wg"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.audit_logs_bucket_name}/athena-results/"
    }
  }

  tags = local.common_tags
}

resource "aws_athena_database" "audit" {
  count  = var.enable_athena ? 1 : 0
  name   = replace("${local.name_prefix}_audit", "-", "_")
  bucket = var.audit_logs_bucket_name
}