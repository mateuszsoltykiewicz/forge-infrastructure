# ==============================================================================
# Observability Infrastructure - Logging & Monitoring
# ==============================================================================
# Lambda Log Transformer + S3 Storage + Kinesis Firehose Delivery Streams
# HIPAA-compliant 7-year retention with automated lifecycle management
# ==============================================================================

# ------------------------------------------------------------------------------
# S3 HIPAA Logs - Cross-Region Replication
# ------------------------------------------------------------------------------
# Primary bucket (current region) + DR bucket (secondary region)
# 7-year HIPAA retention with S3 Replication Time Control (15-min SLA)
# ------------------------------------------------------------------------------

module "s3_hipaa_logs" {
  source = "./logging/hipaa"

  providers = {
    aws.dr_region = aws.dr_region
  }

  # Pattern A variables
  common_prefix = local.common_prefix
  common_tags   = local.merged_tags

  # Region configuration
  primary_region = local.current_region
  dr_region      = local.secondary_region
  dr_tags        = local.dr_tags

  # Safety - prevent accidental deletion
  force_destroy = false
}

# ------------------------------------------------------------------------------
# Kinesis Firehose - Delivery Streams (6 sources)
# ------------------------------------------------------------------------------
# WAF, VPC Flow Logs, RDS, EKS Events, EKS Pods, CloudWatch Metrics
# Direct S3 delivery with Hive partitioning (no Lambda transformation)
# ProcessingFailed → Dedicated S3 prefix for error handling
# ------------------------------------------------------------------------------

module "kinesis_firehose" {
  source = "./data-streams/kinesis-firehose"

  # Pattern A variables
  common_prefix = local.common_prefix
  common_tags   = local.merged_tags
  environment   = "shared"

  # S3 destination
  s3_bucket_arn  = module.s3_hipaa_logs.primary_bucket_arn
  s3_kms_key_arn = module.s3_hipaa_logs.primary_kms_key_arn

  # Buffering configuration (optimize for cost vs latency)
  buffering_size_mb          = 5   # MB (5 MB for faster data availability in Elastic/Grafana)
  buffering_interval_seconds = 300 # seconds (5 minutes)

  # CloudWatch monitoring log retention (1 day)
  firehose_log_retention_days = 1

  # Kinesis Data Stream for CloudWatch subscription filters
  kinesis_cloudwatch_stream_arn = aws_kinesis_stream.cloudwatch_logs.arn

  # Parquet disabled - Elastic/Grafana Stack reads JSON from S3
  enable_metrics_parquet = false

  depends_on = [
    module.s3_hipaa_logs,
    aws_kinesis_stream.cloudwatch_logs,
    module.vpc_endpoint_kinesis_streams,
    module.vpc_endpoint_kinesis_firehose,
    module.vpc_endpoint_s3,
    module.vpc_endpoint_kms
  ]
}

# ------------------------------------------------------------------------------
# Kinesis Data Stream - CloudWatch Logs Aggregation
# ------------------------------------------------------------------------------
# Receives logs from CloudWatch Subscription Filters (Lambda, EKS, RDS, VPN)
# Consumed by Firehose cloudwatch-generic stream for S3 delivery
# ------------------------------------------------------------------------------

resource "aws_kinesis_stream" "cloudwatch_logs" {
  name             = "${local.common_prefix}-cloudwatch-logs-shared"
  shard_count      = 1  # 1 MB/s write capacity (scale to 2 if needed)
  retention_period = 24 # 24 hours minimum

  encryption_type = "KMS"
  kms_key_id      = module.s3_hipaa_logs.primary_kms_key_id # Reuse S3 KMS key

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = merge(
    local.merged_tags,
    {
      Name      = "${local.common_prefix}-cloudwatch-logs-shared"
      Component = "Kinesis Data Stream"
      Purpose   = "CloudWatch Logs Aggregation"
    }
  )
}

