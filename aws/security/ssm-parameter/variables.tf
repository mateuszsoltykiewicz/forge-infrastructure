# ==============================================================================
# SSM Parameter Module - Variables
# ==============================================================================
# This file defines input variables for the SSM parameter module.
# ==============================================================================

# ==============================================================================
# Common Configuration (Pattern A)
# ==============================================================================

variable "common_prefix" {
  description = "Common prefix for SSM parameter path construction (e.g., forge-production-customer-project)"
  type        = string

  validation {
    condition     = length(var.common_prefix) > 0
    error_message = "common_prefix must not be empty"
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
# Parameter Configuration
# ------------------------------------------------------------------------------

variable "parameter_name" {
  description = "Name of the parameter (will be prefixed with hierarchical path)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]+$", var.parameter_name))
    error_message = "parameter_name must contain only alphanumeric characters, underscores, hyphens, and dots"
  }
}

variable "parameter_value" {
  description = "Value of the parameter"
  type        = string
  sensitive   = true
}

variable "parameter_type" {
  description = "Type of parameter: String, StringList, or SecureString"
  type        = string
  default     = "String"

  validation {
    condition     = contains(["String", "StringList", "SecureString"], var.parameter_type)
    error_message = "parameter_type must be one of: String, StringList, SecureString"
  }
}

variable "parameter_description" {
  description = "Description of the parameter"
  type        = string
  default     = ""
}

variable "parameter_tier" {
  description = "Parameter tier: Standard, Advanced, or Intelligent-Tiering"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Advanced", "Intelligent-Tiering"], var.parameter_tier)
    error_message = "parameter_tier must be one of: Standard, Advanced, Intelligent-Tiering"
  }
}

variable "description" {
  description = "Description of the SSM parameter"
  type        = string
  default     = "SSM Parameter managed by Terraform"
}

# ------------------------------------------------------------------------------
# Hierarchical Path Configuration
# ------------------------------------------------------------------------------

variable "resource_type" {
  description = "Type of resource (e.g., 'database', 'cache', 'application', 'config')"
  type        = string
  default     = "config"
}

variable "resource_id" {
  description = "Identifier of the resource (e.g., 'forge-production-db', 'forge-production-redis')"
  type        = string
  default     = ""
}

variable "custom_path" {
  description = "Custom parameter path (overrides automatic hierarchical path if provided)"
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# Encryption Configuration
# ------------------------------------------------------------------------------

variable "kms_key_id" {
  description = "KMS key ID for SecureString encryption (uses AWS managed key if not specified)"
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# Data Protection
# ------------------------------------------------------------------------------

variable "data_type" {
  description = "Data type for parameter validation (e.g., 'text', 'aws:ec2:image')"
  type        = string
  default     = "text"
}

variable "allowed_pattern" {
  description = "Regular expression to validate parameter value"
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# Lifecycle Configuration
# ------------------------------------------------------------------------------

variable "overwrite" {
  description = "Overwrite existing parameter value"
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# Tags Configuration
# ------------------------------------------------------------------------------

variable "common_tags" {
  description = "Common tags to apply to all resources (passed from root module)"
  type        = map(string)
  default     = {}
}