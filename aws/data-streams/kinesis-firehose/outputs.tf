# ==============================================================================
# Outputs - Kinesis Firehose Module
# ==============================================================================

# ------------------------------------------------------------------------------
# Delivery Stream ARNs
# ------------------------------------------------------------------------------

output "waf_stream_arn" {
  description = "ARN of WAF logs Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.waf.arn
}

output "vpc_stream_arn" {
  description = "ARN of VPC Flow Logs Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.vpc.arn
}

output "rds_stream_arn" {
  description = "ARN of RDS logs Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.rds.arn
}

output "eks_events_stream_arn" {
  description = "ARN of EKS Events Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.eks_events.arn
}

output "eks_pods_stream_arn" {
  description = "ARN of EKS Pod Logs Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.eks_pods.arn
}

output "metrics_stream_arn" {
  description = "ARN of CloudWatch Metrics Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.metrics.arn
}

output "cloudwatch_generic_stream_arn" {
  description = "ARN of CloudWatch Generic Firehose delivery stream (from Kinesis Data Stream)"
  value       = aws_kinesis_firehose_delivery_stream.cloudwatch_generic.arn
}

# ------------------------------------------------------------------------------
# Delivery Stream Names
# ------------------------------------------------------------------------------

output "waf_stream_name" {
  description = "Name of WAF logs Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.waf.name
}

output "vpc_stream_name" {
  description = "Name of VPC Flow Logs Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.vpc.name
}

output "rds_stream_name" {
  description = "Name of RDS logs Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.rds.name
}

output "eks_events_stream_name" {
  description = "Name of EKS Events Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.eks_events.name
}

output "eks_pods_stream_name" {
  description = "Name of EKS Pod Logs Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.eks_pods.name
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
# CloudWatch Log Groups
# ------------------------------------------------------------------------------

output "waf_log_group_name" {
  description = "CloudWatch Log Group name for WAF Firehose"
  value       = aws_cloudwatch_log_group.waf.name
}

output "vpc_log_group_name" {
  description = "CloudWatch Log Group name for VPC Firehose"
  value       = aws_cloudwatch_log_group.vpc.name
}

output "rds_log_group_name" {
  description = "CloudWatch Log Group name for RDS Firehose"
  value       = aws_cloudwatch_log_group.rds.name
}

output "eks_events_log_group_name" {
  description = "CloudWatch Log Group name for EKS Events Firehose"
  value       = aws_cloudwatch_log_group.eks_events.name
}

output "eks_pods_log_group_name" {
  description = "CloudWatch Log Group name for EKS Pods Firehose"
  value       = aws_cloudwatch_log_group.eks_pods.name
}

output "metrics_log_group_name" {
  description = "CloudWatch Log Group name for Metrics Firehose"
  value       = aws_cloudwatch_log_group.metrics.name
}

output "cloudwatch_generic_log_group_name" {
  description = "CloudWatch Log Group name for CloudWatch Generic Firehose"
  value       = var.kinesis_cloudwatch_stream_arn != null ? aws_cloudwatch_log_group.cloudwatch_generic.name : null
}

# ------------------------------------------------------------------------------
# All Stream ARNs (for convenience)
# ------------------------------------------------------------------------------

output "all_stream_arns" {
  description = "Map of all Firehose delivery stream ARNs"
  value = {
    waf                = aws_kinesis_firehose_delivery_stream.waf.arn
    vpc                = aws_kinesis_firehose_delivery_stream.vpc.arn
    rds                = aws_kinesis_firehose_delivery_stream.rds.arn
    eks_events         = aws_kinesis_firehose_delivery_stream.eks_events.arn
    eks_pods           = aws_kinesis_firehose_delivery_stream.eks_pods.arn
    metrics            = aws_kinesis_firehose_delivery_stream.metrics.arn
    cloudwatch_generic = aws_kinesis_firehose_delivery_stream.cloudwatch_generic.arn
  }
}

output "all_stream_names" {
  description = "Map of all Firehose delivery stream names"
  value = {
    waf                = aws_kinesis_firehose_delivery_stream.waf.name
    vpc                = aws_kinesis_firehose_delivery_stream.vpc.name
    rds                = aws_kinesis_firehose_delivery_stream.rds.name
    eks_events         = aws_kinesis_firehose_delivery_stream.eks_events.name
    eks_pods           = aws_kinesis_firehose_delivery_stream.eks_pods.name
    metrics            = aws_kinesis_firehose_delivery_stream.metrics.name
    cloudwatch_generic = aws_kinesis_firehose_delivery_stream.cloudwatch_generic.name
  }
}
