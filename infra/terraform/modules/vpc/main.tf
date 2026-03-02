############################################
# VPC Module (Phase 3)
# - Multi-AZ VPC (2 or 3 AZs)
# - 3-tier subnets (public / private-app / private-data)
# - Public routing via Internet Gateway
# - NAT Gateway toggle (default OFF for cost safety)
# - Gateway Endpoints for S3 + DynamoDB (no hourly cost)
############################################

############################################
# 1) Discover AWS region + available AZs
############################################

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

############################################
# 2) Local values (names, tags, CIDR math)
############################################
locals {
  # Pick the first 2 or 3 AZs based on var.az_count
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Consistent naming prefix (e.g., mt-saas-dev)
  name_prefix = "${var.project}-${var.environment}"

  # Standard tags on every resource + optional custom tags
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )

  ##########################################################
  # Subnet CIDR allocation (enterprise style)
  #
  # We start with a big VPC CIDR (usually /16): var.cidr_block
  # We split it into smaller /20 subnets using:
  #
  #   cidrsubnet(VPC_CIDR, newbits, netnum)
  #
  # If VPC is /16 and we want /20:
  #   /16 -> /20 means add 4 bits => newbits = 4
  #
  # netnum selects which /20 block we take.
  #
  # We intentionally leave gaps for future tiers:
  #   public:       netnum 0..2
  #   private_app:  netnum 4..6
  #   private_data: netnum 8..10
  ##########################################################

  public_subnet_cidrs = [
    for i in range(var.az_count) : cidrsubnet(var.cidr_block, 4, i)
  ]

  private_app_subnet_cidrs = [
    for i in range(var.az_count) : cidrsubnet(var.cidr_block, 4, 4 + i)
  ]

  private_data_subnet_cidrs = [
    for i in range(var.az_count) : cidrsubnet(var.cidr_block, 4, 8 + i)
  ]

  # Stable ordering of public subnet IDs (needed for single NAT placement)
  # We sort by AZ name to avoid "random ordering" issues.
  public_subnet_ids_sorted = [
    for az in sort(keys(aws_subnet.public)) : aws_subnet.public[az].id
  ]
}

############################################
# 3) Create the VPC (your network boundary)
############################################
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

############################################
# 4) Internet Gateway (needed for public tier)
############################################
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

############################################
# 5) Subnets (one per AZ per tier)
############################################

# Public subnets (ALB, NAT). Instances launched here can get public IPs.
resource "aws_subnet" "public" {
  for_each = { for idx, az in local.azs : az => idx }

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = local.public_subnet_cidrs[each.value]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-${each.key}"
    Tier = "public"
  })
}

# Private App subnets (ECS/EC2 services). No direct internet ingress.
resource "aws_subnet" "private_app" {
  for_each = { for idx, az in local.azs : az => idx }

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = local.private_app_subnet_cidrs[each.value]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-app-${each.key}"
    Tier = "private-app"
  })
}

# Private Data subnets (RDS). Most restricted tier.
resource "aws_subnet" "private_data" {
  for_each = { for idx, az in local.azs : az => idx }

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = local.private_data_subnet_cidrs[each.value]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-data-${each.key}"
    Tier = "private-data"
  })
}

############################################
# 6) Route Tables (public + private tiers)
############################################

# Public Route Table: default route goes to Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rt-public"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Attach public route table to all public subnets
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

############################################
# 7) NAT Gateway (optional, cost toggle)
# - OFF by default (enable_nat=false)
# - One NAT per VPC (cost saver, not full HA)
############################################

resource "aws_eip" "nat" {
  count  = var.enable_nat ? 1 : 0
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-eip"
  })
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = local.public_subnet_ids_sorted[0] # stable "first" public subnet
  depends_on    = [aws_internet_gateway.this]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat"
  })
}

# Private route tables (one for app tier, one for data tier)
resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rt-private-app"
  })
}

resource "aws_route_table" "private_data" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rt-private-data"
  })
}

# Only add default route to NAT if NAT is enabled
resource "aws_route" "private_app_nat" {
  count                  = var.enable_nat ? 1 : 0
  route_table_id         = aws_route_table.private_app.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route" "private_data_nat" {
  count                  = var.enable_nat ? 1 : 0
  route_table_id         = aws_route_table.private_data.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

# Attach private route tables to their subnets
resource "aws_route_table_association" "private_app" {
  for_each = aws_subnet.private_app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_app.id
}

resource "aws_route_table_association" "private_data" {
  for_each = aws_subnet.private_data

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_data.id
}

############################################
# 8) Gateway Endpoints (S3 + DynamoDB)
# - No hourly cost
# - Lets private subnets reach S3/Dynamo without NAT
############################################

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_gateway_endpoints ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  # Attach endpoint to private route tables (recommended)
  route_table_ids = [
    aws_route_table.private_app.id,
    aws_route_table.private_data.id
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpce-s3"
  })
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_gateway_endpoints ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private_app.id,
    aws_route_table.private_data.id
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpce-dynamodb"
  })
}