# ==============================================================================
# CloudWatch Log Groups for Firehose Monitoring
# ==============================================================================

resource "aws_cloudwatch_log_group" "waf" {
  name              = "/aws/kinesisfirehose/${local.stream_names.waf}"
  retention_in_days = var.firehose_log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name        = "/aws/kinesisfirehose/${local.stream_names.waf}"
      Environment = var.environment
      LogType     = "Firehose WAF"
    }
  )
}

resource "aws_cloudwatch_log_group" "vpc" {
  name              = "/aws/kinesisfirehose/${local.stream_names.vpc}"
  retention_in_days = var.firehose_log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name        = "/aws/kinesisfirehose/${local.stream_names.vpc}"
      Environment = var.environment
      LogType     = "Firehose VPC"
    }
  )
}

resource "aws_cloudwatch_log_group" "rds" {
  name              = "/aws/kinesisfirehose/${local.stream_names.rds}"
  retention_in_days = var.firehose_log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name        = "/aws/kinesisfirehose/${local.stream_names.rds}"
      Environment = var.environment
      LogType     = "Firehose RDS"
    }
  )
}

resource "aws_cloudwatch_log_group" "eks_events" {
  name              = "/aws/kinesisfirehose/${local.stream_names.eks_events}"
  retention_in_days = var.firehose_log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name        = "/aws/kinesisfirehose/${local.stream_names.eks_events}"
      Environment = var.environment
      LogType     = "Firehose EKS Events"
    }
  )
}

resource "aws_cloudwatch_log_group" "eks_pods" {
  name              = "/aws/kinesisfirehose/${local.stream_names.eks_pods}"
  retention_in_days = var.firehose_log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name        = "/aws/kinesisfirehose/${local.stream_names.eks_pods}"
      Environment = var.environment
      LogType     = "Firehose EKS Pods"
    }
  )
}

resource "aws_cloudwatch_log_group" "metrics" {
  name              = "/aws/kinesisfirehose/${local.stream_names.metrics}"
  retention_in_days = var.firehose_log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name        = "/aws/kinesisfirehose/${local.stream_names.metrics}"
      Environment = var.environment
      LogType     = "Firehose Metrics"
    }
  )
}

resource "aws_cloudwatch_log_group" "cloudwatch_generic" {
  name              = "/aws/kinesisfirehose/${local.stream_names.cloudwatch_generic}"
  retention_in_days = var.firehose_log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name        = "/aws/kinesisfirehose/${local.stream_names.cloudwatch_generic}"
      Environment = var.environment
      LogType     = "Firehose CloudWatch Generic"
    }
  )
}
