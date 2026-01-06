# ========================================
# Local Values and Computed Configuration
# ========================================

locals {
  # Multi-tenant detection
  has_customer = var.customer_name != null && var.customer_name != ""
  has_project  = var.project_name != null && var.project_name != ""

  # Certificate naming
  # 1. Shared: forge-{environment}-cert
  # 2. Customer: forge-{environment}-{customer}-cert
  # 3. Project: forge-{environment}-{customer}-{project}-cert
  certificate_name = local.has_project ? "forge-${var.environment}-${var.customer_name}-${var.project_name}-cert" : (
    local.has_customer ? "forge-${var.environment}-${var.customer_name}-cert" :
    "forge-${var.environment}-cert"
  )

  # All domain names (primary + SANs)
  all_domain_names = distinct(concat(
    [var.domain_name],
    var.subject_alternative_names
  ))

  # Check if wildcard certificate
  is_wildcard = startswith(var.domain_name, "*.")

  # Extract base domain from wildcard (*.example.com -> example.com)
  base_domain = local.is_wildcard ? substr(var.domain_name, 2, length(var.domain_name) - 2) : var.domain_name

  # Validation flags
  is_dns_validation         = var.validation_method == "DNS"
  is_email_validation       = var.validation_method == "EMAIL"
  should_create_dns_records = local.is_dns_validation && var.create_route53_records && var.route53_zone_id != null

  # Key algorithm details
  key_type = startswith(var.key_algorithm, "RSA") ? "RSA" : "EC"
  key_size = startswith(var.key_algorithm, "RSA") ? tonumber(split("_", var.key_algorithm)[1]) : null

  # Certificate status description
  validation_method_description = local.is_dns_validation ? (
    "DNS validation via Route 53 (automatic)"
    ) : (
    "Email validation (manual)"
  )

  # Tagging strategy
  base_tags = {
    ManagedBy   = "terraform"
    Module      = "acm-certificate"
    PlanTier    = var.plan_tier
    Environment = var.environment
    Region      = var.region
  }

  customer_tags = local.has_customer ? {
    CustomerName = var.customer_name
  } : {}

  project_tags = local.has_project ? {
    ProjectName = var.project_name
  } : {}

  certificate_tags = {
    Name             = local.certificate_name
    DomainName       = var.domain_name
    ValidationMethod = var.validation_method
    KeyAlgorithm     = var.key_algorithm
    IsWildcard       = tostring(local.is_wildcard)
  }

  merged_tags = merge(
    local.base_tags,
    local.customer_tags,
    local.project_tags,
    local.certificate_tags,
    var.tags
  )

  # Validation
  dns_validation_required = local.is_dns_validation && var.route53_zone_id == null
}

# ========================================
# Validation Rules
# ========================================

# Ensure Route 53 zone ID is provided for DNS validation
resource "null_resource" "dns_validation_check" {
  count = local.dns_validation_required ? 1 : 0

  lifecycle {
    precondition {
      condition     = !local.dns_validation_required
      error_message = "route53_zone_id is required when validation_method is 'DNS'. Provide the Route 53 hosted zone ID for ${var.domain_name}."
    }
  }
}

# Warn if using weak RSA_1024
resource "null_resource" "weak_key_warning" {
  count = var.key_algorithm == "RSA_1024" ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.key_algorithm != "RSA_1024"
      error_message = "RSA_1024 is deprecated and insecure. Use RSA_2048 or higher for production certificates."
    }
  }
}

# Ensure SANs are distinct from primary domain
resource "null_resource" "san_duplicate_check" {
  lifecycle {
    precondition {
      condition     = !contains(var.subject_alternative_names, var.domain_name)
      error_message = "subject_alternative_names should not include the primary domain_name. It is automatically included."
    }
  }
}
