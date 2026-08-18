############################################
# Network Load Balancer, alongside the existing ALB
#
# This fronts the SAME default ECS service the ALB already serves. ECS
# natively supports registering one service with multiple target groups at
# once (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/register-multiple-targetgroups.html)
# specifically for the "ALB + NLB on the same service" pattern - see the
# extra `load_balancer` block on aws_ecs_service.this in ecs.tf.
#
# Why NLB here instead of just adding another ALB listener:
#   - L4 vs L7: NLB forwards raw TCP with no request parsing, buffering, or
#     header rewriting. For gRPC/HTTP2 or other long-lived, high-throughput
#     TCP traffic, that extra L7 hop on an ALB adds latency and can get in
#     the way of HTTP/2 connection multiplexing. ALB *can* proxy gRPC, but
#     when you don't need path/header-based L7 routing for this traffic,
#     NLB is the lower-latency, protocol-agnostic choice.
#   - Client IP preservation: NLB passes the real source IP straight
#     through (no X-Forwarded-For rewrite needed downstream).
#   - Static addressing: NLB gives one static IP per AZ, useful for
#     consumers that need to allow-list by IP.
#   - PrivateLink requirement: a VPC Endpoint Service (AWS PrivateLink) can
#     only attach to a Network Load Balancer or Gateway Load Balancer - an
#     ALB cannot back one. Standing up this NLB is the prerequisite for
#     privatelink.tf, which publishes this service for cross-VPC/
#     cross-account private consumption.
#
# Internal (not internet-facing): this NLB exists to serve internal
# service-to-service / PrivateLink traffic, not public internet ingress -
# that's still the ALB's job.
############################################

data "aws_vpc" "this" {
  id = var.vpc_id
}

resource "aws_security_group" "nlb" {
  count = var.enable_nlb ? 1 : 0

  name        = "${local.compute_name_prefix}-nlb-sg"
  description = "Security group for the internal NLB fronting the default ECS service"
  vpc_id      = var.vpc_id

  ingress {
    description = "App port from anywhere inside the VPC (internal NLB, incl. PrivateLink consumers)"
    from_port   = var.services[local.default_service_key].container_port
    to_port     = var.services[local.default_service_key].container_port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_lb" "nlb" {
  count = var.enable_nlb ? 1 : 0

  name               = "${local.short_prefix}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_app_subnet_ids
  security_groups    = [aws_security_group.nlb[0].id]

  tags = local.common_tags
}

resource "aws_lb_target_group" "nlb_default" {
  count = var.enable_nlb ? 1 : 0

  name        = "${var.environment}-${local.default_service_key}-nlb-tg"
  port        = var.services[local.default_service_key].container_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol            = "TCP"
    port                = "traffic-port"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "nlb_tcp" {
  count = var.enable_nlb ? 1 : 0

  load_balancer_arn = aws_lb.nlb[0].arn
  port              = var.services[local.default_service_key].container_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_default[0].arn
  }
}
