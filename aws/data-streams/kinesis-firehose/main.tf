# ==============================================================================
# Kinesis Firehose Module - Universal Log Delivery Streams
# ==============================================================================
# Creates 7 Firehose delivery streams for centralized log collection:
# - CloudWatch Logs: WAF, VPC Flow Logs, RDS, Generic (from Kinesis Stream)
# - Kubernetes: Events, Pod Logs  
# - CloudWatch Metrics (with optional Parquet format)
#
# All streams use Lambda transformation for Pattern A metadata enrichment
# and deliver to S3 with HIPAA-compliant lifecycle rules.
# ==============================================================================

# ------------------------------------------------------------------------------
# WAF Logs Stream
# ------------------------------------------------------------------------------

resource "aws_kinesis_firehose_delivery_stream" "waf" {
  name        = local.stream_names.waf
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = var.s3_bucket_arn
    prefix     = "logs/cloudwatch/waf/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"

    error_output_prefix = "processing-failed/waf/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"

    buffering_size     = var.buffering_size_mb
    buffering_interval = var.buffering_interval_seconds
    compression_format = "GZIP"

    # Lambda transformation
    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = var.lambda_function_arn
        }

        parameters {
          parameter_name  = "BufferSizeInMBs"
          parameter_value = "3"
        }

        parameters {
          parameter_name  = "BufferIntervalInSeconds"
          parameter_value = "60"
        }
      }
    }

    # CloudWatch logging
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.waf.name
      log_stream_name = "S3Delivery"
    }

    # S3 backup for source records (optional)
    dynamic "s3_backup_configuration" {
      for_each = var.enable_source_record_backup ? [1] : []

      content {
        role_arn   = aws_iam_role.firehose.arn
        bucket_arn = var.s3_bucket_arn
        prefix     = "source-records/waf/"

        buffering_size     = 5
        buffering_interval = 300
        compression_format = "GZIP"
      }
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name        = local.stream_names.waf
      Environment = var.environment
      LogSource   = "AWS WAF"
    }
  )
}

# ------------------------------------------------------------------------------
# VPC Flow Logs Stream
# ------------------------------------------------------------------------------

resource "aws_kinesis_firehose_delivery_stream" "vpc" {
  name        = local.stream_names.vpc
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = var.s3_bucket_arn
    prefix     = "logs/cloudwatch/vpc/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"

    error_output_prefix = "processing-failed/vpc/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"

    buffering_size     = var.buffering_size_mb
    buffering_interval = var.buffering_interval_seconds
    compression_format = "GZIP"

    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = var.lambda_function_arn
        }

        parameters {
          parameter_name  = "BufferSizeInMBs"
          parameter_value = "3"
        }

        parameters {
          parameter_name  = "BufferIntervalInSeconds"
          parameter_value = "60"
        }
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.vpc.name
      log_stream_name = "S3Delivery"
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name        = local.stream_names.vpc
      Environment = var.environment
      LogSource   = "VPC Flow Logs"
    }
  )
}

# ------------------------------------------------------------------------------
# RDS Logs Stream
# ------------------------------------------------------------------------------

resource "aws_kinesis_firehose_delivery_stream" "rds" {
  name        = local.stream_names.rds
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = var.s3_bucket_arn
    prefix     = "logs/cloudwatch/rds/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"

    error_output_prefix = "processing-failed/rds/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"

    buffering_size     = var.buffering_size_mb
    buffering_interval = var.buffering_interval_seconds
    compression_format = "GZIP"

    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = var.lambda_function_arn
        }

        parameters {
          parameter_name  = "BufferSizeInMBs"
          parameter_value = "3"
        }

        parameters {
          parameter_name  = "BufferIntervalInSeconds"
          parameter_value = "60"
        }
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.rds.name
      log_stream_name = "S3Delivery"
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name        = local.stream_names.rds
      Environment = var.environment
      LogSource   = "RDS PostgreSQL"
    }
  )
}

# ------------------------------------------------------------------------------
# EKS Events Stream
# ------------------------------------------------------------------------------

resource "aws_kinesis_firehose_delivery_stream" "eks_events" {
  name        = local.stream_names.eks_events
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = var.s3_bucket_arn
    prefix     = "logs/kubernetes/events/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"

    error_output_prefix = "processing-failed/eks-events/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"

    buffering_size     = var.buffering_size_mb
    buffering_interval = var.buffering_interval_seconds
    compression_format = "GZIP"

    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = var.lambda_function_arn
        }

        parameters {
          parameter_name  = "BufferSizeInMBs"
          parameter_value = "3"
        }

        parameters {
          parameter_name  = "BufferIntervalInSeconds"
          parameter_value = "60"
        }
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.eks_events.name
      log_stream_name = "S3Delivery"
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name        = local.stream_names.eks_events
      Environment = var.environment
      LogSource   = "Kubernetes Events"
    }
  )
}

