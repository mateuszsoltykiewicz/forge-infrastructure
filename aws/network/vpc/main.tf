# ==============================================================================
# Resource: AWS VPC (Forge - Customer-Centric)
# ==============================================================================
# Creates a Virtual Private Cloud (VPC) with DNS support and hostnames enabled.
# Supports both shared (multi-tenant) and dedicated (single-customer) architectures.
# ==============================================================================

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block # The primary CIDR block for the VPC
  enable_dns_support   = true           # Enables DNS resolution within the VPC
  enable_dns_hostnames = true           # Enables DNS hostnames for instances

  tags = merge(local.merged_tags, local.vpc_tags, {
    LastModified = plantimestamp()
  })

  lifecycle {
    ignore_changes = [tags["Created"]]
  }
}

# ==============================================================================
# Multi-Tenancy Pattern:
# ==============================================================================
# - Enable DNS support and hostnames for service discovery and AWS integrations
# - Three isolation levels:
#   1. Shared: workspace only (forge-{env}-vpc)
#   2. Customer: workspace + customer (forge-{env}-cronus-vpc)
#   3. Project: workspace + customer + project (forge-{env}-cronus-analytics-vpc)
# - Apply consistent tagging for auto-discovery by EKS, RDS, Redis, ALB modules
# - Ensure CIDR blocks are unique and non-overlapping
# ==============================================================================
