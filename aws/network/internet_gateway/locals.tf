# ==============================================================================
# Internet Gateway Module - Local Values
# ==============================================================================
# Computes derived values for resource naming, tagging, and configuration.
# ==============================================================================

locals {

  igw_name = "${var.common_prefix}-igw"

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
