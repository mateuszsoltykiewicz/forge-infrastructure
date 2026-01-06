# ========================================
# Local Values and Computed Configuration
# ========================================

locals {
  # Multi-tenant detection
  has_customer = var.customer_name != null && var.customer_name != ""
  has_project  = var.project_name != null && var.project_name != ""

  # WAF naming
  # 1. Shared: forge-{environment}-waf
  # 2. Customer: forge-{environment}-{customer}-waf
  # 3. Project: forge-{environment}-{customer}-{project}-waf
  waf_name = var.name != null ? var.name : (
    local.has_project ? "forge-${var.environment}-${var.customer_name}-${var.project_name}-waf" :
    local.has_customer ? "forge-${var.environment}-${var.customer_name}-waf" :
    "forge-${var.environment}-waf"
  )

  # Log destination naming
  log_group_name = "/aws/wafv2/${local.waf_name}"

  # Flags for enabled features
  has_ip_allow_list       = length(var.ip_allow_list) > 0
  has_ip_block_list       = length(var.ip_block_list) > 0
  has_geo_blocking        = var.geo_blocking_enabled && length(var.geo_blocking_countries) > 0
  has_custom_rules        = length(var.custom_rules) > 0
  should_create_log_group = var.enable_logging && var.log_destination_type == "cloudwatch" && var.log_destination_arn == null

  # AWS Managed Rule Groups
  managed_rule_groups = {
    core_rule_set = {
      enabled        = var.enable_aws_managed_rules_core
      name           = "AWSManagedRulesCommonRuleSet"
      vendor         = "AWS"
      priority       = 20
      excluded_rules = [] # Can be customized per rule group
    }
    known_bad_inputs = {
      enabled        = var.enable_aws_managed_rules_known_bad_inputs
      name           = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor         = "AWS"
      priority       = 30
      excluded_rules = []
    }
    sql_injection = {
      enabled        = var.enable_aws_managed_rules_sqli
      name           = "AWSManagedRulesSQLiRuleSet"
      vendor         = "AWS"
      priority       = 40
      excluded_rules = []
    }
    linux_os = {
      enabled        = var.enable_aws_managed_rules_linux
      name           = "AWSManagedRulesLinuxRuleSet"
      vendor         = "AWS"
      priority       = 50
      excluded_rules = []
    }
    windows_os = {
      enabled        = var.enable_aws_managed_rules_windows
      name           = "AWSManagedRulesWindowsRuleSet"
      vendor         = "AWS"
      priority       = 51
      excluded_rules = []
    }
    php_app = {
      enabled        = var.enable_aws_managed_rules_php
      name           = "AWSManagedRulesPHPRuleSet"
      vendor         = "AWS"
      priority       = 60
      excluded_rules = []
    }
    wordpress = {
      enabled        = var.enable_aws_managed_rules_wordpress
      name           = "AWSManagedRulesWordPressRuleSet"
      vendor         = "AWS"
      priority       = 61
      excluded_rules = []
    }
    anonymous_ip = {
      enabled        = var.enable_aws_managed_rules_anonymous_ip
      name           = "AWSManagedRulesAnonymousIpList"
      vendor         = "AWS"
      priority       = 70
      excluded_rules = []
    }
    ip_reputation = {
      enabled        = var.enable_aws_managed_rules_ip_reputation
      name           = "AWSManagedRulesAmazonIpReputationList"
      vendor         = "AWS"
      priority       = 71
      excluded_rules = []
    }
    bot_control = {
      enabled        = var.enable_aws_managed_rules_bot_control
      name           = "AWSManagedRulesBotControlRuleSet"
      vendor         = "AWS"
      priority       = 80
      excluded_rules = []
    }
    account_takeover = {
      enabled        = var.enable_aws_managed_rules_account_takeover
      name           = "AWSManagedRulesATPRuleSet"
      vendor         = "AWS"
      priority       = 81
      excluded_rules = []
    }
  }

  # Filter enabled managed rule groups
  enabled_managed_rule_groups = {
    for key, group in local.managed_rule_groups :
    key => group if group.enabled
  }

  # Logging configuration
  log_destination_configs = var.enable_logging ? (
    var.log_destination_arn != null ? [var.log_destination_arn] : (
      local.should_create_log_group ? [aws_cloudwatch_log_group.waf[0].arn] : []
    )
  ) : []

  # Visibility configuration for rules
  visibility_config = {
    cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
    sampled_requests_enabled   = var.enable_sampled_requests
    metric_name                = local.waf_name
  }

  # Tagging strategy
  base_tags = {
    ManagedBy        = "terraform"
    Module           = "waf-web-acl"
    CustomerId       = var.customer_id
    CustomerName     = var.customer_name
    ArchitectureType = var.architecture_type
    PlanTier         = var.plan_tier
    Environment      = var.environment
    Region           = var.region
  }

  customer_tags = var.architecture_type == "forge" ? {} : {
    Customer = var.customer_name
  }

  waf_tags = {
    Name  = local.waf_name
    Scope = var.scope
  }

  all_tags = merge(
    local.base_tags,
    local.customer_tags,
    local.waf_tags,
    var.tags
  )

  # Validation flags
  has_alb_association           = var.associate_alb && var.alb_arn != null
  cloudfront_requires_us_east_1 = var.scope == "CLOUDFRONT" && var.region != "us-east-1"
}

# ========================================
# Validation Rules
# ========================================

# CloudFront scope requires us-east-1
resource "null_resource" "cloudfront_region_check" {
  count = local.cloudfront_requires_us_east_1 ? 1 : 0

  lifecycle {
    precondition {
      condition     = !local.cloudfront_requires_us_east_1
      error_message = "WAF Web ACL with scope 'CLOUDFRONT' must be created in us-east-1 region. Current region: ${var.region}"
    }
  }
}

# ALB association requires REGIONAL scope
resource "null_resource" "alb_scope_check" {
  count = local.has_alb_association && var.scope != "REGIONAL" ? 1 : 0

  lifecycle {
    precondition {
      condition     = !(local.has_alb_association && var.scope != "REGIONAL")
      error_message = "ALB association requires WAF scope to be 'REGIONAL', not '${var.scope}'."
    }
  }
}

# Ensure IP allow list priority is lower than block list
resource "null_resource" "ip_list_priority_check" {
  count = local.has_ip_allow_list && local.has_ip_block_list && var.ip_allow_list_priority >= var.ip_block_list_priority ? 1 : 0

  lifecycle {
    precondition {
      condition     = !(local.has_ip_allow_list && local.has_ip_block_list && var.ip_allow_list_priority >= var.ip_block_list_priority)
      error_message = "IP allow list priority (${var.ip_allow_list_priority}) should be lower than IP block list priority (${var.ip_block_list_priority}) to allow trusted IPs before blocking."
    }
  }
}

# Warn about Bot Control additional charges
resource "null_resource" "bot_control_cost_warning" {
  count = var.enable_aws_managed_rules_bot_control ? 1 : 0

  # This is informational only - won't block deployment
  lifecycle {
    ignore_changes = all
  }
}

# Warn about Account Takeover Prevention additional charges
resource "null_resource" "atp_cost_warning" {
  count = var.enable_aws_managed_rules_account_takeover ? 1 : 0

  # This is informational only - won't block deployment
  lifecycle {
    ignore_changes = all
  }
}
