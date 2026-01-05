# ==============================================================================
# NAT Gateway Module - Outputs
# ==============================================================================
# Exposes NAT Gateway, EIP, and configuration details for use by other modules.
# ==============================================================================

# ------------------------------------------------------------------------------
# NAT Gateway Outputs
# ------------------------------------------------------------------------------

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_count" {
  description = "Actual number of NAT Gateways created"
  value       = local.actual_nat_count
}

output "nat_gateway_mode" {
  description = "NAT Gateway deployment mode used"
  value       = var.nat_gateway_mode
}

# ------------------------------------------------------------------------------
# EIP Outputs
# ------------------------------------------------------------------------------

output "eip_ids" {
  description = "List of Elastic IP IDs associated with NAT Gateways"
  value = local.use_existing_eips ? (
    var.existing_eip_allocation_ids
  ) : (
    aws_eip.nat[*].id
  )
}

output "eip_public_ips" {
  description = "List of Elastic IP public IP addresses"
  value = local.use_existing_eips ? (
    [] # Cannot fetch public IPs for existing EIPs without data source
  ) : (
    aws_eip.nat[*].public_ip
  )
}

# ------------------------------------------------------------------------------
# EIP Capacity Information
# ------------------------------------------------------------------------------

output "eip_capacity_info" {
  description = "EIP capacity and usage information"
  value = {
    eip_limit           = local.eip_limit
    existing_eips_count = local.existing_eips_count
    available_eips      = local.available_eips
    eips_used_by_nat    = local.use_existing_eips ? 0 : local.actual_nat_count
    check_quota_enabled = var.check_eip_quota
  }
}

# ------------------------------------------------------------------------------
# Route Table Outputs
# ------------------------------------------------------------------------------

output "private_route_table_ids" {
  description = "Private route table IDs where NAT routes were added"
  value       = var.private_route_table_ids
}

output "route_ids" {
  description = "List of route IDs for NAT Gateway routes"
  value       = aws_route.private_nat_gateway[*].id
}

# ------------------------------------------------------------------------------
# Deployment Status
# ------------------------------------------------------------------------------

output "deployment_status" {
  description = "NAT Gateway deployment status and warnings"
  value = {
    desired_nat_count   = local.desired_nat_count
    actual_nat_count    = local.actual_nat_count
    nat_count_reduced   = local.nat_count_reduced
    has_sufficient_eips = local.has_sufficient_eips
    using_existing_eips = local.use_existing_eips
    high_availability   = local.actual_nat_count > 1
  }
}

# ------------------------------------------------------------------------------
# Customer Context Outputs
# ------------------------------------------------------------------------------

output "customer_id" {
  description = "Customer ID (null for shared infrastructure)"
  value       = var.customer_id
}

output "customer_name" {
  description = "Customer name (null for shared infrastructure)"
  value       = var.customer_name
}

output "architecture_type" {
  description = "Architecture type (shared, dedicated_local, dedicated_regional)"
  value       = var.architecture_type
}

# ------------------------------------------------------------------------------
# Configuration Summary
# ------------------------------------------------------------------------------

output "nat_gateway_summary" {
  description = "Complete NAT Gateway configuration summary"
  value = {
    vpc_id                  = var.vpc_id
    vpc_name                = var.vpc_name
    nat_gateway_count       = local.actual_nat_count
    nat_gateway_mode        = var.nat_gateway_mode
    nat_gateway_ids         = aws_nat_gateway.this[*].id
    public_subnet_ids       = local.nat_subnets
    private_route_table_ids = var.private_route_table_ids
    eip_allocation_ids      = local.use_existing_eips ? var.existing_eip_allocation_ids : aws_eip.nat[*].id
    eip_public_ips          = local.use_existing_eips ? [] : aws_eip.nat[*].public_ip
    customer_id             = var.customer_id
    architecture_type       = var.architecture_type
    high_availability       = local.actual_nat_count > 1
    nat_count_reduced       = local.nat_count_reduced
  }
}
