# ==============================================================================
# S3 Module - Main Resources
# ==============================================================================
# This file creates S3 bucket resources with encryption, versioning, lifecycle,
# and security configurations.
# ==============================================================================

# ------------------------------------------------------------------------------
# S3 Bucket
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "main" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  # Object Lock can only be enabled at bucket creation time
  object_lock_enabled = var.object_lock_enabled

  tags = merge(
    local.merged_tags,
    {
      Name = local.bucket_name
    }
  )
}

# ------------------------------------------------------------------------------
# Bucket Versioning
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status     = var.versioning_enabled ? "Enabled" : "Suspended"
    mfa_delete = var.versioning_mfa_delete ? "Enabled" : "Disabled"
  }
}

# ------------------------------------------------------------------------------
# Server-Side Encryption
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count = var.encryption_enabled ? 1 : 0

  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_type
      kms_master_key_id = var.encryption_type == "aws:kms" ? var.kms_key_id : null
    }

    bucket_key_enabled = var.encryption_type == "aws:kms" ? var.bucket_key_enabled : null
  }
}

# ------------------------------------------------------------------------------
# Public Access Block
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = var.block_public_access ? true : var.block_public_acls
  block_public_policy     = var.block_public_access ? true : var.block_public_policy
  ignore_public_acls      = var.block_public_access ? true : var.ignore_public_acls
  restrict_public_buckets = var.block_public_access ? true : var.restrict_public_buckets
}

# ------------------------------------------------------------------------------
# Lifecycle Configuration
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.main.id

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      # Filter (optional prefix)
      dynamic "filter" {
        for_each = rule.value.prefix != null ? [1] : []

        content {
          prefix = rule.value.prefix
        }
      }

      # Abort incomplete multipart uploads
      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload_days != null ? [1] : []

        content {
          days_after_initiation = rule.value.abort_incomplete_multipart_upload_days
        }
      }

      # Current version expiration
      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []

        content {
          days                         = expiration.value.days
          expired_object_delete_marker = expiration.value.expired_object_delete_marker
        }
      }

      # Noncurrent version expiration
      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []

        content {
          noncurrent_days = noncurrent_version_expiration.value.noncurrent_days
        }
      }

      # Current version transitions
      dynamic "transition" {
        for_each = rule.value.transition != null ? rule.value.transition : []

        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      # Noncurrent version transitions
      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transition != null ? rule.value.noncurrent_version_transition : []

        content {
          noncurrent_days = noncurrent_version_transition.value.noncurrent_days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }
    }
  }
}

# ------------------------------------------------------------------------------
# Bucket Logging
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_logging" "main" {
  count = var.logging_enabled ? 1 : 0

  bucket = aws_s3_bucket.main.id

  target_bucket = var.logging_target_bucket
  target_prefix = var.logging_target_prefix
}

# ------------------------------------------------------------------------------
# Cross-Region Replication
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_replication_configuration" "main" {
  count = var.replication_enabled ? 1 : 0

  # Must have bucket versioning enabled
  depends_on = [aws_s3_bucket_versioning.main]

  bucket = aws_s3_bucket.main.id
  role   = var.replication_role_arn

  dynamic "rule" {
    for_each = var.replication_rules

    content {
      id       = rule.value.id
      status   = rule.value.status
      priority = rule.value.priority

      # Filter (optional prefix)
      dynamic "filter" {
        for_each = rule.value.prefix != null ? [1] : []

        content {
          prefix = rule.value.prefix
        }
      }

      # Destination configuration
      destination {
        bucket        = rule.value.destination.bucket
        storage_class = rule.value.destination.storage_class

        # Encryption configuration for replica
        dynamic "encryption_configuration" {
          for_each = rule.value.destination.replica_kms_key_id != null ? [1] : []

          content {
            replica_kms_key_id = rule.value.destination.replica_kms_key_id
          }
        }
      }

      # Source selection criteria for SSE-KMS encrypted objects
      dynamic "source_selection_criteria" {
        for_each = rule.value.source_selection_criteria != null ? [rule.value.source_selection_criteria] : []

        content {
          dynamic "sse_kms_encrypted_objects" {
            for_each = source_selection_criteria.value.sse_kms_encrypted_objects != null ? [source_selection_criteria.value.sse_kms_encrypted_objects] : []

            content {
              status = sse_kms_encrypted_objects.value.enabled ? "Enabled" : "Disabled"
            }
          }
        }
      }
    }
  }
}

# ------------------------------------------------------------------------------
# Object Lock Configuration
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_object_lock_configuration" "main" {
  count = var.object_lock_enabled && var.object_lock_configuration != null ? 1 : 0

  bucket = aws_s3_bucket.main.id

  rule {
    default_retention {
      mode  = var.object_lock_configuration.mode
      days  = var.object_lock_configuration.days
      years = var.object_lock_configuration.years
    }
  }
}

# ------------------------------------------------------------------------------
# CORS Configuration
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_cors_configuration" "main" {
  count = length(var.cors_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.main.id

  dynamic "cors_rule" {
    for_each = var.cors_rules

    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

# ------------------------------------------------------------------------------
# Intelligent-Tiering Configuration
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_intelligent_tiering_configuration" "main" {
  count = var.intelligent_tiering_enabled ? 1 : 0

  bucket = aws_s3_bucket.main.id
  name   = var.intelligent_tiering_name

  status = "Enabled"

  # Archive Access tier (90-730 days)
  dynamic "tiering" {
    for_each = var.intelligent_tiering_archive_days > 0 ? [1] : []

    content {
      access_tier = "ARCHIVE_ACCESS"
      days        = var.intelligent_tiering_archive_days
    }
  }

  # Deep Archive Access tier (180-730 days)
  dynamic "tiering" {
    for_each = var.intelligent_tiering_deep_archive_days > 0 ? [1] : []

    content {
      access_tier = "DEEP_ARCHIVE_ACCESS"
      days        = var.intelligent_tiering_deep_archive_days
    }
  }
}
