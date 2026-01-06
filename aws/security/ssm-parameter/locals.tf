# ==============================================================================
# SSM Parameter Module - Local Values
# ==============================================================================
# This file defines local values for computed resource attributes.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Parameter Path Generation
  # ------------------------------------------------------------------------------

  # Determine if this is shared or dedicated architecture
  is_shared_architecture = var.architecture_type == "shared"

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

  # Customer-specific tags (only applied for dedicated architectures)
  customer_tags = !local.is_shared_architecture ? {
    CustomerId       = var.customer_id
    CustomerName     = var.customer_name
    ArchitectureType = var.architecture_type
    PlanTier         = var.plan_tier
  } : {}

  # Merge all tags
  merged_tags = merge(
    local.base_tags,
    local.customer_tags,
    var.tags
  )
}
