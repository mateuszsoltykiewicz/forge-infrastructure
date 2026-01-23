# ==============================================================================
# S3 Module - Variables
# ==============================================================================
# This file defines input variables for the S3 bucket module.
# ==============================================================================

# ------------------------------------------------------------------------------
# Naming Variables (Pattern A)
# ------------------------------------------------------------------------------

variable "common_prefix" {
  description = "Common prefix for all resources (e.g., forge-{environment}-{customer}-{project})"
  type        = string
}

variable "common_tags" {
  description = "Common tags passed from root module (ManagedBy, Environment, Region, etc.)"
  type        = map(string)
  default     = {}
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
# KMS Key Configuration (for internal module use)
# ------------------------------------------------------------------------------

variable "kms_key_deletion_window" {
  description = "KMS key deletion window in days (7-30)"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days"
  }
}

variable "kms_enable_key_rotation" {
  description = "Enable automatic KMS key rotation (recommended for production)"
  type        = bool
  default     = true
}

variable "kms_key_administrators" {
  description = "List of IAM principal ARNs that can administer the KMS key (empty = account root)"
  type        = list(string)
  default     = []
}

variable "kms_key_users" {
  description = "List of IAM principal ARNs that can use the KMS key for encryption/decryption"
  type        = list(string)
  default     = []
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
# HIPAA Log Lifecycle Configuration
# ------------------------------------------------------------------------------

variable "enable_hipaa_log_lifecycle" {
  description = "Enable HIPAA 7-year lifecycle rules for log prefixes (logs/cloudwatch/*, logs/kubernetes/*, metrics/cloudwatch/*, processing-failed/)"
  type        = bool
  default     = false
}

variable "enable_s3_inventory" {
  description = "Enable daily S3 inventory reports (Parquet format for Athena)"
  type        = bool
  default     = false
}

variable "enable_processing_failed_alerts" {
  description = "Enable EventBridge alerts when Firehose writes to processing-failed/ prefix (Lambda transformation errors)"
  type        = bool
  default     = false
}

variable "processing_failed_sns_topic_arn" {
  description = "SNS topic ARN for processing-failed alerts (required if enable_processing_failed_alerts is true)"
  type        = string
  default     = null

  validation {
    condition     = var.processing_failed_sns_topic_arn == null || can(regex("^arn:aws:sns:[a-z0-9-]+:\\d+:.+$", var.processing_failed_sns_topic_arn))
    error_message = "processing_failed_sns_topic_arn must be a valid SNS topic ARN or null"
  }
}
