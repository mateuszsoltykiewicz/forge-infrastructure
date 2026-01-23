# --------------------------------------
# Application Load Balancer Module - Variables
# Purpose: HTTP/HTTPS load balancing with advanced routing
# --------------------------------------

# ========================================
# Environment
# ========================================

variable "environments" {
  description = "List of environment names (e.g., [production, staging, development])"
  type        = list(string)
  default = []
}


# ========================================
# Domain Configuration
# ========================================
variable "domain_name" {
  description = "Base domain name for subdomain generation (e.g., cronus-backend.com)"
  type        = string
}

# ========================================
# ALB Attributes
# ========================================

variable "enable_deletion_protection" {
  description = "Enable deletion protection for the ALB"
  type        = bool
  default     = false
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
  description = "Enable access logging to S3 (requires S3 bucket configuration)"
  type        = bool
  default     = false # Disabled by default - enable after creating S3 bucket
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

variable "common_tags" {
  description = "Common tags passed from root module (ManagedBy, Workspace, Region, DomainName, Customer, Project)"
  type        = map(string)
}

# ========================================
# Naming
# ========================================
variable "common_prefix" {
  description = "Common prefix for resource naming"
  type        = string
}

# -=======================================
# Network Context
# ========================================
variable "vpc_id" {
  description = "The ID of the VPC where the ALB will be deployed"
  type        = string
}

# ------------------------------------------------------------------------------
# Subnet Configuration
# ------------------------------------------------------------------------------

variable "subnet_cidrs" {
  description = "List of CIDR blocks for Client VPN subnets (from root locals)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_cidrs) > 0 && length(var.subnet_cidrs) <= 3
    error_message = "subnet_cidrs must contain 1-3 CIDR blocks"
  }
}

variable "availability_zones" {
  description = "List of availability zones for Client VPN subnets (from root locals)"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) > 0 && length(var.availability_zones) <= 3
    error_message = "availability_zones must contain 1-3 zones"
  }

  validation {
    condition     = length(var.availability_zones) == length(var.subnet_cidrs)
    error_message = "availability_zones and subnet_cidrs must have the same length"
  }
}

# ------------------------------------------------------------------------------
# Routing Configuration
# ------------------------------------------------------------------------------

variable "internet_gateway_id" {
  description = "Internet Gateway ID for public subnet routing (ALB requires internet access)"
  type        = string
}
