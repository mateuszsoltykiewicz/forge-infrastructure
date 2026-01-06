# ==============================================================================
# EKS Module - Data Sources for Network Auto-Discovery (Multi-Tenant)
# ==============================================================================
# This file discovers VPC and network resources using tags.
# Supports multi-tenant scenarios with Customer and Project tags.
# No manual vpc_id or subnet_ids required!
# ==============================================================================

# ------------------------------------------------------------------------------
# VPC Discovery (Multi-Tenant)
# ------------------------------------------------------------------------------

data "aws_vpc" "main" {
  tags = merge(
    {
      ManagedBy   = "Terraform"
      Workspace   = var.workspace
      Environment = var.environment
    },
    var.customer_name != "" ? { Customer = var.customer_name } : {},
    var.project_name != "" ? { Project = var.project_name } : {}
  )
}

# ------------------------------------------------------------------------------
# Availability Zones
# ------------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}
