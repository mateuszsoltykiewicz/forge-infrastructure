# ==============================================================================
# WAF Web ACL Module - Local Values (Refactored)
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Naming (Pattern A)
  # ------------------------------------------------------------------------------

  # WAF name: use provided name or generate from common_prefix
  waf_name = var.name != null ? var.name : "${var.common_prefix}-waf"

  # ------------------------------------------------------------------------------
  # KMS Configuration
  # ------------------------------------------------------------------------------

  # Use internal KMS key or external based on create_kms_key flag
  kms_key_id = var.create_kms_key ? (
    length(aws_kms_key.waf_logs) > 0 ? aws_kms_key.waf_logs[0].arn : null
  ) : var.kms_key_id

  # ------------------------------------------------------------------------------
  # Geographic Allowlist (Hardcoded)
  # ------------------------------------------------------------------------------

  # Only these countries are allowed access (all others blocked)
  # AR = Argentina, US = United States, ES = Spain, CA = Canada
  # BG = Bulgaria, HU = Hungary, IN = India, UA = Ukraine
  allowed_countries = ["AR", "US", "ES", "CA", "BG", "HU", "IN", "UA"]

  # ------------------------------------------------------------------------------
  # Tagging Strategy (Pattern A)
  # ------------------------------------------------------------------------------

  # Module-specific tags
  module_tags = {
    TerraformModule = "forge/aws/security/waf-web-acl"
    Name            = local.waf_name
    WAFScope        = var.scope
    WAFType         = "WebACL"
    DefaultAction   = var.default_action
  }

  # Merge common_tags from root + module-specific tags
  merged_tags = merge(
    var.common_tags,
    local.module_tags
  )
}
