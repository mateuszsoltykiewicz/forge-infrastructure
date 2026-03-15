# ==============================================================================
# S3 HIPAA Logs Module - Main Resources
# ==============================================================================
# Primary bucket with cross-region replication to DR region
# HIPAA-compliant 7-year retention with automated lifecycle management
# ==============================================================================

# ------------------------------------------------------------------------------
# KMS Key for Primary Region S3 Encryption
# ------------------------------------------------------------------------------

module "kms_s3_primary" {
  source = "../../security/kms"

  # Pattern A variables
  common_prefix = var.common_prefix
  common_tags   = var.common_tags

  # KMS Key configuration
  key_purpose     = "s3-hipaa-logs-primary"
  key_description = "S3 HIPAA logs encryption (primary region ${var.primary_region})"
  key_usage       = "ENCRYPT_DECRYPT"

  # Security settings
  deletion_window_in_days = 30
  enable_key_rotation     = true

  # Service principals - S3, Kinesis Firehose, CloudWatch Logs
  key_service_roles = [
    "s3.amazonaws.com",
    "firehose.amazonaws.com",
    "logs.amazonaws.com"
  ]

  # Root account as administrator
  key_administrators = [
    "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
}

# ------------------------------------------------------------------------------
# KMS Key for DR Region S3 Encryption
# ------------------------------------------------------------------------------

module "kms_s3_dr" {
  source = "../../security/kms"

  # Pattern A variables
  common_prefix = var.common_prefix
  common_tags   = merge(var.common_tags, var.dr_tags)

  # KMS Key configuration
  key_purpose     = "s3-hipaa-logs-dr"
  key_description = "S3 HIPAA logs encryption (DR region ${var.dr_region})"
  key_usage       = "ENCRYPT_DECRYPT"

  # Security settings
  deletion_window_in_days = 30
  enable_key_rotation     = true

  # Service principals - S3 replication
  key_service_roles = [
    "s3.amazonaws.com"
  ]

  # Root account as administrator
  key_administrators = [
    "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
}

# ------------------------------------------------------------------------------
# Primary S3 Bucket (Current Region)
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "primary" {
  bucket        = local.bucket_name_primary
  force_destroy = var.force_destroy

  tags = merge(
    local.merged_tags,
    {
      Name        = local.bucket_name_primary
      Purpose     = "HIPAA Logs Storage (Primary)"
      Region      = var.primary_region
      Replication = "Source"
    }
  )
}

# Versioning (REQUIRED for replication)
resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = module.kms_s3_primary.key_arn
    }
    bucket_key_enabled = true
  }
}

# Public Access Block
resource "aws_s3_bucket_public_access_block" "primary" {
  bucket = aws_s3_bucket.primary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# HIPAA Lifecycle Policy (7 years = 2555 days)
resource "aws_s3_bucket_lifecycle_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

  # HIPAA 7-year retention: Standard → IA → Glacier IR → Glacier → Deep Archive → Delete
  rule {
    id     = "hipaa-7-year-retention"
    status = "Enabled"

    # Transition to Infrequent Access after 90 days
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier Instant Retrieval after 180 days (6 months)
    transition {
      days          = 180
      storage_class = "GLACIER_IR"
    }

    # Transition to Glacier Flexible Retrieval after 365 days (1 year)
    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    # Transition to Deep Archive after 730 days (2 years)
    transition {
      days          = 730
      storage_class = "DEEP_ARCHIVE"
    }

    # Expire after 2555 days (7 years)
    expiration {
      days = 2555
    }
  }

  # Clean up old versions after 30 days
  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  # Clean up incomplete multipart uploads after 7 days
  rule {
    id     = "cleanup-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ------------------------------------------------------------------------------
# DR S3 Bucket (Secondary Region)
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "dr" {
  provider      = aws.dr_region
  bucket        = local.bucket_name_dr
  force_destroy = var.force_destroy

  tags = merge(
    local.merged_tags,
    var.dr_tags,
    {
      Name        = local.bucket_name_dr
      Purpose     = "HIPAA Logs Storage (DR)"
      Region      = var.dr_region
      Replication = "Destination"
    }
  )
}

# Versioning (REQUIRED for replication destination)
resource "aws_s3_bucket_versioning" "dr" {
  provider = aws.dr_region
  bucket   = aws_s3_bucket.dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption with DR region KMS key
resource "aws_s3_bucket_server_side_encryption_configuration" "dr" {
  provider = aws.dr_region
  bucket   = aws_s3_bucket.dr.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = module.kms_s3_dr.key_arn
    }
    bucket_key_enabled = true
  }
}

# Public Access Block
resource "aws_s3_bucket_public_access_block" "dr" {
  provider = aws.dr_region
  bucket   = aws_s3_bucket.dr.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Same lifecycle policy for DR bucket
resource "aws_s3_bucket_lifecycle_configuration" "dr" {
  provider = aws.dr_region
  bucket   = aws_s3_bucket.dr.id

  # HIPAA 7-year retention
  rule {
    id     = "hipaa-7-year-retention"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER_IR"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    transition {
      days          = 730
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 2555
    }
  }

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  rule {
    id     = "cleanup-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ------------------------------------------------------------------------------
# IAM Role for S3 Replication
# ------------------------------------------------------------------------------

resource "aws_iam_role" "replication" {
  name = local.replication_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(
    local.merged_tags,
    {
      Name    = local.replication_role_name
      Purpose = "S3 Cross-Region Replication"
    }
  )
}

# IAM Policy for Replication
resource "aws_iam_role_policy" "replication" {
  name = "${local.replication_role_name}Policy"
  role = aws_iam_role.replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.primary.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.primary.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.dr.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = module.kms_s3_primary.key_arn
        Condition = {
          StringLike = {
            "kms:ViaService" = "s3.${var.primary_region}.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt"
        ]
        Resource = module.kms_s3_dr.key_arn
        Condition = {
          StringLike = {
            "kms:ViaService" = "s3.${var.dr_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# S3 Replication Configuration
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_replication_configuration" "primary_to_dr" {
  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.dr
  ]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "replicate-all-hipaa-logs-to-dr"
    status = "Enabled"

    # Replicate all objects
    filter {}

    # Delete marker replication (HIPAA compliance)
    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = aws_s3_bucket.dr.arn
      storage_class = "GLACIER_IR" # Start with Glacier Instant Retrieval in DR

      # Encryption configuration for DR bucket
      encryption_configuration {
        replica_kms_key_id = module.kms_s3_dr.key_arn
      }

      # Replication metrics and notifications
      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }

      # Replication time control (SLA: 15 minutes)
      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
    }
  }
}
