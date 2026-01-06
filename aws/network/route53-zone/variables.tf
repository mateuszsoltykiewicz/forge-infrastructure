# ==============================================================================
# Resource Creation Control
# ==============================================================================

variable "create" {
  description = "Whether to create resources. Set to false to skip resource creation."
  type        = bool
  default     = true
}


# ==============================================================================
# Route 53 Hosted Zone Module - Variables
# ==============================================================================
# This file defines input variables for the Route 53 hosted zone module.
# ==============================================================================

# ------------------------------------------------------------------------------
# Customer Context Variables
# ------------------------------------------------------------------------------

variable "customer_name" {
  description = "Name of the customer (used in resource naming, e.g., 'forge', 'acme-corp')"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.customer_name))
    error_message = "customer_name must contain only lowercase letters, numbers, and hyphens"
  }
}

variable "project_name" {
  description = "Project name for multi-tenant deployments"
  type        = string
  default     = null
}

variable "architecture_type" {
  description = "Architecture type (shared, dedicated_local, dedicated_regional)"
  type        = string
  default     = "shared"
}

variable "plan_tier" {
  description = "Customer plan tier: basic, pro, enterprise, or platform"
  type        = string

  validation {
    condition     = contains(["basic", "pro", "enterprise", "platform"], var.plan_tier)
    error_message = "plan_tier must be one of: basic, pro, enterprise, platform"
  }
}

# ------------------------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string
}

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
}

# ------------------------------------------------------------------------------
# Hosted Zone Configuration
# ------------------------------------------------------------------------------

variable "domain_name" {
  description = "Domain name for the hosted zone (e.g., 'example.com', 'api.example.com')"
  type        = string

  validation {
    condition     = can(regex("^([a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,}$", var.domain_name))
    error_message = "domain_name must be a valid domain name format"
  }
}

variable "zone_type" {
  description = "Type of hosted zone: 'public' (internet-facing) or 'private' (VPC-associated)"
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.zone_type)
    error_message = "zone_type must be either 'public' or 'private'"
  }
}

variable "comment" {
  description = "Comment for the hosted zone"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# Private Hosted Zone Configuration
# ------------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC ID to associate with private hosted zone (required for private zones)"
  type        = string
  default     = null

  validation {
    condition     = var.vpc_id == null || can(regex("^vpc-[a-z0-9]{8,}$", var.vpc_id))
    error_message = "vpc_id must be a valid VPC ID format (vpc-xxxxxxxx)"
  }
}

variable "vpc_region" {
  description = "Region of the VPC to associate (defaults to var.region)"
  type        = string
  default     = null
}

variable "additional_vpc_associations" {
  description = "List of additional VPCs to associate with the private hosted zone"
  type = list(object({
    vpc_id     = string
    vpc_region = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for vpc in var.additional_vpc_associations : can(regex("^vpc-[a-z0-9]{8,}$", vpc.vpc_id))
    ])
    error_message = "All vpc_id values must be valid VPC ID format (vpc-xxxxxxxx)"
  }
}

# ------------------------------------------------------------------------------
# DNSSEC Configuration
# ------------------------------------------------------------------------------

variable "enable_dnssec" {
  description = "Enable DNSSEC signing for the hosted zone (public zones only)"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "KMS key ID for DNSSEC signing (required if enable_dnssec is true)"
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_id == null || can(regex("^(arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+|[a-f0-9-]+)$", var.kms_key_id))
    error_message = "kms_key_id must be a valid KMS key ID or ARN"
  }
}

# ------------------------------------------------------------------------------
# Query Logging Configuration
# ------------------------------------------------------------------------------

variable "enable_query_logging" {
  description = "Enable query logging to CloudWatch Logs"
  type        = bool
  default     = false
}

variable "query_log_group_arn" {
  description = "CloudWatch Log Group ARN for query logs (required if enable_query_logging is true)"
  type        = string
  default     = null

  validation {
    condition     = var.query_log_group_arn == null || can(regex("^arn:aws:logs:[a-z0-9-]+:[0-9]{12}:log-group:", var.query_log_group_arn))
    error_message = "query_log_group_arn must be a valid CloudWatch Log Group ARN"
  }
}

# ------------------------------------------------------------------------------
# Delegation Set
# ------------------------------------------------------------------------------

variable "delegation_set_id" {
  description = "ID of the reusable delegation set (for consistent nameservers across zones)"
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Force destroy the hosted zone even if it contains records (use with caution)"
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# Tags
# ------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
