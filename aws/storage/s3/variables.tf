# ==============================================================================
# Resource Creation Control
# ==============================================================================

variable "create" {
  description = "Whether to create resources. Set to false to skip resource creation."
  type        = bool
  default     = true
}


# ==============================================================================
# S3 Module - Variables
# ==============================================================================
# This file defines input variables for the S3 bucket module.
# ==============================================================================

# ------------------------------------------------------------------------------
# Customer Context Variables
# ------------------------------------------------------------------------------

variable "customer_id" {
  description = "UUID of the customer (use 00000000-0000-0000-0000-000000000000 for shared infrastructure)"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.customer_id))
    error_message = "customer_id must be a valid UUID format"
  }
}

variable "customer_name" {
  description = "Name of the customer (used in resource naming, e.g., 'forge', 'acme-corp')"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.customer_name))
    error_message = "customer_name must contain only lowercase letters, numbers, and hyphens"
  }
}

variable "architecture_type" {
  description = "Architecture type: 'shared' (multi-tenant), 'dedicated_single_tenant', or 'dedicated_vpc'"
  type        = string

  validation {
    condition     = contains(["shared", "dedicated_single_tenant", "dedicated_vpc"], var.architecture_type)
    error_message = "architecture_type must be one of: shared, dedicated_single_tenant, dedicated_vpc"
  }
}

variable "project_name" {
  description = "Project name for project-level isolation (empty for customer-level or shared)"
  type        = string
  default     = ""
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
# S3 Bucket Configuration
# ------------------------------------------------------------------------------

variable "bucket_name" {
  description = "Name of the S3 bucket (leave empty for auto-generated name based on customer context)"
  type        = string
  default     = ""

  validation {
    condition     = var.bucket_name == "" || can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be lowercase alphanumeric with hyphens (no underscores), and cannot start or end with hyphen"
  }
}

variable "bucket_purpose" {
  description = "Purpose of the bucket (e.g., 'terraform-state', 'application-data', 'logs', 'backups')"
  type        = string
  default     = "general"
}

variable "force_destroy" {
  description = "Allow destruction of non-empty bucket (WARNING: use with caution)"
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# Versioning Configuration
# ------------------------------------------------------------------------------

variable "versioning_enabled" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "versioning_mfa_delete" {
  description = "Enable MFA delete for versioned objects (requires MFA to delete)"
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# Encryption Configuration
# ------------------------------------------------------------------------------

variable "encryption_enabled" {
  description = "Enable server-side encryption for the bucket"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type: 'AES256' (SSE-S3) or 'aws:kms' (SSE-KMS)"
  type        = string
  default     = "aws:kms"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_type)
    error_message = "encryption_type must be either 'AES256' or 'aws:kms'"
  }
}

variable "kms_key_id" {
  description = "KMS key ID/ARN for bucket encryption (required if encryption_type is 'aws:kms')"
  type        = string
  default     = null
}

variable "bucket_key_enabled" {
  description = "Enable S3 Bucket Keys to reduce KMS request costs"
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# Lifecycle Configuration
# ------------------------------------------------------------------------------

variable "lifecycle_rules" {
  description = "List of lifecycle rules for object transitions and expiration"
  type = list(object({
    id                                     = string
    enabled                                = bool
    prefix                                 = optional(string)
    abort_incomplete_multipart_upload_days = optional(number)

    expiration = optional(object({
      days                         = optional(number)
      expired_object_delete_marker = optional(bool)
    }))

    noncurrent_version_expiration = optional(object({
      noncurrent_days = number
    }))

    transition = optional(list(object({
      days          = number
      storage_class = string
    })))

    noncurrent_version_transition = optional(list(object({
      noncurrent_days = number
      storage_class   = string
    })))
  }))
  default = []
}

# ------------------------------------------------------------------------------
# Access Control Configuration
# ------------------------------------------------------------------------------

variable "block_public_access" {
  description = "Enable all S3 bucket public access blocks"
  type        = bool
  default     = true
}

variable "block_public_acls" {
  description = "Block public ACLs on this bucket"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies on this bucket"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs on this bucket"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public bucket policies on this bucket"
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# Logging Configuration
# ------------------------------------------------------------------------------

variable "logging_enabled" {
  description = "Enable S3 access logging"
  type        = bool
  default     = false
}

variable "logging_target_bucket" {
  description = "Target bucket for access logs (required if logging_enabled is true)"
  type        = string
  default     = ""
}

variable "logging_target_prefix" {
  description = "Prefix for access log objects"
  type        = string
  default     = "s3-access-logs/"
}

# ------------------------------------------------------------------------------
# Replication Configuration
# ------------------------------------------------------------------------------

variable "replication_enabled" {
  description = "Enable cross-region replication"
  type        = bool
  default     = false
}

variable "replication_role_arn" {
  description = "IAM role ARN for replication (required if replication_enabled is true)"
  type        = string
  default     = ""
}

variable "replication_rules" {
  description = "List of replication rules"
  type = list(object({
    id       = string
    status   = string
    priority = optional(number)
    prefix   = optional(string)

    destination = object({
      bucket             = string
      storage_class      = optional(string)
      replica_kms_key_id = optional(string)
    })

    source_selection_criteria = optional(object({
      sse_kms_encrypted_objects = optional(object({
        enabled = bool
      }))
    }))
  }))
  default = []
}

# ------------------------------------------------------------------------------
# Object Lock Configuration
# ------------------------------------------------------------------------------

variable "object_lock_enabled" {
  description = "Enable S3 Object Lock (WORM - Write Once Read Many, can only be enabled at bucket creation)"
  type        = bool
  default     = false
}

variable "object_lock_configuration" {
  description = "Object Lock configuration (COMPLIANCE or GOVERNANCE mode)"
  type = object({
    mode  = string # COMPLIANCE or GOVERNANCE
    days  = optional(number)
    years = optional(number)
  })
  default = null
}

# ------------------------------------------------------------------------------
# CORS Configuration
# ------------------------------------------------------------------------------

variable "cors_rules" {
  description = "List of CORS rules for the bucket"
  type = list(object({
    allowed_headers = optional(list(string))
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string))
    max_age_seconds = optional(number)
  }))
  default = []
}

# ------------------------------------------------------------------------------
# Intelligent Tiering Configuration
# ------------------------------------------------------------------------------

variable "intelligent_tiering_enabled" {
  description = "Enable S3 Intelligent-Tiering for automatic cost optimization"
  type        = bool
  default     = false
}

variable "intelligent_tiering_name" {
  description = "Name for the intelligent tiering configuration"
  type        = string
  default     = "EntireBucket"
}

variable "intelligent_tiering_archive_days" {
  description = "Days before moving to Archive Access tier (90-730 days, 0 to disable)"
  type        = number
  default     = 90

  validation {
    condition     = var.intelligent_tiering_archive_days == 0 || (var.intelligent_tiering_archive_days >= 90 && var.intelligent_tiering_archive_days <= 730)
    error_message = "intelligent_tiering_archive_days must be 0 (disabled) or between 90-730 days"
  }
}

variable "intelligent_tiering_deep_archive_days" {
  description = "Days before moving to Deep Archive Access tier (180-730 days, 0 to disable)"
  type        = number
  default     = 180

  validation {
    condition     = var.intelligent_tiering_deep_archive_days == 0 || (var.intelligent_tiering_deep_archive_days >= 180 && var.intelligent_tiering_deep_archive_days <= 730)
    error_message = "intelligent_tiering_deep_archive_days must be 0 (disabled) or between 180-730 days"
  }
}

# ------------------------------------------------------------------------------
# Tags
# ------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
