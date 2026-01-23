# ==============================================================================
# ALB Module - Security Groups
# ==============================================================================
# Creates one security group per environment to isolate ALB traffic.
# Each environment (production, staging, development) has its own security group.
# ==============================================================================

module "security_group" {
  count  = length(var.environments)
  source = "../../security/security-group"

  vpc_id = var.vpc_id

  # Use original common_prefix (no modification needed - environment handles uniqueness)
  common_prefix = var.common_prefix
  purpose       = "ALB"
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
      from_port   = 0
      to_port     = 65535
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic to EKS pods"
    }
  ]

  common_tags = local.merged_tags
}