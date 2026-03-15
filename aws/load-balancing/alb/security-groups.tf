# ==============================================================================
# ALB Module - Security Groups
# ==============================================================================
# Creates one security group per environment to isolate ALB traffic.
# Each environment (production, staging, development) has its own security group.
# ==============================================================================

data "aws_vpc" "main" {
  id = var.vpc_id
}

module "security_group" {
  source = "../../security/security-group"

  vpc_id = var.vpc_id

  # Use original common_prefix (no modification needed - environment handles uniqueness)
  common_prefix = var.common_prefix
  purpose       = "alb"
  ports         = [var.http_listener.port, var.https_listener.port]

  ingress_rules = [
    {
      from_port   = var.http_listener.port
      to_port     = var.http_listener.port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTP from internet"
    },
    {
      from_port   = var.https_listener.port
      to_port     = var.https_listener.port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTPS from internet"
    }
  ]

  egress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
      description = "Allow HTTP to EKS pods (IP target type)"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
      description = "Allow HTTPS to EKS pods (IP target type)"
    }
  ]

  common_tags = local.merged_tags
}