# ==============================================================================
# AWS Client VPN Module - Security Groups
# ==============================================================================
# This file creates a security group for VPN endpoint access control.
# Controls which VPC resources VPN clients can access.
# ==============================================================================

# ------------------------------------------------------------------------------
# VPN Access Security Group
# ------------------------------------------------------------------------------

module "vpn_security_group" {
  source = "../security-group"

  vpc_id = data.aws_vpc.main.id

  common_prefix = var.common_prefix

  firewall_tier = var.firewall_tier
  firewall_type = var.firewall_type
  purpose       = "client-vpn"
  ports         = [local.vpn_port]

  common_tags = var.common_tags
}

# ------------------------------------------------------------------------------
# Egress Rules - Allow VPN Clients to Access VPC Resources
# ------------------------------------------------------------------------------

# Kubernetes API to EKS
resource "aws_vpc_security_group_egress_rule" "kubernetes_api" {

  security_group_id = module.vpn_security_group.security_group_id
  description       = "Allow Kubernetes API access to EKS"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = data.aws_vpc.main.cidr_block
}