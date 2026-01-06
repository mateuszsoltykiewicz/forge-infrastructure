#
# Application Load Balancer Module - Variables
# Purpose: HTTP/HTTPS load balancing with advanced routing
#

# ========================================
# Multi-Tenant Context
# ========================================

variable "workspace" {
  description = "Workspace name for VPC discovery (e.g., forge-platform)"
  type        = string
  default     = "forge-platform"
}

variable "customer_id" {
  description = "UUID of the customer (empty for shared infrastructure)"
  type        = string
  default     = ""
}

variable "customer_name" {
  description = "Customer name for resource naming (empty for shared infrastructure)"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Project name for project-level isolation (empty for customer-level or shared)"
  type        = string
  default     = ""
}

variable "plan_tier" {
  description = "Customer plan tier (e.g., basic, pro, enterprise, platform)"
  type        = string
  default     = ""
}

# ========================================
# Environment
# ========================================

variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string

  validation {
    condition     = length(var.environment) > 0
    error_message = "environment must not be empty"
  }
}

# ========================================
# ALB Configuration
# ========================================

variable "name" {
  description = "Name for the ALB (optional, generated from customer context if not provided)"
  type        = string
  default     = null
}

variable "load_balancer_type" {
  description = "Type of load balancer (application or network)"
  type        = string
  default     = "application"

  validation {
    condition     = contains(["application", "network"], var.load_balancer_type)
    error_message = "load_balancer_type must be application or network"
  }
}

variable "internal" {
  description = "Whether the ALB is internal (true) or internet-facing (false)"
  type        = bool
  default     = false
}

variable "ip_address_type" {
  description = "IP address type: ipv4, dualstack, or dualstack-without-public-ipv4"
  type        = string
  default     = "ipv4"

  validation {
    condition     = contains(["ipv4", "dualstack", "dualstack-without-public-ipv4"], var.ip_address_type)
    error_message = "ip_address_type must be ipv4, dualstack, or dualstack-without-public-ipv4"
  }
}

# ========================================
# Network Configuration (Auto-Discovery)
# ========================================

variable "alb_subnet_az_count" {
  description = "Number of AZs for ALB subnets (minimum 2 for HA)"
  type        = number
  default     = 2

  validation {
    condition     = var.alb_subnet_az_count >= 2 && var.alb_subnet_az_count <= 3
    error_message = "ALB subnet AZ count must be between 2 and 3."
  }
}

variable "alb_subnet_newbits" {
  description = "Number of bits to add to VPC CIDR for ALB subnets (e.g., 8 for /24 subnets from /16 VPC)"
  type        = number
  default     = 8
}

variable "alb_subnet_netnum_start" {
  description = "Starting number for ALB subnet CIDR calculation"
  type        = number
  default     = 10
}

variable "eks_cluster_name" {
  description = "EKS cluster name for security group integration (empty = auto-discover)"
  type        = string
  default     = ""
}

# ========================================
# ALB Attributes
# ========================================

variable "enable_deletion_protection" {
  description = "Enable deletion protection for the ALB"
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "Enable HTTP/2 protocol"
  type        = bool
  default     = true
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

variable "enable_waf_fail_open" {
  description = "Enable WAF fail open mode"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60

  validation {
    condition     = var.idle_timeout >= 1 && var.idle_timeout <= 4000
    error_message = "idle_timeout must be between 1 and 4000 seconds"
  }
}

variable "desync_mitigation_mode" {
  description = "Determines how the load balancer handles requests with header fields that are not valid HTTP (monitor, defensive, strictest)"
  type        = string
  default     = "defensive"

  validation {
    condition     = contains(["monitor", "defensive", "strictest"], var.desync_mitigation_mode)
    error_message = "desync_mitigation_mode must be monitor, defensive, or strictest"
  }
}

variable "drop_invalid_header_fields" {
  description = "Drop invalid HTTP header fields"
  type        = bool
  default     = true
}

variable "preserve_host_header" {
  description = "Preserve the Host header in the request"
  type        = bool
  default     = true
}

variable "enable_xff_client_port" {
  description = "Add client port to X-Forwarded-For header"
  type        = bool
  default     = false
}

variable "xff_header_processing_mode" {
  description = "X-Forwarded-For header processing mode: append, preserve, remove"
  type        = string
  default     = "append"

  validation {
    condition     = contains(["append", "preserve", "remove"], var.xff_header_processing_mode)
    error_message = "xff_header_processing_mode must be append, preserve, or remove"
  }
}

# ========================================
# Access Logging
# ========================================

variable "enable_access_logs" {
  description = "Enable access logging to S3"
  type        = bool
  default     = true
}

variable "access_logs_bucket" {
  description = "S3 bucket name for access logs (required if enable_access_logs is true)"
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "S3 bucket prefix for access logs"
  type        = string
  default     = "alb"
}

# ========================================
# Target Groups
# ========================================

variable "target_groups" {
  description = "Map of target group configurations"
  type = map(object({
    port                          = number
    protocol                      = string
    target_type                   = optional(string, "instance")
    deregistration_delay          = optional(number, 300)
    slow_start                    = optional(number, 0)
    load_balancing_algorithm_type = optional(string, "round_robin")

    health_check = optional(object({
      enabled             = optional(bool, true)
      interval            = optional(number, 30)
      path                = optional(string, "/health")
      port                = optional(string, "traffic-port")
      protocol            = optional(string, "HTTP")
      timeout             = optional(number, 5)
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 2)
      matcher             = optional(string, "200-299")
    }), {})

    stickiness = optional(object({
      enabled         = optional(bool, false)
      type            = optional(string, "lb_cookie")
      cookie_duration = optional(number, 86400)
      cookie_name     = optional(string, null)
    }), null)
  }))
  default = {}
}

# ========================================
# Listeners
# ========================================

variable "http_listener" {
  description = "HTTP listener configuration"
  type = object({
    enabled          = optional(bool, true)
    port             = optional(number, 80)
    redirect_https   = optional(bool, true)
    default_action   = optional(string, "redirect") # redirect or forward
    target_group_key = optional(string, null)
  })
  default = {
    enabled        = true
    port           = 80
    redirect_https = true
    default_action = "redirect"
  }
}

variable "https_listener" {
  description = "HTTPS listener configuration"
  type = object({
    enabled          = optional(bool, false)
    port             = optional(number, 443)
    certificate_arn  = optional(string, null)
    ssl_policy       = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
    alpn_policy      = optional(string, null)
    target_group_key = optional(string, null)
  })
  default = {
    enabled = false
  }
}

# ========================================
# WAF
# ========================================

variable "web_acl_arn" {
  description = "ARN of the WAF Web ACL to associate with the ALB"
  type        = string
  default     = null
}

# ========================================
# Tags
# ========================================

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
