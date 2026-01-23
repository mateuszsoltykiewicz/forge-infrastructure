# ==============================================================================
# Variables - ECR Module
# ==============================================================================

# ------------------------------------------------------------------------------
# Pattern A Variables (Required)
# ------------------------------------------------------------------------------

variable "common_prefix" {
  description = "Common prefix for all resources (Pattern A)"
  type        = string

  validation {
    condition     = length(var.common_prefix) > 0 && length(var.common_prefix) <= 20
    error_message = "common_prefix must be between 1 and 20 characters"
  }
}

variable "common_tags" {
  description = "Common tags for all resources (Pattern A). Must include: Customer, Project, Environment, ManagedBy"
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

variable "environment" {
  description = "Environment name (dev, staging, production, shared)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production", "shared"], var.environment)
    error_message = "environment must be one of: dev, staging, production, shared"
  }
}

variable "aws_region" {
  description = "AWS region for deployment (Pattern A, passed from parent)"
  type        = string
}

# ------------------------------------------------------------------------------
# Repository Configuration
# ------------------------------------------------------------------------------

variable "repository_name" {
  description = "ECR repository name (will be prefixed with common_prefix-{name}-environment)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-_/]+$", var.repository_name))
    error_message = "repository_name must contain only lowercase letters, numbers, hyphens, underscores, and forward slashes"
  }
}

variable "repository_purpose" {
  description = "Purpose of the repository (e.g., 'Lambda Functions', 'ECS Services')"
  type        = string
  default     = "Container Images"
}

variable "image_tag_mutability" {
  description = "Tag mutability setting for repository (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE"
  }
}

# ------------------------------------------------------------------------------
# Security Configuration
# ------------------------------------------------------------------------------

variable "scan_on_push" {
  description = "Enable vulnerability scanning on image push"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type (AES256 or KMS)"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type must be AES256 or KMS"
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption (required if encryption_type is KMS)"
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:aws:kms:[a-z0-9-]+:\\d+:key/.+$", var.kms_key_arn))
    error_message = "kms_key_arn must be a valid KMS key ARN or null"
  }
}

# ------------------------------------------------------------------------------
# Lifecycle Policy Configuration
# ------------------------------------------------------------------------------

variable "keep_tagged_images" {
  description = "Number of tagged images to keep (per tag prefix)"
  type        = number
  default     = 30

  validation {
    condition     = var.keep_tagged_images >= 1 && var.keep_tagged_images <= 1000
    error_message = "keep_tagged_images must be between 1 and 1000"
  }
}

variable "keep_untagged_images" {
  description = "Number of untagged images to keep (for rollback)"
  type        = number
  default     = 5

  validation {
    condition     = var.keep_untagged_images >= 1 && var.keep_untagged_images <= 100
    error_message = "keep_untagged_images must be between 1 and 100"
  }
}

variable "keep_tag_prefixes" {
  description = "List of tag prefixes to keep (e.g., ['v', 'release-', 'prod-'])"
  type        = list(string)
  default     = ["v", "release-", "prod-", "staging-", "latest"]
}

# ------------------------------------------------------------------------------
# IAM Access Control
# ------------------------------------------------------------------------------

variable "allowed_principals" {
  description = "List of IAM principal ARNs allowed to pull images (empty = no repository policy)"
  type        = list(string)
  default     = []
}

variable "allowed_push_principals" {
  description = "List of IAM principal ARNs allowed to push images"
  type        = list(string)
  default     = []
}
