# ==============================================================================
# NAT Gateway Module - Local Values
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Pattern A: Common Prefix Transformations
  # ------------------------------------------------------------------------------

  # PascalCase prefix for resource names (e.g., "AcmeForgeDevNetworkNatGw")
  pascal_prefix = join("", [for part in split("-", var.common_prefix) : title(part)])

  # Path-like prefix (e.g., "/acme/forge/dev/network/")
  path_prefix = "/${replace(var.common_prefix, "-", "/")}/"

  # NAT Gateway name prefix (PascalCase)
  nat_name_prefix = "${local.pascal_prefix}NatGw"

  # Module-specific tags
  module_tags = {
    TerraformModule = "forge/aws/network/nat-gateway"
    Module          = "NatGateway"
    Family          = "Network"
  }

  # Merged tags
  merged_tags = merge(
    var.common_tags,
    local.module_tags
  )
}
