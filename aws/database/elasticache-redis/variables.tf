# ==============================================================================
# ElastiCache Redis Module - Input Variables
# ==============================================================================
# This module creates an Amazon ElastiCache Redis cluster.
# Optimized for Forge's caching and session management requirements.
# ==============================================================================

# ------------------------------------------------------------------------------
# Customer Context (Required for Customer-Aware Naming)
# ------------------------------------------------------------------------------

variable "customer_id" {
  description = "Customer identifier (empty for shared infrastructure)"
  type        = string
  default     = ""
}

variable "customer_name" {
  description = "Customer name for resource naming (empty for shared infrastructure)"
  type        = string
  default     = ""
}

variable "architecture_type" {
  description = "Architecture deployment type: shared, dedicated_local, or dedicated_regional"
  type        = string
  default     = "shared"

  validation {
    condition     = contains(["shared", "dedicated_local", "dedicated_regional"], var.architecture_type)
    error_message = "Architecture type must be one of: shared, dedicated_local, or dedicated_regional."
  }
}

variable "plan_tier" {
  description = "Customer plan tier (e.g., basic, pro, advanced) for cost allocation"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# ElastiCache Configuration
# ------------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be one of: production, staging, or development."
  }
}

variable "aws_region" {
  description = "AWS region where the ElastiCache cluster will be deployed"
  type        = string
}

variable "replication_group_id_override" {
  description = "Optional override for replication group ID (if empty, auto-generated)"
  type        = string
  default     = ""
}

variable "description" {
  description = "Description of the replication group"
  type        = string
  default     = "Forge Redis cluster for caching and session management"
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"

  validation {
    condition     = can(regex("^[67]\\.[0-9]+$", var.engine_version))
    error_message = "Redis version must be 6.x or 7.x."
  }
}

variable "node_type" {
  description = "ElastiCache node type (e.g., cache.r7g.large for production)"
  type        = string
  default     = "cache.r7g.large"
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (nodes) in the replication group"
  type        = number
  default     = 2

  validation {
    condition     = var.num_cache_clusters >= 1 && var.num_cache_clusters <= 6
    error_message = "Number of cache clusters must be between 1 and 6."
  }
}

variable "port" {
  description = "Redis port"
  type        = number
  default     = 6379

  validation {
    condition     = var.port >= 1024 && var.port <= 65535
    error_message = "Port must be between 1024 and 65535."
  }
}

# ------------------------------------------------------------------------------
# Network Configuration
# ------------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC ID where the ElastiCache cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the cache subnet group (must span at least 2 AZs)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Cache subnet group must span at least 2 availability zones."
  }
}

variable "security_group_ids" {
  description = "Security group IDs to attach to the ElastiCache cluster"
  type        = list(string)
  default     = []
}

variable "preferred_cache_cluster_azs" {
  description = "List of AZs in which the cache clusters will be created"
  type        = list(string)
  default     = []
}

# ------------------------------------------------------------------------------
# High Availability Configuration
# ------------------------------------------------------------------------------

variable "multi_az_enabled" {
  description = "Enable Multi-AZ with automatic failover"
  type        = bool
  default     = true
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover (required for Multi-AZ)"
  type        = bool
  default     = true

  validation {
    condition     = !var.automatic_failover_enabled || var.num_cache_clusters >= 2
    error_message = "Automatic failover requires at least 2 cache clusters."
  }
}

# ------------------------------------------------------------------------------
# Security Configuration
# ------------------------------------------------------------------------------

variable "at_rest_encryption_enabled" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "transit_encryption_enabled" {
  description = "Enable encryption in transit (TLS)"
  type        = bool
  default     = true
}

variable "auth_token_enabled" {
  description = "Enable Redis AUTH token for authentication"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (if empty, uses default AWS managed key)"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# Backup Configuration
# ------------------------------------------------------------------------------

variable "snapshot_retention_limit" {
  description = "Number of days to retain automatic snapshots (0-35)"
  type        = number
  default     = 7

  validation {
    condition     = var.snapshot_retention_limit >= 0 && var.snapshot_retention_limit <= 35
    error_message = "Snapshot retention limit must be between 0 and 35 days."
  }
}

variable "snapshot_window" {
  description = "Daily time range for snapshots (UTC, e.g., 03:00-05:00)"
  type        = string
  default     = "03:00-05:00"

  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]-([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.snapshot_window))
    error_message = "Snapshot window must be in format HH:MM-HH:MM (UTC)."
  }
}

variable "final_snapshot_identifier" {
  description = "Name of final snapshot on deletion (if empty, no final snapshot)"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# Maintenance Configuration
# ------------------------------------------------------------------------------

variable "maintenance_window" {
  description = "Weekly maintenance window (UTC, e.g., sun:05:00-sun:07:00)"
  type        = string
  default     = "sun:05:00-sun:07:00"
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately (if false, apply during maintenance window)"
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# Parameter Group Configuration
# ------------------------------------------------------------------------------

variable "create_parameter_group" {
  description = "Create a custom parameter group (if false, uses default)"
  type        = bool
  default     = true
}

variable "parameter_group_family" {
  description = "Redis parameter group family (e.g., redis7)"
  type        = string
  default     = "redis7"
}

variable "parameters" {
  description = "Redis parameters to apply"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "maxmemory-policy"
      value = "allkeys-lru"
    },
    {
      name  = "timeout"
      value = "300"
    }
  ]
}

# ------------------------------------------------------------------------------
# Monitoring Configuration
# ------------------------------------------------------------------------------

variable "notification_topic_arn" {
  description = "SNS topic ARN for ElastiCache notifications"
  type        = string
  default     = ""
}

variable "log_delivery_configuration" {
  description = "CloudWatch Logs delivery configuration"
  type = list(object({
    destination      = string
    destination_type = string
    log_format       = string
    log_type         = string
  }))
  default = []
}

# ------------------------------------------------------------------------------
# Resource Tags
# ------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to all ElastiCache resources"
  type        = map(string)
  default     = {}
}
