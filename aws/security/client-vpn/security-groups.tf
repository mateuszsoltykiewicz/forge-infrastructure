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
  purpose       = "client-vpn"
  ports         = [local.vpn_port]

  ingress_rules = [
    {
      from_port   = local.vpn_port
      to_port     = local.vpn_port
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow VPN connections from internet"
    }
  ]

  egress_rules = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
      description = "Allow HTTPS (EKS API, VPC endpoints)"
    },
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
      description = "Allow PostgreSQL access"
    },
    {
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
      description = "Allow Redis access"
    }
  ]

  common_tags = var.common_tags
}