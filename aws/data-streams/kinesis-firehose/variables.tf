# ==============================================================================
# Variables - Kinesis Firehose Module
# ==============================================================================

# ------------------------------------------------------------------------------
# Pattern A Variables (Required)
# ------------------------------------------------------------------------------

variable "common_prefix" {
  description = "Common prefix for all resources (Pattern A)"
  type        = string

  validation {
    condition     = length(var.common_prefix) > 0 && length(var.common_prefix) <= 20
    error_message = "common_prefix must be between 1 and 20 characters"
  }
}

variable "common_tags" {
  description = "Common tags for all resources (Pattern A). Must include: Customer, Project, Environment, ManagedBy"
  type        = map(string)

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

variable "environment" {
  description = "Environment name (dev, staging, production, shared)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production", "shared"], var.environment)
    error_message = "environment must be one of: dev, staging, production, shared"
  }
}

# ------------------------------------------------------------------------------
# Lambda Configuration
# ------------------------------------------------------------------------------

variable "lambda_function_arn" {
  description = "ARN of Lambda function for log transformation (from compute/lambda-log-transformer module)"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:lambda:[a-z0-9-]+:\\d+:function:.+$", var.lambda_function_arn))
    error_message = "lambda_function_arn must be a valid Lambda ARN"
  }
}

# ------------------------------------------------------------------------------
# S3 Configuration
# ------------------------------------------------------------------------------

variable "s3_bucket_arn" {
  description = "ARN of S3 bucket for log storage (from storage/s3 module)"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:s3:::.+$", var.s3_bucket_arn))
    error_message = "s3_bucket_arn must be a valid S3 bucket ARN"
  }
}

variable "s3_kms_key_arn" {
  description = "ARN of KMS key for S3 encryption (from storage/s3 module)"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:kms:[a-z0-9-]+:\\d+:key/.+$", var.s3_kms_key_arn))
    error_message = "s3_kms_key_arn must be a valid KMS key ARN"
  }
}

# ------------------------------------------------------------------------------
# Buffering Configuration
# ------------------------------------------------------------------------------

variable "buffering_size_mb" {
  description = "Buffer size in MB before flushing to S3 (1-128 MB)"
  type        = number
  default     = 5

  validation {
    condition     = var.buffering_size_mb >= 1 && var.buffering_size_mb <= 128
    error_message = "buffering_size_mb must be between 1 and 128 MB"
  }
}

variable "buffering_interval_seconds" {
  description = "Buffer interval in seconds before flushing to S3 (60-900 seconds)"
  type        = number
  default     = 300

  validation {
    condition     = var.buffering_interval_seconds >= 60 && var.buffering_interval_seconds <= 900
    error_message = "buffering_interval_seconds must be between 60 and 900 seconds"
  }
}

# ------------------------------------------------------------------------------
# CloudWatch Logs Configuration
# ------------------------------------------------------------------------------

variable "firehose_log_retention_days" {
  description = "CloudWatch Logs retention for Firehose delivery logs (days)"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.firehose_log_retention_days)
    error_message = "firehose_log_retention_days must be a valid CloudWatch Logs retention period"
  }
}

# ------------------------------------------------------------------------------
# Feature Flags
# ------------------------------------------------------------------------------

variable "enable_metrics_parquet" {
  description = "Enable Parquet format for CloudWatch Metrics stream (10x faster Athena, 5x compression)"
  type        = bool
  default     = true
}

variable "enable_source_record_backup" {
  description = "Enable S3 backup of source records before transformation (for debugging)"
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# Glue Configuration (for Parquet)
# ------------------------------------------------------------------------------

variable "glue_database_name" {
  description = "AWS Glue database name for Parquet schema (required if enable_metrics_parquet is true). If null, uses '{common_prefix}_logs'"
  type        = string
  default     = null

  validation {
    condition     = var.glue_database_name == null || can(regex("^[a-z0-9_]+$", var.glue_database_name))
    error_message = "glue_database_name must contain only lowercase letters, numbers, and underscores"
  }
}

# ------------------------------------------------------------------------------
# Kinesis Data Stream Configuration
# ------------------------------------------------------------------------------

variable "kinesis_cloudwatch_stream_arn" {
  description = "ARN of Kinesis Data Stream for CloudWatch logs aggregation (optional, for cloudwatch-generic stream)"
  type        = string
  default     = null
}
