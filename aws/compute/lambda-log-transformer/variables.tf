# ==============================================================================
# Variables - Lambda Log Transformer Module
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

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

# ------------------------------------------------------------------------------
# Lambda Configuration
# ------------------------------------------------------------------------------

variable "image_uri" {
  description = "ECR image URI for Lambda function (e.g., 123456789012.dkr.ecr.us-east-1.amazonaws.com/lambda-log-transformer:latest)"
  type        = string

  validation {
    condition     = can(regex("^\\d+\\.dkr\\.ecr\\.[a-z0-9-]+\\.amazonaws\\.com/.+:.+$", var.image_uri))
    error_message = "image_uri must be a valid ECR image URI with tag"
  }
}

variable "timeout" {
  description = "Lambda function timeout in seconds (max 900 for Lambda, Firehose timeout is 180s)"
  type        = number
  default     = 180

  validation {
    condition     = var.timeout >= 60 && var.timeout <= 180
    error_message = "timeout must be between 60 and 180 seconds (Firehose limit)"
  }
}

variable "memory_size" {
  description = "Lambda function memory in MB (128-10240)"
  type        = number
  default     = 1024

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "memory_size must be between 128 and 10240 MB"
  }
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions (null = unreserved, -1 = throttle all, 1+ = reserved). Default null for moderate workloads (~30 pods)."
  type        = number
  default     = null
}

# ------------------------------------------------------------------------------
# Feature Flags
# ------------------------------------------------------------------------------

variable "enable_metrics_parquet" {
  description = "Enable Parquet format for CloudWatch Metrics (10x faster Athena queries, 5x better compression)"
  type        = bool
  default     = true
}

variable "log_level" {
  description = "Lambda function log level (DEBUG, INFO, WARNING, ERROR)"
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR"], var.log_level)
    error_message = "log_level must be one of: DEBUG, INFO, WARNING, ERROR"
  }
}

# ------------------------------------------------------------------------------
# CloudWatch Logs Configuration
# ------------------------------------------------------------------------------

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days (HIPAA 7-year = 2557 days)"
  type        = number
  default     = 2557

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch Logs retention period"
  }
}

variable "cloudwatch_kms_key_arn" {
  description = "Optional KMS key ARN for CloudWatch Logs encryption (null = AWS managed key)"
  type        = string
  default     = null

  validation {
    condition     = var.cloudwatch_kms_key_arn == null || can(regex("^arn:aws:kms:[a-z0-9-]+:\\d+:key/[a-f0-9-]+$", var.cloudwatch_kms_key_arn))
    error_message = "cloudwatch_kms_key_arn must be a valid KMS key ARN or null"
  }
}
