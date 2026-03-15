# ==============================================================================
# AWS Client VPN Module - CloudWatch Dashboard
# ==============================================================================

resource "aws_cloudwatch_dashboard" "vpn" {
  dashboard_name = "${local.vpn_name}-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      # Row 1: Connection Metrics
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ClientVPN", "ActiveConnectionsCount", { stat = "Sum", label = "Active Connections" }],
            [".", "ConnectionAttemptsCount", { stat = "Sum", label = "Connection Attempts" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "VPN Connection Metrics"
          period  = 300
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },

      # Row 1: Authentication Failures
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ClientVPN", "AuthenticationFailuresCount", { stat = "Sum", label = "Auth Failures" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "Authentication Failures"
          period  = 300
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },

      # Row 2: Data Transfer (Ingress/Egress)
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ClientVPN", "IngressBytes", { stat = "Sum", label = "Ingress (VPN → Client)" }],
            [".", "EgressBytes", { stat = "Sum", label = "Egress (Client → VPN)" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "Data Transfer (Bytes)"
          period  = 300
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },

      # Row 2: Ingress/Egress Packets
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ClientVPN", "IngressPackets", { stat = "Sum", label = "Ingress Packets" }],
            [".", "EgressPackets", { stat = "Sum", label = "Egress Packets" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "Packet Transfer"
          period  = 300
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },

      # Row 3: CloudWatch Logs Insights - Recent Connections
      {
        type   = "log"
        width  = 24
        height = 6
        properties = {
          query  = <<-EOQ
            SOURCE '${aws_cloudwatch_log_group.vpn_connection_logs.name}'
            | fields @timestamp, connection-id, common-name, client-ip, event
            | filter event = "connection-established"
            | sort @timestamp desc
            | limit 20
          EOQ
          region = data.aws_region.current.id
          title  = "Recent VPN Connections (Last 20)"
        }
      },

      # Row 4: CloudWatch Logs Insights - Active Users
      {
        type   = "log"
        width  = 12
        height = 6
        properties = {
          query  = <<-EOQ
            SOURCE '${aws_cloudwatch_log_group.vpn_connection_logs.name}'
            | fields @timestamp, common-name, client-ip
            | filter event = "connection-established"
            | stats count() by common-name
            | sort count desc
          EOQ
          region = data.aws_region.current.id
          title  = "Active Users (Connection Count)"
        }
      },

      # Row 4: CloudWatch Logs Insights - Failed Connections
      {
        type   = "log"
        width  = 12
        height = 6
        properties = {
          query  = <<-EOQ
            SOURCE '${aws_cloudwatch_log_group.vpn_connection_logs.name}'
            | fields @timestamp, common-name, client-ip, connection-attempt-failure-reason
            | filter event = "connection-attempt-failure"
            | sort @timestamp desc
            | limit 10
          EOQ
          region = data.aws_region.current.id
          title  = "Failed Connection Attempts (Last 10)"
        }
      },

      # Row 5: Data Transfer by User (Top 10)
      {
        type   = "log"
        width  = 24
        height = 6
        properties = {
          query  = <<-EOQ
            SOURCE '${aws_cloudwatch_log_group.vpn_connection_logs.name}'
            | fields @timestamp, common-name, bytes-sent, bytes-received
            | filter event = "connection-reset" or event = "connection-terminate"
            | stats sum(bytes-sent + bytes-received) as total_bytes by common-name
            | sort total_bytes desc
            | limit 10
          EOQ
          region = data.aws_region.current.id
          title  = "Data Transfer by User (Top 10)"
        }
      }
    ]
  })

  depends_on = [
    aws_cloudwatch_log_group.vpn_connection_logs
  ]
}
