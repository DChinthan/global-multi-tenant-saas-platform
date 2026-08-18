############################################
# AWS PrivateLink: publish the NLB as a VPC Endpoint Service
#
# This is the mirror image of modules/vpc/privatelink.tf's Interface
# Endpoints:
#   - An Interface Endpoint lets resources IN this VPC reach an AWS-owned
#     (or another account's) service privately.
#   - A VPC Endpoint *Service* does the opposite: it turns a load balancer
#     WE own into something other VPCs - in this account, or (via
#     allowed_principals) a completely different AWS account - can reach
#     privately through their own Interface Endpoint. No VPC peering, no
#     Transit Gateway, and the service is never exposed to the public
#     internet.
#   - Only NLB/GWLB can back a VPC Endpoint Service, which is the reason
#     nlb.tf exists rather than just adding another ALB listener rule.
#
# acceptance_required = true means every connection request from a consumer
# still has to be explicitly accepted (via `aws ec2 accept-vpc-endpoint-
# connections`) even if their principal ARN is allow-listed below -
# allow-listing only skips the "can this principal even see/request my
# service" step, not the connection-acceptance step.
############################################

resource "aws_vpc_endpoint_service" "app" {
  count = var.enable_nlb && var.enable_privatelink_endpoint_service ? 1 : 0

  acceptance_required        = true
  network_load_balancer_arns = [aws_lb.nlb[0].arn]

  tags = merge(local.common_tags, {
    Name = "${local.compute_name_prefix}-app-endpoint-service"
  })
}

resource "aws_vpc_endpoint_service_allowed_principal" "app" {
  for_each = var.enable_nlb && var.enable_privatelink_endpoint_service ? toset(var.privatelink_allowed_principal_arns) : toset([])

  vpc_endpoint_service_id = aws_vpc_endpoint_service.app[0].id
  principal_arn           = each.value
}
