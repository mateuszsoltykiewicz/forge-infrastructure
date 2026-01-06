# ==============================================================================
# RDS PostgreSQL Module - CloudWatch Monitoring
# ==============================================================================
# This file creates CloudWatch log groups, dashboard, and alarms for RDS monitoring.
# ==============================================================================

# ------------------------------------------------------------------------------
# CloudWatch Log Groups
# ------------------------------------------------------------------------------

# PostgreSQL log group (for database logs)
resource "aws_cloudwatch_log_group" "postgresql" {
  name              = "/aws/rds/instance/${local.db_identifier}/postgresql"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.rds.arn

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.db_identifier}-postgresql-logs"
    }
  )
}

# Upgrade log group (for RDS version upgrades)
resource "aws_cloudwatch_log_group" "upgrade" {
  name              = "/aws/rds/instance/${local.db_identifier}/upgrade"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.rds.arn

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.db_identifier}-upgrade-logs"
    }
  )
}

# ------------------------------------------------------------------------------
# CloudWatch Dashboard
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "rds" {
  dashboard_name = "${local.db_identifier}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { stat = "Average", label = "CPU Average" }],
            ["...", { stat = "Maximum", label = "CPU Max" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "CPU Utilization"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "FreeableMemory", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Freeable Memory"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", { stat = "Average", label = "Connections" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Database Connections"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "ReadIOPS", { stat = "Average", label = "Read IOPS" }],
            [".", "WriteIOPS", { stat = "Average", label = "Write IOPS" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Read/Write IOPS"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "ReadLatency", { stat = "Average", label = "Read Latency" }],
            [".", "WriteLatency", { stat = "Average", label = "Write Latency" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Read/Write Latency"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Free Storage Space"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "NetworkReceiveThroughput", { stat = "Average", label = "Network In" }],
            [".", "NetworkTransmitThroughput", { stat = "Average", label = "Network Out" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Network Throughput"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "ReplicaLag", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Replica Lag (Multi-AZ)"
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# CloudWatch Alarms
# ------------------------------------------------------------------------------

# High CPU alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.db_identifier}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU utilization is too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = local.db_identifier
  }

  tags = local.merged_tags
}

# Low freeable memory alarm
resource "aws_cloudwatch_metric_alarm" "low_memory" {
  alarm_name          = "${local.db_identifier}-low-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 1073741824 # 1 GB in bytes
  alarm_description   = "RDS freeable memory is too low"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = local.db_identifier
  }

  tags = local.merged_tags
}

# Low free storage alarm
resource "aws_cloudwatch_metric_alarm" "low_storage" {
  alarm_name          = "${local.db_identifier}-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240 # 10 GB in bytes
  alarm_description   = "RDS free storage space is too low"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = local.db_identifier
  }

  tags = local.merged_tags
}

# High database connections alarm
resource "aws_cloudwatch_metric_alarm" "high_connections" {
  alarm_name          = "${local.db_identifier}-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 200
  alarm_description   = "RDS database connections are too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = local.db_identifier
  }

  tags = local.merged_tags
}

# High read latency alarm
resource "aws_cloudwatch_metric_alarm" "high_read_latency" {
  alarm_name          = "${local.db_identifier}-high-read-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 0.1 # 100ms
  alarm_description   = "RDS read latency is too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = local.db_identifier
  }

  tags = local.merged_tags
}

# High write latency alarm
resource "aws_cloudwatch_metric_alarm" "high_write_latency" {
  alarm_name          = "${local.db_identifier}-high-write-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "WriteLatency"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 0.1 # 100ms
  alarm_description   = "RDS write latency is too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = local.db_identifier
  }

  tags = local.merged_tags
}

# Replica lag alarm (for Multi-AZ)
resource "aws_cloudwatch_metric_alarm" "high_replica_lag" {
  count = var.multi_az ? 1 : 0

  alarm_name          = "${local.db_identifier}-high-replica-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReplicaLag"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 30 # 30 seconds
  alarm_description   = "RDS replica lag is too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = local.db_identifier
  }

  tags = local.merged_tags
}
