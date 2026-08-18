# Phase 2.1 placeholder. Modules wired in Phase 2.2+

module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment

  cidr_block = var.cidr_block

  az_count = 3

  enable_nat               = var.enable_nat
  enable_gateway_endpoints = true

  enable_interface_endpoints = true
  enable_troubleshooting_lab = false
  app_container_port         = 8080

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

  # Phase 1 (multi-service ECS refactor): app1-python is the pre-existing
  # single service, keyed "app" so all derived resource names (ECR repo, task
  # family, ECS service, target group, autoscaling target) stay identical to
  # the pre-refactor hardcoded names — see modules/compute/moved.tf.
  services = {
    app = {
      container_port    = 8080
      cpu               = 512
      memory            = 1024
      desired_count     = 2
      image_tag         = "latest"
      health_check_path = "/health"
      is_default        = true

      # Pins the autoscaling policy name to the old hardcoded value so this
      # migration is a zero-diff plan. New service entries should omit this.
      autoscaling_policy_name = "${var.project}-${var.environment}-ecs-cpu-scaling"
    }

    # Phase 2: FastAPI demo service, path-routed off the same ALB at /app5/*
    # (see services/app5-fileservice and modules/compute/alb.tf listener rules).
    "app5-fileservice" = {
      container_port    = 8080
      cpu               = 256
      memory            = 512
      desired_count     = 2
      image_tag         = "latest"
      health_check_path = "/healthz"
      is_default        = false
      path_patterns     = ["/app5/*"]
    }
  }

  enable_lambda      = true
  enable_api_gateway = true
  lambda_zip_path    = "${path.root}/../../../../artifacts/webhook-handler.zip"

  alb_acm_certificate_arn = var.alb_acm_certificate_arn

  enable_nlb = true

  # Prod stays off by default - only turn this on deliberately with a real
  # allow-listed consumer account, not as a default-on demo like stage.
  enable_privatelink_endpoint_service = false
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

  enable_apigw_access_logs = true
  enable_vpc_flow_logs     = true
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

  secondary_alb_dns_name = var.secondary_alb_dns_name
  secondary_alb_zone_id  = var.secondary_alb_zone_id

  replication_bucket_mappings = {
    audit_logs = {
      source_bucket_name     = module.data.audit_logs_bucket_name
      source_bucket_arn      = module.data.audit_logs_bucket_arn
      destination_bucket_arn = var.dr_audit_logs_bucket_arn
    }

    exports = {
      source_bucket_name     = module.data.exports_bucket_name
      source_bucket_arn      = module.data.exports_bucket_arn
      destination_bucket_arn = var.dr_exports_bucket_arn
    }

    tenant_reports = {
      source_bucket_name     = module.data.tenant_reports_bucket_name
      source_bucket_arn      = module.data.tenant_reports_bucket_arn
      destination_bucket_arn = var.dr_tenant_reports_bucket_arn
    }
  }

  backup_resource_arns = compact([
    try(module.data.rds_cluster_arn, null)
  ])
}

module "ci_cd_oidc" {
  source = "../../modules/ci_cd_oidc"

  github_org       = "DChinthan"
  github_repo      = "global-multi-tenant-saas-platform"
  role_name        = "global-mt-saas-github-actions-role"
  allowed_branches = ["dev", "stage", "main"]
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

# Phase 3 (Kubernetes/Helm demo): real EKS module, gated off by default - see
# modules/eks/main.tf for the cost breakdown. The runnable Helm/K8s evidence
# for this repo comes from a local kind cluster instead (docs/app5-multicloud-demo.md).
module "eks" {
  source = "../../modules/eks"
  count  = var.enable_eks ? 1 : 0

  project     = var.project
  environment = var.environment
  tags        = var.tags

  vpc_id                 = module.vpc.vpc_id
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  public_subnet_ids      = module.vpc.public_subnet_ids
}

# Observability: Terraform-managed kube-prometheus-stack (Prometheus +
# Grafana + Alertmanager) on top of module.eks - see modules/monitoring/main.tf.
# Only meaningful once a real cluster exists, so it's gated behind the same
# enable_eks flag. The runnable observability evidence for this repo comes
# from `helm install` against a local kind cluster instead - see
# docs/observability-demo.md.
module "monitoring" {
  source = "../../modules/monitoring"
  count  = var.enable_eks ? 1 : 0

  project     = var.project
  environment = var.environment
  tags        = var.tags

  depends_on = [module.eks]
}