# ==============================================================================
# ALB Module - CloudWatch Monitoring
# ==============================================================================
# This file creates CloudWatch dashboard and alarms for ALB monitoring.
# ==============================================================================

# ------------------------------------------------------------------------------
# CloudWatch Dashboard
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "alb" {
  count = length(local.environments)

  dashboard_name = "${local.alb_names[count.index]}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat : "Average" }],
            ["...", { stat : "p99" }]
          ]
          period = 300
          region = local.current_region
          title  = "Target Response Time"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount"]
          ]
          period = 300
          stat   = "Sum"
          region = local.current_region
          title  = "Request Count"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount"],
            [".", "UnHealthyHostCount"]
          ]
          period = 300
          stat   = "Average"
          region = local.current_region
          title  = "Target Health"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count"],
            [".", "HTTPCode_Target_3XX_Count"],
            [".", "HTTPCode_Target_4XX_Count"],
            [".", "HTTPCode_Target_5XX_Count"]
          ]
          period = 300
          stat   = "Sum"
          region = local.current_region
          title  = "Target HTTP Response Codes"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_4XX_Count"],
            [".", "HTTPCode_ELB_5XX_Count"]
          ]
          period = 300
          stat   = "Sum"
          region = local.current_region
          title  = "ALB HTTP Response Codes"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "ActiveConnectionCount"],
            [".", "NewConnectionCount"]
          ]
          period = 300
          stat   = "Sum"
          region = local.current_region
          title  = "Connections"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "ProcessedBytes"]
          ]
          period = 300
          stat   = "Sum"
          region = local.current_region
          title  = "Processed Bytes"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetTLSNegotiationErrorCount"],
            [".", "ClientTLSNegotiationErrorCount"]
          ]
          period = 300
          stat   = "Sum"
          region = local.current_region
          title  = "TLS Negotiation Errors"
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# CloudWatch Alarms
# ------------------------------------------------------------------------------

# High target 5XX errors
resource "aws_cloudwatch_metric_alarm" "high_target_5xx" {
  count = length(local.environments)

  alarm_name          = "${local.alb_names[count.index]}-high-target-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB target 5XX errors are too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.this[count.index].arn_suffix
  }

  tags = merge(
    local.merged_tags,
    {
      Environment = local.environments[count.index]
    }
  )
}

# High ALB 5XX errors
resource "aws_cloudwatch_metric_alarm" "high_alb_5xx" {
  count = length(local.environments)

  alarm_name          = "${local.alb_names[count.index]}-high-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "ALB 5XX errors are too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.this[count.index].arn_suffix
  }

  tags = merge(
    local.merged_tags,
    {
      Environment = local.environments[count.index]
    }
  )
}

# High response time
resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  count = length(local.environments)

  alarm_name          = "${local.alb_names[count.index]}-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 5.0 # 5 seconds
  alarm_description   = "ALB target response time is too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.this[count.index].arn_suffix
  }

  tags = merge(
    local.merged_tags,
    {
      Environment = local.environments[count.index]
    }
  )
}

# Unhealthy targets
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  count = length(local.environments)

  alarm_name          = "${local.alb_names[count.index]}-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "ALB has unhealthy targets"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.this[count.index].arn_suffix
  }

  tags = merge(
    local.merged_tags,
    {
      Environment = local.environments[count.index]
    }
  )
}

# No healthy targets (critical)
resource "aws_cloudwatch_metric_alarm" "no_healthy_targets" {
  count = length(local.environments)

  alarm_name          = "${local.alb_names[count.index]}-no-healthy-targets"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "ALB has no healthy targets (CRITICAL)"
  treat_missing_data  = "breaching"

  dimensions = {
    LoadBalancer = aws_lb.this[count.index].arn_suffix
  }

  tags = merge(
    local.merged_tags,
    {
      Environment = local.environments[count.index]
    }
  )
}

# High TLS negotiation errors
resource "aws_cloudwatch_metric_alarm" "high_tls_errors" {
  count = length(var.environments)

  alarm_name          = "${local.alb_names[count.index]}-high-tls-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetTLSNegotiationErrorCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB TLS negotiation errors are too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.this[count.index].arn_suffix
  }

  tags = merge(
    local.merged_tags,
    {
      Environment = local.environments[count.index]
    }
  )
}
