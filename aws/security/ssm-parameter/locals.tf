# ==============================================================================
# SSM Parameter Module - Local Values
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Parameter Path Generation
  # ------------------------------------------------------------------------------

  # Automatic hierarchical path using common_prefix
  # Pattern: /common-prefix/resource-type/parameter-name
  # Example: /forge-prod-acme-webapp/database/host
  automatic_path = var.custom_path != null ? var.custom_path : join("/", compact([
    "",
    replace(var.common_prefix, "-", "/"),
    var.resource_type,
    var.parameter_name
  ]))

  # Use custom path if provided, otherwise use automatic hierarchical path
  parameter_full_path = local.automatic_path

  # ------------------------------------------------------------------------------
  # Parameter Naming
  # ------------------------------------------------------------------------------

  # Parameter name for display purposes
  parameter_display_name = basename(local.parameter_full_path)

  # ------------------------------------------------------------------------------
  # Tagging Strategy (Pattern A)
  # ------------------------------------------------------------------------------

  # Module-specific tags (only SSM metadata)
  module_tags = {
    TerraformModule = "forge/aws/security/ssm-parameter"
    ParameterType   = var.parameter_type
    ParameterTier   = var.parameter_tier
    ResourceType    = var.resource_type
    ParameterName   = var.parameter_name
  }

  # Merge common_tags from root + module-specific tags
  merged_tags = merge(
    var.common_tags,
    local.module_tags
  )

  # ------------------------------------------------------------------------------
  # KMS Encryption Validation
  # ------------------------------------------------------------------------------

  # SecureString requires KMS key
  requires_kms = var.parameter_type == "SecureString"
  has_kms_key  = var.kms_key_id != null

  kms_validation_passed = !local.requires_kms || local.has_kms_key
}