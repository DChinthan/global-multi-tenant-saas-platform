resource "aws_kinesis_stream" "high_volume_logs" {
  count            = var.enable_kinesis ? 1 : 0
  name             = "${local.name_prefix}-high-volume-logs"
  shard_count      = 1
  retention_period = 24

  encryption_type = "KMS"
  kms_key_id      = var.kms_key_arn

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-high-volume-logs"
    Type = "stream"
  })
}