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

  common_prefix = local.pascal_prefix

  purpose = "rds-postgresql"
  ports   = [var.port]

  ingress_rules = [
    {
      from_port   = var.port
      to_port     = var.port
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
      description = "Allow PostgreSQL from VPC (EKS pods, VPN clients)"
    }
  ]

  egress_rules = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
      description = "Allow HTTPS to VPC endpoints (CloudWatch, Performance Insights)"
    }
  ]

  common_tags = var.common_tags
}