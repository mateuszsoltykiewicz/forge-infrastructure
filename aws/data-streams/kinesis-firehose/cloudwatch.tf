# ==============================================================================
# CloudWatch Log Groups for Firehose Monitoring
# ==============================================================================
# These log groups monitor Firehose delivery stream operations (errors, throttling, etc.)
# They are NOT application log sources - those go to CloudWatch → Kinesis Stream
# ==============================================================================

# WAF Firehose monitoring (WAF logs go directly to this Firehose)
resource "aws_cloudwatch_log_group" "waf" {
  name              = "/aws/kinesisfirehose/${local.stream_names.waf}"
  retention_in_days = var.firehose_log_retention_days

  tags = merge(
    local.merged_tags,
    {
      Name        = "/aws/kinesisfirehose/${local.stream_names.waf}"
      Environment = var.environment
      LogType     = "Firehose WAF Monitoring"
    }
  )
}

# CloudWatch Metrics Firehose monitoring (Metric Stream goes directly here)
resource "aws_cloudwatch_log_group" "metrics" {
  name              = "/aws/kinesisfirehose/${local.stream_names.metrics}"
  retention_in_days = var.firehose_log_retention_days

  tags = merge(
    local.merged_tags,
    {
      Name        = "/aws/kinesisfirehose/${local.stream_names.metrics}"
      Environment = var.environment
      LogType     = "Firehose Metrics Monitoring"
    }
  )
}

# CloudWatch Generic Firehose monitoring (ALL CloudWatch Logs via Kinesis Stream)
resource "aws_cloudwatch_log_group" "cloudwatch_generic" {
  name              = "/aws/kinesisfirehose/${local.stream_names.cloudwatch_generic}"
  retention_in_days = var.firehose_log_retention_days

  tags = merge(
    local.merged_tags,
    {
      Name        = "/aws/kinesisfirehose/${local.stream_names.cloudwatch_generic}"
      Environment = var.environment
      LogType     = "Firehose CloudWatch Generic Monitoring"
    }
  )
}