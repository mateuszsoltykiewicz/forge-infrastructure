# ==============================================================================
# Resource: AWS Subnets (Forge - Customer-Centric)
# ==============================================================================
# Creates subnets within a VPC with configurable CIDR blocks, availability zones,
# and tier classification (Public/Private).
# ==============================================================================

resource "aws_subnet" "this" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.tier == "public" ? true : false

  tags = merge(local.common_tags, local.subnet_tags, {
    Name                = each.key
    SubnetName          = each.key
    Purpose             = each.value.purpose
    Tier                = title(each.value.tier)
    AvailabilityZone    = each.value.availability_zone
    LastModified        = plantimestamp()
  })

  lifecycle {
    ignore_changes = [tags["Created"]]
  }
}

# ==============================================================================
# Route Tables: Separate for Public and Private Subnets
# ==============================================================================
# Public subnets route to Internet Gateway
# Private subnets route to NAT Gateway
# ==============================================================================

resource "aws_route_table" "public" {
  count = local.has_public_subnets ? 1 : 0

  vpc_id = var.vpc_id

  tags = merge(local.common_tags, local.subnet_tags, {
    Name     = local.is_customer_vpc ? "${var.customer_name}-public-rt" : "${var.vpc_name}-public-rt"
    Tier     = "Public"
    Purposes = join(",", local.public_purposes)
    LastModified = plantimestamp()
  })

  lifecycle {
    ignore_changes = [tags["Created"]]
  }
}

resource "aws_route_table" "private" {
  count = local.has_private_subnets ? 1 : 0

  vpc_id = var.vpc_id

  tags = merge(local.common_tags, local.subnet_tags, {
    Name     = local.is_customer_vpc ? "${var.customer_name}-private-rt" : "${var.vpc_name}-private-rt"
    Tier     = "Private"
    Purposes = join(",", local.private_purposes)
    LastModified = plantimestamp()
  })

  lifecycle {
    ignore_changes = [tags["Created"]]
  }
}

# ==============================================================================
# Route Table Associations: Link Subnets to Route Tables
# ==============================================================================

resource "aws_route_table_association" "this" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = each.value.tier == "public" ? aws_route_table.public[0].id : aws_route_table.private[0].id
}

# ==============================================================================
# Forge Best Practices:
# ==============================================================================
# - Use at least 2 AZs for high availability (3 AZs recommended)
# - Public subnets: For load balancers, NAT gateways, bastion hosts
# - Private subnets: For EKS nodes, RDS databases, application servers
# - Ensure CIDR blocks don't overlap and fit within VPC CIDR
# - Use purpose tags for organizing subnets (eks, database, application, etc.)
# - Customer-specific subnets inherit customer tags from locals
# ==============================================================================
