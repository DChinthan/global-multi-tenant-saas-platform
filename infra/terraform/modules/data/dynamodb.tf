resource "aws_dynamodb_table" "tenant_config" {
  name         = "${local.name_prefix}-tenant-config"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "tenant_id"

  attribute {
    name = "tenant_id"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.data.arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-tenant-config"
    DataType = "tenant-config"
  })
}

resource "aws_dynamodb_table" "session_store" {
  name         = "${local.name_prefix}-session-store"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "session_id"

  attribute {
    name = "session_id"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.data.arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-session-store"
    DataType = "session"
  })
}

resource "aws_dynamodb_table" "rate_limit" {
  name         = "${local.name_prefix}-rate-limit"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "rate_key"

  attribute {
    name = "rate_key"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.data.arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-rate-limit"
    DataType = "rate-limit"
  })
}