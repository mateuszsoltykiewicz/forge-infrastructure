#
# Application Load Balancer Module - Outputs
# Purpose: Export ALB and target group information
#

# ========================================
# Multi-Tenant Identification
# ========================================

output "alb_identifiers" {
  description = "ALB identifier (name)"
  value       = local.alb_name
}

# ========================================
# ALB Identification
# ========================================

output "alb_id" {
  description = "Application Load Balancer ID"
  value       = aws_lb.this.id
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = aws_lb.this.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix for use with CloudWatch Metrics"
  value       = aws_lb.this.arn_suffix
}

output "alb_name" {
  description = "Application Load Balancer names"
  value       = aws_lb.this.name
}

# ========================================
# ALB DNS Information
# ========================================

output "dns_name" {
  description = "DNS name of the ALB (use with Route 53 alias records)"
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "Canonical hosted zone ID of the ALB (for Route 53 alias records)"
  value       = aws_lb.this.zone_id
}

# ========================================
# ALB Configuration
# ========================================

output "alb_type" {
  description = "Load balancer type"
  value       = aws_lb.this.load_balancer_type
}

output "vpc_id" {
  description = "VPC ID where the ALB is deployed (auto-discovered)"
  value       = var.vpc_id
}

output "subnet_ids" {
  description = "List of subnet IDs attached to all ALBs (shared subnets)"
  value       = module.alb_subnet.subnet_ids
}

output "subnet_cidrs" {
  description = "List of subnet CIDR blocks"
  value       = module.alb_subnet.subnet_cidrs
}

output "availability_zones" {
  description = "Availability zones used for ALB subnets"
  value       = module.alb_subnet.availability_zones
}

output "security_group_id" {
  description = "Security group ID associated with the ALB"
  value       = module.security_group.security_group_id
}

output "route_table_ids" {
  description = "Route table IDs for ALB public subnets"
  value       = module.alb_subnet.route_table_ids
}

output "ip_address_type" {
  description = "IP address type of the ALB"
  value       = aws_lb.this.ip_address_type
}

output "is_internal" {
  description = "Whether the ALB is internal or internet-facing"
  value       = aws_lb.this.internal
}

# ========================================
# Listeners
# ========================================

output "http_listener_arn" {
  description = "ARN of the HTTP listener (null if not enabled)"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (null if not enabled)"
  value       = aws_lb_listener.https.arn
}

output "http_listener_id" {
  description = "ID of the HTTP listener (null if not enabled)"
  value       = aws_lb_listener.http.id
}

output "https_listener_id" {
  description = "ID of the HTTPS listener (null if not enabled)"
  value       = aws_lb_listener.https.id
}

# ========================================
# WAF Association
# ========================================

output "web_acl_arn" {
  description = "ARN of the WAF Web ACL associated with the ALB (null if none)"
  value       = var.web_acl_arn
}

output "has_waf" {
  description = "Whether a WAF Web ACL is associated with the ALB"
  value       = var.web_acl_arn != null
}

# ========================================
# Access Logs
# ========================================

output "access_logs_enabled" {
  description = "Whether access logging is enabled"
  value       = var.enable_access_logs
}

output "access_logs_bucket" {
  description = "S3 bucket for access logs (null if not enabled)"
  value       = var.enable_access_logs ? var.access_logs_bucket : null
}

output "access_logs_prefix" {
  description = "S3 prefix for access logs (null if not enabled)"
  value       = var.enable_access_logs ? var.access_logs_prefix : null
}

# ========================================
# CloudWatch Outputs
# ========================================

output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.alb.dashboard_name
}

output "cloudwatch_alarms" {
  description = "CloudWatch alarm names"
  value = {
    high_target_5xx    = aws_cloudwatch_metric_alarm.high_target_5xx.alarm_name
    high_alb_5xx       = aws_cloudwatch_metric_alarm.high_alb_5xx.alarm_name
    high_response_time = aws_cloudwatch_metric_alarm.high_response_time.alarm_name
    unhealthy_targets  = aws_cloudwatch_metric_alarm.unhealthy_targets.alarm_name
    no_healthy_targets = aws_cloudwatch_metric_alarm.no_healthy_targets.alarm_name
    high_tls_errors    = aws_cloudwatch_metric_alarm.high_tls_errors.alarm_name
  }
}

# ========================================
# Route 53 Integration
# ========================================

output "route53_alias_config" {
  description = "Configuration for Route 53 alias record"
  value = {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}
