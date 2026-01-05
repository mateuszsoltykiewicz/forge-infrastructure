# ==============================================================================
# Internet Gateway Module - Local Values
# ==============================================================================
# Computes derived values for resource naming, tagging, and configuration.
# ==============================================================================

locals {
  # Module identification
  module = "internet_gateway"
  family = "network"

  # Customer context
  is_customer_vpc = var.customer_id != null

  # Internet Gateway naming based on architecture type
  igw_name = var.architecture_type == "shared" ? (
    "${var.vpc_name}-igw"
    ) : (
    "${var.customer_name}-${var.aws_region}-igw"
  )

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

  # IGW-specific tags
  igw_tags = {
    ResourceType = "InternetGateway"
    Purpose      = "PublicInternetAccess"
  }

  # Combined tags
  common_tags = merge(
    local.base_tags,
    local.customer_tags,
    var.common_tags
  )
}
