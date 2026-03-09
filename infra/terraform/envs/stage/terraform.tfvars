project     = "global-multi-tenant-saas-platform"
environment = "stage"
cidr_block  = "10.10.0.0/16"


enable_nat        = false
enable_rds        = false
enable_opensearch = false
enable_kinesis    = false


enable_identity       = true
cognito_domain_prefix = "mt-saas-stage-auth-chinthan"
callback_urls         = ["https://stage.example.com/callback"]
logout_urls           = ["https://stage.example.com/logout"]