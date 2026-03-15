# ==============================================================================
# LOCAL VALUES - VPC Module (Forge - Customer-Centric)
# ==============================================================================
# This file defines local values for consistent usage throughout the module.
# All resources should reference local.* instead of var.* for better maintainability.
#
# Sections:
# 1. Pattern A Transformations
# 2. Naming and Identification
# 3. Tag Management (Customer-Aware)
# ==============================================================================

locals {

  # ============================================================================
  # SECTION 1: PATTERN A TRANSFORMATIONS
  # ============================================================================

  # PascalCase prefix for resource names (e.g., "AcmeForgeDevNetworkVpc")
  pascal_prefix = join("", [for part in split("-", var.common_prefix) : title(part)])

  # Path-like prefix (e.g., "/acme/forge/dev/network/")
  path_prefix = "/${replace(var.common_prefix, "-", "/")}/"

  # ============================================================================
  # SECTION 2: NAMING AND IDENTIFICATION
  # ============================================================================

  # VPC name (PascalCase)
  vpc_name = "${local.pascal_prefix}Vpc"

  # ============================================================================
  # SECTION 3: TAG MANAGEMENT (Multi-Tenant)
  # ============================================================================

  # Module-specific tags (only VPC-specific metadata)
  module_tags = {
    TerraformModule = "forge/aws/network/vpc"
    Module          = "VPC"
    Family          = "Network"
    CIDR            = var.cidr_block
  }

  # Merge common tags from root + module-specific tags
  merged_tags = merge(
    var.common_tags,   # Common tags from root (ManagedBy, Region, etc.)
    local.module_tags, # Module-specific tags
  )
}

# ==============================================================================
# Tag Management Strategy:
# ==============================================================================
# - common_tags: Passed from root module (ManagedBy, Workspace, Region, DomainName, 
#                Customer, Project, Environment)
# - module_tags: VPC-specific metadata (Module, Family, Name, CIDR)
# ==============================================================================
