# ==============================================================================
# ElastiCache Redis Module - Security Groups
# ==============================================================================
# This file creates security groups for Redis with automatic EKS integration.
# ==============================================================================

# ------------------------------------------------------------------------------
# Redis Security Group
# ------------------------------------------------------------------------------

module "redis_security_group" {
  source = "../../security/security-group"

  vpc_id = data.aws_vpc.main.id

  common_prefix = var.common_prefix

  purpose       = "Redis"
  ports         = [var.port]

  common_tags = var.common_tags
}