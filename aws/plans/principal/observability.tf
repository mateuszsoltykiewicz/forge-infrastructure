# ==============================================================================
# Observability Infrastructure - Logging & Monitoring
# ==============================================================================
# Lambda Log Transformer + S3 Storage + Kinesis Firehose Delivery Streams
# HIPAA-compliant 7-year retention with automated lifecycle management
# ==============================================================================

# ------------------------------------------------------------------------------
# S3 Bucket - HIPAA Logs Storage
# ------------------------------------------------------------------------------
# Centralized log storage with 7-year HIPAA retention policy
# Lifecycle: 90d Standard → IA → Glacier IR → Deep Archive → Expire
# ------------------------------------------------------------------------------

module "s3_logs" {
  source = "../../storage/s3"

  # Pattern A variables
  common_prefix = local.common_prefix
  common_tags   = local.merged_tags
  environment   = "shared"
  region        = local.current_region

  # Bucket configuration
  bucket_purpose = "hipaa-logs"
  force_destroy  = false

  # HIPAA lifecycle enabled
  enable_hipaa_log_lifecycle = true

  # S3 Inventory for compliance reporting
  enable_s3_inventory = true

  # Processing failed alerts
  enable_processing_failed_alerts = true
  # processing_failed_sns_topic_arn will be added when SNS module exists

  # Versioning for data protection
  versioning_enabled = true

  # KMS encryption (module creates its own key)
  kms_enable_key_rotation = true
  bucket_key_enabled      = true

  depends_on = [module.vpc]
}

# ------------------------------------------------------------------------------
# Lambda Function - Log Transformer
# ------------------------------------------------------------------------------
# Universal log transformation for Kinesis Firehose
# Auto-detects source (WAF, VPC, RDS, EKS Events, EKS Pods, Metrics)
# Injects Pattern A metadata (Customer, Project, Environment)
# ------------------------------------------------------------------------------

module "lambda_log_transformer" {
  source = "../../compute/lambda-log-transformer"

  # Pattern A variables
  common_prefix = local.common_prefix
  common_tags   = local.merged_tags
  environment   = "shared"
  aws_region    = local.current_region

  # Lambda configuration
  image_uri   = "398456183268.dkr.ecr.${var.current_region}.amazonaws.com/${local.common_prefix}-lambda-log-transformer-production:latest"
  timeout     = 180
  memory_size = 1024

  # Log retention (1 day - S3 is source of truth for ELK)
  log_retention_days = 1

  # CloudWatch KMS encryption (optional)
  cloudwatch_kms_key_arn = null

  # Metrics Parquet format
  enable_metrics_parquet = true

  depends_on = [
    module.vpc
  ]
}

# ------------------------------------------------------------------------------
# Kinesis Firehose - Delivery Streams (6 sources)
# ------------------------------------------------------------------------------
# WAF, VPC Flow Logs, RDS, EKS Events, EKS Pods, CloudWatch Metrics
# Lambda transformation → S3 with Hive partitioning
# ProcessingFailed → Dedicated S3 prefix for error handling
# ------------------------------------------------------------------------------

module "kinesis_firehose" {
  source = "../../data-streams/kinesis-firehose"

  # Pattern A variables
  common_prefix = local.common_prefix
  common_tags   = local.merged_tags
  environment   = "shared"

  # Lambda transformation
  lambda_function_arn = module.lambda_log_transformer.function_arn

  # S3 destination
  s3_bucket_arn  = module.s3_logs.bucket_arn
  s3_kms_key_arn = module.s3_logs.kms_key_arn

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
    module.lambda_log_transformer,
    module.s3_logs,
    aws_kinesis_stream.cloudwatch_logs,
    module.vpc_endpoint_lambda,
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
  kms_key_id      = module.s3_logs.kms_key_id # Reuse S3 KMS key

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
      Resource = module.s3_logs.kms_key_arn
    }]
  })
}

# ------------------------------------------------------------------------------
# CloudWatch Subscription Filters → Kinesis → Firehose → S3
# ------------------------------------------------------------------------------
# For services that REQUIRE CloudWatch (Lambda, EKS, RDS, VPN)
# 1-day CloudWatch retention + 7-year S3 archival via Kinesis → Firehose
# ------------------------------------------------------------------------------

# Lambda Log Transformer logs → Kinesis → Firehose → S3
resource "aws_cloudwatch_log_subscription_filter" "lambda_to_kinesis" {
  name            = "lambda-transformer-to-kinesis"
  log_group_name  = module.lambda_log_transformer.log_group_name
  filter_pattern  = "" # Send all logs
  destination_arn = aws_kinesis_stream.cloudwatch_logs.arn
  role_arn        = aws_iam_role.cloudwatch_to_kinesis.arn

  depends_on = [
    aws_iam_role_policy.cloudwatch_to_kinesis,
    aws_kinesis_stream.cloudwatch_logs
  ]
}

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

# ==============================================================================
# Architecture Summary
# ==============================================================================
# Data Flow:
# 1. Direct Firehose Sources:
#    - Fluent Bit (EKS Events/Pods) → Firehose → Lambda → S3
#    - CloudWatch Metric Stream → Firehose → Lambda → S3
#    - WAF/VPC/Redis (if migrated) → Firehose → Lambda → S3
#
# 2. CloudWatch Subscription Filter Sources (mandatory CloudWatch services):
#    - CloudWatch Logs (Lambda/EKS/RDS/VPN) → Subscription Filter → Kinesis Data Stream
#    - Kinesis Data Stream → Firehose "cloudwatch-generic" → Lambda → S3
#
# CloudWatch Retention Strategy:
# - CloudWatch: 1 day (operational debugging, real-time alerting)
# - S3: 7 years HIPAA (source of truth for ELK/Logstash)
# - All logs flow to same S3 bucket with Hive partitioning
#
# S3 Structure:
# - logs/cloudwatch/waf/year=YYYY/month=MM/day=DD/hour=HH/
# - logs/cloudwatch/vpc/year=YYYY/month=MM/day=DD/hour=HH/
# - logs/cloudwatch/rds/year=YYYY/month=MM/day=DD/hour=HH/
# - logs/cloudwatch/generic/year=YYYY/month=MM/day=DD/hour=HH/  (Lambda/EKS/RDS/VPN via subscription)
# - logs/kubernetes/events/year=YYYY/month=MM/day=DD/hour=HH/
# - logs/kubernetes/pods/year=YYYY/month=MM/day=DD/hour=HH/
# - metrics/cloudwatch/year=YYYY/month=MM/day=DD/hour=HH/ (Parquet)
# - processing-failed/{source}/year=YYYY/month=MM/day=DD/hour=HH/
#
# Lifecycle (HIPAA 7-year retention):
# - 0-90d: S3 Standard
# - 91-365d: S3 Standard-IA
# - 366-2555d: S3 Glacier Instant Retrieval
# - 2556-2557d: S3 Glacier Deep Archive
# - 2558d+: Expire
#
# Cost Estimate (assuming 100GB/month ingestion):
# - CloudWatch Storage: ~$10/month (1-day retention vs $180 for 7-year)
# - Kinesis Data Stream: ~$11/month (1 shard × 730 hours × $0.015)
# - Lambda: ~$240/month (1.5M invocations × 180s avg)
# - S3 Storage: ~$29/month (7 years × 100GB/month = 8.4TB total)
# - Firehose: ~$67/month (100GB × $0.029/GB × 7 streams)  # +1 cloudwatch-generic
# - Total: ~$357/month (vs $507 with 7-year CloudWatch = $150/month savings)
# ==============================================================================
