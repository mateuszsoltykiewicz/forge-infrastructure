# ========================================
# Customer Context Variables
# ========================================

variable "customer_name" {
  description = "Human-readable name of the customer"
  type        = string

  validation {
    condition     = length(var.customer_name) > 0 && length(var.customer_name) <= 100
    error_message = "Customer name must be between 1 and 100 characters."
  }
}

variable "project_name" {
  description = "Project name for multi-tenant deployments"
  type        = string
  default     = null
}

variable "plan_tier" {
  description = "Service plan tier (e.g., 'basic', 'pro', 'enterprise')"
  type        = string
  default     = "basic"

  validation {
    condition     = contains(["basic", "pro", "enterprise", "custom"], var.plan_tier)
    error_message = "Plan tier must be one of: basic, pro, enterprise, custom."
  }
}

variable "environment" {
  description = "Environment name (e.g., 'dev', 'staging', 'production')"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production", "test"], var.environment)
    error_message = "Environment must be one of: dev, staging, production, test."
  }
}

variable "region" {
  description = "AWS region for the WAF Web ACL (must match ALB region, or use 'CLOUDFRONT' scope for CloudFront)"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1, eu-west-1)."
  }
}

# ========================================
# WAF Configuration
# ========================================

variable "name" {
  description = "Name for the WAF Web ACL. If not provided, will be generated from customer/environment context."
  type        = string
  default     = null

  validation {
    condition     = var.name == null || (length(var.name) >= 1 && length(var.name) <= 128)
    error_message = "WAF Web ACL name must be between 1 and 128 characters."
  }
}

variable "scope" {
  description = "Scope of the WAF Web ACL. Use 'REGIONAL' for ALB/API Gateway, 'CLOUDFRONT' for CloudFront distributions."
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "Scope must be either 'REGIONAL' or 'CLOUDFRONT'."
  }
}

variable "default_action" {
  description = "Default action when no rules match. 'allow' permits requests, 'block' denies them."
  type        = string
  default     = "allow"

  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "Default action must be either 'allow' or 'block'."
  }
}

# ========================================
# Rate Limiting
# ========================================

variable "rate_limit_enabled" {
  description = "Enable rate limiting rule to prevent DDoS attacks"
  type        = bool
  default     = true
}

variable "rate_limit_requests" {
  description = "Maximum number of requests allowed from a single IP in a 5-minute window"
  type        = number
  default     = 2000

  validation {
    condition     = var.rate_limit_requests >= 100 && var.rate_limit_requests <= 20000000
    error_message = "Rate limit must be between 100 and 20,000,000 requests per 5 minutes."
  }
}

variable "rate_limit_action" {
  description = "Action to take when rate limit is exceeded: 'block', 'count' (monitor only), or 'captcha'"
  type        = string
  default     = "block"

  validation {
    condition     = contains(["block", "count", "captcha"], var.rate_limit_action)
    error_message = "Rate limit action must be 'block', 'count', or 'captcha'."
  }
}

variable "rate_limit_priority" {
  description = "Priority for rate limiting rule (lower numbers evaluated first)"
  type        = number
  default     = 1

  validation {
    condition     = var.rate_limit_priority >= 0
    error_message = "Priority must be a non-negative integer."
  }
}

# ========================================
# AWS Managed Rule Groups
# ========================================

variable "enable_aws_managed_rules_core" {
  description = "Enable AWS Managed Rules - Core Rule Set (protects against common vulnerabilities)"
  type        = bool
  default     = true
}

variable "enable_aws_managed_rules_known_bad_inputs" {
  description = "Enable AWS Managed Rules - Known Bad Inputs (protects against known malicious patterns)"
  type        = bool
  default     = true
}

variable "enable_aws_managed_rules_sqli" {
  description = "Enable AWS Managed Rules - SQL Injection prevention"
  type        = bool
  default     = true
}

variable "enable_aws_managed_rules_linux" {
  description = "Enable AWS Managed Rules - Linux Operating System protection"
  type        = bool
  default     = false
}

variable "enable_aws_managed_rules_windows" {
  description = "Enable AWS Managed Rules - Windows Operating System protection"
  type        = bool
  default     = false
}

variable "enable_aws_managed_rules_php" {
  description = "Enable AWS Managed Rules - PHP Application protection"
  type        = bool
  default     = false
}

variable "enable_aws_managed_rules_wordpress" {
  description = "Enable AWS Managed Rules - WordPress Application protection"
  type        = bool
  default     = false
}

variable "enable_aws_managed_rules_anonymous_ip" {
  description = "Enable AWS Managed Rules - Anonymous IP List (blocks requests from VPNs, proxies, Tor)"
  type        = bool
  default     = false
}

variable "enable_aws_managed_rules_ip_reputation" {
  description = "Enable AWS Managed Rules - Amazon IP Reputation List (blocks known malicious IPs)"
  type        = bool
  default     = true
}

variable "enable_aws_managed_rules_bot_control" {
  description = "Enable AWS Managed Rules - Bot Control (requires additional charges)"
  type        = bool
  default     = false
}

variable "enable_aws_managed_rules_account_takeover" {
  description = "Enable AWS Managed Rules - Account Takeover Prevention (ATP, requires additional charges)"
  type        = bool
  default     = false
}

# ========================================
# Geographic Blocking
# ========================================

variable "geo_blocking_enabled" {
  description = "Enable geographic blocking to restrict access by country"
  type        = bool
  default     = false
}

