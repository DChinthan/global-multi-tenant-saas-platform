resource "aws_kms_key" "dr" {
  count = local.dr_enabled && var.enable_kms_multi_region ? 1 : 0

  description         = "Multi-region KMS key for DR-enabled data encryption"
  enable_key_rotation = true
  multi_region        = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-dr-kms"
  })
}

resource "aws_kms_alias" "dr" {
  count = local.dr_enabled && var.enable_kms_multi_region ? 1 : 0

  name          = "alias/${local.name_prefix}-dr"
  target_key_id = aws_kms_key.dr[0].key_id
}