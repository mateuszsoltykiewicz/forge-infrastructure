# ==============================================================================
# Client VPN Module - Dedicated Subnets
# ==============================================================================
# Creates dedicated subnets for Client VPN network associations using subnet module
# ==============================================================================

module "client_vpn_subnets" {
  source = "../../network/subnet"

  vpc_id             = data.aws_vpc.main.id
  subnet_cidrs       = var.subnet_cidrs
  availability_zones = var.availability_zones

  common_prefix = var.common_prefix
  environment   = "shared"
  purpose       = "vpn"

  common_tags = var.common_tags
}