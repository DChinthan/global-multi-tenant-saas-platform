locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
      Component   = "identity"
    },
    var.tags
  )
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "archive_file" "pre_token_generation_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/pre_token_generation.py"
  output_path = "${path.module}/lambda/pre_token_generation.zip"
}

############################################################
# DynamoDB: Tenant registry
############################################################
resource "aws_dynamodb_table" "tenants" {
  count        = var.enable_identity ? 1 : 0
  name         = "${local.name_prefix}-tenants"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "tenant_id"

  attribute {
    name = "tenant_id"
    type = "S"
  }

  attribute {
    name = "tenant_slug"
    type = "S"
  }

  global_secondary_index {
    name            = "tenant_slug_index"
    hash_key        = "tenant_slug"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = local.common_tags
}

############################################################
# IAM role for Lambda
############################################################
resource "aws_iam_role" "pre_token_lambda_role" {
  count = var.enable_identity ? 1 : 0
  name  = "${local.name_prefix}-pre-token-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "pre_token_lambda_basic" {
  count      = var.enable_identity ? 1 : 0
  role       = aws_iam_role.pre_token_lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "pre_token_tenant_read" {
  count = var.enable_identity ? 1 : 0
  name  = "${local.name_prefix}-pre-token-tenant-read"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.tenants[0].arn,
          "${aws_dynamodb_table.tenants[0].arn}/index/*"
        ]
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "pre_token_tenant_read_attach" {
  count      = var.enable_identity ? 1 : 0
  role       = aws_iam_role.pre_token_lambda_role[0].name
  policy_arn = aws_iam_policy.pre_token_tenant_read[0].arn
}

############################################################
# Lambda: Pre Token Generation
############################################################
resource "aws_lambda_function" "pre_token_generation" {
  count         = var.enable_identity ? 1 : 0
  function_name = "${local.name_prefix}-pre-token-generation"
  role          = aws_iam_role.pre_token_lambda_role[0].arn
  handler       = "pre_token_generation.lambda_handler"
  runtime       = "python3.12"
  timeout       = 10

  filename         = data.archive_file.pre_token_generation_zip.output_path
  source_code_hash = data.archive_file.pre_token_generation_zip.output_base64sha256

  environment {
    variables = {
      TENANTS_TABLE = aws_dynamodb_table.tenants[0].name
    }
  }

  tags = local.common_tags
}

############################################################
# Cognito User Pool
############################################################
resource "aws_cognito_user_pool" "this" {
  count = var.enable_identity ? 1 : 0
  name  = "${local.name_prefix}-user-pool"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  mfa_configuration = "OFF"

  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  schema {
    name                     = "tenant_id"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 64
    }
  }

  schema {
    name                     = "tenant_slug"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 64
    }
  }

  schema {
    name                     = "app_role"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 64
    }
  }

  lambda_config {
    pre_token_generation = aws_lambda_function.pre_token_generation[0].arn
  }

  tags = local.common_tags
}

resource "aws_lambda_permission" "allow_cognito_invoke" {
  count         = var.enable_identity ? 1 : 0
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pre_token_generation[0].function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.this[0].arn
}

############################################################
# Cognito App Client
############################################################
resource "aws_cognito_user_pool_client" "app" {
  count = var.enable_identity ? 1 : 0
  name  = "${local.name_prefix}-app-client"

  user_pool_id = aws_cognito_user_pool.this[0].id

  generate_secret                      = false
  prevent_user_existence_errors        = "ENABLED"
  enable_token_revocation              = true
  allowed_oauth_flows_user_pool_client = true

  explicit_auth_flows = [
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  allowed_oauth_flows = [
    "code"
  ]

  allowed_oauth_scopes = [
    "openid",
    "email",
    "profile"
  ]

  supported_identity_providers = [
    "COGNITO"
  ]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls
}

############################################################
# Cognito Domain
############################################################
resource "aws_cognito_user_pool_domain" "this" {
  count        = var.enable_identity ? 1 : 0
  domain       = var.cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.this[0].id
}

############################################################
# IAM roles mapped to groups
############################################################
resource "aws_iam_role" "platform_admin" {
  count = var.enable_identity ? 1 : 0
  name  = "${local.name_prefix}-platform-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role" "tenant_admin" {
  count = var.enable_identity ? 1 : 0
  name  = "${local.name_prefix}-tenant-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role" "tenant_user" {
  count = var.enable_identity ? 1 : 0
  name  = "${local.name_prefix}-tenant-user-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

############################################################
# Cognito groups
############################################################
resource "aws_cognito_user_group" "platform_admin" {
  count        = var.enable_identity ? 1 : 0
  user_pool_id = aws_cognito_user_pool.this[0].id
  name         = var.platform_admin_group_name
  description  = "Platform-wide administrators"
  precedence   = 1
  role_arn     = aws_iam_role.platform_admin[0].arn
}

resource "aws_cognito_user_group" "tenant_admin" {
  count        = var.enable_identity ? 1 : 0
  user_pool_id = aws_cognito_user_pool.this[0].id
  name         = var.tenant_admin_group_name
  description  = "Tenant administrators"
  precedence   = 5
  role_arn     = aws_iam_role.tenant_admin[0].arn
}

resource "aws_cognito_user_group" "tenant_user" {
  count        = var.enable_identity ? 1 : 0
  user_pool_id = aws_cognito_user_pool.this[0].id
  name         = var.tenant_user_group_name
  description  = "Tenant end users"
  precedence   = 10
  role_arn     = aws_iam_role.tenant_user[0].arn
}