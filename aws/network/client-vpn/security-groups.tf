# ==============================================================================
# AWS Client VPN Module - Security Groups
# ==============================================================================
# This file creates a security group for VPN endpoint access control.
# Controls which VPC resources VPN clients can access.
# ==============================================================================

# ------------------------------------------------------------------------------
# VPN Access Security Group
# ------------------------------------------------------------------------------

resource "aws_security_group" "vpn_access" {
  count = var.create_security_group ? 1 : 0

  name_prefix = "${local.security_group_name}-"
  description = "Security group for AWS Client VPN access to VPC resources"
  vpc_id      = var.vpc_id

  tags = merge(
    local.merged_tags,
    {
      Name = local.security_group_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------------------------
# Egress Rules - Allow VPN Clients to Access VPC Resources
# ------------------------------------------------------------------------------

# Allow all outbound traffic to VPC CIDR
resource "aws_vpc_security_group_egress_rule" "vpc_all" {
  count = var.create_security_group ? 1 : 0

  security_group_id = aws_security_group.vpn_access[0].id
  description       = "Allow VPN clients to access all resources in VPC"

  ip_protocol = "-1"
  cidr_ipv4   = var.vpc_cidr_block

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.security_group_name}-vpc-all"
    }
  )
}

# ------------------------------------------------------------------------------
# Specific Egress Rules (Examples - Commented Out)
# ------------------------------------------------------------------------------

# Uncomment and customize these rules for more restrictive access

# HTTPS to VPC resources
# resource "aws_vpc_security_group_egress_rule" "https" {
#   count = var.create_security_group ? 1 : 0
#
#   security_group_id = aws_security_group.vpn_access[0].id
#   description       = "Allow HTTPS to VPC resources"
#
#   ip_protocol = "tcp"
#   from_port   = 443
#   to_port     = 443
#   cidr_ipv4   = var.vpc_cidr_block
# }

# SSH to EC2 instances
# resource "aws_vpc_security_group_egress_rule" "ssh" {
#   count = var.create_security_group ? 1 : 0
#
#   security_group_id = aws_security_group.vpn_access[0].id
#   description       = "Allow SSH to EC2 instances"
#
#   ip_protocol = "tcp"
#   from_port   = 22
#   to_port     = 22
#   cidr_ipv4   = var.vpc_cidr_block
# }

# PostgreSQL to RDS
# resource "aws_vpc_security_group_egress_rule" "postgresql" {
#   count = var.create_security_group ? 1 : 0
#
#   security_group_id = aws_security_group.vpn_access[0].id
#   description       = "Allow PostgreSQL to RDS"
#
#   ip_protocol = "tcp"
#   from_port   = 5432
#   to_port     = 5432
#   cidr_ipv4   = var.vpc_cidr_block
# }

# Redis to ElastiCache
# resource "aws_vpc_security_group_egress_rule" "redis" {
#   count = var.create_security_group ? 1 : 0
#
#   security_group_id = aws_security_group.vpn_access[0].id
#   description       = "Allow Redis to ElastiCache"
#
#   ip_protocol = "tcp"
#   from_port   = 6379
#   to_port     = 6379
#   cidr_ipv4   = var.vpc_cidr_block
# }

# Kubernetes API to EKS
# resource "aws_vpc_security_group_egress_rule" "kubernetes_api" {
#   count = var.create_security_group ? 1 : 0
#
#   security_group_id = aws_security_group.vpn_access[0].id
#   description       = "Allow Kubernetes API access to EKS"
#
#   ip_protocol = "tcp"
#   from_port   = 443
#   to_port     = 443
#   cidr_ipv4   = var.vpc_cidr_block
# }

# ------------------------------------------------------------------------------
# Ingress Rules (Usually Not Required for VPN)
# ------------------------------------------------------------------------------

# VPN endpoints typically don't need ingress rules since connections are
# outbound from VPN clients. However, if you need to allow VPC resources
# to initiate connections to VPN clients (rare), add ingress rules here.

# ==============================================================================
# Security Group Best Practices:
# ==============================================================================
# - Start with broad access (all VPC), then restrict based on actual usage
# - Use the principle of least privilege - only allow required ports/protocols
# - Consider separate security groups for different user groups
# - Monitor VPC Flow Logs to understand actual traffic patterns
# - Use security group references instead of CIDR blocks where possible
# - Tag security groups for easy identification and management
# - Regularly audit and remove unused security group rules
# ==============================================================================
