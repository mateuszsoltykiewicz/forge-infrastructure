# ==============================================================================
# ElastiCache Redis Module - CloudWatch Monitoring
# ==============================================================================
# This file creates CloudWatch log groups, dashboard, and alarms for Redis.
# ==============================================================================

# ------------------------------------------------------------------------------
# CloudWatch Log Groups
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "redis_slow_log" {
  name              = "/aws/elasticache/${local.replication_group_id}/slow-log"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.redis.arn

  tags = merge(
    local.merged_tags,
    {
      Name    = "${local.replication_group_id}-slow-log"
      LogType = "slow-log"
    }
  )
}

resource "aws_cloudwatch_log_group" "redis_engine_log" {
  name              = "/aws/elasticache/${local.replication_group_id}/engine-log"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.redis.arn

  tags = merge(
    local.merged_tags,
    {
      Name    = "${local.replication_group_id}-engine-log"
      LogType = "engine-log"
    }
  )
}

# ------------------------------------------------------------------------------
# CloudWatch Dashboard
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "redis" {
  dashboard_name = "${local.replication_group_id}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # CPU Utilization
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ElastiCache", "CPUUtilization", { stat = "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "CPU Utilization"
          period  = 300
        }
      },
      # Memory Usage
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ElastiCache", "DatabaseMemoryUsagePercentage", { stat = "Average" }],
            [".", "FreeableMemory", { stat = "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Memory Usage"
          period  = 300
        }
      },
      # Network I/O
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ElastiCache", "NetworkBytesIn", { stat = "Sum" }],
            [".", "NetworkBytesOut", { stat = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Network I/O"
          period  = 300
        }
      },
      # Connections
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ElastiCache", "CurrConnections", { stat = "Average" }],
            [".", "NewConnections", { stat = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Connections"
          period  = 300
        }
      },
      # Cache Hits/Misses
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ElastiCache", "CacheHits", { stat = "Sum" }],
            [".", "CacheMisses", { stat = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Cache Performance"
          period  = 300
        }
      },
      # Evictions
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ElastiCache", "Evictions", { stat = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Evictions"
          period  = 300
        }
      },
      # Replication Lag (Multi-AZ)
      {
        type = "metric"
        properties = {
          metrics = var.multi_az_enabled ? [
            ["AWS/ElastiCache", "ReplicationLag", { stat = "Average" }]
          ] : []
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Replication Lag"
          period  = 300
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# CloudWatch Alarms
# ------------------------------------------------------------------------------

# High CPU Utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.replication_group_id}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "This metric monitors Redis CPU utilization"
  alarm_actions       = var.notification_topic_arn != "" ? [var.notification_topic_arn] : []

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.main.id
  }

  tags = local.merged_tags
}

# High Memory Usage
resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "${local.replication_group_id}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "This metric monitors Redis memory usage"
  alarm_actions       = var.notification_topic_arn != "" ? [var.notification_topic_arn] : []

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.main.id
  }

  tags = local.merged_tags
}

# High Evictions
resource "aws_cloudwatch_metric_alarm" "high_evictions" {
  alarm_name          = "${local.replication_group_id}-high-evictions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Evictions"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Sum"
  threshold           = 1000
  alarm_description   = "This metric monitors Redis evictions"
  alarm_actions       = var.notification_topic_arn != "" ? [var.notification_topic_arn] : []

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.main.id
  }

  tags = local.merged_tags
}

# High Replication Lag (Multi-AZ only)
resource "aws_cloudwatch_metric_alarm" "high_replication_lag" {
  count = var.multi_az_enabled ? 1 : 0

  alarm_name          = "${local.replication_group_id}-high-replication-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReplicationLag"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 60
  alarm_description   = "This metric monitors Redis replication lag"
  alarm_actions       = var.notification_topic_arn != "" ? [var.notification_topic_arn] : []

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.main.id
  }

  tags = local.merged_tags
}

# High Connection Count
resource "aws_cloudwatch_metric_alarm" "high_connections" {
  alarm_name          = "${local.replication_group_id}-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CurrConnections"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 65000 # Default Redis max connections
  alarm_description   = "This metric monitors Redis connection count"
  alarm_actions       = var.notification_topic_arn != "" ? [var.notification_topic_arn] : []

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.main.id
  }

  tags = local.merged_tags
}
