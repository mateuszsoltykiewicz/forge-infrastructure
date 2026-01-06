# ==============================================================================
# ElastiCache Redis Module - Private Subnets
# ==============================================================================
# This file creates dedicated private subnets for Redis.
# Subnets are distributed across available AZs with proper tagging.
# ==============================================================================

# ------------------------------------------------------------------------------
# Calculate Subnet CIDR Blocks
# ------------------------------------------------------------------------------

locals {
  # Get VPC CIDR block
  vpc_cidr = data.aws_vpc.main.cidr_block

  # Calculate number of AZs to use (minimum 2, maximum 3)
  az_count = min(var.redis_subnet_az_count, length(data.aws_availability_zones.available.names))

  # Selected AZs for Redis subnets
  azs = slice(data.aws_availability_zones.available.names, 0, local.az_count)

  # Calculate subnet CIDR blocks based on VPC CIDR
  # Example: VPC 10.0.0.0/16 -> Redis subnets: 10.0.100.0/24, 10.0.101.0/24, 10.0.102.0/24
  # Each subnet gets /24 (256 IPs) which is sufficient for Redis cache nodes
  redis_subnet_cidrs = [
    for idx in range(local.az_count) :
    cidrsubnet(local.vpc_cidr, var.redis_subnet_newbits, var.redis_subnet_netnum_start + idx)
  ]
}

# ------------------------------------------------------------------------------
# Redis Private Subnets
# ------------------------------------------------------------------------------

resource "aws_subnet" "redis_private" {
  count = local.az_count

  vpc_id                  = data.aws_vpc.main.id
  cidr_block              = local.redis_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.replication_group_id}-private-${local.azs[count.index]}"
      Type = "private"
      Tier = "redis"
    }
  )
}

# ------------------------------------------------------------------------------
# Private Route Tables (one per AZ)
# ------------------------------------------------------------------------------

resource "aws_route_table" "redis_private" {
  count = local.az_count

  vpc_id = data.aws_vpc.main.id

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.replication_group_id}-private-${local.azs[count.index]}"
      Type = "private"
    }
  )
}

# ------------------------------------------------------------------------------
# Route Table Associations
# ------------------------------------------------------------------------------

resource "aws_route_table_association" "redis_private" {
  count = local.az_count

  subnet_id      = aws_subnet.redis_private[count.index].id
  route_table_id = aws_route_table.redis_private[count.index].id
}
