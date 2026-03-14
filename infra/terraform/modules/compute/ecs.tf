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
# ECS Task Definition
################################################

resource "aws_ecs_task_definition" "app" {
  family                   = "${local.compute_name_prefix}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${aws_ecr_repository.app.repository_url}:${var.app_image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
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
          awslogs-stream-prefix = "app"
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
          value = "${var.project}-${var.environment}-app"
        }
      ]
    }
  ])

  tags = local.common_tags
}


################################################
# ECS Service
################################################

resource "aws_ecs_service" "app" {
  name            = "${local.compute_name_prefix}-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_app_subnet_ids
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]

  tags = local.common_tags
}