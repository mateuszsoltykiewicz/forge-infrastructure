# ==============================================================================
# HIPAA Log Lifecycle Rules - 7-Year Retention with Glacier Transitions
# ==============================================================================
# Lifecycle policies for Kinesis Firehose transformed logs with HIPAA compliance.
# Applies to: CloudWatch Logs (WAF, VPC, RDS), Kubernetes (Events, Pod Logs), 
# CloudWatch Metrics, and processing-failed records.
#
# Retention Timeline:
#   Days 0-90:     S3 Standard (frequent access for troubleshooting)
#   Days 91-365:   S3 Standard-IA (monthly access for compliance reviews)
#   Days 366-2555: S3 Glacier Instant Retrieval (annual compliance audits)
#   Days 2556-2557: S3 Glacier Deep Archive (7-year HIPAA retention)
#   Day 2558+:     Expire (auto-delete after 7 years + 1 day)
# ==============================================================================

# ------------------------------------------------------------------------------
# Lifecycle Rule: CloudWatch WAF Logs
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "waf_logs" {
  count  = var.enable_hipaa_log_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "hipaa-waf-logs-7year-retention"
    status = "Enabled"

    filter {
      prefix = "logs/cloudwatch/waf/"
    }

    # 90 days: Standard → Standard-IA
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    # 1 year: Standard-IA → Glacier Instant Retrieval
    transition {
      days          = 365
      storage_class = "GLACIER_IR"
    }

    # 7 years - 2 days: Glacier IR → Deep Archive
    transition {
      days          = 2555
      storage_class = "DEEP_ARCHIVE"
    }

    # 7 years + 1 day: Expire
    expiration {
      days = 2558
    }

    # Also apply to noncurrent versions (if versioning enabled)
    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 365
      storage_class   = "GLACIER_IR"
    }

    noncurrent_version_expiration {
      noncurrent_days = 2558
    }
  }

  depends_on = [ aws_s3_bucket.main ]
}

# ------------------------------------------------------------------------------
# Lifecycle Rule: CloudWatch VPC Flow Logs
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "vpc_logs" {
  count  = var.enable_hipaa_log_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "hipaa-vpc-logs-7year-retention"
    status = "Enabled"

    filter {
      prefix = "logs/cloudwatch/vpc/"
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER_IR"
    }

    transition {
      days          = 2555
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 2558
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 365
      storage_class   = "GLACIER_IR"
    }

    noncurrent_version_expiration {
      noncurrent_days = 2558
    }
  }

  depends_on = [ aws_s3_bucket_lifecycle_configuration.waf_logs ]
}

# ------------------------------------------------------------------------------
# Lifecycle Rule: CloudWatch RDS Logs
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "rds_logs" {
  count  = var.enable_hipaa_log_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "hipaa-rds-logs-7year-retention"
    status = "Enabled"

    filter {
      prefix = "logs/cloudwatch/rds/"
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER_IR"
    }

    transition {
      days          = 2555
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 2558
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 365
      storage_class   = "GLACIER_IR"
    }

    noncurrent_version_expiration {
      noncurrent_days = 2558
    }
  }

  depends_on = [ aws_s3_bucket_lifecycle_configuration.vpc_logs ]
}

# ------------------------------------------------------------------------------
# Lifecycle Rule: Kubernetes Events
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "eks_events" {
  count  = var.enable_hipaa_log_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "hipaa-eks-events-7year-retention"
    status = "Enabled"

    filter {
      prefix = "logs/kubernetes/events/"
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER_IR"
    }

    transition {
      days          = 2555
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 2558
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 365
      storage_class   = "GLACIER_IR"
    }

    noncurrent_version_expiration {
      noncurrent_days = 2558
    }
  }

  depends_on = [ aws_s3_bucket_lifecycle_configuration.rds_logs ]
}

# ------------------------------------------------------------------------------
# Lifecycle Rule: Kubernetes Pod Logs
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "eks_pods" {
  count  = var.enable_hipaa_log_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "hipaa-eks-pods-7year-retention"
    status = "Enabled"

    filter {
      prefix = "logs/kubernetes/pods/"
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER_IR"
    }

    transition {
      days          = 2555
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 2558
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 365
      storage_class   = "GLACIER_IR"
    }

    noncurrent_version_expiration {
      noncurrent_days = 2558
    }
  }

  depends_on = [ aws_s3_bucket_lifecycle_configuration.eks_events ]
}

