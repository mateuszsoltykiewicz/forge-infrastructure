# ==============================================================================
# EKS Module - Data Sources for Network Auto-Discovery (Multi-Tenant)
# ==============================================================================
# This file discovers VPC and network resources using tags.
# Supports multi-tenant scenarios with Customer and Project tags.
# No manual vpc_id or subnet_ids required!
# ==============================================================================

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# ------------------------------------------------------------------------------
# VPC Discovery (Multi-Tenant)
# ------------------------------------------------------------------------------

data "aws_vpc" "main" {
  id = var.vpc_id
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
