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
  has_customer = var.customer_name != null && var.customer_name != ""
  has_project  = var.project_name != null && var.project_name != ""

  # Internet Gateway naming based on multi-tenant pattern
  # 1. Shared: {vpc_name}-igw
  # 2. Customer: {vpc_name}-igw (vpc_name already includes customer)
  # 3. Project: {vpc_name}-igw (vpc_name already includes customer and project)
  igw_name = "${var.vpc_name}-igw"

  # Base tags (always applied)
  base_tags = {
    ManagedBy   = "Terraform"
    Module      = local.module
    Family      = local.family
    Workspace   = var.workspace
    Environment = var.environment
    Region      = var.aws_region
  }

  # Customer-specific tags
  customer_tags = local.has_customer ? {
    Customer = var.customer_name
  } : {}

  project_tags = local.has_project ? {
    Project = var.project_name
  } : {}

  # IGW-specific tags
  igw_tags = {
    ResourceType = "InternetGateway"
    Purpose      = "PublicInternetAccess"
  }

  # Combined tags
  merged_tags = merge(
    local.base_tags,
    local.customer_tags,
    local.project_tags,
    var.merged_tags
  )
}
