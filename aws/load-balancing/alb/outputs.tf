#
# Application Load Balancer Module - Outputs
# Purpose: Export ALB and target group information
#

# ========================================
# ALB Identification
# ========================================

output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.this.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix for use with CloudWatch Metrics"
  value       = aws_lb.this.arn_suffix
}

output "alb_name" {
  description = "Name of the Application Load Balancer"
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
  description = "Type of load balancer"
  value       = aws_lb.this.load_balancer_type
}

output "vpc_id" {
  description = "VPC ID where the ALB is deployed"
  value       = aws_lb.this.vpc_id
}

output "subnet_ids" {
  description = "List of subnet IDs attached to the ALB"
  value       = aws_lb.this.subnets
}

output "security_group_ids" {
  description = "List of security group IDs attached to the ALB"
  value       = aws_lb.this.security_groups
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
# Target Groups
# ========================================

output "target_group_arns" {
  description = "Map of target group keys to ARNs"
  value = {
    for tg_key, tg in aws_lb_target_group.this :
    tg_key => tg.arn
  }
}

output "target_group_arn_suffixes" {
  description = "Map of target group keys to ARN suffixes (for CloudWatch Metrics)"
  value = {
    for tg_key, tg in aws_lb_target_group.this :
    tg_key => tg.arn_suffix
  }
}

output "target_group_names" {
  description = "Map of target group keys to names"
  value = {
    for tg_key, tg in aws_lb_target_group.this :
    tg_key => tg.name
  }
}

output "target_group_ids" {
  description = "Map of target group keys to IDs"
  value = {
    for tg_key, tg in aws_lb_target_group.this :
    tg_key => tg.id
  }
}

# ========================================
# Listeners
# ========================================

output "http_listener_arn" {
  description = "ARN of the HTTP listener (null if not enabled)"
  value       = local.http_listener_enabled ? aws_lb_listener.http[0].arn : null
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (null if not enabled)"
  value       = local.https_listener_enabled ? aws_lb_listener.https[0].arn : null
}

output "http_listener_id" {
  description = "ID of the HTTP listener (null if not enabled)"
  value       = local.http_listener_enabled ? aws_lb_listener.http[0].id : null
}

output "https_listener_id" {
  description = "ID of the HTTPS listener (null if not enabled)"
  value       = local.https_listener_enabled ? aws_lb_listener.https[0].id : null
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

# ========================================
# Summary
# ========================================

output "summary" {
  description = "Summary of the ALB configuration"
  value = {
    # Identification
    alb_id         = aws_lb.this.id
    alb_arn        = aws_lb.this.arn
    alb_arn_suffix = aws_lb.this.arn_suffix
    alb_name       = aws_lb.this.name

    # DNS
    dns_name = aws_lb.this.dns_name
    zone_id  = aws_lb.this.zone_id

    # Configuration
    alb_type          = aws_lb.this.load_balancer_type
    is_internal       = aws_lb.this.internal
    ip_address_type   = aws_lb.this.ip_address_type
    vpc_id            = aws_lb.this.vpc_id
    subnet_count      = length(aws_lb.this.subnets)
    security_group_count = length(aws_lb.this.security_groups)

    # Target groups
    target_group_count = length(aws_lb_target_group.this)
    target_group_keys  = keys(aws_lb_target_group.this)

    # Listeners
    http_listener_enabled  = local.http_listener_enabled
    https_listener_enabled = local.https_listener_enabled
    http_redirects_to_https = local.http_listener_enabled && var.http_listener.redirect_https

    # Features
    has_waf              = var.web_acl_arn != null
    access_logs_enabled  = var.enable_access_logs
    deletion_protection  = var.enable_deletion_protection
    http2_enabled        = var.enable_http2

    # Route 53 integration
    route53_alias = {
      name                   = aws_lb.this.dns_name
      zone_id                = aws_lb.this.zone_id
      evaluate_target_health = true
    }
  }
}
