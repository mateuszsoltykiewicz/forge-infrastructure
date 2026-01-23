# ==============================================================================
# WAF Web ACL Module - Outputs (Refactored)
# ==============================================================================

# ==============================================================================
# Primary Outputs (for ALB association)
# ==============================================================================

output "web_acl_arn" {
  description = "ARN of the WAF Web ACL - use this with ALB, API Gateway, or CloudFront"
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.this.id
}

output "web_acl_name" {
  description = "Name of the WAF Web ACL"
  value       = aws_wafv2_web_acl.this.name
}

output "web_acl_capacity" {
  description = "Web ACL capacity units (WCUs) consumed by rules"
  value       = aws_wafv2_web_acl.this.capacity
}

# ==============================================================================
# KMS Outputs
# ==============================================================================

output "kms_key_id" {
  description = "KMS Key ID used for log encryption (internal or external)"
  value       = local.kms_key_id
}

output "kms_key_arn" {
  description = "KMS Key ARN used for log encryption"
  value       = var.create_kms_key ? (length(aws_kms_key.waf_logs) > 0 ? aws_kms_key.waf_logs[0].arn : null) : var.kms_key_id
}

output "kms_key_alias" {
  description = "KMS Key alias (only for internal KMS keys)"
  value       = var.create_kms_key ? (length(aws_kms_alias.waf_logs) > 0 ? aws_kms_alias.waf_logs[0].name : null) : null
}

# ==============================================================================
# Logging Outputs
# ==============================================================================

output "log_group_name" {
  description = "CloudWatch Log Group name for WAF logs"
  value       = aws_cloudwatch_log_group.waf.name
}

output "log_group_arn" {
  description = "CloudWatch Log Group ARN for WAF logs"
  value       = aws_cloudwatch_log_group.waf.arn
}

output "log_retention_days" {
  description = "CloudWatch log retention period in days"
  value       = var.log_retention_days
}

# ==============================================================================
# Configuration Summary
# ==============================================================================

output "waf_config" {
  description = "Complete WAF configuration summary"
  value = {
    # Identity
    name     = local.waf_name
    arn      = aws_wafv2_web_acl.this.arn
    id       = aws_wafv2_web_acl.this.id
    scope    = var.scope
    capacity = aws_wafv2_web_acl.this.capacity

    # Actions
    default_action = var.default_action
    rate_limit     = var.rate_limit_requests

    # Geographic allowlist (hardcoded)
    allowed_countries = local.allowed_countries
    blocked_countries = "All except: ${join(", ", local.allowed_countries)}"

    # AWS Managed Rules (always enabled)
    managed_rules = [
      "AWSManagedRulesCommonRuleSet",
      "AWSManagedRulesKnownBadInputsRuleSet",
      "AWSManagedRulesSQLiRuleSet",
      "AWSManagedRulesAmazonIpReputationList"
    ]

    # Logging (always enabled)
    logging_enabled    = true
    log_destination    = "CloudWatch"
    log_group          = aws_cloudwatch_log_group.waf.name
    log_retention_days = var.log_retention_days

    # Encryption
    kms_encryption = var.create_kms_key ? "Internal KMS Key" : "External KMS Key"
    kms_key_arn    = local.kms_key_id
  }
}

# ==============================================================================
# Cost Estimation
# ==============================================================================

output "estimated_monthly_cost_usd" {
  description = "Estimated monthly cost breakdown (USD)"
  value = {
    web_acl_base      = 5.00                             # $5/month per Web ACL
    rules             = 6.00                             # 6 rules × $1/month = $6
    managed_rules     = 0.00                             # AWS managed rules are free
    kms_key           = var.create_kms_key ? 1.00 : 0.00 # $1/month if internal KMS
    total_fixed       = var.create_kms_key ? 12.00 : 11.00
    variable_costs    = "Plus $0.60 per million requests"
    cloudwatch_logs   = "Plus $0.50/GB ingested, $0.03/GB stored/month"
    estimated_monthly = var.create_kms_key ? "$12-20" : "$11-19"
    note              = "Assuming ~10-15M requests/month and ~5GB logs/month"
  }
}

# ==============================================================================
# Integration Instructions
# ==============================================================================

output "integration_guide" {
  description = "How to integrate this WAF with ALB modules"
  value = {
    usage                   = "Pass web_acl_arn to ALB module's web_acl_arn variable"
    alb_module_fix_required = "Ensure ALB module has: count = var.web_acl_arn != null ? 1 : 0 in aws_wafv2_web_acl_association resource"
    example_usage           = <<-EOT
      module "waf" {
        source = "./security/waf-web-acl"
        
        common_prefix = local.common_prefix
        common_tags   = local.common_tags
      }
      
      module "alb" {
        source = "./load-balancing/alb"
        
        web_acl_arn = module.waf.web_acl_arn
        # ... other variables
      }
    EOT
  }
}

# ==============================================================================
# Compliance & Security
# ==============================================================================

output "security_features" {
  description = "Security features enabled in this WAF"
  value = {
    ddos_protection = {
      enabled         = true
      rate_limit      = "${var.rate_limit_requests} requests per 5 minutes per IP"
      mitigation_type = "Block (hardcoded)"
    }
    geographic_restriction = {
      enabled       = true
      allowed_only  = local.allowed_countries
      blocked_count = "~190 countries blocked"
    }
    owasp_top_10_protection = {
      sql_injection    = "AWS Managed SQLi RuleSet"
      xss              = "Included in Core RuleSet"
      csrf             = "Included in Core RuleSet"
      malicious_inputs = "AWS Managed Known Bad Inputs"
      ip_reputation    = "AWS Managed IP Reputation List"
    }
    logging_compliance = {
      enabled         = true
      retention       = "${var.log_retention_days} days"
      encryption      = var.create_kms_key ? "KMS (internal)" : "KMS (external)"
      redacted_fields = ["authorization", "cookie"]
      audit_trail     = "Full request/response logging to CloudWatch"
    }
  }
}
