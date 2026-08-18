resource "aws_security_group" "alb" {
  name        = "${local.compute_name_prefix}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group" "ecs_service" {
  name        = "${local.compute_name_prefix}-ecs-service-sg"
  description = "Security group for ECS service"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = local.service_ports
    content {
      description     = "Traffic from ALB on port ${ingress.value}"
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.alb.id]
    }
  }

  # NLB (nlb.tf) targets the default service's container_port directly - NLB
  # itself has no per-listener SG concept for its own traffic, so the source
  # here is the NLB's own SG (aws_lb.nlb has security_groups attached).
  dynamic "ingress" {
    for_each = var.enable_nlb ? [1] : []
    content {
      description     = "Traffic from internal NLB on the default service's app port"
      from_port       = var.services[local.default_service_key].container_port
      to_port         = var.services[local.default_service_key].container_port
      protocol        = "tcp"
      security_groups = [aws_security_group.nlb[0].id]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}