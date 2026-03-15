# ==============================================================================
# AWS Client VPN Module - HIPAA S3 Integration
# ==============================================================================
# CloudWatch Logs → Kinesis Data Stream → Firehose → S3 HIPAA Bucket
# 7-year retention for HIPAA compliance
# ==============================================================================

# ------------------------------------------------------------------------------
# Subscription Filter - VPN Logs → Kinesis Data Stream
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_subscription_filter" "vpn_to_kinesis" {
  count = var.enable_hipaa_s3_export ? 1 : 0

  name            = "${local.vpn_name}-to-kinesis"
  log_group_name  = aws_cloudwatch_log_group.vpn_connection_logs.name
  filter_pattern  = "" # Send ALL logs (empty = all events)
  destination_arn = var.kinesis_cloudwatch_stream_arn
  role_arn        = var.cloudwatch_to_kinesis_role_arn

  depends_on = [
    aws_cloudwatch_log_group.vpn_connection_logs
  ]
}

# ==============================================================================
# HIPAA Compliance Flow:
# ==============================================================================
# 1. VPN Connection Event → CloudWatch Logs (30 days - operational debugging)
# 2. Subscription Filter → Kinesis Data Stream (cloudwatch-logs-shared)
# 3. Kinesis Stream (24h buffer) → Kinesis Firehose (cloudwatch-generic)
# 4. Firehose → S3 Primary Bucket (7-year HIPAA retention)
# 5. S3 Replication → S3 DR Bucket (15-min SLA, 7-year retention)
#
# Logged Events:
# - connection-attempt (user initiated connection)
# - connection-established (successful authentication & connection)
# - connection-reset (unexpected disconnection)
# - connection-terminate (user-initiated disconnection)
# - connection-attempt-failure (failed authentication with reason)
#
# Audit Fields:
# - @timestamp: Event timestamp (ISO 8601)
# - connection-id: Unique connection identifier
# - common-name: Username (certificate CN or AD username)
# - client-ip: VPN client IP address (from client_cidr_block)
# - event: Event type (see above)
# - bytes-sent: Data sent from VPN to client (bytes)
# - bytes-received: Data received from client to VPN (bytes)
# - duration-seconds: Connection duration (for terminate/reset events)
# - connection-attempt-failure-reason: Failure reason (for failure events)
#
# S3 Structure:
# logs/cloudwatch/generic/year=YYYY/month=MM/day=DD/hour=HH/
#   └── {prefix}-vpn-{timestamp}.gz (GZIP compressed JSON)
#
# S3 Lifecycle (HIPAA 7-year retention):
# - 0-90d: S3 Standard
# - 91-180d: S3 Standard-IA
# - 181-365d: S3 Glacier Instant Retrieval
# - 366-730d: S3 Glacier Flexible Retrieval
# - 731-2555d: S3 Glacier Deep Archive
# - 2556d+: Expire (automatic deletion)
#
# Encryption:
# - In Transit: TLS (CloudWatch → Kinesis → Firehose → S3)
# - At Rest: KMS (CloudWatch Logs, Kinesis Stream, S3)
# - Cross-Region: Separate KMS keys per region
#
# Geographic Redundancy:
# - Primary: us-east-1 (or configured primary_region)
# - DR: us-west-2 (or configured dr_region)
# - Replication SLA: 15 minutes (S3 Replication Time Control)
# ==============================================================================
