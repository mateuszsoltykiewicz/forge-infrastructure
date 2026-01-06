# ==============================================================================
# SSM Parameter Module - Local Values
# ==============================================================================
# This file defines local values for computed resource attributes.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Parameter Path Generation
  # ------------------------------------------------------------------------------

  # Automatic hierarchical path: /ENV/resource-type/resource-id/parameter-name
  # Example: /production/database/forge-production-db/host
  automatic_path = join("/", compact([
    "",
    var.environment,
    var.resource_type,
    var.resource_id,
    var.parameter_name
  ]))

  # Use custom path if provided, otherwise use automatic hierarchical path
  parameter_full_path = var.custom_path != null ? var.custom_path : local.automatic_path

  # ------------------------------------------------------------------------------
  # Parameter Naming
  # ------------------------------------------------------------------------------

  # Parameter name for display purposes
  parameter_display_name = basename(local.parameter_full_path)

  # ------------------------------------------------------------------------------
  # Tagging Strategy
  # ------------------------------------------------------------------------------

  # Detect multi-tenant context
  has_customer = var.customer_name != null && var.customer_name != ""
  has_project  = var.project_name != null && var.project_name != ""

  # Base tags applied to all resources
  base_tags = {
    Environment     = var.environment
    ManagedBy       = "terraform"
    TerraformModule = "configuration/ssm-parameter"
    Region          = var.region
    ParameterType   = var.parameter_type
    ParameterTier   = var.parameter_tier
    ResourceType    = var.resource_type
  }

  # Customer-specific tags
  customer_tags = local.has_customer ? {
    CustomerName = var.customer_name
    PlanTier     = var.plan_tier
  } : {}

  # Project-specific tags
  project_tags = local.has_project ? {
    ProjectName = var.project_name
  } : {}

  # Merge all tags
  merged_tags = merge(
    local.base_tags,
    local.customer_tags,
    local.project_tags,
    var.tags
  )
}