# ------------------------------------------------------------------------------
# IAM Role - CloudWatch Logs to Kinesis Data Stream
# ------------------------------------------------------------------------------
# Allows CloudWatch Subscription Filters to write to Kinesis
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "cloudwatch_to_kinesis" {
  name        = "${local.common_prefix}-cloudwatch-to-kinesis-shared"
  description = "Allows CloudWatch Logs to publish to Kinesis Data Stream"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "logs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringLike = {
          "aws:SourceArn" = "arn:aws:logs:${local.current_region}:${data.aws_caller_identity.current.account_id}:log-group:*"
        }
      }
    }]
  })

  tags = merge(
    local.merged_tags,
    {
      Name      = "${local.common_prefix}-cloudwatch-to-kinesis-shared"
      Component = "IAM Role"
      Purpose   = "CloudWatch Subscription Filters"
    }
  )
}

resource "aws_iam_role_policy" "cloudwatch_to_kinesis" {
  name = "kinesis-put-records"
  role = aws_iam_role.cloudwatch_to_kinesis.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "kinesis:PutRecord",
        "kinesis:PutRecords"
      ]
      Resource = aws_kinesis_stream.cloudwatch_logs.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
        "kms:GenerateDataKey"]
        Resource = module.s3_hipaa_logs.primary_kms_key_arn
    }]
  })
}

# ------------------------------------------------------------------------------
# CloudWatch Subscription Filters → Kinesis → Firehose → S3
# ------------------------------------------------------------------------------
# For services that REQUIRE CloudWatch (EKS, RDS, VPN)
# 1-day CloudWatch retention + 7-year S3 archival via Kinesis → Firehose
# ------------------------------------------------------------------------------

# RDS PostgreSQL logs → Kinesis → Firehose → S3 (HIPAA compliance)
resource "aws_cloudwatch_log_subscription_filter" "rds_postgresql_to_kinesis" {
  name            = "rds-postgresql-to-kinesis"
  log_group_name  = "/aws/rds/instance/${module.rds.db_identifier}/postgresql"
  filter_pattern  = "" # Send all logs
  destination_arn = aws_kinesis_stream.cloudwatch_logs.arn
  role_arn        = aws_iam_role.cloudwatch_to_kinesis.arn

  depends_on = [
    aws_iam_role_policy.cloudwatch_to_kinesis,
    aws_kinesis_stream.cloudwatch_logs,
    module.rds # Wait for RDS log group creation
  ]
}

# RDS Upgrade logs → Kinesis → Firehose → S3 (HIPAA compliance)
resource "aws_cloudwatch_log_subscription_filter" "rds_upgrade_to_kinesis" {
  name            = "rds-upgrade-to-kinesis"
  log_group_name  = "/aws/rds/instance/${module.rds.db_identifier}/upgrade"
  filter_pattern  = "" # Send all logs
  destination_arn = aws_kinesis_stream.cloudwatch_logs.arn
  role_arn        = aws_iam_role.cloudwatch_to_kinesis.arn

  depends_on = [
    aws_iam_role_policy.cloudwatch_to_kinesis,
    aws_kinesis_stream.cloudwatch_logs,
    module.rds # Wait for RDS log group creation
  ]
}

# ElastiCache Redis Slow Log → Kinesis → Firehose → S3 (HIPAA compliance)
resource "aws_cloudwatch_log_subscription_filter" "redis_slow_to_kinesis" {
  name            = "redis-slow-to-kinesis"
  log_group_name  = "${module.redis.cloudwatch_log_group_prefix}/slow-log"
  filter_pattern  = "" # Send all logs
  destination_arn = aws_kinesis_stream.cloudwatch_logs.arn
  role_arn        = aws_iam_role.cloudwatch_to_kinesis.arn

  depends_on = [
    aws_iam_role_policy.cloudwatch_to_kinesis,
    aws_kinesis_stream.cloudwatch_logs,
    module.redis # Wait for Redis log group creation
  ]
}

# ElastiCache Redis Engine Log → Kinesis → Firehose → S3 (HIPAA compliance)
resource "aws_cloudwatch_log_subscription_filter" "redis_engine_to_kinesis" {
  name            = "redis-engine-to-kinesis"
  log_group_name  = "${module.redis.cloudwatch_log_group_prefix}/engine-log"
  filter_pattern  = "" # Send all logs
  destination_arn = aws_kinesis_stream.cloudwatch_logs.arn
  role_arn        = aws_iam_role.cloudwatch_to_kinesis.arn

  depends_on = [
    aws_iam_role_policy.cloudwatch_to_kinesis,
    aws_kinesis_stream.cloudwatch_logs,
    module.redis # Wait for Redis log group creation
  ]
}

