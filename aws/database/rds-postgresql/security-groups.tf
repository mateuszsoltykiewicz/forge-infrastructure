# ==============================================================================
# RDS PostgreSQL Module - Security Groups
# ==============================================================================
# This file creates security groups for RDS and configures EKS integration.
# ==============================================================================

# ------------------------------------------------------------------------------
# RDS Security Group
# ------------------------------------------------------------------------------

module "rds_security_group" {
  source = "../../security/security-group"

  vpc_id = data.aws_vpc.main.id

  common_prefix = var.common_prefix
  environment   = var.environment

  firewall_tier = var.firewall_tier
  firewall_type = var.firewall_type
  purpose       = "rds-postgresql"
  ports         = [var.port]

  common_tags = var.common_tags
}