# ==============================================================================
# LOCAL VALUES - Subnet Module (Forge - Customer-Centric)
# ==============================================================================

locals {
  # ============================================================================
  # SECTION 1: MODULE METADATA
  # ============================================================================
  
  module = "subnet"
  family = "network"
  
  # ============================================================================
  # SECTION 2: CUSTOMER CONTEXT
  # ============================================================================
  
  # Determine if this is a customer-specific deployment
  is_customer_vpc = var.customer_id != null
  
  # ============================================================================
  # SECTION 3: SUBNET ORGANIZATION
  # ============================================================================
  
  # Check for public and private subnets
  has_public_subnets  = length([for s in var.subnets : s if lower(s.tier) == "public"]) > 0
  has_private_subnets = length([for s in var.subnets : s if lower(s.tier) == "private"]) > 0
  
  # Collect unique purposes for each tier
  public_purposes = distinct([
    for s in var.subnets : s.purpose
    if lower(s.tier) == "public"
  ])
  
  private_purposes = distinct([
    for s in var.subnets : s.purpose
    if lower(s.tier) == "private"
  ])
  
  # ============================================================================
  # SECTION 4: TAG MANAGEMENT (Customer-Aware)
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
  
  # Subnet-specific tags
  subnet_tags = {
    VpcId   = var.vpc_id
    VpcName = var.vpc_name
  }
  
  # Merge all tags: base + customer + subnet-specific + user-provided
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
# - Customer subnets include CustomerId and CustomerName for cost allocation
# - Tier and Purpose tags enable filtering and organization
# - Route tables tagged with associated subnet purposes
# ==============================================================================
