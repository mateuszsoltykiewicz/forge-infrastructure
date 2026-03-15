# ==============================================================================
# Kinesis Firehose Module - Main Resources
# ==============================================================================
# Unified CloudWatch Approach:
# - WAF logs → Firehose → S3 (direct - WAFv2 requirement)
# - CloudWatch Metrics → Firehose → S3 (direct - Metric Stream)
# - ALL CloudWatch Logs → Kinesis Stream → Firehose "cloudwatch_generic" → S3
# ==============================================================================

# ------------------------------------------------------------------------------
# Kinesis Firehose Delivery Stream - WAF Logs (Direct - WAFv2 Requirement)
# ------------------------------------------------------------------------------
# WAFv2 does NOT support CloudWatch Logs - must use Firehose directly

resource "aws_kinesis_firehose_delivery_stream" "waf" {
  name        = local.stream_names.waf
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose.arn
    bucket_arn          = var.s3_bucket_arn
    prefix              = "logs/cloudwatch/waf/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "processing-failed/waf/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"

    buffering_size     = var.buffering_size_mb
    buffering_interval = var.buffering_interval_seconds
    compression_format = "GZIP"

    # KMS encryption
    s3_backup_mode = var.enable_source_record_backup ? "Enabled" : "Disabled"

    dynamic "s3_backup_configuration" {
      for_each = var.enable_source_record_backup ? [1] : []
      content {
        role_arn   = aws_iam_role.firehose.arn
        bucket_arn = var.s3_bucket_arn
        prefix     = "source-backup/waf/"
      }
    }

    # CloudWatch Logs for delivery monitoring
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.waf.name
      log_stream_name = "S3Delivery"
    }
  }

  tags = merge(
    local.merged_tags,
    {
      Name        = local.stream_names.waf
      Source      = "AWS WAF"
      Environment = var.environment
    }
  )
}

# ------------------------------------------------------------------------------
# Kinesis Firehose Delivery Stream - CloudWatch Metrics (Direct - Metric Stream)
# ------------------------------------------------------------------------------
# CloudWatch Metric Stream sends directly to Firehose (not CloudWatch Logs)

resource "aws_kinesis_firehose_delivery_stream" "metrics" {
  name        = local.stream_names.metrics
  destination = var.enable_metrics_parquet ? "extended_s3" : "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose.arn
    bucket_arn          = var.s3_bucket_arn
    prefix              = var.enable_metrics_parquet ? "metrics/cloudwatch/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/" : "metrics/cloudwatch/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "processing-failed/metrics/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"

    buffering_size     = var.buffering_size_mb
    buffering_interval = var.buffering_interval_seconds
    compression_format = var.enable_metrics_parquet ? "UNCOMPRESSED" : "GZIP"

    s3_backup_mode = var.enable_source_record_backup ? "Enabled" : "Disabled"

    dynamic "s3_backup_configuration" {
      for_each = var.enable_source_record_backup ? [1] : []
      content {
        role_arn   = aws_iam_role.firehose.arn
        bucket_arn = var.s3_bucket_arn
        prefix     = "source-backup/metrics/"
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.metrics.name
      log_stream_name = "S3Delivery"
    }

    # Parquet conversion (optional)
    dynamic "data_format_conversion_configuration" {
      for_each = var.enable_metrics_parquet ? [1] : []

      content {
        input_format_configuration {
          deserializer {
            open_x_json_ser_de {}
          }
        }

        output_format_configuration {
          serializer {
            parquet_ser_de {
              compression = "SNAPPY"
            }
          }
        }

        schema_configuration {
          database_name = local.glue_database
          table_name    = "cloudwatch_metrics"
          role_arn      = aws_iam_role.firehose.arn
        }
      }
    }
  }

  tags = merge(
    local.merged_tags,
    {
      Name        = local.stream_names.metrics
      Source      = "CloudWatch Metrics"
      Environment = var.environment
    }
  )
}

# ------------------------------------------------------------------------------
# Kinesis Firehose Delivery Stream - CloudWatch Generic (from Kinesis Data Stream)
# ------------------------------------------------------------------------------

resource "aws_kinesis_firehose_delivery_stream" "cloudwatch_generic" {
  name        = local.stream_names.cloudwatch_generic
  destination = "extended_s3"

  # Source from Kinesis Data Stream
  kinesis_source_configuration {
    kinesis_stream_arn = var.kinesis_cloudwatch_stream_arn
    role_arn           = aws_iam_role.firehose.arn
  }

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose.arn
    bucket_arn          = var.s3_bucket_arn
    prefix              = "logs/cloudwatch/generic/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "processing-failed/cloudwatch-generic/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"

    buffering_size     = var.buffering_size_mb
    buffering_interval = var.buffering_interval_seconds
    compression_format = "GZIP"

    s3_backup_mode = var.enable_source_record_backup ? "Enabled" : "Disabled"

    dynamic "s3_backup_configuration" {
      for_each = var.enable_source_record_backup ? [1] : []
      content {
        role_arn   = aws_iam_role.firehose.arn
        bucket_arn = var.s3_bucket_arn
        prefix     = "source-backup/cloudwatch-generic/"
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.cloudwatch_generic.name
      log_stream_name = "S3Delivery"
    }
  }

  tags = merge(
    local.merged_tags,
    {
      Name        = local.stream_names.cloudwatch_generic
      Source      = "CloudWatch Logs (Generic)"
      Environment = var.environment
    }
  )
}