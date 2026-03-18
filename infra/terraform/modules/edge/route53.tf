resource "aws_route53_zone" "primary" {
  name = var.domain_name

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-hosted-zone"
  })
}

# Create the normal app alias only when Route53 failover is NOT enabled.
# If failover is enabled, the disaster_recovery module will create the
# primary/secondary failover records instead.
resource "aws_route53_record" "app_alias" {
  count   = var.enable_route53_failover ? 0 : 1
  zone_id = aws_route53_zone.primary.zone_id
  name    = local.fqdn
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.app.domain_name
    zone_id                = aws_cloudfront_distribution.app.hosted_zone_id
    evaluate_target_health = false
  }
}
