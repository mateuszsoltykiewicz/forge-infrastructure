# ==============================================================================
# AWS Client VPN Module - CloudWatch Logs Configuration
# ==============================================================================
# This file configures CloudWatch Logs for VPN connection logging.
# Logs include: connection attempts, successful connections, disconnections, and errors.
# ==============================================================================

# ------------------------------------------------------------------------------
# CloudWatch Log Group
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "vpn_connection_logs" {
  count = var.enable_connection_logs ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = var.cloudwatch_kms_key_arn

  tags = merge(
    local.merged_tags,
    {
      Name        = local.log_group_name
      Description = "VPN connection logs for ${local.vpn_name}"
    }
  )
}

# ------------------------------------------------------------------------------
# CloudWatch Log Stream
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_stream" "vpn_connection_stream" {
  count = var.enable_connection_logs ? 1 : 0

  name           = "connection-log-stream"
  log_group_name = aws_cloudwatch_log_group.vpn_connection_logs[0].name
}

# ==============================================================================
# CloudWatch Logs Structure:
# ==============================================================================
# VPN connection logs include the following information:
# - Timestamp: When the event occurred
# - Connection ID: Unique identifier for the VPN connection
# - Client IP: IP address assigned to the VPN client
# - Username: Authenticated user (certificate CN or AD username)
# - Event: connection-attempt, connection-established, connection-reset, connection-terminate
# - Bytes In/Out: Data transferred during the connection
# - Duration: Connection duration in seconds
# - Status: Success or failure reason
#
# Example log entry:
# {
#   "connection-id": "cvpn-connection-abc123",
#   "client-ip": "172.16.0.10",
#   "common-name": "user@example.com",
#   "event": "connection-established",
#   "timestamp": "2026-01-06T10:30:45Z",
#   "bytes-sent": 1024000,
#   "bytes-received": 2048000,
#   "duration-seconds": 3600
# }
# ==============================================================================

# ==============================================================================
# Monitoring Best Practices:
# ==============================================================================
# - Set retention to 30 days for production, 7 days for development
# - Use KMS encryption for sensitive connection logs
# - Create CloudWatch Insights queries for connection analytics
# - Set up CloudWatch Alarms for failed connection attempts
# - Export logs to S3 for long-term archival (via Lambda or Kinesis Firehose)
# - Monitor metrics: active connections, connection attempts, data transfer
# ==============================================================================