# ------------------------------------------------------------------------------
# EKS Pod Logs Stream
# ------------------------------------------------------------------------------

resource "aws_kinesis_firehose_delivery_stream" "eks_pods" {
  name        = local.stream_names.eks_pods
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = var.s3_bucket_arn
    prefix     = "logs/kubernetes/pods/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"

    error_output_prefix = "processing-failed/eks-pods/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"

    buffering_size     = var.buffering_size_mb
    buffering_interval = var.buffering_interval_seconds
    compression_format = "GZIP"

    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = var.lambda_function_arn
        }

        parameters {
          parameter_name  = "BufferSizeInMBs"
          parameter_value = "3"
        }

        parameters {
          parameter_name  = "BufferIntervalInSeconds"
          parameter_value = "60"
        }
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.eks_pods.name
      log_stream_name = "S3Delivery"
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name        = local.stream_names.eks_pods
      Environment = var.environment
      LogSource   = "Kubernetes Pod Logs"
    }
  )
}

# ------------------------------------------------------------------------------
# CloudWatch Metrics Stream (with optional Parquet format)
# ------------------------------------------------------------------------------

resource "aws_kinesis_firehose_delivery_stream" "metrics" {
  name        = local.stream_names.metrics
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = var.s3_bucket_arn
    prefix     = "metrics/cloudwatch/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"

    error_output_prefix = "processing-failed/metrics/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"

    buffering_size     = var.buffering_size_mb
    buffering_interval = var.buffering_interval_seconds

    # Parquet format for Athena optimization (if enabled)
    compression_format = var.enable_metrics_parquet ? "UNCOMPRESSED" : "GZIP"

    # Data format conversion for Parquet
    dynamic "data_format_conversion_configuration" {
      for_each = var.enable_metrics_parquet ? [1] : []

      content {
        enabled = true

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
          database_name = var.glue_database_name != null ? var.glue_database_name : "${var.common_prefix}_logs"
          table_name    = "cloudwatch_metrics"
          region        = data.aws_region.current.name
          role_arn      = aws_iam_role.firehose.arn
        }
      }
    }

    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = var.lambda_function_arn
        }

        parameters {
          parameter_name  = "BufferSizeInMBs"
          parameter_value = "3"
        }

        parameters {
          parameter_name  = "BufferIntervalInSeconds"
          parameter_value = "60"
        }
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.metrics.name
      log_stream_name = "S3Delivery"
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name        = local.stream_names.metrics
      Environment = var.environment
      LogSource   = "CloudWatch Metrics"
    }
  )
}

# ------------------------------------------------------------------------------
# CloudWatch Generic Logs Stream (from Kinesis Data Stream)
# ------------------------------------------------------------------------------

resource "aws_kinesis_firehose_delivery_stream" "cloudwatch_generic" {
  name        = local.stream_names.cloudwatch_generic
  destination = "extended_s3"

  # Source: Kinesis Data Stream (subscription filters from CloudWatch)
  # Dynamic block - only created if ARN is provided
  dynamic "kinesis_source_configuration" {
    for_each = var.kinesis_cloudwatch_stream_arn != null ? [1] : []
    content {
      kinesis_stream_arn = var.kinesis_cloudwatch_stream_arn
      role_arn           = aws_iam_role.firehose.arn
    }
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = var.s3_bucket_arn
    prefix     = "logs/cloudwatch/generic/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"

    error_output_prefix = "processing-failed/cloudwatch-generic/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"

    buffering_size     = var.buffering_size_mb
    buffering_interval = var.buffering_interval_seconds
    compression_format = "GZIP"

    # Lambda transformation (same as other streams)
    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = var.lambda_function_arn
        }

        parameters {
          parameter_name  = "BufferSizeInMBs"
          parameter_value = "3"
        }

        parameters {
          parameter_name  = "BufferIntervalInSeconds"
          parameter_value = "60"
        }
      }
    }

    # S3 backup for source records (optional)
    dynamic "s3_backup_configuration" {
      for_each = var.enable_source_record_backup ? [1] : []
      content {
        role_arn   = aws_iam_role.firehose.arn
        bucket_arn = var.s3_bucket_arn
        prefix     = "backup/cloudwatch-generic/"
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.cloudwatch_generic.name
      log_stream_name = "S3Delivery"
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name        = local.stream_names.cloudwatch_generic
      Environment = var.environment
      LogSource   = "Kinesis Data Stream - CloudWatch Subscription Filters"
    }
  )

  depends_on = [
    aws_iam_role_policy.firehose_s3,
    aws_iam_role_policy.firehose_lambda
  ]
}
