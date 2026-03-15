# ==============================================================================
# VPN Certificate Generator Module - Input Variables
# ==============================================================================

# ==============================================================================
# Common Configuration (Pattern A)
# ==============================================================================

variable "common_prefix" {
  description = "Common prefix for resource naming (e.g., forge-production-customer-project)"
  type        = string

  validation {
    condition     = length(var.common_prefix) > 0 && length(var.common_prefix) <= 63
    error_message = "common_prefix must be between 1 and 63 characters"
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources (passed from root module)"
  type        = map(string)
  default     = {}

  validation {
    condition = (
      contains(keys(var.common_tags), "Customer") &&
      contains(keys(var.common_tags), "Project") &&
      contains(keys(var.common_tags), "Environment") &&
      contains(keys(var.common_tags), "ManagedBy")
    )
    error_message = "common_tags must include: Customer, Project, Environment, ManagedBy"
  }
}

# ==============================================================================
# Certificate Configuration
# ==============================================================================

variable "cert_common_name" {
  description = "Common Name (CN) for VPN server certificate (FQDN). If null, defaults to 'vpn.{common_prefix}.internal'"
  type        = string
  default     = null
}

variable "cert_org_name" {
  description = "Organization Name for certificate authority. If null, defaults to 'Forge Platform'"
  type        = string
  default     = null
}

variable "cert_validity_days" {
  description = "Certificate validity period in days. AWS recommendation: 365 for production, 730 for dev/test"
  type        = number
  default     = 730

  validation {
    condition     = var.cert_validity_days >= 30 && var.cert_validity_days <= 3650
    error_message = "cert_validity_days must be between 30 and 3650 (10 years)"
  }
}

# ==============================================================================
# KMS Configuration
# ==============================================================================

variable "kms_key_arn" {
  description = "ARN of existing KMS key for SSM encryption. If null, a new key will be created"
  type        = string
  default     = null
}

variable "enable_kms_key_rotation" {
  description = "Enable automatic KMS key rotation (90-day period)"
  type        = bool
  default     = true
}

variable "kms_deletion_window_in_days" {
  description = "KMS key deletion window in days (7-30)"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "kms_deletion_window_in_days must be between 7 and 30"
  }
}

# ==============================================================================
# Cross-Region Backup Configuration
# ==============================================================================

variable "enable_dr_backup" {
  description = "Enable cross-region backup of CA private key in DR region"
  type        = bool
  default     = true
}

variable "dr_region" {
  description = "DR region for cross-region SSM backup. If null, uses provider alias 'dr_region'"
  type        = string
  default     = null
}

# ==============================================================================
# IAM Policy Configuration
# ==============================================================================

variable "create_rotation_policy" {
  description = "Create IAM policy for certificate rotation job (Kubernetes/Lambda)"
  type        = bool
  default     = true
}
