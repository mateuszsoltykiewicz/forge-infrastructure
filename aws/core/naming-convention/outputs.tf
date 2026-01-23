# ==============================================================================
# Naming Convention Module - Outputs
# ==============================================================================

# ------------------------------------------------------------------------------
# Base Prefix
# ------------------------------------------------------------------------------

output "common_prefix" {
  description = "Common prefix for all AWS resources (e.g., 'san-cro-p-use1')"
  value       = local.common_prefix

  # Post-condition: Validate AWS naming constraints
  precondition {
    condition     = length(local.common_prefix) <= 255
    error_message = "common_prefix length (${length(local.common_prefix)}) exceeds maximum 255 characters."
  }

  precondition {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", local.common_prefix))
    error_message = "common_prefix '${local.common_prefix}' must start and end with alphanumeric character, contain only lowercase letters, numbers, and hyphens."
  }

  precondition {
    condition     = !can(regex("--", local.common_prefix))
    error_message = "common_prefix '${local.common_prefix}' must not contain consecutive hyphens."
  }
}

# ------------------------------------------------------------------------------
# Component Codes
# ------------------------------------------------------------------------------

output "customer_code" {
  description = "3-letter customer code (e.g., 'san')"
  value       = local.customer_code
}

output "project_code" {
  description = "3-letter project code (e.g., 'cro')"
  value       = local.project_code
}

output "dr_code" {
  description = "DR mode code: 'p' = primary, 's' = secondary"
  value       = local.dr_code
}

output "region_code" {
  description = "4-letter region code (e.g., 'use1')"
  value       = local.region_code
}

# ------------------------------------------------------------------------------
# Service-Specific Prefixes
# ------------------------------------------------------------------------------

output "prefix_rds" {
  description = "Sanitized prefix for RDS resources (max 63 chars, lowercase)"
  value       = local.prefix_rds

  precondition {
    condition     = length(local.prefix_rds) <= 63
    error_message = "RDS prefix length (${length(local.prefix_rds)}) exceeds maximum 63 characters."
  }

  precondition {
    condition     = can(regex("^[a-z][a-z0-9-]*$", local.prefix_rds))
    error_message = "RDS prefix '${local.prefix_rds}' must start with letter, contain only lowercase alphanumeric and hyphens."
  }
}

output "prefix_redis" {
  description = "Sanitized prefix for ElastiCache Redis resources (max 40 chars, lowercase)"
  value       = local.prefix_redis

  precondition {
    condition     = length(local.prefix_redis) <= 40
    error_message = "Redis prefix length (${length(local.prefix_redis)}) exceeds maximum 40 characters."
  }

  precondition {
    condition     = can(regex("^[a-z][a-z0-9-]*$", local.prefix_redis))
    error_message = "Redis prefix '${local.prefix_redis}' must start with letter, contain only lowercase alphanumeric and hyphens."
  }
}

output "prefix_alb" {
  description = "Sanitized prefix for ALB resources (max 32 chars, lowercase)"
  value       = local.prefix_alb

  precondition {
    condition     = length(local.prefix_alb) <= 32
    error_message = "ALB prefix length (${length(local.prefix_alb)}) exceeds maximum 32 characters."
  }

  precondition {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", local.prefix_alb))
    error_message = "ALB prefix '${local.prefix_alb}' must start/end with alphanumeric, contain only lowercase alphanumeric and hyphens."
  }
}

output "prefix_iam" {
  description = "Sanitized prefix for IAM resources (max 38 chars for role prefixes with suffixes)"
  value       = local.prefix_iam

  precondition {
    condition     = length(local.prefix_iam) <= 38
    error_message = "IAM prefix length (${length(local.prefix_iam)}) exceeds maximum 38 characters (to allow suffixes)."
  }

  precondition {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", local.prefix_iam))
    error_message = "IAM prefix '${local.prefix_iam}' must start/end with alphanumeric, contain only lowercase alphanumeric and hyphens."
  }
}

output "prefix_eks" {
  description = "Sanitized prefix for EKS cluster resources (max 100 chars)"
  value       = local.prefix_eks

  precondition {
    condition     = length(local.prefix_eks) <= 100
    error_message = "EKS prefix length (${length(local.prefix_eks)}) exceeds maximum 100 characters."
  }

  precondition {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", local.prefix_eks))
    error_message = "EKS prefix '${local.prefix_eks}' must start/end with alphanumeric, contain only lowercase alphanumeric and hyphens."
  }
}

output "prefix_kms" {
  description = "Sanitized prefix for KMS resources (max 250 chars for alias)"
  value       = local.prefix_kms

  precondition {
    condition     = length(local.prefix_kms) <= 250
    error_message = "KMS prefix length (${length(local.prefix_kms)}) exceeds maximum 250 characters."
  }
}

output "prefix_s3" {
  description = "Sanitized prefix for S3 bucket names (max 63 chars, lowercase)"
  value       = local.prefix_s3

  precondition {
    condition     = length(local.prefix_s3) <= 63
    error_message = "S3 prefix length (${length(local.prefix_s3)}) exceeds maximum 63 characters."
  }

  precondition {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", local.prefix_s3))
    error_message = "S3 prefix '${local.prefix_s3}' must start/end with alphanumeric, contain only lowercase alphanumeric and hyphens."
  }
}

output "prefix_sg" {
  description = "Sanitized prefix for Security Group resources (max 255 chars)"
  value       = local.prefix_sg

  precondition {
    condition     = length(local.prefix_sg) <= 255
    error_message = "Security Group prefix length (${length(local.prefix_sg)}) exceeds maximum 255 characters."
  }
}

output "prefix_cloudwatch" {
  description = "Sanitized prefix for CloudWatch log groups (max 500 chars)"
  value       = local.prefix_cloudwatch

  precondition {
    condition     = length(local.prefix_cloudwatch) <= 500
    error_message = "CloudWatch prefix length (${length(local.prefix_cloudwatch)}) exceeds maximum 500 characters."
  }
}

output "prefix_vpn" {
  description = "Sanitized prefix for Client VPN resources (max 255 chars)"
  value       = local.prefix_vpn

  precondition {
    condition     = length(local.prefix_vpn) <= 255
    error_message = "VPN prefix length (${length(local.prefix_vpn)}) exceeds maximum 255 characters."
  }
}
