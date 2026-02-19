#
# Application Load Balancer Module - Local Variables
# Purpose: Computed values and validation logic
#

locals {

  # Get current region from tags
  current_region = var.common_tags["CurrentRegion"]

  # ========================================
  # Multi-Tenant Naming Convention
  # ========================================

  # If var.environments is empty set environment to tag value "Workspace" else set to var.environments
  environments = length(var.environments) > 0 ? var.environments : [var.common_tags["Workspace"]]

  # Generate ALB names for each environment (max 32 characters):
  # Pattern: {common_prefix}-{environment}-alb
  # Example: san-cro-p-use1-production-alb
  alb_names = [
    for env in local.environments :
    substr("alb-${env}-${var.common_prefix}", 0, 32)
  ]

  # Target group name prefixes for each environment (max 25 characters)
  tg_name_prefixes = [
    for env in local.environments :
    substr("tg-${env}-${var.common_prefix}", 0, 25)
  ]

  # Subdomain for each environment
  # production -> project-backend.com
  # staging -> staging.project-backend.com
  subdomains = [
    for env in local.environments :
    env == "Production" || env == "Shared" ? var.domain_name : "${env}.${var.domain_name}"
  ]

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
