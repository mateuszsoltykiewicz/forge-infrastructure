# ------------------------------------------------------------------------------
# Security group for Firewal tiering based communication
# ------------------------------------------------------------------------------

module "endpoint_security_group" {
  source = "../../security/security-group"
  count  = local.security_group_required ? 1 : 0

  vpc_id = data.aws_vpc.main.id

  # Add service type to common_prefix to ensure unique SG names per VPC endpoint type
  common_prefix = "${var.common_prefix}-${local.service_short_name_sanitized}"
  environment   = "shared"

  firewall_tier = var.firewall_tier
  firewall_type = var.firewall_type
  purpose       = local.service_short_name_sanitized
  ports         = [443]

  common_tags = var.common_tags
}