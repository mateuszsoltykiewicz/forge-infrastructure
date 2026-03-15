# ==============================================================================
# Outputs - Kinesis Firehose Module (Unified CloudWatch Approach)
# ==============================================================================
# Only 3 active streams: WAF (direct), Metrics (direct), CloudWatch Generic (unified)
# ==============================================================================

# ------------------------------------------------------------------------------
# Delivery Stream ARNs
# ------------------------------------------------------------------------------

output "waf_stream_arn" {
  description = "ARN of WAF logs Firehose delivery stream (direct - WAFv2 requirement)"
  value       = aws_kinesis_firehose_delivery_stream.waf.arn
}

output "metrics_stream_arn" {
  description = "ARN of CloudWatch Metrics Firehose delivery stream (direct - Metric Stream)"
  value       = aws_kinesis_firehose_delivery_stream.metrics.arn
}

output "cloudwatch_generic_stream_arn" {
  description = "ARN of CloudWatch Generic Firehose delivery stream (unified - all CloudWatch Logs via Kinesis Stream)"
  value       = aws_kinesis_firehose_delivery_stream.cloudwatch_generic.arn
}

# ------------------------------------------------------------------------------
# Delivery Stream Names
# ------------------------------------------------------------------------------

output "waf_stream_name" {
  description = "Name of WAF logs Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.waf.name
}

output "metrics_stream_name" {
  description = "Name of CloudWatch Metrics Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.metrics.name
}

output "cloudwatch_generic_stream_name" {
  description = "Name of CloudWatch Generic Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.cloudwatch_generic.name
}

# ------------------------------------------------------------------------------
# IAM Role
# ------------------------------------------------------------------------------

output "firehose_role_arn" {
  description = "ARN of Firehose IAM service role"
  value       = aws_iam_role.firehose.arn
}

output "firehose_role_name" {
  description = "Name of Firehose IAM service role"
  value       = aws_iam_role.firehose.name
}

# ------------------------------------------------------------------------------
# CloudWatch Log Groups (Firehose Monitoring)
# ------------------------------------------------------------------------------

output "waf_log_group_name" {
  description = "CloudWatch Log Group name for WAF Firehose monitoring"
  value       = aws_cloudwatch_log_group.waf.name
}

output "metrics_log_group_name" {
  description = "CloudWatch Log Group name for Metrics Firehose monitoring"
  value       = aws_cloudwatch_log_group.metrics.name
}

output "cloudwatch_generic_log_group_name" {
  description = "CloudWatch Log Group name for CloudWatch Generic Firehose monitoring"
  value       = var.kinesis_cloudwatch_stream_arn != null ? aws_cloudwatch_log_group.cloudwatch_generic.name : null
}

# ------------------------------------------------------------------------------
# All Stream ARNs (for convenience)
# ------------------------------------------------------------------------------

output "all_stream_arns" {
  description = "Map of all active Firehose delivery stream ARNs"
  value = {
    waf                = aws_kinesis_firehose_delivery_stream.waf.arn
    metrics            = aws_kinesis_firehose_delivery_stream.metrics.arn
    cloudwatch_generic = aws_kinesis_firehose_delivery_stream.cloudwatch_generic.arn
  }
}

output "all_stream_names" {
  description = "Map of all active Firehose delivery stream names"
  value = {
    waf                = aws_kinesis_firehose_delivery_stream.waf.name
    metrics            = aws_kinesis_firehose_delivery_stream.metrics.name
    cloudwatch_generic = aws_kinesis_firehose_delivery_stream.cloudwatch_generic.name
  }
}
