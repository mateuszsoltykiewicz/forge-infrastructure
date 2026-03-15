#
# Application Load Balancer Module - Local Variables
# Purpose: Computed values and validation logic
#

# ==============================================================================
# Data Sources
# ==============================================================================

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# ==============================================================================
# Local Values
# ==============================================================================

locals {

  # Get current region from data source
  current_region = data.aws_region.current.id

  # ========================================
  # Naming Convention (Pattern A)
  # ========================================
  # Note: common_prefix = "{customer}-{project}-{environment}"
  # For path-like naming: replace "-" with "/"
  # For ALB/resource names: use PascalCase (no hyphens)

  # Path-like prefix for resources (replace hyphens with slashes)
  path_prefix = replace(var.common_prefix, "-", "/")

  # PascalCase prefix for resource names (capitalize each word, remove hyphens)
  pascal_prefix = join("", [for part in split("-", var.common_prefix) : title(part)])

  # ALB name (PascalCase, max 32 characters)
  alb_name = substr("${local.pascal_prefix}Alb", 0, 32)

<<<<<<< HEAD
  # Subdomain for each environment
  # production -> project-backend.com
  # staging -> staging.project-backend.com
  subdomains = [
    for env in local.environments :
    env == "Production" || env == "Shared" ? var.domain_name : "${env}.${var.domain_name}"
  ]
=======
  # Target group name prefixes (PascalCase, max 25 characters)
  tg_name_prefixes = substr("${local.pascal_prefix}Tg", 0, 25)
>>>>>>> b8c3fda (commit)

  # ========================================
  # Access Logs Configuration
  # ========================================

  # Access logs validation
  access_logs_valid = !var.enable_access_logs || var.access_logs_bucket != null

  # Access logs configuration
  access_logs_config = var.enable_access_logs ? {
    bucket  = var.access_logs_bucket
    prefix  = var.access_logs_prefix
    enabled = true
  } : null

  # ========================================
  # Resource Tags
  # ========================================

  # Module-specific tags (only ALB-specific metadata)
  module_tags = {
    TerraformModule = "forge/aws/load-balancing/alb"
    Module          = "ALB"
    Family          = "LoadBalancing"
    Visibility      = "internet-facing"
  }

  # Merge common tags from root + module-specific tags
  merged_tags = merge(
    var.common_tags,   # Common tags from root (ManagedBy, Workspace, Region, etc.)
    local.module_tags, # Module-specific tags
  )
}
