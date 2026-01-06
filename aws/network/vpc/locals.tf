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
  # SECTION 2: NAMING AND IDENTIFICATION (Multi-Tenant Pattern)
  # ============================================================================
  
  # Detect multi-tenancy level
  has_customer = var.customer_name != null
  has_project  = var.project_name != null
  
  # Three naming scenarios:
  # 1. Shared: forge-{environment}-vpc
  # 2. Customer: forge-{environment}-{customer}-vpc
  # 3. Project: forge-{environment}-{customer}-{project}-vpc
  
  name_prefix = local.has_project ? "forge-${var.environment}-${var.customer_name}-${var.project_name}" : (
    local.has_customer ? "forge-${var.environment}-${var.customer_name}" : "forge-${var.environment}"
  )
  
  vpc_name_computed = "${local.name_prefix}-vpc"
  
  # ============================================================================
  # SECTION 3: TAG MANAGEMENT (Multi-Tenant)
  # ============================================================================
  
  # Base tags applied to all Forge resources
  base_tags = {
    ManagedBy   = "Terraform"
    Module      = local.module
    Family      = local.family
    Workspace   = var.workspace
    Environment = var.environment
  }
  
  # Customer and project tags (conditional)
  customer_tags = local.has_customer ? {
    Customer = var.customer_name
  } : {}
  
  project_tags = local.has_project ? {
    Project = var.project_name
  } : {}
  
  # Customer ID tag (optional for billing)
  customer_id_tags = var.customer_id != null ? {
    CustomerId = var.customer_id
  } : {}
  
  # Plan tier tag (optional for cost allocation)
  plan_tier_tags = var.plan_tier != null ? {
    PlanTier = var.plan_tier
  } : {}
  
  # VPC-specific tags
  vpc_tags = {
    Name = var.vpc_name
    CIDR = var.cidr_block
  }
  
  # Merge all tags: base + customer + project + customer_id + plan_tier + vpc + user-provided
  common_tags = merge(
    local.base_tags,
    local.customer_tags,
    local.project_tags,
    local.customer_id_tags,
    local.plan_tier_tags,
    var.common_tags
  )
}

# ==============================================================================
# Multi-Tenant Tagging Strategy:
# ==============================================================================
# - All resources include Workspace and Environment for auto-discovery
# - Customer tag added when customer_name is provided
# - Project tag added when project_name is provided
# - Optional CustomerId for billing integration
# - Optional PlanTier for cost allocation
# - Tags enable auto-discovery by downstream modules (EKS, RDS, Redis, ALB)
# ==============================================================================
