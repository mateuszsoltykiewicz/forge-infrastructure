# ==============================================================================
# ElastiCache Redis Module - Security Groups
# ==============================================================================
# This file creates security groups for Redis with automatic EKS integration.
# ==============================================================================

# ------------------------------------------------------------------------------
# Redis Security Group
# ------------------------------------------------------------------------------

resource "aws_security_group" "redis" {
  name_prefix = "${local.replication_group_id}-"
  description = "Security group for ElastiCache Redis ${local.replication_group_id}"
  vpc_id      = data.aws_vpc.main.id

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.replication_group_id}-redis"
      Type = "redis"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------------------------
# Ingress Rule: Allow Redis port from EKS Nodes (if EKS cluster exists)
# ------------------------------------------------------------------------------

resource "aws_security_group_rule" "redis_from_eks" {
  count = local.eks_node_security_group_id != "" ? 1 : 0

  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = local.eks_node_security_group_id
  security_group_id        = aws_security_group.redis.id

  description = "Allow Redis access from EKS nodes (${local.eks_cluster_name})"
}

# ------------------------------------------------------------------------------
# Ingress Rule: Allow Redis port from self (for replication)
# ------------------------------------------------------------------------------

resource "aws_security_group_rule" "redis_self" {
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.redis.id

  description = "Allow Redis replication within cluster"
}

# ------------------------------------------------------------------------------
# Egress Rule: Deny all outbound (Redis doesn't need outbound)
# ------------------------------------------------------------------------------

# Note: ElastiCache manages replication internally, so we don't need egress rules
# AWS automatically allows egress for ElastiCache service communication
