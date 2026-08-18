################################################
# CloudWatch Logs for ECS
data "aws_region" "current" {}
################################################

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${local.compute_name_prefix}-app"
  retention_in_days = 14
  tags              = local.common_tags
}

################################################
# ECS Cluster
################################################

resource "aws_ecs_cluster" "main" {
  name = "${local.compute_name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}

################################################
################################################
# ECS Task Definitions (one per entry in var.services)
################################################

resource "aws_ecs_task_definition" "this" {
  for_each = var.services

  family                   = "${local.compute_name_prefix}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(each.value.cpu)
  memory                   = tostring(each.value.memory)
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = "${aws_ecr_repository.this[each.key].repository_url}:${each.value.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = each.value.container_port
          hostPort      = each.value.container_port
          protocol      = "tcp"
        }
      ]

      ################################################
      # CloudWatch Logging (Phase 10 Observability)
      ################################################

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.ecs_log_group_name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = each.key
        }
      }

      ################################################
      # Environment Variables
      ################################################

      environment = [
        {
          name  = "APP_ENV"
          value = var.environment
        },
        {
          name  = "AWS_XRAY_TRACING_NAME"
          value = "${var.project}-${var.environment}-${each.key}"
        }
      ]
    }
  ])

  tags = local.common_tags
}


################################################
# ECS Services (one per entry in var.services)
################################################

resource "aws_ecs_service" "this" {
  for_each = var.services

  name            = "${local.compute_name_prefix}-${each.key}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.this[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_app_subnet_ids
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this[each.key].arn
    container_name   = each.key
    container_port   = each.value.container_port
  }

  # Second target-group registration for the default service only, so the
  # NLB in nlb.tf serves live traffic too (not just the ALB). See nlb.tf for
  # why this service is dual-registered instead of adding another ALB rule.
  dynamic "load_balancer" {
    for_each = var.enable_nlb && each.key == local.default_service_key ? [aws_lb_target_group.nlb_default[0].arn] : []
    content {
      target_group_arn = load_balancer.value
      container_name   = each.key
      container_port   = each.value.container_port
    }
  }

  depends_on = [aws_lb_listener.http, aws_lb_listener.https, aws_lb_listener.nlb_tcp]

  tags = local.common_tags
}
