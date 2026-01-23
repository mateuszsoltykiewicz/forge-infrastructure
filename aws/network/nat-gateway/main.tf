# ==============================================================================
# NAT Gateway Module - Main Resources
# ==============================================================================
# Creates NAT Gateway(s) in public subnets for private subnet internet egress.
# Number of NAT Gateways scales with number of Availability Zones (1-3).
#
# Architecture:
# - 1 NAT Gateway per AZ for high availability
# - Each NAT GW placed in corresponding ALB public subnet
# - Elastic IP allocated per NAT GW
# - Private subnets route 0.0.0.0/0 traffic through NAT GW
#
# Part of: Forge Network Family
# Dependencies: VPC module, IGW module, Public subnets (ALB)
# Used by: Private subnets (EKS, RDS, Redis)
# ==============================================================================

# ------------------------------------------------------------------------------
# Elastic IP for NAT Gateway
# ------------------------------------------------------------------------------
# One EIP per NAT Gateway for stable outbound IP addresses.
# EIPs are free when attached to running NAT Gateways.
# ------------------------------------------------------------------------------

resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.nat_name_prefix}-${var.availability_zones[count.index]}"
      AZ   = var.availability_zones[count.index]
      Type = "NAT-Gateway-EIP"
    }
  )

  # Ensure VPC exists before creating EIP
  depends_on = [data.aws_vpc.selected]
}

# ------------------------------------------------------------------------------
# NAT Gateway Resource
# ------------------------------------------------------------------------------
# Creates NAT Gateway in each AZ for high availability.
# Round-robin distribution: private subnets route to NAT GW in same AZ.
# ------------------------------------------------------------------------------

resource "aws_nat_gateway" "this" {
  count = length(var.availability_zones)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = var.public_subnet_ids[count.index]

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.nat_name_prefix}-${var.availability_zones[count.index]}"
      AZ   = var.availability_zones[count.index]
      Type = "NAT-Gateway"
    }
  )

  # NAT Gateway requires Internet Gateway to be created first
  depends_on = [aws_eip.nat]

  lifecycle {
    create_before_destroy = true
  }
}
