# ==============================================================================
# ElastiCache Redis Module - Subnets (via CIDR Calculator)
# ==============================================================================
# Uses intelligent CIDR calculation to prevent subnet conflicts
# ==============================================================================

# ------------------------------------------------------------------------------
# Redis Private Subnets (via Subnet Module)
# ------------------------------------------------------------------------------

module "redis_subnets" {
  source = "../../network/subnet"

  vpc_id = var.vpc_id

  # Use calculated CIDRs from calculator
  subnet_cidrs       = var.subnet_cidrs
  availability_zones = var.availability_zones

  # Tagging
  common_prefix = var.common_prefix
  purpose       = "Redis"
  tier          = "Private"

  common_tags = local.merged_tags
}