# ------------------------------------------------------------------------------
# Lifecycle Rule: CloudWatch Metrics (Parquet format)
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "metrics" {
  count  = var.enable_hipaa_log_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "hipaa-metrics-7year-retention"
    status = "Enabled"

    filter {
      prefix = "metrics/cloudwatch/"
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER_IR"
    }

    transition {
      days          = 2555
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 2558
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 365
      storage_class   = "GLACIER_IR"
    }

    noncurrent_version_expiration {
      noncurrent_days = 2558
    }
  }

  depends_on = [ aws_s3_bucket_lifecycle_configuration.eks_pods ]
}

# ------------------------------------------------------------------------------
# Lifecycle Rule: Processing Failed Records
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "processing_failed" {
  count  = var.enable_hipaa_log_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "hipaa-processing-failed-7year-retention"
    status = "Enabled"

    filter {
      prefix = "processing-failed/"
    }

    # Failed records also require 7-year retention for compliance audits
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER_IR"
    }

    transition {
      days          = 2555
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 2558
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 365
      storage_class   = "GLACIER_IR"
    }

    noncurrent_version_expiration {
      noncurrent_days = 2558
    }
  }

  depends_on = [ aws_s3_bucket_lifecycle_configuration.metrics ]
}

# ------------------------------------------------------------------------------
# S3 Object Lock Configuration (Governance Mode for HIPAA)
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_object_lock_configuration" "hipaa_compliance" {
  count  = var.enable_hipaa_log_lifecycle && var.object_lock_enabled ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    default_retention {
      mode  = "GOVERNANCE" # Allows privileged users to delete if needed
      years = 7
    }
  }

  depends_on = [ aws_s3_bucket_lifecycle_configuration.processing_failed ]
}

# ------------------------------------------------------------------------------
# S3 Inventory Configuration (Daily)
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_inventory" "hipaa_logs" {
  count  = var.enable_hipaa_log_lifecycle && var.enable_s3_inventory ? 1 : 0
  bucket = aws_s3_bucket.main.id
  name   = "hipaa-logs-daily-inventory"

  included_object_versions = "All"

  schedule {
    frequency = "Daily"
  }

  destination {
    bucket {
      format     = "Parquet" # Optimized for Athena queries
      bucket_arn = aws_s3_bucket.main.arn
      prefix     = "inventory/"

      encryption {
        sse_kms {
          key_id = module.kms_s3.key_arn
        }
      }
    }
  }

  optional_fields = [
    "Size",
    "LastModifiedDate",
    "StorageClass",
    "ETag",
    "IsMultipartUploaded",
    "ReplicationStatus",
    "EncryptionStatus",
    "ObjectLockRetainUntilDate",
    "ObjectLockMode",
    "ObjectLockLegalHoldStatus"
  ]
}

# ------------------------------------------------------------------------------
# EventBridge Rule: Alert on Processing Failed Records
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "processing_failed_alert" {
  count       = var.enable_hipaa_log_lifecycle && var.enable_processing_failed_alerts ? 1 : 0
  name        = "${var.common_prefix}-${var.environment}-processing-failed-alert"
  description = "Alert when Firehose writes to processing-failed/ prefix (Lambda transformation errors)"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.main.id]
      }
      object = {
        key = [{
          prefix = "processing-failed/"
        }]
      }
    }
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.common_prefix}-${var.environment}-processing-failed-alert"
      Environment = var.environment
      Purpose     = "HIPAA Compliance Monitoring"
    }
  )
}

resource "aws_cloudwatch_event_target" "processing_failed_sns" {
  count = var.enable_hipaa_log_lifecycle && var.enable_processing_failed_alerts && var.processing_failed_sns_topic_arn != null ? 1 : 0
  rule  = aws_cloudwatch_event_rule.processing_failed_alert[0].name
  arn   = var.processing_failed_sns_topic_arn
}

# ------------------------------------------------------------------------------
# S3 Event Notifications (Enable EventBridge)
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_notification" "hipaa_events" {
  count  = var.enable_hipaa_log_lifecycle && var.enable_processing_failed_alerts ? 1 : 0
  bucket = aws_s3_bucket.main.id

  eventbridge = true
}
