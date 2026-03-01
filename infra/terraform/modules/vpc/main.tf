resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
  tags = {
    Name = "${var.project}-${var.environment}-vpc"
  }
}

# NAT Gateway will be implemented in Phase 3
# Requires:
# - Public subnet
# - Elastic IP
# - Internet Gateway
# - Route tables