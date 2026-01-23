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

  name              = "/aws/vpc/${local.vpc_name}/flow-logs"
  retention_in_days = var.flow_logs_retention_days
  kms_key_id        = module.kms_flow_logs.key_arn

  tags = merge(
    local.merged_tags,
    {
      Name    = "${local.vpc_name}-flow-logs"
      LogType = "vpc-flow-logs"
    }
  )

  depends_on = [module.kms_flow_logs]
}

# ------------------------------------------------------------------------------
# IAM Role for Flow Logs
# ------------------------------------------------------------------------------

resource "aws_iam_role" "flow_logs" {

  name = "${local.vpc_name}-flow-logs-role"
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
      Name = "${local.vpc_name}-flow-logs-role"
    }
  )
}

# ------------------------------------------------------------------------------
# IAM Policy for Flow Logs
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy" "flow_logs" {

  name = "${local.vpc_name}-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

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
        Resource = "${aws_cloudwatch_log_group.flow_logs.arn}:*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# VPC Flow Log
# ------------------------------------------------------------------------------

resource "aws_flow_log" "main" {

  vpc_id                   = aws_vpc.this.id
  traffic_type             = var.flow_logs_traffic_type
  iam_role_arn             = aws_iam_role.flow_logs.arn
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.flow_logs.arn
  max_aggregation_interval = var.flow_logs_aggregation_interval

  tags = merge(
    local.merged_tags,
    {
      Name        = "${local.vpc_name}-flow-log"
      TrafficType = var.flow_logs_traffic_type
    }
  )
}