############################################
# AWS PrivateLink: Interface Endpoints (consuming AWS services)
#
# Distinction from the Gateway Endpoints in main.tf (S3/DynamoDB):
#   - Gateway Endpoints are NOT PrivateLink. They're a route-table entry
#     (a prefix-list target) that routes traffic to S3/DynamoDB over AWS's
#     internal network. No ENI, no security group, free, and only S3 and
#     DynamoDB support this endpoint type.
#   - Interface Endpoints ARE PrivateLink. Each one provisions an actual
#     ENI (with a private IP) per subnet you attach it to, fronted by a
#     PrivateLink-powered AWS-managed service endpoint. Private DNS makes
#     the service's normal hostname (e.g. ecr.us-east-1.amazonaws.com)
#     resolve to that ENI's private IP instead of a public one. Traffic
#     never touches the internet or needs a NAT Gateway/IGW. Billed hourly
#     per-AZ plus data processing, and requires a security group.
#
# Why this matters here: enable_nat defaults to false in every env (cost
# safety), which means the private-app subnets have no internet route at
# all. Before this file, that left ECS Fargate tasks with a path to S3/
# DynamoDB only - nothing to pull container images (ECR), ship logs
# (CloudWatch Logs), or read secrets (Secrets Manager). Interface Endpoints
# close that gap without paying for a NAT Gateway.
############################################

resource "aws_security_group" "vpc_endpoints" {
  count = var.enable_interface_endpoints ? 1 : 0

  name        = "${local.name_prefix}-vpce-sg"
  description = "Allows resources inside this VPC to reach Interface (PrivateLink) endpoints on 443"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from anywhere inside this VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpce-sg"
  })
}

locals {
  # Minimum set an ECS Fargate task actually needs with no NAT: pull images
  # (ecr.api for auth/manifest, ecr.dkr for layer pulls), ship container
  # logs, and read app secrets (Aurora creds, etc. per HLD/LLD's Secrets
  # Manager rotation plan).
  interface_endpoint_services = toset([
    "ecr.api",
    "ecr.dkr",
    "logs",
    "secretsmanager",
  ])
}

resource "aws_vpc_endpoint" "interface" {
  for_each = var.enable_interface_endpoints ? local.interface_endpoint_services : []

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.private_app_subnet_ids_sorted
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpce-${each.value}"
  })
}
