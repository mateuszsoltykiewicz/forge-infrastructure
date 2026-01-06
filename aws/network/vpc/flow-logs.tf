# ==============================================================================
# VPC Flow Logs - Network Traffic Monitoring
# ==============================================================================
# Captures network traffic information for security monitoring and troubleshooting.
# Logs are sent to CloudWatch Logs with KMS encryption.
# ==============================================================================

# ------------------------------------------------------------------------------
# CloudWatch Log Group for Flow Logs
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.create && var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/${var.vpc_name}/flow-logs"
  retention_in_days = var.flow_logs_retention_days
  kms_key_id        = var.flow_logs_kms_key_id

  tags = merge(
    local.merged_tags,
    {
      Name    = "${var.vpc_name}-flow-logs"
      LogType = "vpc-flow-logs"
    }
  )
}

# ------------------------------------------------------------------------------
# IAM Role for Flow Logs
# ------------------------------------------------------------------------------

resource "aws_iam_role" "flow_logs" {
  count = var.create && var.enable_flow_logs ? 1 : 0

  name = "${var.vpc_name}-flow-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.merged_tags,
    {
      Name = "${var.vpc_name}-flow-logs-role"
    }
  )
}

# ------------------------------------------------------------------------------
# IAM Policy for Flow Logs
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.vpc_name}-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.flow_logs[0].arn}:*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# VPC Flow Log
# ------------------------------------------------------------------------------

resource "aws_flow_log" "main" {
  count = var.create && var.enable_flow_logs ? 1 : 0

  vpc_id                   = aws_vpc.this[0].id
  traffic_type             = var.flow_logs_traffic_type
  iam_role_arn             = aws_iam_role.flow_logs[0].arn
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.flow_logs[0].arn
  max_aggregation_interval = var.flow_logs_aggregation_interval

  tags = merge(
    local.merged_tags,
    {
      Name        = "${var.vpc_name}-flow-log"
      TrafficType = var.flow_logs_traffic_type
    }
  )
}

# ==============================================================================
# Flow Logs Best Practices:
# ==============================================================================
# - Enable for security monitoring and compliance
# - Use "REJECT" traffic type for security analysis (cheaper)
# - Use "ALL" for comprehensive network troubleshooting
# - Set appropriate retention (7 days dev, 30-90 days prod)
# - Use KMS encryption for sensitive environments
# - Monitor CloudWatch costs (flow logs can be expensive)
# ==============================================================================