variable "geo_blocking_countries" {
  description = "List of ISO 3166-1 alpha-2 country codes to block (e.g., ['CN', 'RU', 'KP'])"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for country in var.geo_blocking_countries :
      can(regex("^[A-Z]{2}$", country))
    ])
    error_message = "Country codes must be 2-letter ISO 3166-1 alpha-2 codes (e.g., 'US', 'GB', 'CN')."
  }
}

variable "geo_blocking_action" {
  description = "Action to take for blocked countries: 'block' or 'count'"
  type        = string
  default     = "block"

  validation {
    condition     = contains(["block", "count"], var.geo_blocking_action)
    error_message = "Geographic blocking action must be 'block' or 'count'."
  }
}

variable "geo_blocking_priority" {
  description = "Priority for geographic blocking rule"
  type        = number
  default     = 5

  validation {
    condition     = var.geo_blocking_priority >= 0
    error_message = "Priority must be a non-negative integer."
  }
}

# ========================================
# IP Allow/Block Lists
# ========================================

variable "ip_allow_list" {
  description = "List of IP addresses or CIDR blocks to explicitly allow (e.g., office IPs, trusted partners)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.ip_allow_list :
      can(cidrhost(cidr, 0))
    ])
    error_message = "IP allow list must contain valid CIDR blocks (e.g., '192.0.2.0/24', '203.0.113.5/32')."
  }
}

variable "ip_block_list" {
  description = "List of IP addresses or CIDR blocks to explicitly block (e.g., known attackers)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.ip_block_list :
      can(cidrhost(cidr, 0))
    ])
    error_message = "IP block list must contain valid CIDR blocks (e.g., '192.0.2.0/24', '203.0.113.5/32')."
  }
}

variable "ip_allow_list_priority" {
  description = "Priority for IP allow list rule (should be lower than other rules to allow trusted IPs first)"
  type        = number
  default     = 0

  validation {
    condition     = var.ip_allow_list_priority >= 0
    error_message = "Priority must be a non-negative integer."
  }
}

variable "ip_block_list_priority" {
  description = "Priority for IP block list rule"
  type        = number
  default     = 10

  validation {
    condition     = var.ip_block_list_priority >= 0
    error_message = "Priority must be a non-negative integer."
  }
}

# ========================================
# Custom Rules
# ========================================

variable "custom_rules" {
  description = <<-EOT
    List of custom WAF rules. Each rule must have:
    - name: Rule name
    - priority: Rule priority (unique, lower evaluated first)
    - action: 'block', 'allow', 'count', or 'captcha'
    - statement: WAF rule statement (complex object, see AWS WAF documentation)
    
    Example:
    [
      {
        name     = "BlockUserAgent"
        priority = 100
        action   = "block"
        statement = {
          byte_match_statement = {
            search_string         = "BadBot"
            field_to_match        = { single_header = { name = "user-agent" } }
            positional_constraint = "CONTAINS"
            text_transformations  = [{ priority = 0, type = "LOWERCASE" }]
          }
        }
      }
    ]
  EOT
  type = list(object({
    name      = string
    priority  = number
    action    = string
    statement = any
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.custom_rules :
      contains(["block", "allow", "count", "captcha"], rule.action)
    ])
    error_message = "Custom rule action must be 'block', 'allow', 'count', or 'captcha'."
  }
}

# ========================================
# Logging and Monitoring
# ========================================

variable "enable_logging" {
  description = "Enable WAF request logging to CloudWatch Logs, S3, or Kinesis Firehose"
  type        = bool
  default     = true
}

variable "log_destination_type" {
  description = "Destination for WAF logs: 'cloudwatch' (CloudWatch Logs), 's3' (S3 bucket), or 'kinesis' (Kinesis Firehose)"
  type        = string
  default     = "cloudwatch"

  validation {
    condition     = contains(["cloudwatch", "s3", "kinesis"], var.log_destination_type)
    error_message = "Log destination type must be 'cloudwatch', 's3', or 'kinesis'."
  }
}

variable "log_destination_arn" {
  description = "ARN of the log destination (CloudWatch Log Group, S3 bucket, or Kinesis Firehose). If not provided, will be created automatically."
  type        = string
  default     = null

  validation {
    condition     = var.log_destination_arn == null || can(regex("^arn:aws", var.log_destination_arn))
    error_message = "Log destination ARN must be a valid AWS ARN."
  }
}

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain WAF logs in CloudWatch (if using CloudWatch logging)"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_retention_days)
    error_message = "CloudWatch log retention must be one of: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653 days."
  }
}

variable "enable_sampled_requests" {
  description = "Enable sampling of requests that match rules (for troubleshooting)"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_metrics" {
  description = "Enable CloudWatch metrics for WAF rules"
  type        = bool
  default     = true
}

variable "metric_namespace" {
  description = "CloudWatch metric namespace for WAF metrics"
  type        = string
  default     = "WAF"

  validation {
    condition     = length(var.metric_namespace) >= 1 && length(var.metric_namespace) <= 255
    error_message = "Metric namespace must be between 1 and 255 characters."
  }
}

# ========================================
# Association (Optional)
# ========================================

variable "associate_alb" {
  description = "Whether to automatically associate this WAF with an ALB"
  type        = bool
  default     = false
}

variable "alb_arn" {
  description = "ARN of the ALB to associate with this WAF Web ACL (if associate_alb is true)"
  type        = string
  default     = null

  validation {
    condition     = var.alb_arn == null || can(regex("^arn:aws:elasticloadbalancing:", var.alb_arn))
    error_message = "ALB ARN must be a valid Elastic Load Balancing ARN."
  }
}

# ========================================
# Tags
# ========================================

variable "tags" {
  description = "Additional tags to apply to the WAF Web ACL and related resources"
  type        = map(string)
  default     = {}
}
