# ==============================================================================
# Internet Gateway Module - Local Values
# ==============================================================================
# Computes derived values for resource naming, tagging, and configuration.
# ==============================================================================

locals {

  # ------------------------------------------------------------------------------
  # Pattern A: Common Prefix Transformations
  # ------------------------------------------------------------------------------

  # PascalCase prefix for resource names (e.g., "AcmeForgeDevNetworkIgw")
  pascal_prefix = join("", [for part in split("-", var.common_prefix) : title(part)])

  # Path-like prefix (e.g., "/acme/forge/dev/network/")
  path_prefix = "/${replace(var.common_prefix, "-", "/")}/"

  # IGW name (PascalCase)
  igw_name = "${local.pascal_prefix}Igw"

  # Base tags (always applied)
  module_tags = {
    TerraformModule = "forge/aws/network/internet_gateway"
    Module          = "InternetGateway"
    Family          = "Network"
  }

  # Combined tags
  merged_tags = merge(
    var.common_tags,
    local.module_tags
  )
}
