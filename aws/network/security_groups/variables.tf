# ==============================================================================
# Security Groups Module - Input Variables
# ==============================================================================
# Defines input parameters for creating security groups with predefined rules
# for common Forge infrastructure components (EKS, RDS, ALB, etc.).
# ==============================================================================

# ------------------------------------------------------------------------------
# VPC Configuration (Required)
# ------------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created"
  type        = string

  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC ID (starts with 'vpc-')."
  }
}

variable "vpc_name" {
  description = "Name of the VPC (used for security group naming)"
  type        = string

  validation {
    condition     = length(var.vpc_name) > 0
    error_message = "VPC name cannot be empty."
  }
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC (for internal VPC traffic rules)"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "VPC CIDR block must be a valid CIDR notation."
  }
}

# ------------------------------------------------------------------------------
# Security Group Configuration (Required)
# ------------------------------------------------------------------------------

variable "security_groups" {
  description = <<-EOT
    Map of security groups to create. Each key is the security group name, and the value
    contains configuration for that security group including description and rules.
    
    Example:
    {
      "eks_cluster" = {
        description = "EKS cluster control plane security group"
        ingress_rules = [
          {
            from_port   = 443
            to_port     = 443
            protocol    = "tcp"
            cidr_blocks = ["10.0.0.0/16"]
            description = "Allow HTTPS from VPC"
          }
        ]
        egress_rules = [
          {
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
            description = "Allow all outbound"
          }
        ]
      }
    }
  EOT
  type = map(object({
    description = string
    ingress_rules = optional(list(object({
      from_port                = number
      to_port                  = number
      protocol                 = string
      cidr_blocks              = optional(list(string))
      ipv6_cidr_blocks         = optional(list(string))
      source_security_group_id = optional(string)
      self                     = optional(bool)
      description              = string
    })), [])
    egress_rules = optional(list(object({
      from_port                = number
      to_port                  = number
      protocol                 = string
      cidr_blocks              = optional(list(string))
      ipv6_cidr_blocks         = optional(list(string))
      source_security_group_id = optional(string)
      self                     = optional(bool)
      description              = string
    })), [])
  }))

  validation {
    condition     = length(var.security_groups) > 0
    error_message = "At least one security group must be defined."
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
  description = "AWS region where security groups will be created"
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

variable "common_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
