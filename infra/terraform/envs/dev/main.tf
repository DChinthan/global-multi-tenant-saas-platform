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
  domain_name        = "example.com"
  app_subdomain      = "app"
  origin_domain_name = "example-origin.example.com" # temporary placeholder

  enable_waf = true

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
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

module "compute" {
  source = "../../modules/compute"

  project                = var.project
  environment            = var.environment
  tags                   = var.tags
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  private_app_subnet_ids = module.vpc.private_app_subnet_ids

  container_port    = 8080
  desired_count     = 2
  cpu               = 512
  memory            = 1024
  app_image_tag     = "latest"
  health_check_path = "/health"

  enable_lambda      = true
  enable_api_gateway = true
}

module "data" {
  source = "../../modules/data"

  project     = var.project
  environment = var.environment
  tags        = var.tags

  vpc_id                  = module.vpc.vpc_id
  private_data_subnet_ids = module.vpc.private_data_subnet_ids
  app_security_group_id   = module.compute.app_security_group_id

  enable_aurora              = false
  aurora_database_name       = "appdb"
  aurora_master_username     = "dbadmin"
  aurora_instance_count      = 1
  aurora_min_capacity        = 0.5
  aurora_max_capacity        = 1
  backup_retention_period    = 7
  enable_deletion_protection = false

  enable_s3_access_points = false
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

