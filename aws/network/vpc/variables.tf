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
  description = "Customer name for resource naming and tagging (e.g., 'cronus', 'acme'). Optional."
  default     = null
}

variable "project_name" {
  type        = string
  description = "Project name for resource naming and tagging (e.g., 'analytics', 'ml-platform'). Optional."
  default     = null
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
# Multi-Tenancy Patterns:
# ==============================================================================
# 1. Shared Infrastructure (workspace only):
#    - customer_name = null, project_name = null
#    - Resources: forge-{environment}-*
#
# 2. Customer-Specific (workspace + customer):
#    - customer_name = "cronus", project_name = null
#    - Resources: forge-{environment}-cronus-*
#
# 3. Project-Specific (workspace + customer + project):
#    - customer_name = "cronus", project_name = "analytics"
#    - Resources: forge-{environment}-cronus-analytics-*
#
# Always provide unique CIDR blocks to avoid routing conflicts.
# Tag resources consistently for cost allocation and auto-discovery.
# ==============================================================================