# VPC Flow Logs → Kinesis → Firehose → S3 (HIPAA compliance)
resource "aws_cloudwatch_log_subscription_filter" "vpc_flow_to_kinesis" {
  name            = "vpc-flow-to-kinesis"
  log_group_name  = module.vpc.flow_logs_log_group_name
  filter_pattern  = "" # Send all logs
  destination_arn = aws_kinesis_stream.cloudwatch_logs.arn
  role_arn        = aws_iam_role.cloudwatch_to_kinesis.arn

  depends_on = [
    aws_iam_role_policy.cloudwatch_to_kinesis,
    aws_kinesis_stream.cloudwatch_logs,
    module.vpc # Wait for VPC Flow Logs log group creation
  ]
}

# EKS Control Plane Logs → Kinesis → Firehose → S3 (HIPAA compliance)
resource "aws_cloudwatch_log_subscription_filter" "eks_cluster_to_kinesis" {
  name            = "eks-cluster-to-kinesis"
  log_group_name  = module.eks.cloudwatch_log_group_name
  filter_pattern  = "" # Send all logs
  destination_arn = aws_kinesis_stream.cloudwatch_logs.arn
  role_arn        = aws_iam_role.cloudwatch_to_kinesis.arn

  depends_on = [
    aws_iam_role_policy.cloudwatch_to_kinesis,
    aws_kinesis_stream.cloudwatch_logs,
    module.eks # Wait for EKS log group creation
  ]
}

# ==============================================================================
# CloudWatch Alarms - S3 Cross-Region Replication Monitoring
# ==============================================================================
# Monitors replication lag and pending bytes for HIPAA compliance
# ==============================================================================

