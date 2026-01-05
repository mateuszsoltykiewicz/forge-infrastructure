# ==============================================================================
# VPC Module Variables (Forge - Customer-Centric)
# ==============================================================================

# ------------------------------------------------------------------------------
# Required Variables
# ------------------------------------------------------------------------------

variable "vpc_name" {
  type        = string
  description = "Name of the VPC. For shared: 'forge-{workspace}-{environment}'. For dedicated: '{customer_name}-{region}'."
}

variable "cidr_block" {
  type        = string
  description = "Primary CIDR block for the VPC (e.g., 10.0.0.0/16). Ensure this does not overlap with other VPCs."
  validation {
    condition     = can(cidrnetmask(var.cidr_block))
    error_message = "The provided CIDR block is not valid. Please provide a valid CIDR notation (e.g., 10.0.0.0/16)."
  }
}

# ------------------------------------------------------------------------------
# Forge Infrastructure Variables
# ------------------------------------------------------------------------------

variable "workspace" {
  type        = string
  description = "Terraform workspace name (e.g., 'production', 'staging', 'development')."
  validation {
    condition     = length(var.workspace) > 0
    error_message = "Workspace name cannot be empty."
  }
}

variable "environment" {
  type        = string
  description = "Environment identifier (e.g., 'prod', 'staging', 'dev')."
  validation {
    condition     = contains(["prod", "staging", "dev"], var.environment)
    error_message = "Environment must be one of: prod, staging, dev."
  }
}

variable "aws_region" {
  type        = string
  description = "The AWS region to deploy resources in."
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "Invalid AWS region format. Expected format: us-east-1, eu-west-1, etc."
  }
}

# ------------------------------------------------------------------------------
# Customer Context Variables (Optional - for customer-specific VPCs)
# ------------------------------------------------------------------------------

variable "customer_id" {
  type        = string
  description = "Customer UUID from the Forge database. Required for dedicated architectures."
  default     = null
}

variable "customer_name" {
  type        = string
  description = "Customer name for resource naming and tagging. Required for dedicated architectures."
  default     = null
}

variable "architecture_type" {
  type        = string
  description = "Architecture deployment model: 'shared', 'dedicated_local', 'dedicated_regional'."
  default     = "shared"
  
  validation {
    condition     = contains(["shared", "dedicated_local", "dedicated_regional"], var.architecture_type)
    error_message = "Architecture type must be one of: shared, dedicated_local, dedicated_regional."
  }
}

variable "plan_tier" {
  type        = string
  description = "Customer plan tier (e.g., 'trial', 'basic', 'pro', 'enterprise'). Used for tagging and cost allocation."
  default     = null
}

# ------------------------------------------------------------------------------
# Tagging Variables
# ------------------------------------------------------------------------------

variable "common_tags" {
  type        = map(string)
  description = "Additional tags to apply to the VPC for cost allocation, automation, and compliance."
  default     = {}
}

# ==============================================================================
# Forge Best Practices:
# ==============================================================================
# - For shared VPCs: customer_id and customer_name should be null
# - For dedicated VPCs: customer_id and customer_name are required
# - Always provide unique CIDR blocks to avoid routing conflicts
# - Use architecture_type to determine resource isolation level
# - Tag resources consistently for accurate cost allocation by customer
# ==============================================================================
