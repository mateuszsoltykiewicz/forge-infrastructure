# ==============================================================================
# ALB Module - Subnets (via CIDR Calculator)
# ==============================================================================
# Uses intelligent CIDR calculation to prevent subnet conflicts
# Public subnets with Internet Gateway for ALB internet-facing deployment
# Tagged for AWS Load Balancer Controller discovery
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
  purpose       = "alb"
  tier          = "Public"

  # Tags configuration - AWS Load Balancer Controller discovery
  common_tags = merge(
    local.merged_tags,
    {
      "kubernetes.io/role/elb" = "1" # Required for AWS LB Controller to discover public subnets for internet-facing ALB/NLB
    }
  )

  # Public subnet routing
  internet_gateway_id = var.internet_gateway_id
}
