# ========================================
# IP Sets (Allow/Block Lists)
# ========================================

# IP Allow List
resource "aws_wafv2_ip_set" "allow_list" {
  count = local.has_ip_allow_list ? 1 : 0

  name               = "${local.waf_name}-allow-list"
  description        = "IP addresses allowed to bypass WAF rules"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.ip_allow_list

  tags = merge(
    local.all_tags,
    {
      Name = "${local.waf_name}-allow-list"
      Type = "allow-list"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# IP Block List
resource "aws_wafv2_ip_set" "block_list" {
  count = local.has_ip_block_list ? 1 : 0

  name               = "${local.waf_name}-block-list"
  description        = "IP addresses explicitly blocked by WAF"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.ip_block_list

  tags = merge(
    local.all_tags,
    {
      Name = "${local.waf_name}-block-list"
      Type = "block-list"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ========================================
# WAF Web ACL
# ========================================

resource "aws_wafv2_web_acl" "main" {
  name        = local.waf_name
  description = "WAF Web ACL for ${var.customer_name} ${var.environment} environment"
  scope       = var.scope

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

  # Rule 1: IP Allow List (highest priority)
  dynamic "rule" {
    for_each = local.has_ip_allow_list ? [1] : []

    content {
      name     = "IPAllowList"
      priority = var.ip_allow_list_priority

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.allow_list[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
        sampled_requests_enabled   = var.enable_sampled_requests
        metric_name                = "IPAllowList"
      }
    }
  }

  # Rule 2: Rate Limiting
  dynamic "rule" {
    for_each = var.rate_limit_enabled ? [1] : []

    content {
      name     = "RateLimitRule"
      priority = var.rate_limit_priority

      dynamic "action" {
        for_each = var.rate_limit_action == "block" ? [1] : []
        content {
          block {}
        }
      }

      dynamic "action" {
        for_each = var.rate_limit_action == "count" ? [1] : []
        content {
          count {}
        }
      }

      dynamic "action" {
        for_each = var.rate_limit_action == "captcha" ? [1] : []
        content {
          captcha {}
        }
      }

      statement {
        rate_based_statement {
          limit              = var.rate_limit_requests
          aggregate_key_type = "IP"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
        sampled_requests_enabled   = var.enable_sampled_requests
        metric_name                = "RateLimitRule"
      }
    }
  }

  # Rule 3: Geographic Blocking
  dynamic "rule" {
    for_each = local.has_geo_blocking ? [1] : []

    content {
      name     = "GeoBlockRule"
      priority = var.geo_blocking_priority

      dynamic "action" {
        for_each = var.geo_blocking_action == "block" ? [1] : []
        content {
          block {}
        }
      }

      dynamic "action" {
        for_each = var.geo_blocking_action == "count" ? [1] : []
        content {
          count {}
        }
      }

      statement {
        geo_match_statement {
          country_codes = var.geo_blocking_countries
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
        sampled_requests_enabled   = var.enable_sampled_requests
        metric_name                = "GeoBlockRule"
      }
    }
  }

  # Rule 4: IP Block List
  dynamic "rule" {
    for_each = local.has_ip_block_list ? [1] : []

    content {
      name     = "IPBlockList"
      priority = var.ip_block_list_priority

      action {
        block {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.block_list[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
        sampled_requests_enabled   = var.enable_sampled_requests
        metric_name                = "IPBlockList"
      }
    }
  }

  # Rules 5+: AWS Managed Rule Groups
  dynamic "rule" {
    for_each = local.enabled_managed_rule_groups

    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          vendor_name = rule.value.vendor
          name        = rule.value.name

          dynamic "excluded_rule" {
            for_each = rule.value.excluded_rules

            content {
              name = excluded_rule.value
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
        sampled_requests_enabled   = var.enable_sampled_requests
        metric_name                = rule.value.name
      }
    }
  }

  # Custom Rules
  dynamic "rule" {
    for_each = var.custom_rules

    content {
      name     = rule.value.name
      priority = rule.value.priority

      dynamic "action" {
        for_each = rule.value.action == "block" ? [1] : []
        content {
          block {}
        }
      }

      dynamic "action" {
        for_each = rule.value.action == "allow" ? [1] : []
        content {
          allow {}
        }
      }

      dynamic "action" {
        for_each = rule.value.action == "count" ? [1] : []
        content {
          count {}
        }
      }

      dynamic "action" {
        for_each = rule.value.action == "captcha" ? [1] : []
        content {
          captcha {}
        }
      }

      statement {
        dynamic "byte_match_statement" {
          for_each = try([rule.value.statement.byte_match_statement], [])
          
          content {
            search_string = byte_match_statement.value.search_string
            
            field_to_match {
              dynamic "uri_path" {
                for_each = try([byte_match_statement.value.field_to_match.uri_path], [])
                content {}
              }
              
              dynamic "query_string" {
                for_each = try([byte_match_statement.value.field_to_match.query_string], [])
                content {}
              }
              
              dynamic "single_header" {
                for_each = try([byte_match_statement.value.field_to_match.single_header], [])
                content {
                  name = single_header.value.name
                }
              }
              
              dynamic "body" {
                for_each = try([byte_match_statement.value.field_to_match.body], [])
                content {}
              }
            }

            positional_constraint = byte_match_statement.value.positional_constraint

            dynamic "text_transformation" {
              for_each = byte_match_statement.value.text_transformations
              
              content {
                priority = text_transformation.value.priority
                type     = text_transformation.value.type
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
        sampled_requests_enabled   = var.enable_sampled_requests
        metric_name                = rule.value.name
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
    sampled_requests_enabled   = var.enable_sampled_requests
    metric_name                = local.waf_name
  }

  tags = local.all_tags

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = var.scope == "CLOUDFRONT" ? var.region == "us-east-1" : true
      error_message = "CloudFront WAF Web ACLs must be created in us-east-1 region."
    }
  }
}

# ========================================
# CloudWatch Log Group (for WAF Logging)
# ========================================

resource "aws_cloudwatch_log_group" "waf" {
  count = local.should_create_log_group ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(
    local.all_tags,
    {
      Name = local.log_group_name
      Type = "waf-logs"
    }
  )
}

# ========================================
# WAF Logging Configuration
# ========================================

resource "aws_wafv2_web_acl_logging_configuration" "main" {
  count = var.enable_logging && length(local.log_destination_configs) > 0 ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.main.arn
  log_destination_configs = local.log_destination_configs

  # Redact sensitive fields
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

  depends_on = [aws_cloudwatch_log_group.waf]
}

# ========================================
# ALB Association (Optional)
# ========================================

resource "aws_wafv2_web_acl_association" "alb" {
  count = local.has_alb_association ? 1 : 0

  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn

  lifecycle {
    create_before_destroy = true
  }
}
