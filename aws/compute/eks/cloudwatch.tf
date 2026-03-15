# ==============================================================================
# EKS Module - CloudWatch Monitoring
# ==============================================================================
# This file creates CloudWatch dashboard for EKS cluster monitoring.
# Uses AWS/EKS namespace (no Container Insights DaemonSet required).
# ==============================================================================

# ------------------------------------------------------------------------------
# CloudWatch Dashboard
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "eks" {
  dashboard_name = local.dashboard_name

  dashboard_body = jsonencode({
    widgets = [
      # Cluster Status - API Server Availability
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EKS", "cluster_failed_node_count", { "ClusterName" = module.eks.cluster_name, stat = "Average" }],
            [".", "cluster_node_count", { "ClusterName" = module.eks.cluster_name, stat = "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "Cluster Node Status"
          period  = 60
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      # Node Group CPU Utilization (from EC2 metrics)
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", label = "Node CPU Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "Node CPU Utilization"
          period  = 60
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      # Node Group Network (from EC2 metrics)
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", { stat = "Sum", label = "Network In" }],
            [".", "NetworkOut", { stat = "Sum", label = "Network Out" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "Node Network Throughput"
          period  = 60
        }
      },
      # Managed Node Group Status
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", { "AutoScalingGroupName" = "*system-graviton3*", stat = "Average" }],
            [".", "GroupInServiceInstances", { "AutoScalingGroupName" = "*system-graviton3*", stat = "Average" }],
            [".", "GroupMinSize", { "AutoScalingGroupName" = "*system-graviton3*", stat = "Average" }],
            [".", "GroupMaxSize", { "AutoScalingGroupName" = "*system-graviton3*", stat = "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "Node Group Scaling (System)"
          period  = 60
        }
      },
      # Application Node Group Status (if exists)
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", { "AutoScalingGroupName" = "*application-graviton3*", stat = "Average" }],
            [".", "GroupInServiceInstances", { "AutoScalingGroupName" = "*application-graviton3*", stat = "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "Node Group Scaling (Application)"
          period  = 60
        }
      },
      # EBS Volume Metrics (Node Disk I/O)
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EBS", "VolumeReadOps", { stat = "Sum", label = "Read Ops" }],
            [".", "VolumeWriteOps", { stat = "Sum", label = "Write Ops" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "Node Disk I/O"
          period  = 60
        }
      },
      # ELB/ALB Health (if integrated)
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average", label = "Response Time" }],
            [".", "HealthyHostCount", { stat = "Average", label = "Healthy Targets" }],
            [".", "UnHealthyHostCount", { stat = "Average", label = "Unhealthy Targets" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.id
          title   = "ALB Health (EKS Ingress)"
          period  = 60
        }
      },
      # CloudWatch Logs - Control Plane Events
      {
        type = "log"
        properties = {
          query  = <<-EOT
            SOURCE '${module.eks.cloudwatch_log_group_name}'
            | fields @timestamp, @message
            | filter @message like /error|Error|ERROR|fail|Fail|FAIL/
            | sort @timestamp desc
            | limit 100
          EOT
          region = data.aws_region.current.id
          title  = "Control Plane Errors (Last 100)"
        }
      }
    ]
  })

  depends_on = [module.eks]
}

# ------------------------------------------------------------------------------
# CloudWatch Alarms
# ------------------------------------------------------------------------------

# High Node Count Failure
resource "aws_cloudwatch_metric_alarm" "cluster_failed_nodes" {
  alarm_name          = local.alarm_cluster_failed_nodes
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "cluster_failed_node_count"
  namespace           = "AWS/EKS"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "This metric monitors EKS cluster failed nodes"
  alarm_actions       = var.notification_topic_arn != "" ? [var.notification_topic_arn] : []

  dimensions = {
    ClusterName = module.eks.cluster_name
  }

  tags = local.merged_tags
}

# Node Group CPU Utilization
resource "aws_cloudwatch_metric_alarm" "node_high_cpu" {
  alarm_name          = local.alarm_node_high_cpu
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors EKS node CPU utilization"
  alarm_actions       = var.notification_topic_arn != "" ? [var.notification_topic_arn] : []

  tags = local.merged_tags
}
