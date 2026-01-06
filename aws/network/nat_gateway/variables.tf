# ==============================================================================
# NAT Gateway Module - Input Variables
# ==============================================================================
# Defines input parameters for creating NAT Gateways with EIP management and
# flexible deployment modes (HA, single, best-effort).
# ==============================================================================

# ------------------------------------------------------------------------------
# VPC and Subnet Configuration (Required)
# ------------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID of the VPC where NAT Gateways will be created"
  type        = string

  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC ID (starts with 'vpc-')."
  }
}

variable "vpc_name" {
  description = "Name of the VPC (used for NAT Gateway naming)"
  type        = string

  validation {
    condition     = length(var.vpc_name) > 0
    error_message = "VPC name cannot be empty."
  }
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where NAT Gateways will be placed (one per AZ for HA)"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) > 0
    error_message = "At least one public subnet ID is required for NAT Gateway placement."
  }

  validation {
    condition = alltrue([
      for id in var.public_subnet_ids : can(regex("^subnet-", id))
    ])
    error_message = "All subnet IDs must be valid AWS subnet IDs (start with 'subnet-')."
  }
}

variable "private_route_table_ids" {
  description = "List of private route table IDs where default routes (0.0.0.0/0) will be added"
  type        = list(string)

  validation {
    condition     = length(var.private_route_table_ids) > 0
    error_message = "At least one private route table ID is required."
  }

  validation {
    condition = alltrue([
      for id in var.private_route_table_ids : can(regex("^rtb-", id))
    ])
    error_message = "All route table IDs must be valid AWS route table IDs (start with 'rtb-')."
  }
}

# ------------------------------------------------------------------------------
# NAT Gateway Deployment Mode (Required)
# ------------------------------------------------------------------------------

variable "nat_gateway_mode" {
  description = <<-EOT
    NAT Gateway deployment mode:
    - 'high_availability': One NAT Gateway per AZ (recommended for production)
    - 'single': One NAT Gateway total (cost optimization for dev/test)
    - 'best_effort': Create as many NAT Gateways as EIPs available (graceful degradation)
  EOT
  type        = string
  default     = "high_availability"

  validation {
    condition     = contains(["high_availability", "single", "best_effort"], var.nat_gateway_mode)
    error_message = "NAT Gateway mode must be 'high_availability', 'single', or 'best_effort'."
  }
}

# ------------------------------------------------------------------------------
# EIP Management (Optional)
# ------------------------------------------------------------------------------

variable "check_eip_quota" {
  description = "Whether to check EIP service quota via AWS Service Quotas API (requires servicequotas:GetServiceQuota permission)"
  type        = bool
  default     = false
}

variable "default_eip_limit" {
  description = "Default EIP limit to use when check_eip_quota is false or API call fails"
  type        = number
  default     = 5

  validation {
    condition     = var.default_eip_limit > 0
    error_message = "Default EIP limit must be greater than 0."
  }
}

variable "existing_eip_allocation_ids" {
  description = "Optional list of existing EIP allocation IDs to use instead of creating new ones (must match nat_gateway_count)"
  type        = list(string)
  default     = null

  validation {
    condition = var.existing_eip_allocation_ids == null || alltrue([
      for id in var.existing_eip_allocation_ids : can(regex("^eipalloc-", id))
    ])
    error_message = "All EIP allocation IDs must be valid AWS allocation IDs (start with 'eipalloc-')."
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
  description = "AWS region where NAT Gateways will be created"
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
