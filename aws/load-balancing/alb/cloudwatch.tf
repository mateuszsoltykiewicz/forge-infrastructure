# ==============================================================================
# ALB Module - CloudWatch Monitoring
# ==============================================================================
# This file creates CloudWatch dashboard and alarms for ALB monitoring.
# ==============================================================================

# ------------------------------------------------------------------------------
# CloudWatch Dashboard
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "alb" {
  dashboard_name = "${local.alb_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average", label = "Avg Response Time" }],
            ["...", { stat = "p99", label = "p99 Response Time" }]
          ]
          period = 300
          stat   = "Average"
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
            ["AWS/ApplicationELB", "RequestCount", { stat = "Sum", label = "Total Requests" }]
          ]
          period = 300
          stat   = "Sum"
          title  = "Request Count"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", { stat = "Average", label = "Healthy Targets" }],
            [".", "UnHealthyHostCount", { stat = "Average", label = "Unhealthy Targets" }]
          ]
          period = 300
          stat   = "Average"
          title  = "Target Health"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", { stat = "Sum", label = "2XX Responses" }],
            [".", "HTTPCode_Target_3XX_Count", { stat = "Sum", label = "3XX Responses" }],
            [".", "HTTPCode_Target_4XX_Count", { stat = "Sum", label = "4XX Responses" }],
            [".", "HTTPCode_Target_5XX_Count", { stat = "Sum", label = "5XX Responses" }]
          ]
          period = 300
          stat   = "Sum"
          title  = "Target HTTP Response Codes"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_4XX_Count", { stat = "Sum", label = "ELB 4XX" }],
            [".", "HTTPCode_ELB_5XX_Count", { stat = "Sum", label = "ELB 5XX" }]
          ]
          period = 300
          stat   = "Sum"
          title  = "ALB HTTP Response Codes"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "ActiveConnectionCount", { stat = "Sum", label = "Active Connections" }],
            [".", "NewConnectionCount", { stat = "Sum", label = "New Connections" }]
          ]
          period = 300
          stat   = "Sum"
          title  = "Connections"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "ProcessedBytes", { stat = "Sum", label = "Processed Bytes" }]
          ]
          period = 300
          stat   = "Sum"
          title  = "Processed Bytes"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetTLSNegotiationErrorCount", { stat = "Sum", label = "TLS Errors" }],
            [".", "ClientTLSNegotiationErrorCount", { stat = "Sum", label = "Client TLS Errors" }]
          ]
          period = 300
          stat   = "Sum"
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
  alarm_name          = "${local.alb_name}-high-target-5xx"
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
    LoadBalancer = aws_lb.this.arn_suffix
  }

  tags = local.all_tags
}

# High ALB 5XX errors
resource "aws_cloudwatch_metric_alarm" "high_alb_5xx" {
  alarm_name          = "${local.alb_name}-high-alb-5xx"
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
    LoadBalancer = aws_lb.this.arn_suffix
  }

  tags = local.all_tags
}

# High response time
resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  alarm_name          = "${local.alb_name}-high-response-time"
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
    LoadBalancer = aws_lb.this.arn_suffix
  }

  tags = local.all_tags
}

# Unhealthy targets
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "${local.alb_name}-unhealthy-targets"
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
    LoadBalancer = aws_lb.this.arn_suffix
  }

  tags = local.all_tags
}

# No healthy targets (critical)
resource "aws_cloudwatch_metric_alarm" "no_healthy_targets" {
  alarm_name          = "${local.alb_name}-no-healthy-targets"
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
    LoadBalancer = aws_lb.this.arn_suffix
  }

  tags = local.all_tags
}

# High TLS negotiation errors
resource "aws_cloudwatch_metric_alarm" "high_tls_errors" {
  alarm_name          = "${local.alb_name}-high-tls-errors"
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
    LoadBalancer = aws_lb.this.arn_suffix
  }

  tags = local.all_tags
}
