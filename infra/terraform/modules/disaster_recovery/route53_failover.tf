resource "aws_route53_health_check" "primary" {
  count = local.dr_enabled && var.enable_route53_failover ? 1 : 0

  fqdn              = var.domain_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-primary-health-check"
  })
}

resource "aws_route53_record" "primary" {
  count = local.dr_enabled && var.enable_route53_failover ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  set_identifier = "primary"

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = var.primary_alb_dns_name
    zone_id                = var.primary_alb_zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.primary[0].id
}

resource "aws_route53_record" "secondary" {
  count = local.dr_enabled && var.enable_route53_failover ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  set_identifier = "secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = var.secondary_alb_dns_name
    zone_id                = var.secondary_alb_zone_id
    evaluate_target_health = true
  }
}