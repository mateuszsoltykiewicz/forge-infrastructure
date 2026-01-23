# ==============================================================================
# Common Configuration
# ==============================================================================

variable "common_prefix" {
  description = "Common prefix for certificate naming (e.g., forge-production-customer-project)"
  type        = string

  validation {
    condition     = length(var.common_prefix) > 0 && length(var.common_prefix) <= 63
    error_message = "common_prefix must be between 1 and 63 characters"
  }
}

# ========================================
# General Configuration
# ========================================

variable "environment" {
  description = "Environment name (e.g., 'dev', 'staging', 'production')"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production", "test"], var.environment)
    error_message = "Environment must be one of: dev, staging, production, test."
  }
}

variable "region" {
  description = "AWS region for the certificate (must match ALB region, or us-east-1 for CloudFront)"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1, eu-west-1)."
  }
}

# ========================================
# Certificate Configuration
# ========================================

variable "domain_name" {
  description = "Primary domain name for the certificate (e.g., 'example.com', '*.example.com')"
  type        = string

  validation {
    condition     = can(regex("^(\\*\\.)?[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*$", var.domain_name))
    error_message = "Domain name must be a valid DNS name, optionally starting with '*.' for wildcard."
  }
}

variable "subject_alternative_names" {
  description = "List of additional domain names for Subject Alternative Names (SANs). The primary domain_name is automatically included."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for san in var.subject_alternative_names :
      can(regex("^(\\*\\.)?[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*$", san))
    ])
    error_message = "All SANs must be valid DNS names, optionally starting with '*.' for wildcard."
  }
}

variable "validation_method" {
  description = "Certificate validation method. Use 'DNS' for automatic Route 53 validation (recommended), or 'EMAIL' for manual validation."
  type        = string
  default     = "DNS"

  validation {
    condition     = contains(["DNS", "EMAIL"], var.validation_method)
    error_message = "Validation method must be either 'DNS' or 'EMAIL'."
  }
}

variable "validation_timeout" {
  description = "Timeout for certificate validation in minutes. DNS validation typically completes in 5-10 minutes."
  type        = string
  default     = "45m"

  validation {
    condition     = can(regex("^[0-9]+[mh]$", var.validation_timeout))
    error_message = "Validation timeout must be in format '45m' or '2h'."
  }
}

# ========================================
# Route 53 Configuration (DNS Validation)
# ========================================

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for DNS validation. Required when validation_method is 'DNS'. Must be the zone that contains the domain_name."
  type        = string
  default     = null

  validation {
    condition     = var.route53_zone_id == null || can(regex("^Z[A-Z0-9]+$", var.route53_zone_id))
    error_message = "Route 53 zone ID must start with 'Z' followed by alphanumeric characters."
  }
}

variable "create_route53_records" {
  description = "Whether to automatically create Route 53 validation records. Set to false if managing DNS records manually or using external DNS provider."
  type        = bool
  default     = true
}

variable "validation_record_ttl" {
  description = "TTL for Route 53 validation records in seconds"
  type        = number
  default     = 60

  validation {
    condition     = var.validation_record_ttl >= 60 && var.validation_record_ttl <= 86400
    error_message = "TTL must be between 60 seconds (1 minute) and 86400 seconds (1 day)."
  }
}

# ========================================
# Certificate Options
# ========================================

variable "key_algorithm" {
  description = "Algorithm used to generate the certificate's private key. RSA_2048 is most compatible, EC keys offer better performance."
  type        = string
  default     = "RSA_2048"

  validation {
    condition     = contains(["RSA_1024", "RSA_2048", "RSA_3072", "RSA_4096", "EC_prime256v1", "EC_secp384r1"], var.key_algorithm)
    error_message = "Key algorithm must be one of: RSA_1024, RSA_2048, RSA_3072, RSA_4096, EC_prime256v1, EC_secp384r1."
  }
}

variable "certificate_transparency_logging" {
  description = "Whether to enable Certificate Transparency logging. Recommended for production certificates."
  type        = bool
  default     = true
}

# ========================================
# Lifecycle and Renewal
# ========================================

variable "wait_for_validation" {
  description = "Whether to wait for certificate validation to complete before returning. Set to false for faster Terraform runs, but certificate won't be usable immediately."
  type        = bool
  default     = true
}

variable "early_renewal_duration" {
  description = "Duration before expiration to trigger renewal warnings (not automatic renewal). ACM handles renewal automatically ~60 days before expiration."
  type        = string
  default     = "720h" # 30 days

  validation {
    condition     = can(regex("^[0-9]+h$", var.early_renewal_duration))
    error_message = "Early renewal duration must be in format '720h' (hours)."
  }
}

# ========================================
# Tags
# ========================================

variable "common_tags" {
  description = "Additional tags to apply to the certificate and validation records"
  type        = map(string)
  default     = {}
}
