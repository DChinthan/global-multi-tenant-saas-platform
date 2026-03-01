resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
  tags = {
    Name = "${var.project}-${var.environment}-vpc"
  }
}

# Example NAT resource toggled (placeholder)
resource "aws_nat_gateway" "this" {
  count = var.enable_nat ? 1 : 0

  allocation_id = "PLACEHOLDER" # keep design-only unless deploying
  subnet_id     = "PLACEHOLDER"
}