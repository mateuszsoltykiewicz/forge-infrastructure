# ==============================================================================
# RDS PostgreSQL Module - Subnets
# ==============================================================================
# This file creates private subnets for RDS across multiple AZs.
# ==============================================================================

# ------------------------------------------------------------------------------
# Private RDS Subnets
# ------------------------------------------------------------------------------

resource "aws_subnet" "rds_private" {
  count = var.rds_subnet_az_count

  vpc_id            = data.aws_vpc.main.id
  cidr_block        = cidrsubnet(data.aws_vpc.main.cidr_block, var.rds_subnet_newbits, var.rds_subnet_netnum_start + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.db_identifier}-private-${data.aws_availability_zones.available.names[count.index]}"
      Type = "private"
      Tier = "rds"
    }
  )
}

# ------------------------------------------------------------------------------
# Route Tables for RDS Subnets
# ------------------------------------------------------------------------------

# Each RDS subnet gets its own route table (following AWS best practices)
resource "aws_route_table" "rds_private" {
  count = var.rds_subnet_az_count

  vpc_id = data.aws_vpc.main.id

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.db_identifier}-private-rt-${data.aws_availability_zones.available.names[count.index]}"
      Type = "private"
      Tier = "rds"
    }
  )
}

# ------------------------------------------------------------------------------
# Route Table Associations
# ------------------------------------------------------------------------------

resource "aws_route_table_association" "rds_private" {
  count = var.rds_subnet_az_count

  subnet_id      = aws_subnet.rds_private[count.index].id
  route_table_id = aws_route_table.rds_private[count.index].id
}
