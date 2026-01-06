# ==============================================================================
# NAT Gateway Module - Main Resources
# ==============================================================================
# Creates NAT Gateways with Elastic IPs for private subnet internet access.
# Includes EIP capacity validation and flexible deployment modes.
# ==============================================================================

# ------------------------------------------------------------------------------
# EIP Capacity Validation
# ------------------------------------------------------------------------------
# Validates EIP availability BEFORE attempting to create resources
# ------------------------------------------------------------------------------

resource "terraform_data" "eip_validation" {
  lifecycle {
    # Strict validation (fails for high_availability and single modes)
    precondition {
      condition = (
        var.nat_gateway_mode == "best_effort" ||
        local.use_existing_eips ||
        local.has_sufficient_eips
      )
      error_message = local.eip_shortage_message
    }
  }
}

# ------------------------------------------------------------------------------
# NAT Gateway Count Warning
# ------------------------------------------------------------------------------
# Warns when NAT count was reduced in best_effort mode
# ------------------------------------------------------------------------------

resource "terraform_data" "nat_count_warning" {
  count = local.nat_count_reduced && var.nat_gateway_mode == "best_effort" ? 1 : 0

  lifecycle {
    postcondition {
      condition     = !local.nat_count_reduced
      error_message = <<-EOT
        WARNING: NAT Gateway count reduced due to EIP availability.
        
        Requested: ${local.desired_nat_count} NAT Gateways
        Created: ${local.actual_nat_count} NAT Gateways
        
        This configuration is NOT highly available. For production workloads:
        1. Request EIP limit increase to ${local.desired_nat_count}
        2. Change nat_gateway_mode to "high_availability" after EIP increase
      EOT
    }
  }
}

# ------------------------------------------------------------------------------
# Elastic IP Addresses
# ------------------------------------------------------------------------------
# Creates EIPs for NAT Gateways (unless using existing EIPs)
# ------------------------------------------------------------------------------

resource "aws_eip" "nat" {
  count  = local.use_existing_eips ? 0 : local.actual_nat_count
  domain = "vpc"

  tags = merge(
    local.merged_tags,
    local.nat_tags,
    {
      Name    = "${local.nat_name_prefix}-eip-${count.index + 1}"
      Purpose = "NATGateway"
      Index   = count.index + 1
    }
  )

  lifecycle {
    create_before_destroy = true
  }

  # Explicit dependency on validation
  depends_on = [terraform_data.eip_validation]
}

# ------------------------------------------------------------------------------
# NAT Gateways
# ------------------------------------------------------------------------------
# Creates NAT Gateways in public subnets for private subnet internet access
# ------------------------------------------------------------------------------

resource "aws_nat_gateway" "this" {
  count = local.actual_nat_count

  allocation_id = local.use_existing_eips ? (
    var.existing_eip_allocation_ids[count.index]
    ) : (
    aws_eip.nat[count.index].id
  )

  subnet_id = local.nat_subnets[count.index]

  tags = merge(
    local.merged_tags,
    local.nat_tags,
    {
      Name      = "${local.nat_name_prefix}-${count.index + 1}"
      SubnetId  = local.nat_subnets[count.index]
      Index     = count.index + 1
      EIPSource = local.use_existing_eips ? "existing" : "created"
    }
  )

  lifecycle {
    create_before_destroy = true
  }

  # Explicit dependency on validation
  depends_on = [terraform_data.eip_validation]
}

# ------------------------------------------------------------------------------
# Private Route Table Routes
# ------------------------------------------------------------------------------
# Adds default routes (0.0.0.0/0) to all private route tables via NAT Gateway
# Uses first NAT Gateway in single mode, distributes in HA mode
# ------------------------------------------------------------------------------

resource "aws_route" "private_nat_gateway" {
  count = length(var.private_route_table_ids)

  route_table_id         = var.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"

  # Route distribution strategy:
  # - Single mode: All routes use NAT GW 0
  # - HA mode: Distribute routes across NAT GWs (round-robin)
  nat_gateway_id = aws_nat_gateway.this[
    var.nat_gateway_mode == "single" ? 0 : count.index % local.actual_nat_count
  ].id
}
