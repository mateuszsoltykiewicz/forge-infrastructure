# ==============================================================================
# Route 53 Hosted Zone Module - Local Values
# ==============================================================================
# This file defines local values for computed resource attributes.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Architecture Detection
  # ------------------------------------------------------------------------------

  # Determine if this is shared or dedicated architecture
  is_shared_architecture = var.architecture_type == "shared"

  # ------------------------------------------------------------------------------
  # Zone Naming
  # ------------------------------------------------------------------------------

  # Zone name is the domain name
  zone_name = var.domain_name

  # ------------------------------------------------------------------------------
  # VPC Configuration
  # ------------------------------------------------------------------------------

  # Use provided vpc_region or default to var.region
  primary_vpc_region = coalesce(var.vpc_region, var.region)

  # Validate private zone has VPC
  private_zone_valid = var.zone_type == "private" ? var.vpc_id != null : true

  # ------------------------------------------------------------------------------
  # DNSSEC Validation
  # ------------------------------------------------------------------------------

  # DNSSEC requires KMS key
  dnssec_valid = var.enable_dnssec ? var.kms_key_id != null : true

  # DNSSEC only works with public zones
  dnssec_type_valid = var.enable_dnssec ? var.zone_type == "public" : true

  # ------------------------------------------------------------------------------
  # Query Logging Validation
  # ------------------------------------------------------------------------------

  # Query logging requires log group ARN
  query_logging_valid = var.enable_query_logging ? var.query_log_group_arn != null : true

  # ------------------------------------------------------------------------------
  # Comment Generation
  # ------------------------------------------------------------------------------

  # Auto-generate comment if not provided
  auto_comment = var.comment != "" ? var.comment : (
    var.zone_type == "public" ? (
      "Public hosted zone for ${var.domain_name} (${var.environment})"
      ) : (
      "Private hosted zone for ${var.domain_name} in VPC ${var.vpc_id} (${var.environment})"
    )
  )

  # ------------------------------------------------------------------------------
  # Tagging Strategy
  # ------------------------------------------------------------------------------

  # Base tags applied to all resources
  base_tags = {
    Environment     = var.environment
    ManagedBy       = "terraform"
    TerraformModule = "network/route53-zone"
    Region          = var.region
    DomainName      = var.domain_name
    ZoneType        = var.zone_type
  }

  # Customer-specific tags (only applied for dedicated architectures)
  customer_tags = !local.is_shared_architecture ? {
    CustomerId       = var.customer_id
    CustomerName     = var.customer_name
    ArchitectureType = var.architecture_type
    PlanTier         = var.plan_tier
  } : {}

  # Merge all tags
  merged_tags = merge(
    local.base_tags,
    local.customer_tags,
    var.tags
  )
}
