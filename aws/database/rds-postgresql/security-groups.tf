# ==============================================================================
# RDS PostgreSQL Module - Security Groups
# ==============================================================================
# This file creates security groups for RDS and configures EKS integration.
# ==============================================================================

# ------------------------------------------------------------------------------
# RDS Security Group
# ------------------------------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${local.db_identifier}-sg"
  description = "Security group for ${local.db_identifier} RDS PostgreSQL"
  vpc_id      = data.aws_vpc.main.id

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.db_identifier}-sg"
    }
  )
}

# ------------------------------------------------------------------------------
# Ingress Rules
# ------------------------------------------------------------------------------

# Allow PostgreSQL access from EKS nodes (if EKS cluster exists)
resource "aws_security_group_rule" "rds_from_eks" {
  count = local.eks_node_security_group_id != null ? 1 : 0

  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = local.eks_node_security_group_id
  security_group_id        = aws_security_group.rds.id
  description              = "Allow PostgreSQL access from EKS nodes"
}

# Allow PostgreSQL access from self (for RDS internal operations)
resource "aws_security_group_rule" "rds_from_self" {
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.rds.id
  description       = "Allow PostgreSQL access from self"
}

# ------------------------------------------------------------------------------
# Egress Rules
# ------------------------------------------------------------------------------

# RDS instances typically don't need outbound connectivity
# Only allowing internal VPC communication if needed
resource "aws_security_group_rule" "rds_egress_vpc" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.main.cidr_block]
  security_group_id = aws_security_group.rds.id
  description       = "Allow outbound to VPC"
}
