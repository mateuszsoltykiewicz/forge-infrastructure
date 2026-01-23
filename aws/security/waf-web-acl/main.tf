# ==============================================================================
# WAF Web ACL Module - Main Resources (Refactored)
# ==============================================================================
# Opinionated WAF configuration with:
# - Always-on logging to CloudWatch
# - Geographic allowlist (8 countries only)
# - Rate limiting (DDoS protection)
# - AWS Managed Rules: Core, Known Bad Inputs, SQLi, IP Reputation
# - Optional internal KMS key creation
# ==============================================================================

# ==============================================================================
# Data Sources
# ==============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ==============================================================================
# KMS Key for CloudWatch Logs Encryption (Optional Internal)
# ==============================================================================

resource "aws_kms_key" "waf_logs" {
  count = var.create_kms_key ? 1 : 0

  description             = "KMS key for WAF CloudWatch Logs encryption - ${local.waf_name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(local.merged_tags, {
    Purpose = "WAF-Logs-Encryption"
  })
}

resource "aws_kms_alias" "waf_logs" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/${local.waf_name}-logs"
  target_key_id = aws_kms_key.waf_logs[0].key_id
}

# KMS Key Policy to allow CloudWatch Logs to use the key
resource "aws_kms_key_policy" "waf_logs" {
  count = var.create_kms_key ? 1 : 0

  key_id = aws_kms_key.waf_logs[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/wafv2/${local.waf_name}"
          }
        }
      }
    ]
  })
}

# ==============================================================================
# CloudWatch Log Group (ALWAYS ENABLED)
# ==============================================================================

resource "aws_cloudwatch_log_group" "waf" {
  name              = "/aws/wafv2/${local.waf_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = local.kms_key_id

  tags = local.merged_tags

  depends_on = [
    aws_kms_key_policy.waf_logs
  ]
}

# ==============================================================================
# WAF Web ACL
# ==============================================================================

resource "aws_wafv2_web_acl" "this" {
  name        = local.waf_name
  description = "WAF Web ACL with Core Rules, SQLi, Rate Limit, Geo-allowlist: ${join(", ", local.allowed_countries)}"
  scope       = var.scope

  # Default action when no rules match
  default_action {
    dynamic "allow" {
      for_each = var.default_action == "allow" ? [1] : []
      content {}
    }

    dynamic "block" {
      for_each = var.default_action == "block" ? [1] : []
      content {}
    }
  }

  # ------------------------------------------------------------------------------
  # Rule 1: Rate Limiting (DDoS Protection) - Priority 1
  # ------------------------------------------------------------------------------

  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit_requests
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.waf_name}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  # ------------------------------------------------------------------------------
  # Rule 2: Geographic Allowlist (Block all except 8 countries) - Priority 5
  # ------------------------------------------------------------------------------

  rule {
    name     = "GeoAllowlistRule"
    priority = 5

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          geo_match_statement {
            country_codes = local.allowed_countries
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.waf_name}-geo-allowlist"
      sampled_requests_enabled   = true
    }
  }

  # ------------------------------------------------------------------------------
  # Rule 3: AWS Managed - Core Rule Set - Priority 20
  # ------------------------------------------------------------------------------

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.waf_name}-core-rules"
      sampled_requests_enabled   = true
    }
  }

  # ------------------------------------------------------------------------------
  # Rule 4: AWS Managed - Known Bad Inputs - Priority 30
  # ------------------------------------------------------------------------------

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 30

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.waf_name}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  # ------------------------------------------------------------------------------
  # Rule 5: AWS Managed - SQL Injection - Priority 40
  # ------------------------------------------------------------------------------

  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 40

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesSQLiRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.waf_name}-sqli"
      sampled_requests_enabled   = true
    }
  }

  # ------------------------------------------------------------------------------
  # Rule 6: AWS Managed - IP Reputation - Priority 71
  # ------------------------------------------------------------------------------

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 71

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesAmazonIpReputationList"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.waf_name}-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  # ------------------------------------------------------------------------------
  # Global Visibility Configuration
  # ------------------------------------------------------------------------------

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.waf_name}-global"
    sampled_requests_enabled   = true
  }

  tags = local.merged_tags
}

# ==============================================================================
# WAF Logging Configuration (ALWAYS ENABLED)
# ==============================================================================

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  resource_arn            = aws_wafv2_web_acl.this.arn
  log_destination_configs = [var.firehose_delivery_stream_arn]

  # Redact sensitive headers from logs
  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.waf
  ]
}
