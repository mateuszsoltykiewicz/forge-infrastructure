# ==============================================================================
# KMS Module - Variables
# ==============================================================================
# This file defines input variables for the KMS key module.
# ==============================================================================

# ------------------------------------------------------------------------------
# Customer Context Variables
# ------------------------------------------------------------------------------

variable "customer_name" {
  description = "Name of the customer (used in resource naming, e.g., 'forge', 'acme-corp')"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.customer_name))
    error_message = "customer_name must contain only lowercase letters, numbers, and hyphens"
  }
}

variable "project_name" {
  description = "Project name for multi-tenant deployments"
  type        = string
  default     = null
}

variable "plan_tier" {
  description = "Customer plan tier: basic, pro, enterprise, or platform"
  type        = string

  validation {
    condition     = contains(["basic", "pro", "enterprise", "platform"], var.plan_tier)
    error_message = "plan_tier must be one of: basic, pro, enterprise, platform"
  }
}

# ------------------------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string
}

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
}

# ------------------------------------------------------------------------------
# KMS Key Configuration
# ------------------------------------------------------------------------------

variable "key_description" {
  description = "Description of the KMS key"
  type        = string
  default     = "KMS key created by Terraform"
}

variable "key_purpose" {
  description = "Purpose of the key (e.g., 'rds', 's3', 'eks', 'general')"
  type        = string
  default     = "general"
}

variable "key_usage" {
  description = "Intended use of the key (ENCRYPT_DECRYPT or SIGN_VERIFY)"
  type        = string
  default     = "ENCRYPT_DECRYPT"

  validation {
    condition     = contains(["ENCRYPT_DECRYPT", "SIGN_VERIFY"], var.key_usage)
    error_message = "key_usage must be either ENCRYPT_DECRYPT or SIGN_VERIFY"
  }
}

variable "customer_master_key_spec" {
  description = "Key spec (SYMMETRIC_DEFAULT, RSA_2048, RSA_3072, RSA_4096, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521, ECC_SECG_P256K1)"
  type        = string
  default     = "SYMMETRIC_DEFAULT"

  validation {
    condition = contains([
      "SYMMETRIC_DEFAULT",
      "RSA_2048", "RSA_3072", "RSA_4096",
      "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521",
      "ECC_SECG_P256K1"
    ], var.customer_master_key_spec)
    error_message = "customer_master_key_spec must be a valid key spec"
  }
}

variable "multi_region" {
  description = "Create a multi-region key"
  type        = bool
  default     = false
}

variable "enable_key_rotation" {
  description = "Enable automatic key rotation (only for symmetric keys)"
  type        = bool
  default     = true
}

variable "rotation_period_in_days" {
  description = "Number of days between automatic key rotations (90-2560 days)"
  type        = number
  default     = 365

  validation {
    condition     = var.rotation_period_in_days >= 90 && var.rotation_period_in_days <= 2560
    error_message = "rotation_period_in_days must be between 90 and 2560 days"
  }
}

variable "deletion_window_in_days" {
  description = "Waiting period before key deletion (7-30 days)"
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "deletion_window_in_days must be between 7 and 30 days"
  }
}

variable "is_enabled" {
  description = "Whether the key is enabled"
  type        = bool
  default     = true
}

variable "bypass_policy_lockout_safety_check" {
  description = "Bypass policy lockout safety check (use with caution)"
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# Key Policy Configuration
# ------------------------------------------------------------------------------

variable "enable_default_policy" {
  description = "Use default key policy (grants root account full access)"
  type        = bool
  default     = true
}

variable "key_administrators" {
  description = "List of IAM ARNs that can administer the key"
  type        = list(string)
  default     = []
}

variable "key_users" {
  description = "List of IAM ARNs that can use the key for cryptographic operations"
  type        = list(string)
  default     = []
}

variable "key_service_users" {
  description = "List of AWS service principals that can use the key (e.g., ['s3.amazonaws.com', 'rds.amazonaws.com'])"
  type        = list(string)
  default     = []
}

variable "custom_key_policy" {
  description = "Custom key policy JSON (overrides all policy settings if provided)"
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# Alias Configuration
# ------------------------------------------------------------------------------

variable "create_alias" {
  description = "Create an alias for the key"
  type        = bool
  default     = true
}

variable "alias_name" {
  description = "Alias name for the key (without 'alias/' prefix, leave empty for auto-generated name)"
  type        = string
  default     = ""

  validation {
    condition     = var.alias_name == "" || can(regex("^[a-zA-Z0-9/_-]+$", var.alias_name))
    error_message = "alias_name must contain only alphanumeric characters, underscores, hyphens, and forward slashes"
  }
}

# ------------------------------------------------------------------------------
# Grant Configuration
# ------------------------------------------------------------------------------

variable "grants" {
  description = "List of KMS grants to create"
  type = list(object({
    name              = string
    grantee_principal = string
    operations        = list(string)
    constraints = optional(object({
      encryption_context_equals = optional(map(string))
      encryption_context_subset = optional(map(string))
    }))
    retiring_principal    = optional(string)
    grant_creation_tokens = optional(list(string))
  }))
  default = []
}

# ------------------------------------------------------------------------------
# Tags
# ------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
