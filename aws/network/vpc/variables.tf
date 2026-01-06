# ==============================================================================
# Resource Creation Control
# ==============================================================================

variable "create" {
  description = "Whether to create resources. Set to false to skip resource creation."
  type        = bool
  default     = true
}


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
  description = "Environment identifier (e.g., 'prod', 'staging', 'dev', 'shared')."
  validation {
    condition     = contains(["prod", "staging", "dev", "shared"], var.environment)
    error_message = "Environment must be one of: prod, staging, dev, shared."
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

variable "merged_tags" {
  type        = map(string)
  description = "Additional tags to apply to the VPC for cost allocation, automation, and compliance."
  default     = {}
}

# ------------------------------------------------------------------------------
# VPC Flow Logs Configuration
# ------------------------------------------------------------------------------

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs for network traffic monitoring and security analysis"
  type        = bool
  default     = true
}

variable "flow_logs_traffic_type" {
  description = "Type of traffic to capture: ALL (all traffic), ACCEPT (accepted traffic), REJECT (rejected traffic)"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "ACCEPT", "REJECT"], var.flow_logs_traffic_type)
    error_message = "Traffic type must be one of: ALL, ACCEPT, REJECT."
  }
}

variable "flow_logs_retention_days" {
  description = "CloudWatch Logs retention period for flow logs in days"
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.flow_logs_retention_days)
    error_message = "Retention must be a valid CloudWatch value."
  }
}

variable "flow_logs_kms_key_id" {
  description = "KMS key ID for encrypting flow logs (optional, recommended for production)"
  type        = string
  default     = null
}

variable "flow_logs_aggregation_interval" {
  description = "Maximum interval for flow log aggregation in seconds (60 or 600)"
  type        = number
  default     = 600

  validation {
    condition     = contains([60, 600], var.flow_logs_aggregation_interval)
    error_message = "Aggregation interval must be 60 or 600 seconds."
  }
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
