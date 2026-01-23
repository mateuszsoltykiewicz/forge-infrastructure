# ==============================================================================
# Naming Convention Module - Input Variables
# ==============================================================================

variable "customer_name" {
  description = "Customer/tenant name (e.g., 'Sanofi'). Must be at least 3 characters for meaningful abbreviation."
  type        = string

  validation {
    condition     = length(var.customer_name) >= 3
    error_message = "customer_name must be at least 3 characters long for proper code generation."
  }

  validation {
    condition     = can(regex("^[A-Za-z0-9]+$", var.customer_name))
    error_message = "customer_name must contain only alphanumeric characters (no spaces, hyphens, or special characters)."
  }
}

variable "project_name" {
  description = "Project name (e.g., 'Cronus'). Must be at least 3 characters for meaningful abbreviation."
  type        = string

  validation {
    condition     = length(var.project_name) >= 3
    error_message = "project_name must be at least 3 characters long for proper code generation."
  }

  validation {
    condition     = can(regex("^[A-Za-z0-9]+$", var.project_name))
    error_message = "project_name must contain only alphanumeric characters (no spaces, hyphens, or special characters)."
  }
}

variable "current_region" {
  description = "Current AWS region where resources will be deployed (e.g., 'us-east-1')."
  type        = string

  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "eu-west-1", "eu-west-2", "eu-west-3", "eu-central-1", "eu-central-2", "eu-north-1",
      "ap-south-1", "ap-southeast-1", "ap-southeast-2", "ap-northeast-1"
    ], var.current_region)
    error_message = "current_region must be one of the supported AWS regions with defined region codes."
  }
}

variable "primary_aws_region" {
  description = "Primary AWS region for DR mode determination (e.g., 'us-east-1')."
  type        = string

  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "eu-west-1", "eu-west-2", "eu-west-3", "eu-central-1", "eu-central-2", "eu-north-1",
      "ap-south-1", "ap-southeast-1", "ap-southeast-2", "ap-northeast-1"
    ], var.primary_aws_region)
    error_message = "primary_aws_region must be one of the supported AWS regions with defined region codes."
  }
}
