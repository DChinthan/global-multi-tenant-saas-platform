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
  domain_name             = "example.com"
  app_subdomain           = "app"
  origin_domain_name      = "example-origin.example.com" # temporary placeholder
  enable_route53_failover = var.enable_route53_failover


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
  ecs_log_group_name     = module.observability.ecs_log_group_name
  apigw_log_group_arn    = module.observability.apigw_log_group_arn

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

module "event_backbone" {
  source = "../../modules/event_backbone"

  project     = var.project
  environment = var.environment
  tags        = var.tags

  kms_key_arn = module.security.kms_key_arn

  enable_kinesis = var.enable_kinesis

  tenant_onboarding_definition = jsonencode({
    Comment = "Tenant onboarding workflow"
    StartAt = "PublishTenantCreated"
    States = {
      PublishTenantCreated = {
        Type     = "Task"
        Resource = "arn:aws:states:::events:putEvents"
        Arguments = {
          Entries = [
            {
              Source       = "saas.platform"
              DetailType   = "tenant.created"
              EventBusName = "${var.project}-${var.environment}-domain-bus"
              Detail = {
                status = "created"
              }
            }
          ]
        }
        End = true
      }
    }
  })

  anomaly_detection_definition = jsonencode({
    Comment = "Anomaly detection pipeline"
    StartAt = "QueueAnomalyJob"
    States = {
      QueueAnomalyJob = {
        Type     = "Task"
        Resource = "arn:aws:states:::sqs:sendMessage"
        Arguments = {
          QueueUrl = "REPLACE_AT_MODULE_LEVEL"
          MessageBody = {
            job = "anomaly-detection"
          }
        }
        End = true
      }
    }
  })

  report_generation_definition = jsonencode({
    Comment = "Report generation workflow"
    StartAt = "PublishReportRequested"
    States = {
      PublishReportRequested = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Arguments = {
          TopicArn = "REPLACE_AT_MODULE_LEVEL"
          Message = {
            action = "generate-report"
          }
        }
        End = true
      }
    }
  })
}

module "observability" {
  source = "../../modules/observability"

  project                = var.project
  environment            = var.environment
  region                 = var.aws_region
  tags                   = var.tags
  kms_key_arn            = module.security.kms_key_arn
  log_retention_days     = 30
  enable_xray            = true
  enable_cloudtrail      = true
  enable_athena          = true
  audit_logs_bucket_name = module.data.audit_logs_bucket_id

  alb_name               = module.compute.alb_name
  alb_arn_suffix         = module.compute.alb_arn_suffix
  ecs_cluster_name       = module.compute.ecs_cluster_name
  ecs_service_name       = module.compute.ecs_service_name
  lambda_function_name   = module.compute.lambda_webhook_handler_name
  api_gateway_id         = module.compute.webhook_api_id
  api_gateway_stage_name = "default"

  rds_instance_id     = module.data.rds_instance_id
  sns_alert_topic_arn = module.event_backbone.alerts_topic_arn
  vpc_id              = module.vpc.vpc_id
}

module "analytics" {
  source = "../../modules/analytics"

  project     = var.project
  environment = var.environment
  region      = var.aws_region
  tags        = var.tags

  analytics_bucket_name      = module.data.tenant_reports_bucket_name
  athena_results_bucket_name = module.data.exports_bucket_name

  crawler_s3_target_path = "analytics/"
  crawler_schedule       = "cron(0 3 * * ? *)"

  enable_glue_crawler      = true
  enable_athena            = true
  enable_scheduled_reports = true

  report_schedule_expression = "cron(0 8 * * ? *)"
  report_timezone            = "America/Toronto"
  report_output_prefix       = "scheduled-reports/"
}

module "disaster_recovery" {
  source = "../../modules/disaster_recovery"

  project          = var.project
  environment      = var.environment
  aws_region       = var.aws_region
  secondary_region = var.secondary_region

  enable_disaster_recovery = var.enable_disaster_recovery
  enable_s3_replication    = var.enable_s3_replication
  enable_route53_failover  = var.enable_route53_failover
  enable_backup_plan       = var.enable_backup_plan
  enable_kms_multi_region  = var.enable_kms_multi_region

  hosted_zone_id = var.hosted_zone_id
  domain_name    = var.domain_name

  primary_alb_dns_name = module.compute.alb_dns_name
  primary_alb_zone_id  = module.compute.alb_zone_id

  # placeholder until true secondary stack exists
  secondary_alb_dns_name = var.secondary_alb_dns_name
  secondary_alb_zone_id  = var.secondary_alb_zone_id

  replication_bucket_mappings = var.replication_bucket_mappings

  backup_resource_arns = compact([
    try(module.data.rds_cluster_arn, null),
    try(module.data.efs_file_system_arn, null),
    try(module.event_backbone.dynamodb_table_arn, null)
  ])
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

