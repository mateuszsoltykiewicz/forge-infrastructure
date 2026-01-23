# ==============================================================================
# RDS PostgreSQL Module - Subnets (via CIDR Calculator)
# ==============================================================================
# Uses intelligent CIDR calculation to prevent subnet conflicts
# ==============================================================================

# ------------------------------------------------------------------------------
# RDS Private Subnets (via Subnet Module)
# ------------------------------------------------------------------------------

module "rds_subnets" {
  source = "../../network/subnet"

  vpc_id = var.vpc_id

  # Use calculated CIDRs from calculator
  subnet_cidrs       = var.subnet_cidrs
  availability_zones = var.availability_zones

  # Tagging
  common_prefix = var.common_prefix
  environment   = var.environment
  purpose       = "rds"

  common_tags = merge(
    local.merged_tags,
    {
      Tier = "RDS"
      Type = "Private"
    }
  )
}
