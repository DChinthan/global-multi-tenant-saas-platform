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

module "edge" {
  source = "../../modules/edge"

  project     = var.project
  environment = var.environment

  # CHANGE THESE:
  domain_name     = "example.com"
  app_subdomain   = "app"
  origin_domain_name = "example-origin.example.com" # temporary placeholder

  enable_waf = true

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
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