resource "aws_cloudwatch_metric_alarm" "s3_replication_lag" {
  alarm_name          = "${local.common_prefix}-s3-replication-lag-shared"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReplicationLatency"
  namespace           = "AWS/S3"
  period              = 300 # 5 minutes
  statistic           = "Maximum"
  threshold           = 900 # 15 minutes (RTC SLA threshold)
  alarm_description   = "S3 replication lag exceeded 15 minutes (RTC SLA)"
  treat_missing_data  = "notBreaching"

  dimensions = {
    SourceBucket      = module.s3_hipaa_logs.primary_bucket_id
    DestinationBucket = split(":", module.s3_hipaa_logs.dr_bucket_arn)[5] # Extract bucket name from ARN
    RuleId            = "replicate-all-hipaa-logs-to-dr"
  }

  tags = merge(
    local.merged_tags,
    {
      Name      = "${local.common_prefix}-s3-replication-lag-shared"
      Component = "CloudWatch Alarm"
      Purpose   = "S3 Replication Monitoring"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "s3_replication_pending" {
  alarm_name          = "${local.common_prefix}-s3-replication-pending-shared"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "BytesPendingReplication"
  namespace           = "AWS/S3"
  period              = 300 # 5 minutes
  statistic           = "Maximum"
  threshold           = 1073741824 # 1 GB
  alarm_description   = "S3 replication pending bytes exceeded 1 GB"
  treat_missing_data  = "notBreaching"

  dimensions = {
    SourceBucket      = module.s3_hipaa_logs.primary_bucket_id
    DestinationBucket = split(":", module.s3_hipaa_logs.dr_bucket_arn)[5]
    RuleId            = "replicate-all-hipaa-logs-to-dr"
  }

  tags = merge(
    local.merged_tags,
    {
      Name      = "${local.common_prefix}-s3-replication-pending-shared"
      Component = "CloudWatch Alarm"
      Purpose   = "S3 Replication Monitoring"
    }
  )
}

# ==============================================================================
# Architecture Summary - Unified CloudWatch Approach
# ==============================================================================
# Data Flow (Unified):
# ALL sources → CloudWatch Logs (1 day retention) → Kinesis Stream → Firehose → S3
#
# S3 Cross-Region Replication:
# - Primary bucket: {prefix}-hipaa-logs-{primary-region}
# - DR bucket: {prefix}-hipaa-logs-{dr-region}
# - Replication SLA: 15 minutes (S3 Replication Time Control)
# - Encryption: Separate KMS keys per region
# - Lifecycle: 7-year HIPAA retention (both regions)
#
# EXCEPTION: WAF → Firehose (direct) - WAFv2 API does NOT support CloudWatch Logs
#
# Sources sending to CloudWatch:
# 1. RDS PostgreSQL (postgresql + upgrade logs) → CloudWatch → Subscription Filter
# 2. ElastiCache Redis (slow-log + engine-log) → CloudWatch → Subscription Filter
# 3. VPC Flow Logs → CloudWatch → Subscription Filter
# 4. EKS Control Plane (api, audit, authenticator, controllerManager, scheduler) → CloudWatch → Subscription Filter
# 5. EKS Pods/Events → Fluent Bit → Firehose (direct - can be migrated to CloudWatch)
# 6. CloudWatch Metrics → Metric Stream → Firehose (direct - stays as is)
#
# Direct to Firehose (Exceptions):
# - WAF Web ACL → Firehose (WAFv2 requirement - see security.tf)
# - CloudWatch Metrics → Metric Stream → Firehose (Metric Stream is separate from Logs)
#
# CloudWatch Retention Strategy:
# - CloudWatch: 1 day (operational debugging, real-time alerting, CloudWatch Insights)
# - Kinesis Stream: 24 hours buffer (aggregation layer)
# - S3 Primary: 7 years HIPAA (source of truth for compliance & long-term analysis)
# - S3 DR: 7 years HIPAA (disaster recovery copy)
#
# Benefits of Unified CloudWatch:
# - Single observability interface (CloudWatch Logs Insights)
# - Consistent log format and metadata injection possible
# - Easy addition of CloudWatch Alarms and Metric Filters
# - One architectural pattern for all log sources
# - Cross-region disaster recovery with 15-minute RTC SLA
#
# S3 Structure (via Firehose cloudwatch-generic stream):
# - logs/cloudwatch/generic/year=YYYY/month=MM/day=DD/hour=HH/  (ALL CloudWatch sources)
# - logs/kubernetes/pods/year=YYYY/month=MM/day=DD/hour=HH/     (Fluent Bit direct)
# - logs/kubernetes/events/year=YYYY/month=MM/day=DD/hour=HH/   (Fluent Bit direct)
# - metrics/cloudwatch/year=YYYY/month=MM/day=DD/hour=HH/       (Metric Stream direct)
# - processing-failed/{source}/year=YYYY/month=MM/day=DD/hour=HH/
#
# Lifecycle (HIPAA 7-year retention):
# - 0-90d: S3 Standard
# - 91-180d: S3 Standard-IA
# - 181-365d: S3 Glacier Instant Retrieval
# - 366-730d: S3 Glacier Flexible Retrieval
# - 731-2555d: S3 Glacier Deep Archive
# - 2556d+: Expire
#
# Cost Estimate (unified CloudWatch + Cross-Region Replication):
# - CloudWatch Ingestion: ~$50-100/month (varies by volume - WAF/VPC can be high)
# - CloudWatch Storage (1 day): ~$2/month
# - Kinesis Data Stream: ~$11/month (1 shard × 730 hours × $0.015)
# - Kinesis Firehose: ~$30/month (1 stream for CloudWatch generic + 2 direct streams)
# - S3 Storage (Primary): ~$29/month (7 years × 100GB/month = 8.4TB total)
# - S3 Storage (DR): ~$29/month (replicated copy)
# - S3 Replication: ~$10/month (data transfer + RTC)
# - KMS (2 regions): ~$2/month (2 keys × $1/month)
# - Total: ~$163-212/month (vs $122-171 single region)
#
# Trade-offs:
# - Cost: Higher due to cross-region replication and dual storage
# - Simplicity: Much simpler - one pattern for all sources
# - Debugging: CloudWatch Logs Insights available for real-time analysis (1 day window)
# - Flexibility: Easy to add filters, alarms, and metric extraction
# - Compliance: HIPAA-compliant disaster recovery with geographic redundancy
# ==============================================================================
