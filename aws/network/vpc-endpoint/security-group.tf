# ------------------------------------------------------------------------------
# Security group for Firewal tiering based communication
# ------------------------------------------------------------------------------

module "endpoint_security_group" {
  source = "../../security/security-group"
  count  = local.security_group_required ? 1 : 0

  vpc_id = data.aws_vpc.main.id

  # Add service type to common_prefix to ensure unique SG names per VPC endpoint type
  common_prefix = "${var.common_prefix}-${local.service_short_name_sanitized}"
  purpose       = local.service_short_name_sanitized
  ports         = [443]

  ingress_rules = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
      description = "Allow HTTPS from VPC to ${local.service_short_name}"
    }
  ]

  egress_rules = [] # VPC endpoints are unidirectional

  common_tags = var.common_tags
}