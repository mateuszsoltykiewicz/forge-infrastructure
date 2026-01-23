# ==============================================================================
# ACM Certificate Module - Local Values
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Certificate Naming (Pattern A)
  # ------------------------------------------------------------------------------

  # Certificate name using common_prefix
  certificate_name = "${var.common_prefix}-cert"

  # ------------------------------------------------------------------------------
  # Domain Configuration
  # ------------------------------------------------------------------------------

  # All domain names (primary + SANs)
  all_domain_names = distinct(concat(
    [var.domain_name],
    var.subject_alternative_names
  ))

  # Check if wildcard certificate
  is_wildcard = startswith(var.domain_name, "*.")

  # Extract base domain from wildcard (*.example.com -> example.com)
  base_domain = local.is_wildcard ? substr(var.domain_name, 2, length(var.domain_name) - 2) : var.domain_name

  # ------------------------------------------------------------------------------
  # Validation Configuration
  # ------------------------------------------------------------------------------

  # Validation flags
  is_dns_validation         = var.validation_method == "DNS"
  is_email_validation       = var.validation_method == "EMAIL"
  should_create_dns_records = local.is_dns_validation && var.create_route53_records && var.route53_zone_id != null

  # Validation method description
  validation_method_description = local.is_dns_validation ? "DNS validation via Route 53 (automatic)" : "Email validation (manual)"

  # ------------------------------------------------------------------------------
  # Key Algorithm Details
  # ------------------------------------------------------------------------------

  key_type = startswith(var.key_algorithm, "RSA") ? "RSA" : "EC"
  key_size = startswith(var.key_algorithm, "RSA") ? tonumber(split("_", var.key_algorithm)[1]) : null

  # ------------------------------------------------------------------------------
  # Tagging Strategy (Pattern A)
  # ------------------------------------------------------------------------------

  # Module-specific tags (only ACM metadata)
  module_tags = {
    TerraformModule  = "forge/aws/security/acm-certificate"
    Name             = local.certificate_name
    DomainName       = var.domain_name
    ValidationMethod = var.validation_method
    KeyAlgorithm     = var.key_algorithm
    IsWildcard       = tostring(local.is_wildcard)
  }

  # Merge common_tags from root + module-specific tags
  merged_tags = merge(
    var.common_tags,
    local.module_tags
  )

  # ------------------------------------------------------------------------------
  # Validation Rules
  # ------------------------------------------------------------------------------

  # DNS validation requires Route 53 zone ID
  dns_validation_required = local.is_dns_validation && var.route53_zone_id == null
}
