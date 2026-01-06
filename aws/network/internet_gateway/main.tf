# ==============================================================================
# Internet Gateway Module - Main Resources
# ==============================================================================
# Creates an Internet Gateway for VPC internet connectivity and adds a default
# route (0.0.0.0/0) to the public route table for outbound internet access.
#
# Part of: Forge Network Family
# Dependencies: VPC module, Subnet module (for public_route_table_id)
# Used by: Public subnets for internet access
# ==============================================================================

# ------------------------------------------------------------------------------
# Internet Gateway Resource
# ------------------------------------------------------------------------------
# Attaches to the VPC and provides internet connectivity for public subnets.
# Only one IGW per VPC is allowed by AWS.
# ------------------------------------------------------------------------------

resource "aws_internet_gateway" "this" {
  count = var.create ? 1 : 0

  vpc_id = var.vpc_id

  tags = merge(
    local.merged_tags,
    local.igw_tags,
    {
      Name = local.igw_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------------------------
# Default Route to Internet Gateway
# ------------------------------------------------------------------------------
# Adds 0.0.0.0/0 route to the public route table, enabling internet access
# for all resources in public subnets.
# ------------------------------------------------------------------------------

resource "aws_route" "public_internet_access" {
  route_table_id         = var.public_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}
