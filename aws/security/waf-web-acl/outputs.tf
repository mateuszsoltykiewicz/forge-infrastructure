# ========================================
# WAF Web ACL Outputs
# ========================================

output "web_acl_arn" {
  description = "ARN of the WAF Web ACL. Use this with ALB, API Gateway, or CloudFront."
  value       = aws_wafv2_web_acl.main.arn
}

output "web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.id
}

output "web_acl_name" {
  description = "Name of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.name
}

output "web_acl_capacity" {
  description = "Web ACL capacity units (WCUs) used"
  value       = aws_wafv2_web_acl.main.capacity
}

# ========================================
# IP Sets
# ========================================

output "ip_allow_list_arn" {
  description = "ARN of the IP allow list IP set"
  value       = local.has_ip_allow_list ? aws_wafv2_ip_set.allow_list[0].arn : null
}

output "ip_allow_list_id" {
  description = "ID of the IP allow list IP set"
  value       = local.has_ip_allow_list ? aws_wafv2_ip_set.allow_list[0].id : null
}

output "ip_block_list_arn" {
  description = "ARN of the IP block list IP set"
  value       = local.has_ip_block_list ? aws_wafv2_ip_set.block_list[0].arn : null
}

output "ip_block_list_id" {
  description = "ID of the IP block list IP set"
  value       = local.has_ip_block_list ? aws_wafv2_ip_set.block_list[0].id : null
}

# ========================================
# Configuration Details
# ========================================

output "scope" {
  description = "Scope of the WAF Web ACL (REGIONAL or CLOUDFRONT)"
  value       = var.scope
}

output "default_action" {
  description = "Default action when no rules match"
  value       = var.default_action
}

output "rate_limit_enabled" {
  description = "Whether rate limiting is enabled"
  value       = var.rate_limit_enabled
}

output "rate_limit_requests" {
  description = "Rate limit threshold (requests per 5 minutes)"
  value       = var.rate_limit_requests
}

output "geo_blocking_enabled" {
  description = "Whether geographic blocking is enabled"
  value       = local.has_geo_blocking
}

output "geo_blocking_countries" {
  description = "List of blocked countries"
  value       = var.geo_blocking_countries
}

output "enabled_managed_rule_groups" {
  description = "List of enabled AWS managed rule groups"
  value       = [for key, group in local.enabled_managed_rule_groups : group.name]
}

# ========================================
# Logging Configuration
# ========================================

output "logging_enabled" {
  description = "Whether WAF logging is enabled"
  value       = var.enable_logging
}

output "log_destination_type" {
  description = "Type of log destination (cloudwatch, s3, kinesis)"
  value       = var.log_destination_type
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for WAF logs"
  value       = local.should_create_log_group ? aws_cloudwatch_log_group.waf[0].arn : null
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for WAF logs"
  value       = local.should_create_log_group ? aws_cloudwatch_log_group.waf[0].name : null
}

output "log_retention_days" {
  description = "CloudWatch log retention period in days"
  value       = var.cloudwatch_log_retention_days
}

# ========================================
# Association Details
# ========================================

output "alb_association_created" {
  description = "Whether the WAF was automatically associated with an ALB"
  value       = local.has_alb_association
}

output "associated_alb_arn" {
  description = "ARN of the associated ALB (if any)"
  value       = local.has_alb_association ? var.alb_arn : null
}

# ========================================
# Integration Outputs
# ========================================

output "alb_integration" {
  description = "Configuration object for ALB integration"
  value = {
    web_acl_arn = aws_wafv2_web_acl.main.arn
    scope       = var.scope
    region      = var.region
  }
}

output "cloudfront_integration" {
  description = "Configuration object for CloudFront integration (requires us-east-1)"
  value = var.scope == "CLOUDFRONT" ? {
    web_acl_arn = aws_wafv2_web_acl.main.arn
    scope       = var.scope
    region      = var.region
  } : null
}

output "api_gateway_integration" {
  description = "Configuration object for API Gateway integration"
  value = var.scope == "REGIONAL" ? {
    web_acl_arn = aws_wafv2_web_acl.main.arn
    scope       = var.scope
    region      = var.region
  } : null
}

