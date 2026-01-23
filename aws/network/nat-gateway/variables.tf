# ==============================================================================
# NAT Gateway Module - Variables
# ==============================================================================

# ------------------------------------------------------------------------------
# Required Variables
# ------------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID of the VPC where NAT Gateway will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where NAT Gateways will be placed (typically ALB subnets)"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 1 && length(var.public_subnet_ids) <= 3
    error_message = "Must provide 1-3 public subnet IDs (one per AZ)."
  }
}

variable "availability_zones" {
  description = "List of availability zones for NAT Gateway placement"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 1 && length(var.availability_zones) <= 3
    error_message = "Must provide 1-3 availability zones."
  }

  validation {
    condition     = length(var.availability_zones) == length(distinct(var.availability_zones))
    error_message = "Availability zones must be unique."
  }
}

# ------------------------------------------------------------------------------
# Optional Variables
# ------------------------------------------------------------------------------

variable "common_prefix" {
  description = "Common prefix for resource naming (e.g., 'forge-dev', 'forge-prod')"
  type        = string
  default     = "forge"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
