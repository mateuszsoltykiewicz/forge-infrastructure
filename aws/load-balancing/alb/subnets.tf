# ==============================================================================
# ALB Module - Subnets
# ==============================================================================
# This file creates public subnets for ALB across multiple AZs.
# ==============================================================================

# ------------------------------------------------------------------------------
# Public ALB Subnets
# ------------------------------------------------------------------------------

resource "aws_subnet" "alb_public" {
  count = var.alb_subnet_az_count

  vpc_id                  = data.aws_vpc.main.id
  cidr_block              = cidrsubnet(data.aws_vpc.main.cidr_block, var.alb_subnet_newbits, var.alb_subnet_netnum_start + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.all_tags,
    {
      Name = "${local.alb_name}-public-${data.aws_availability_zones.available.names[count.index]}"
      Type = "public"
      Tier = "alb"
    }
  )
}

# ------------------------------------------------------------------------------
# Route Tables for ALB Subnets
# ------------------------------------------------------------------------------

# Single route table for all public ALB subnets (all route to IGW)
resource "aws_route_table" "alb_public" {
  vpc_id = data.aws_vpc.main.id

  tags = merge(
    local.all_tags,
    {
      Name = "${local.alb_name}-public-rt"
      Type = "public"
      Tier = "alb"
    }
  )
}

# ------------------------------------------------------------------------------
# Routes
# ------------------------------------------------------------------------------

# Route to Internet Gateway for public ALB subnets
resource "aws_route" "alb_internet_gateway" {
  route_table_id         = aws_route_table.alb_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = data.aws_internet_gateway.main.id
}

# IPv6 route to Internet Gateway (if using dualstack)
resource "aws_route" "alb_internet_gateway_ipv6" {
  count = var.ip_address_type != "ipv4" ? 1 : 0

  route_table_id              = aws_route_table.alb_public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = data.aws_internet_gateway.main.id
}

# ------------------------------------------------------------------------------
# Route Table Associations
# ------------------------------------------------------------------------------

resource "aws_route_table_association" "alb_public" {
  count = var.alb_subnet_az_count

  subnet_id      = aws_subnet.alb_public[count.index].id
  route_table_id = aws_route_table.alb_public.id
}
