# ==============================================================================
# Route 53 Hosted Zone Module - Local Values
# ==============================================================================
# This file defines local values for computed resource attributes.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Zone Naming (Pattern A)
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
  # Tagging Strategy (Pattern A)
  # ------------------------------------------------------------------------------

  # Module-specific tags (only Route53 metadata)
  module_tags = {
    TerraformModule = "forge/aws/network/route53-zone"
    DomainName      = var.domain_name
    ZoneType        = var.zone_type
  }

  # Merge common_tags from root + module-specific tags
  merged_tags = merge(
    var.common_tags,  # Common tags from root (includes Customer, Project, Environment, etc.)
    local.module_tags # Module-specific tags
  )
}
