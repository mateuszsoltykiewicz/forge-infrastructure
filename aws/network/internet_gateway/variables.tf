# ==============================================================================
# Internet Gateway Module - Input Variables
# ==============================================================================
# Defines input parameters for creating an Internet Gateway and configuring
# internet access for public subnets.
# ==============================================================================

# ------------------------------------------------------------------------------
# VPC Configuration (Required)
# ------------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID of the VPC where the Internet Gateway will be attached"
  type        = string

  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC ID (starts with 'vpc-')."
  }
}

variable "vpc_name" {
  description = "Name of the VPC (used for Internet Gateway naming)"
  type        = string

  validation {
    condition     = length(var.vpc_name) > 0
    error_message = "VPC name cannot be empty."
  }
}

variable "public_route_table_id" {
  description = "ID of the public route table where the default route (0.0.0.0/0) will be added"
  type        = string

  validation {
    condition     = can(regex("^rtb-", var.public_route_table_id))
    error_message = "Route table ID must be a valid AWS route table ID (starts with 'rtb-')."
  }
}

# ------------------------------------------------------------------------------
# Infrastructure Context (Required)
# ------------------------------------------------------------------------------

variable "workspace" {
  description = "Workspace name (e.g., 'production', 'staging', 'development')"
  type        = string

  validation {
    condition     = contains(["production", "staging", "development"], var.workspace)
    error_message = "Workspace must be 'production', 'staging', or 'development'."
  }
}

variable "environment" {
  description = "Environment name (e.g., 'prod', 'staging', 'dev')"
  type        = string
}

variable "aws_region" {
  description = "AWS region where the Internet Gateway will be created"
  type        = string
}

# ------------------------------------------------------------------------------
# Customer Context (Optional - for dedicated customer VPCs)
# ------------------------------------------------------------------------------

variable "customer_id" {
  description = "Customer UUID (null for shared Forge infrastructure)"
  type        = string
  default     = null

  validation {
    condition = var.customer_id == null || can(
      regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.customer_id)
    )
    error_message = "Customer ID must be a valid UUID or null."
  }
}

variable "customer_name" {
  description = "Customer name (null for shared Forge infrastructure)"
  type        = string
  default     = null
}

variable "architecture_type" {
  description = "Architecture type: 'shared' (multi-tenant), 'dedicated_local' (single region), 'dedicated_regional' (multi-region)"
  type        = string
  default     = "shared"

  validation {
    condition     = contains(["shared", "dedicated_local", "dedicated_regional"], var.architecture_type)
    error_message = "Architecture type must be 'shared', 'dedicated_local', or 'dedicated_regional'."
  }
}

variable "plan_tier" {
  description = "Customer plan tier (e.g., 'trial', 'basic', 'pro', 'enterprise')"
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# Additional Tags (Optional)
# ------------------------------------------------------------------------------

variable "merged_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
