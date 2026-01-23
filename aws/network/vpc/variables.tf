# ==============================================================================
# VPC Module Variables (Forge - Customer-Centric)
# ==============================================================================

# ------------------------------------------------------------------------------
# Required Variables
# ------------------------------------------------------------------------------

variable "common_prefix" {
  type        = string
  description = "Common prefix for all VPC resources (e.g., 'forge-prod-shared'). Ensures unique naming across environments and customers."
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

variable "aws_region" {
  type        = string
  description = "AWS region for the VPC resources."
}

# ------------------------------------------------------------------------------
# VPC Flow Logs Configuration
# ------------------------------------------------------------------------------

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

variable "flow_logs_aggregation_interval" {
  description = "Maximum interval for flow log aggregation in seconds (60 or 600)"
  type        = number
  default     = 600

  validation {
    condition     = contains([60, 600], var.flow_logs_aggregation_interval)
    error_message = "Aggregation interval must be 60 or 600 seconds."
  }
}

# ------------------------------------------------------------------------------
# KMS Configuration for Flow Logs
# ------------------------------------------------------------------------------

variable "kms_deletion_window_in_days" {
  description = "KMS key deletion waiting period in days (7-30)"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "KMS deletion window must be between 7 and 30 days."
  }
}

variable "enable_kms_key_rotation" {
  description = "Enable automatic KMS key rotation (recommended for production)"
  type        = bool
  default     = true
}

# ==============================================================================
# Tagging
# ==============================================================================

variable "common_tags" {
  description = "Common tags passed from root module (ManagedBy, Workspace, Region, DomainName, Customer, Project)"
  type        = map(string)
  default     = {}
}