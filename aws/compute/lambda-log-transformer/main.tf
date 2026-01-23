# ==============================================================================
# Lambda Log Transformer Module
# ==============================================================================
# Universal Lambda function for Kinesis Firehose log transformation.
# Supports multiple sources: WAF, VPC Flow Logs, RDS, EKS Events/Pods, Metrics.
# Pattern A compliant with auto-detection from deliveryStreamArn.
# ==============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ------------------------------------------------------------------------------
# Lambda Function (Container Image)
# ------------------------------------------------------------------------------

resource "aws_lambda_function" "log_transformer" {
  function_name = local.function_name
  description   = "Universal log transformer for Kinesis Firehose (WAF, VPC, RDS, EKS, Metrics)"

  # Container image deployment
  package_type  = "Image"
  image_uri     = var.image_uri
  architectures = ["x86_64"] # AWS Lambda public base images use x86_64

  # IAM role
  role = aws_iam_role.lambda_execution.arn

  # Performance settings
  timeout     = var.timeout
  memory_size = var.memory_size

  # Concurrency (null = unreserved)
  reserved_concurrent_executions = var.reserved_concurrent_executions

  # Environment variables (Pattern A)
  environment {
    variables = {
      CUSTOMER    = var.common_tags.Customer
      PROJECT     = var.common_tags.Project
      ENVIRONMENT = var.environment

      # Optional feature flags
      ENABLE_METRICS_PARQUET = tostring(var.enable_metrics_parquet)
      LOG_LEVEL              = var.log_level
    }
  }

  # CloudWatch Logs configuration
  logging_config {
    log_format = "Text" # JSON format causes nested escaping issues
    log_group  = aws_cloudwatch_log_group.lambda_logs.name
  }

  # Tagging (Pattern A)
  tags = merge(
    var.common_tags,
    {
      Name        = local.function_name
      Component   = "Lambda Log Transformer"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Module      = "compute/lambda-log-transformer"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_cloudwatch_log_group.lambda_logs
  ]
}

# ------------------------------------------------------------------------------
# CloudWatch Log Group (7-year retention for HIPAA)
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days

  # KMS encryption (optional, controlled by var)
  kms_key_id = var.cloudwatch_kms_key_arn

  tags = merge(
    var.common_tags,
    {
      Name        = "/aws/lambda/${local.function_name}"
      Component   = "Lambda Logs"
      Environment = var.environment
    }
  )
}

# ------------------------------------------------------------------------------
# Lambda Invocation Permission for Firehose
# ------------------------------------------------------------------------------

# Random suffix to prevent conflicts during create_before_destroy lifecycle
resource "random_id" "permission_suffix" {
  byte_length = 4

  keepers = {
    # Trigger regeneration when Lambda image changes (not function_name - it's constant)
    image_uri = var.image_uri
  }
}

resource "aws_lambda_permission" "allow_firehose" {
  statement_id  = "AllowKinesisFirehoseInvoke-${random_id.permission_suffix.hex}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_transformer.function_name
  principal     = "firehose.amazonaws.com"

  # Source ARN pattern: match all Firehose streams in this account/region
  source_arn = "arn:aws:firehose:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deliverystream/*"

  # Prevent create_before_destroy inheritance to avoid statement_id conflicts
  lifecycle {
    create_before_destroy = false
  }
}
