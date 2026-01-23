# ==============================================================================
# WAF Web ACL Module - Variables (Refactored)
# ==============================================================================
# Pattern A compliance with simplified, opinionated WAF configuration
# Logging ALWAYS enabled, Geo-allowlist hardcoded, KMS optional internal
# ==============================================================================

# ==============================================================================
# Pattern A - Common Configuration
# ==============================================================================

variable "common_prefix" {
  description = "Common prefix for WAF Web ACL naming (from naming module)"
  type        = string

  validation {
    condition     = length(var.common_prefix) > 0 && length(var.common_prefix) <= 100
    error_message = "common_prefix must be between 1 and 100 characters"
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources (passed from root module)"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# WAF Configuration
# ==============================================================================

variable "name" {
  description = "Override WAF Web ACL name (if null, generated from common_prefix as '{prefix}-waf')"
  type        = string
  default     = null
}

variable "scope" {
  description = "Scope of the WAF Web ACL. Use 'REGIONAL' for ALB/API Gateway, 'CLOUDFRONT' for CloudFront distributions"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "scope must be REGIONAL or CLOUDFRONT"
  }
}

variable "default_action" {
  description = "Default action when no rules match: 'allow' permits requests, 'block' denies them"
  type        = string
  default     = "allow"

  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "default_action must be allow or block"
  }
}

# ==============================================================================
# Rate Limiting (DDoS Protection)
# ==============================================================================

variable "rate_limit_requests" {
  description = "Maximum number of requests allowed from a single IP in a 5-minute window (DDoS protection)"
  type        = number
  default     = 2000

  validation {
    condition     = var.rate_limit_requests >= 100 && var.rate_limit_requests <= 20000000
    error_message = "rate_limit_requests must be between 100 and 20,000,000"
  }
}

# ==============================================================================
# Logging (ALWAYS ENABLED - CloudWatch only)
# ==============================================================================

variable "log_retention_days" {
  description = "Number of days to retain WAF logs in CloudWatch (always enabled)"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Must be valid CloudWatch retention period: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653 days"
  }
}

# ==============================================================================
# KMS Encryption (Optional Internal Creation)
# ==============================================================================

variable "create_kms_key" {
  description = "Create KMS key for CloudWatch Logs encryption (if false, use kms_key_id variable)"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "External KMS key ARN for log encryption (used only when create_kms_key = false)"
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_id == null || can(regex("^arn:aws:kms:", var.kms_key_id))
    error_message = "kms_key_id must be a valid KMS key ARN starting with 'arn:aws:kms:'"
  }
}

variable "firehose_delivery_stream_arn" {
  description = "ARN of Kinesis Firehose delivery stream for WAF logging (required - WAFv2 does not support direct CloudWatch logging)"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:firehose:", var.firehose_delivery_stream_arn))
    error_message = "firehose_delivery_stream_arn must be a valid Kinesis Firehose ARN starting with 'arn:aws:firehose:'"
  }
}
