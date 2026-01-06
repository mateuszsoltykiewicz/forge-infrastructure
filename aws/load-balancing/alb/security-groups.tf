# ==============================================================================
# ALB Module - Security Groups
# ==============================================================================
# This file creates security groups for ALB and configures EKS integration.
# ==============================================================================

# ------------------------------------------------------------------------------
# ALB Security Group
# ------------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${local.alb_name}-sg"
  description = "Security group for ${local.alb_name} Application Load Balancer"
  vpc_id      = data.aws_vpc.main.id

  tags = merge(
    local.all_tags,
    {
      Name = "${local.alb_name}-sg"
    }
  )
}

# ------------------------------------------------------------------------------
# Ingress Rules
# ------------------------------------------------------------------------------

# Allow HTTP from anywhere (for internet-facing ALBs)
resource "aws_security_group_rule" "alb_http_ingress" {
  count = !var.internal ? 1 : 0

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = var.ip_address_type != "ipv4" ? ["::/0"] : null
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from internet"
}

# Allow HTTPS from anywhere (for internet-facing ALBs)
resource "aws_security_group_rule" "alb_https_ingress" {
  count = !var.internal ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = var.ip_address_type != "ipv4" ? ["::/0"] : null
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from internet"
}

# Allow HTTP from VPC (for internal ALBs)
resource "aws_security_group_rule" "alb_http_internal" {
  count = var.internal ? 1 : 0

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.main.cidr_block]
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from VPC"
}

# Allow HTTPS from VPC (for internal ALBs)
resource "aws_security_group_rule" "alb_https_internal" {
  count = var.internal ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.main.cidr_block]
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from VPC"
}

# ------------------------------------------------------------------------------
# Egress Rules
# ------------------------------------------------------------------------------

# Allow all outbound traffic to EKS nodes (for health checks and forwarding)
resource "aws_security_group_rule" "alb_to_eks" {
  count = local.eks_node_security_group_id != null ? 1 : 0

  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = local.eks_node_security_group_id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow traffic to EKS nodes"
}

# Allow all outbound traffic to VPC (fallback if no EKS)
resource "aws_security_group_rule" "alb_to_vpc" {
  count = local.eks_node_security_group_id == null ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.main.cidr_block]
  security_group_id = aws_security_group.alb.id
  description       = "Allow traffic to VPC"
}

# ------------------------------------------------------------------------------
# EKS Node Security Group - Allow traffic from ALB
# ------------------------------------------------------------------------------

# Allow traffic from ALB to EKS nodes on all ports (for target groups)
resource "aws_security_group_rule" "eks_from_alb" {
  count = local.eks_node_security_group_id != null ? 1 : 0

  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = local.eks_node_security_group_id
  description              = "Allow traffic from ALB"
}
