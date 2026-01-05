# ==============================================================================
# IAM Module - Variables
# ==============================================================================
# This file defines input variables for the IAM module.
# ==============================================================================

# ------------------------------------------------------------------------------
# Customer Context Variables
# ------------------------------------------------------------------------------

variable "customer_id" {
  description = "UUID of the customer (use 00000000-0000-0000-0000-000000000000 for shared infrastructure)"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.customer_id))
    error_message = "customer_id must be a valid UUID format"
  }
}

variable "customer_name" {
  description = "Name of the customer (used in resource naming, e.g., 'forge', 'acme-corp')"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.customer_name))
    error_message = "customer_name must contain only lowercase letters, numbers, and hyphens"
  }
}

variable "architecture_type" {
  description = "Architecture type: 'shared' (multi-tenant), 'dedicated_single_tenant', or 'dedicated_vpc'"
  type        = string

  validation {
    condition     = contains(["shared", "dedicated_single_tenant", "dedicated_vpc"], var.architecture_type)
    error_message = "architecture_type must be one of: shared, dedicated_single_tenant, dedicated_vpc"
  }
}

variable "plan_tier" {
  description = "Customer plan tier: basic, pro, enterprise, or platform"
  type        = string

  validation {
    condition     = contains(["basic", "pro", "enterprise", "platform"], var.plan_tier)
    error_message = "plan_tier must be one of: basic, pro, enterprise, platform"
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
# IAM Role Configuration
# ------------------------------------------------------------------------------

variable "role_name" {
  description = "Name of the IAM role (leave empty for auto-generated name based on customer context)"
  type        = string
  default     = ""

  validation {
    condition     = var.role_name == "" || can(regex("^[a-zA-Z0-9+=,.@_-]+$", var.role_name))
    error_message = "role_name must contain only alphanumeric characters and +=,.@_-"
  }
}

variable "role_description" {
  description = "Description of the IAM role"
  type        = string
  default     = "IAM role created by Terraform"
}

variable "role_purpose" {
  description = "Purpose of the role (e.g., 'eks-node', 'eks-pod', 'rds-monitoring', 's3-replication')"
  type        = string
  default     = "general"
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds (1 hour to 12 hours)"
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 (1 hour) and 43200 (12 hours)"
  }
}

variable "force_detach_policies" {
  description = "Force detach policies when destroying the role"
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# Trust Policy Configuration
# ------------------------------------------------------------------------------

variable "trusted_services" {
  description = "List of AWS services that can assume this role (e.g., ['ec2.amazonaws.com', 'eks.amazonaws.com'])"
  type        = list(string)
  default     = []
}

variable "trusted_aws_accounts" {
  description = "List of AWS account IDs that can assume this role"
  type        = list(string)
  default     = []
}

variable "trusted_federated_arns" {
  description = "List of federated ARNs (OIDC, SAML) that can assume this role"
  type        = list(string)
  default     = []
}

variable "oidc_condition" {
  description = "OIDC condition for EKS IRSA (e.g., for service account authentication)"
  type = object({
    test     = string
    variable = string
    values   = list(string)
  })
  default = null
}

variable "custom_assume_role_policy" {
  description = "Custom assume role policy JSON (overrides all trust policy settings if provided)"
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# Managed Policies
# ------------------------------------------------------------------------------

variable "aws_managed_policy_arns" {
  description = "List of AWS managed policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "customer_managed_policy_arns" {
  description = "List of customer managed policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

# ------------------------------------------------------------------------------
# Inline Policy Configuration
# ------------------------------------------------------------------------------

variable "inline_policies" {
  description = "Map of inline policy names to policy documents"
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------------------------
# Instance Profile Configuration
# ------------------------------------------------------------------------------

variable "create_instance_profile" {
  description = "Create an instance profile for EC2/EKS node use"
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# Permission Boundary
# ------------------------------------------------------------------------------

variable "permissions_boundary_arn" {
  description = "ARN of the policy to set as permissions boundary"
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# Tags
# ------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
