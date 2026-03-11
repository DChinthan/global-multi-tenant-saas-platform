project     = "global-multi-tenant-saas-platform"
environment = "prod"
cidr_block  = "10.10.0.0/16"
tags = {
  Owner = "Chinthan"
}

enable_nat        = false
enable_rds        = false
enable_opensearch = false
enable_kinesis    = false

enable_identity       = true
cognito_domain_prefix = "mt-saas-prod-auth-chinthan"
callback_urls         = ["https://app.example.com/callback"]
logout_urls           = ["https://app.example.com/logout"]