# ========================================
# Monitoring Outputs
# ========================================

output "cloudwatch_metric_namespace" {
  description = "CloudWatch metric namespace for WAF metrics"
  value       = var.metric_namespace
}

output "metric_names" {
  description = "List of CloudWatch metric names"
  value = concat(
    [local.waf_name],
    local.has_ip_allow_list ? ["IPAllowList"] : [],
    var.rate_limit_enabled ? ["RateLimitRule"] : [],
    local.has_geo_blocking ? ["GeoBlockRule"] : [],
    local.has_ip_block_list ? ["IPBlockList"] : [],
    [for group in local.enabled_managed_rule_groups : group.name],
    [for rule in var.custom_rules : rule.name]
  )
}

# ========================================
# Cost Estimation
# ========================================

output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown (USD)"
  value = {
    web_acl_base         = 5.00                                                         # $5/month per Web ACL
    rules_standard       = length(aws_wafv2_web_acl.main.rule) * 1.00                   # $1/month per rule
    rule_groups          = length(local.enabled_managed_rule_groups) * 0.00             # AWS managed groups are free
    wcu_capacity         = aws_wafv2_web_acl.main.capacity * 0.00                       # First 1500 WCUs free, then $1/WCU
    requests_per_million = 0.60                                                         # $0.60 per million requests
    bot_control_premium  = var.enable_aws_managed_rules_bot_control ? 10.00 : 0.00      # $10/month + $1 per million requests
    atp_premium          = var.enable_aws_managed_rules_account_takeover ? 10.00 : 0.00 # $10/month + $1 per million requests
    total_base           = 5.00 + (length(aws_wafv2_web_acl.main.rule) * 1.00) + (var.enable_aws_managed_rules_bot_control ? 10.00 : 0.00) + (var.enable_aws_managed_rules_account_takeover ? 10.00 : 0.00)
    note                 = "Add $0.60 per million requests. CloudWatch Logs: $0.50/GB ingested, $0.03/GB stored."
  }
}

# ========================================
# Summary Output
# ========================================

output "waf_summary" {
  description = "Complete summary of the WAF Web ACL configuration"
  value = {
    # Identification
    web_acl_arn  = aws_wafv2_web_acl.main.arn
    web_acl_id   = aws_wafv2_web_acl.main.id
    web_acl_name = aws_wafv2_web_acl.main.name
    scope        = var.scope
    region       = var.region
    capacity     = aws_wafv2_web_acl.main.capacity

    # Default action
    default_action = var.default_action

    # Rate limiting
    rate_limiting = {
      enabled  = var.rate_limit_enabled
      limit    = var.rate_limit_requests
      action   = var.rate_limit_action
      priority = var.rate_limit_priority
    }

    # Geographic blocking
    geo_blocking = {
      enabled   = local.has_geo_blocking
      countries = var.geo_blocking_countries
      action    = var.geo_blocking_action
    }

    # IP lists
    ip_allow_list = {
      enabled   = local.has_ip_allow_list
      addresses = var.ip_allow_list
      arn       = local.has_ip_allow_list ? aws_wafv2_ip_set.allow_list[0].arn : null
    }

    ip_block_list = {
      enabled   = local.has_ip_block_list
      addresses = var.ip_block_list
      arn       = local.has_ip_block_list ? aws_wafv2_ip_set.block_list[0].arn : null
    }

    # Managed rule groups
    managed_rule_groups = local.enabled_managed_rule_groups

    # Custom rules
    custom_rules_count = length(var.custom_rules)

    # Logging
    logging = {
      enabled              = var.enable_logging
      destination_type     = var.log_destination_type
      cloudwatch_log_group = local.should_create_log_group ? aws_cloudwatch_log_group.waf[0].name : null
      retention_days       = var.cloudwatch_log_retention_days
    }

    # Association
    alb_association = {
      enabled = local.has_alb_association
      alb_arn = local.has_alb_association ? var.alb_arn : null
    }

    # Metrics
    cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
    sampled_requests_enabled   = var.enable_sampled_requests

    # Tags
    tags = local.merged_tags
  }
}
