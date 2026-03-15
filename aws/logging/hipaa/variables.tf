# ==============================================================================
# S3 HIPAA Logs Module - Input Variables
# ==============================================================================

variable "common_prefix" {
  description = "Common prefix for resource naming (Pattern A)"
  type        = string

  validation {
    condition     = length(var.common_prefix) > 0 && length(var.common_prefix) <= 20
    error_message = "common_prefix must be between 1 and 20 characters"
  }
}

variable "common_tags" {
  description = "Common tags for all resources (Pattern A)"
  type        = map(string)

  validation {
    condition = (
      contains(keys(var.common_tags), "Customer") &&
      contains(keys(var.common_tags), "Project") &&
      contains(keys(var.common_tags), "Environment") &&
      contains(keys(var.common_tags), "ManagedBy")
    )
    error_message = "common_tags must include: Customer, Project, Environment, ManagedBy"
  }
}

variable "primary_region" {
  description = "Primary AWS region (e.g., us-east-2)"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.primary_region))
    error_message = "primary_region must be a valid AWS region (e.g., us-east-2)"
  }
}

variable "dr_region" {
  description = "Disaster Recovery AWS region (e.g., us-west-2)"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.dr_region))
    error_message = "dr_region must be a valid AWS region (e.g., us-west-2)"
  }
}

variable "dr_tags" {
  description = "Additional tags for Disaster Recovery resources"
  type        = map(string)
  default     = {}
}

variable "force_destroy" {
  description = "Allow bucket destruction with objects (DANGEROUS - use only for testing)"
  type        = bool
  default     = false
}
