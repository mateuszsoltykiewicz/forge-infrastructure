# ==============================================================================
# Data Sources - External Resources
# ==============================================================================
# References to existing AWS resources not managed by this Terraform configuration
# ==============================================================================

# ------------------------------------------------------------------------------
# Availability Zones
# ------------------------------------------------------------------------------
# Get list of available AZs in current region
# ------------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

# ------------------------------------------------------------------------------
# Route 53 Hosted Zone (existing zone)
# ------------------------------------------------------------------------------
# Uses existing Route 53 hosted zone for domain management
# Domain: cronus-backend.com
# ------------------------------------------------------------------------------

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}
