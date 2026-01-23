# ==============================================================================
# Subnet Module - Main Resources
# ==============================================================================
# Creates subnets using CIDR blocks and AZs calculated by cidr-calculator module
# ==============================================================================

# ------------------------------------------------------------------------------
# AWS Private/Public Subnets
# ------------------------------------------------------------------------------

resource "aws_subnet" "this" {
  count = length(var.subnet_cidrs)

  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  # Public vs Private subnet configuration
  map_public_ip_on_launch = var.tier == "Public"

  tags = merge(
    local.merged_tags,
    {
      Name  = local.subnet_names[count.index]
      AZ    = var.availability_zones[count.index]
      CIDR  = var.subnet_cidrs[count.index]
      VPCId = var.vpc_id
    }
  )

  lifecycle {
    # Validate subnet name length
    precondition {
      condition     = local.subnet_validations[count.index].length_ok
      error_message = "Subnet name '${local.subnet_names[count.index]}' exceeds 255 characters (length: ${length(local.subnet_names[count.index])})"
    }

    # Validate subnet name pattern
    precondition {
      condition     = local.subnet_validations[count.index].pattern_ok
      error_message = "Subnet name '${local.subnet_names[count.index]}' contains invalid characters"
    }

    # Validate no double hyphens
    precondition {
      condition     = local.subnet_validations[count.index].no_double_dash
      error_message = "Subnet name '${local.subnet_names[count.index]}' contains double hyphens (--)"
    }
  }
}

# ------------------------------------------------------------------------------
# Route Tables (optional, controlled by variable)
# ------------------------------------------------------------------------------

resource "aws_route_table" "this" {
  count = length(var.subnet_cidrs)

  vpc_id = var.vpc_id

  tags = merge(
    local.merged_tags,
    {
      Name     = "${local.subnet_names[count.index]}-rt"
      SubnetID = aws_subnet.this[count.index].id
      AZ       = var.availability_zones[count.index]
    }
  )
}

# Associate route tables with subnets
resource "aws_route_table_association" "this" {
  count = length(var.subnet_cidrs)

  subnet_id      = aws_subnet.this[count.index].id
  route_table_id = aws_route_table.this[count.index].id
}

# ------------------------------------------------------------------------------
# Routes - Internet Gateway (Public Subnets)
# ------------------------------------------------------------------------------
# Public subnets route all traffic (0.0.0.0/0) to Internet Gateway.
# Used by: ALB subnets for internet-facing load balancer.
# Terraform dependency graph ensures IGW is created before routes.
# ------------------------------------------------------------------------------

resource "aws_route" "public_internet_gateway" {
  count = var.tier == "Public" ? length(var.subnet_cidrs) : 0

  route_table_id         = aws_route_table.this[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.internet_gateway_id
}

# ------------------------------------------------------------------------------
# Routes - NAT Gateway (Private Subnets)
# ------------------------------------------------------------------------------
# Private subnets route internet traffic (0.0.0.0/0) to NAT Gateway.
# Round-robin distribution: subnet N → NAT Gateway N % count(NAT GW).
# Used by: EKS subnets for pod egress (selective, controlled by Network Policies).
# ------------------------------------------------------------------------------

resource "aws_route" "private_nat_gateway" {
  count = var.tier == "Private" && length(var.nat_gateway_ids) > 0 ? length(var.subnet_cidrs) : 0

  route_table_id         = aws_route_table.this[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_ids[count.index % length(var.nat_gateway_ids)]
}

# ------------------------------------------------------------------------------
# VPC Endpoint Association - S3 Gateway
# ------------------------------------------------------------------------------
# Associates S3 Gateway VPC Endpoint with route tables for free S3 access.
# Automatically adds prefix list routes for S3 service (no 0.0.0.0/0 needed).
# Used by: EKS subnets for ECR image pulls (ECR uses S3 backend).
# Created when enable_s3_gateway_route = true.
# Terraform dependency graph ensures S3 endpoint exists before association.
# ------------------------------------------------------------------------------

resource "aws_vpc_endpoint_route_table_association" "s3_gateway" {
  for_each = var.enable_s3_gateway_route ? toset([for idx, cidr in var.subnet_cidrs : tostring(idx)]) : toset([])

  vpc_endpoint_id = var.s3_gateway_endpoint_id
  route_table_id  = aws_route_table.this[tonumber(each.key)].id
}
