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

  vpc_id = data.aws_vpc.selected.id

  tags = merge(
    local.merged_tags,
    {
      Name = local.igw_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
