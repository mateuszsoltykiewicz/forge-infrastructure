# ==============================================================================
# Internet Gateway Module - Input Variables
# ==============================================================================
# Defines input parameters for creating an Internet Gateway and configuring
# internet access for public subnets.
# ==============================================================================

variable "common_prefix" {
  description = "Common prefix for resource naming"
  type        = string
}

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

# ------------------------------------------------------------------------------
# Infrastructure Context (Required)
# ------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region where the Internet Gateway will be created"
  type        = string
}

# ------------------------------------------------------------------------------
# Additional Tags (Optional)
# ------------------------------------------------------------------------------

variable "common_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
