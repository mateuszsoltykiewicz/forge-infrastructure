# ==============================================================================
# ALB Module - Subnets (via CIDR Calculator)
# ==============================================================================
# Uses intelligent CIDR calculation to prevent subnet conflicts
# Public subnets with Internet Gateway for ALB internet-facing deployment
# ==============================================================================

# ------------------------------------------------------------------------------
# ALB Public Subnets
# ------------------------------------------------------------------------------

module "alb_subnet" {
  source = "../../network/subnet"

  vpc_id = var.vpc_id

  # Use calculated CIDRs from calculator
  subnet_cidrs       = var.subnet_cidrs
  availability_zones = var.availability_zones

  # Tagging
  common_prefix = var.common_prefix
  purpose       = "ALB"
  tier          = "Public"

  # Tags configuration
  common_tags = local.merged_tags

  # Public subnet routing
  internet_gateway_id = var.internet_gateway_id
}
