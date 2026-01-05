# ==============================================================================
# LOCAL VALUES - VPC Module (Forge - Customer-Centric)
# ==============================================================================
# This file defines local values for consistent usage throughout the module.
# All resources should reference local.* instead of var.* for better maintainability.
#
# Sections:
# 1. Module Metadata
# 2. Naming and Identification
# 3. Tag Management (Customer-Aware)
# ==============================================================================

locals {
  # ============================================================================
  # SECTION 1: MODULE METADATA
  # ============================================================================
  
  module = "vpc"
  family = "network"
  
  # ============================================================================
  # SECTION 2: NAMING AND IDENTIFICATION
  # ============================================================================
  
  # Determine if this VPC is customer-specific or shared
  is_customer_vpc = var.customer_id != null
  
  # Resource naming follows Forge conventions:
  # - Shared VPCs: forge-{workspace}-{environment}
  # - Customer VPCs: {customer_name}-{region}
  resource_prefix = local.is_customer_vpc ? "${var.customer_name}-${var.aws_region}" : "forge-${var.workspace}-${var.environment}"
  
  # ============================================================================
  # SECTION 3: TAG MANAGEMENT (Customer-Aware)
  # ============================================================================
  
  # Base tags applied to all Forge resources
  base_tags = {
    ManagedBy        = "Forge"
    Module           = local.module
    Family           = local.family
    Workspace        = var.workspace
    Environment      = var.environment
    Region           = var.aws_region
    ArchitectureType = var.architecture_type
  }
  
  # Customer-specific tags (only applied when customer_id is provided)
  customer_tags = local.is_customer_vpc ? {
    CustomerId   = var.customer_id
    CustomerName = var.customer_name
    PlanTier     = var.plan_tier != null ? var.plan_tier : "unknown"
  } : {}
  
  # VPC-specific tags
  vpc_tags = {
    Name = var.vpc_name
    CIDR = var.cidr_block
  }
  
  # Merge all tags: base + customer + vpc-specific + user-provided
  common_tags = merge(
    local.base_tags,
    local.customer_tags,
    var.common_tags
  )
}

# ==============================================================================
# Forge Tagging Strategy:
# ==============================================================================
# - All resources include ManagedBy = "Forge" for identification
# - Customer VPCs include CustomerId and CustomerName for cost allocation
# - Architecture type determines resource isolation level
# - Tags enable accurate cost reporting by customer and plan tier
# ==============================================================================
