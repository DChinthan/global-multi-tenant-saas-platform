output "hosted_zone_id" {
  value = aws_route53_zone.primary.zone_id
}

output "app_fqdn" {
  value = local.fqdn
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.app.domain_name
}

output "waf_web_acl_arn" {
  value       = var.enable_waf ? aws_wafv2_web_acl.this[0].arn : null
  description = "WAF ARN if enabled"
}
