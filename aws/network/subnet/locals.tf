# ==============================================================================
# Subnet Module - Local Values
# ==============================================================================
# Computes derived values for resource naming, tagging, and configuration.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Subnet Name Construction with Validation and Sanitization
  # ------------------------------------------------------------------------------

  # Step 1: Build raw subnet base name (AZ will be appended per-subnet)
  raw_subnet_base = "${var.purpose}-${var.tier}-${var.common_prefix}"

  # Step 2: Sanitize - lowercase and replace invalid characters with hyphens
  # Subnet names (via tags) allow any UTF-8, but we enforce consistency
  sanitized_subnet_base = lower(replace(replace(local.raw_subnet_base, "/[^a-z0-9-]/", "-"), "/--+/", "-"))

  # Step 3: Apply AWS 255-character limit (will be checked per-subnet with AZ appended)
  subnet_base = substr(local.sanitized_subnet_base, 0, 200) # Reserve 55 chars for AZ suffix

  # Step 4: Validation checks for base name
  base_validation = {
    length_ok      = length(local.subnet_base) <= 200
    pattern_ok     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", local.subnet_base))
    no_double_dash = !can(regex("--", local.subnet_base))
    not_empty      = length(local.subnet_base) > 0
  }

  # Step 5: Generate per-subnet names with AZ appended
  subnet_names = [
    for idx, az in var.availability_zones :
    "subnet-${az}-${local.subnet_base}"
  ]

  # Step 6: Per-subnet validation (ensure each full name fits in 255 chars)
  subnet_validations = {
    for idx, name in local.subnet_names :
    idx => {
      length_ok      = length(name) <= 255
      pattern_ok     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", name))
      no_double_dash = !can(regex("--", name))
    }
  }

  # Base tags (always applied)
  module_tags = {
    TerraformModule = "forge/aws/network/subnet"
    Module          = "Subnet"
    Family          = "Network"
    Purpose         = var.purpose
    Tier            = var.tier
  }

  # Combined tags
  merged_tags = merge(
    var.common_tags,
    local.module_tags
  )
}
