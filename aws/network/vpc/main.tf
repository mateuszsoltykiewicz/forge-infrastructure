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

  tags = merge(local.common_tags, local.vpc_tags, {
    LastModified = plantimestamp()
  })

  lifecycle {
    ignore_changes = [tags["Created"]]
  }
}

# ==============================================================================
# Forge Best Practices:
# ==============================================================================
# - Enable DNS support and hostnames for service discovery and AWS integrations
# - Use customer_id and customer_name variables for customer-specific VPCs
# - For shared architecture: Single VPC serves multiple customers via namespaces
# - For dedicated_local: One VPC per customer in a single region
# - For dedicated_regional: Multiple regional VPCs per customer
# - Apply consistent tagging for cost allocation by customer
# - Ensure CIDR blocks are unique and documented in the database
# ==============================================================================
