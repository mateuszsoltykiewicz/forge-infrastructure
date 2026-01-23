# ==============================================================================
# RDS PostgreSQL Module - Data Sources
# ==============================================================================
# This file handles auto-discovery of VPC, EKS, and network resources.
# ==============================================================================

# ------------------------------------------------------------------------------
# Current AWS Region and Account
# ------------------------------------------------------------------------------

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# ------------------------------------------------------------------------------
# Availability Zones
# ------------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "main" {
  id = var.vpc_id
}

# ------------------------------------------------------------------------------
# EKS Cluster Configuration
# ------------------------------------------------------------------------------
# NOTE: EKS cluster name must be explicitly provided via variable
# Auto-discovery is disabled to prevent circular dependencies during initial deployment
