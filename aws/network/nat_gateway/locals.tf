# ==============================================================================
# NAT Gateway Module - Local Values
# ==============================================================================
# Computes derived values for resource naming, tagging, EIP management, and
# NAT Gateway deployment strategy with error handling.
# ==============================================================================

locals {
  # Module identification
  module = "nat_gateway"
  family = "network"

  # Customer context
  has_customer = var.customer_name != null && var.customer_name != ""

  # ------------------------------------------------------------------------------
  # EIP Capacity Planning
  # ------------------------------------------------------------------------------

  # Get EIP limit (from Service Quotas API or default)
  eip_limit = var.check_eip_quota && length(data.aws_servicequotas_service_quota.eip_limit) > 0 ? (
    data.aws_servicequotas_service_quota.eip_limit[0].value
  ) : var.default_eip_limit

  # Count existing EIPs in region
  existing_eips_count = length(data.aws_eips.existing.allocation_ids)

  # Calculate available EIPs
  available_eips = max(0, local.eip_limit - local.existing_eips_count)

  # ------------------------------------------------------------------------------
  # NAT Gateway Count Calculation
  # ------------------------------------------------------------------------------

  # Determine desired count based on mode
  desired_nat_count = var.nat_gateway_mode == "single" ? 1 : length(var.public_subnet_ids)

  # Use existing EIPs or calculate based on availability
  use_existing_eips = var.existing_eip_allocation_ids != null

  # Actual NAT Gateway count (with error handling)
  actual_nat_count = local.use_existing_eips ? (
    # If using existing EIPs, count is based on provided list
    length(var.existing_eip_allocation_ids)
    ) : (
    # If creating new EIPs, respect mode and availability
    var.nat_gateway_mode == "best_effort" ? (
      min(local.desired_nat_count, local.available_eips)
    ) : local.desired_nat_count
  )

  # Subnet selection for NAT Gateway placement
  nat_subnets = slice(var.public_subnet_ids, 0, local.actual_nat_count)

  # ------------------------------------------------------------------------------
  # Error Detection
  # ------------------------------------------------------------------------------

  # Check if we have enough EIPs
  has_sufficient_eips = local.use_existing_eips || local.available_eips >= local.desired_nat_count

  # Check if we had to reduce NAT count
  nat_count_reduced = local.actual_nat_count < local.desired_nat_count

  # Generate error/warning messages
  eip_shortage_message = <<-EOT
    Insufficient EIPs available for NAT Gateway deployment.
    
    Mode: ${var.nat_gateway_mode}
    Desired NAT Gateways: ${local.desired_nat_count}
    Available EIPs: ${local.available_eips}
    EIP Limit (${var.check_eip_quota ? "from AWS API" : "default"}): ${local.eip_limit}
    Currently in use: ${local.existing_eips_count}
    
    Solutions:
    1. Request EIP limit increase via AWS Service Quotas:
       https://console.aws.amazon.com/servicequotas/
    2. Set nat_gateway_mode = "single" (creates 1 NAT Gateway only)
    3. Set nat_gateway_mode = "best_effort" (creates ${min(local.desired_nat_count, local.available_eips)} NAT Gateways)
    4. Release unused EIPs in region ${var.aws_region}
    5. Provide existing_eip_allocation_ids to reuse allocated EIPs
  EOT

  # ------------------------------------------------------------------------------
  # NAT Gateway Naming
  # ------------------------------------------------------------------------------

  nat_name_prefix = var.architecture_type == "shared" ? (
    "${var.vpc_name}-nat"
    ) : (
    "${var.customer_name}-${var.aws_region}-nat"
  )

  # ------------------------------------------------------------------------------
  # Tagging Strategy
  # ------------------------------------------------------------------------------

  # Base tags (always applied)
  base_tags = {
    ManagedBy   = "Terraform"
    Module      = local.module
    Family      = local.family
    Workspace   = var.workspace
    Environment = var.environment
    Region      = var.aws_region
  }

  # Customer-specific tags (only for dedicated VPCs)
  customer_tags = local.is_customer_vpc ? {
    CustomerId       = var.customer_id
    CustomerName     = var.customer_name
    ArchitectureType = var.architecture_type
    PlanTier         = var.plan_tier
  } : {}

  # NAT Gateway-specific tags
  nat_tags = {
    ResourceType   = "NATGateway"
    DeploymentMode = var.nat_gateway_mode
  }

  # Combined tags
  common_tags = merge(
    local.base_tags,
    local.customer_tags,
    var.common_tags
  )
}
