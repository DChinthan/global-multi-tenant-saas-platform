# Phase 2.1 placeholder. Modules wired in Phase 2.2+

module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment

  cidr_block = var.cidr_block

  az_count = 3

  enable_nat               = var.enable_nat
  enable_gateway_endpoints = true

  tags = {
    Env = var.environment
  }
}
module "security" {
  source = "../../modules/security"

  project     = var.project
  environment = var.environment

  enable_cloudtrail        = true
  enable_config            = false
  enable_security_services = false

  tags = {
    Env = var.environment
  }
}

module "identity" {
  source = "../../modules/identity"

  project     = var.project
  environment = var.environment

  enable_identity       = var.enable_identity
  cognito_domain_prefix = var.cognito_domain_prefix
  callback_urls         = var.callback_urls
  logout_urls           = var.logout_urls

  tags = {
    Env = var.environment
  }
}

module "rds" {
  source = "../../modules/rds"
  count  = var.enable_rds ? 1 : 0

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id


  instance_class = var.rds_instance_class
}

module "opensearch" {
  source = "../../modules/opensearch"
  count  = var.enable_opensearch ? 1 : 0

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id

  instance_type = var.opensearch_instance_type
}

module "kinesis" {
  source = "../../modules/kinesis"
  count  = var.enable_kinesis ? 1 : 0

  project     = var.project
  environment = var.environment
}