# ==============================================================================
# RDS PostgreSQL Module - Input Variables
# ==============================================================================
# This module creates an Amazon RDS PostgreSQL database instance.
# Optimized for Forge's configuration database (PostgreSQL 16).
# ==============================================================================

# ------------------------------------------------------------------------------
# Multi-Tenant Context
# ------------------------------------------------------------------------------

variable "workspace" {
  description = "Workspace name for VPC discovery (e.g., forge-platform)"
  type        = string
  default     = "forge-platform"
}

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

variable "project_name" {
  description = "Project name for project-level isolation (empty for customer-level or shared)"
  type        = string
  default     = ""
}

variable "plan_tier" {
  description = "Customer plan tier (e.g., basic, pro, advanced) for cost allocation"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# RDS Instance Configuration
# ------------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be one of: production, staging, or development."
  }
}

variable "identifier_override" {
  description = "Optional override for DB identifier (if empty, auto-generated based on customer context)"
  type        = string
  default     = ""
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.4"

  validation {
    condition     = can(regex("^1[6-9]\\.", var.engine_version))
    error_message = "PostgreSQL version must be 16.x or higher."
  }
}

variable "instance_class" {
  description = "RDS instance type (e.g., db.r8g.xlarge for production)"
  type        = string
  default     = "db.r8g.xlarge"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 500

  validation {
    condition     = var.allocated_storage >= 20 && var.allocated_storage <= 65536
    error_message = "Allocated storage must be between 20 GB and 65536 GB."
  }
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling (0 = disabled)"
  type        = number
  default     = 1000

  validation {
    condition     = var.max_allocated_storage == 0 || var.max_allocated_storage >= var.allocated_storage
    error_message = "Max allocated storage must be 0 (disabled) or >= allocated_storage."
  }
}

variable "storage_type" {
  description = "Storage type: gp3, gp2, or io1"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2"], var.storage_type)
    error_message = "Storage type must be one of: gp3, gp2, io1, io2."
  }
}

variable "iops" {
  description = "Provisioned IOPS (required for io1/io2, optional for gp3)"
  type        = number
  default     = 0
}

variable "storage_throughput" {
  description = "Storage throughput in MB/s (gp3 only, 125-1000)"
  type        = number
  default     = 125

  validation {
    condition     = var.storage_throughput >= 125 && var.storage_throughput <= 1000
    error_message = "Storage throughput must be between 125 and 1000 MB/s."
  }
}

# ------------------------------------------------------------------------------
# Database Configuration
# ------------------------------------------------------------------------------

variable "database_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = "forge"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.database_name))
    error_message = "Database name must start with a letter and contain only lowercase letters, numbers, and underscores."
  }
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
  default     = "forgeadmin"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.master_username))
    error_message = "Master username must start with a letter and contain only lowercase letters, numbers, and underscores."
  }
}

variable "master_password" {
  description = "Master password (if empty, auto-generated and stored in Secrets Manager)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "port" {
  description = "Database port"
  type        = number
  default     = 5432

  validation {
    condition     = var.port >= 1024 && var.port <= 65535
    error_message = "Port must be between 1024 and 65535."
  }
}

# ------------------------------------------------------------------------------
# Network Configuration (Auto-Discovery)
# ------------------------------------------------------------------------------

variable "rds_subnet_az_count" {
  description = "Number of AZs for RDS subnets (2-3 for Multi-AZ)"
  type        = number
  default     = 2

  validation {
    condition     = var.rds_subnet_az_count >= 2 && var.rds_subnet_az_count <= 3
    error_message = "RDS subnet AZ count must be between 2 and 3."
  }
}

variable "rds_subnet_newbits" {
  description = "Number of bits to add to VPC CIDR for RDS subnets (e.g., 8 for /24 subnets from /16 VPC)"
  type        = number
  default     = 8
}

variable "rds_subnet_netnum_start" {
  description = "Starting number for RDS subnet CIDR calculation"
  type        = number
  default     = 50
}

variable "eks_cluster_name" {
  description = "EKS cluster name for security group integration (empty = auto-discover)"
  type        = string
  default     = ""
}

variable "publicly_accessible" {
  description = "Make the RDS instance publicly accessible (not recommended for production)"
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# High Availability Configuration
# ------------------------------------------------------------------------------

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = true
}

variable "availability_zone" {
  description = "Preferred AZ for single-AZ deployment (ignored if multi_az = true)"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# Backup Configuration
# ------------------------------------------------------------------------------

variable "backup_retention_period" {
  description = "Number of days to retain automated backups (0-35)"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 0 and 35 days."
  }
}

variable "backup_window" {
  description = "Preferred backup window (UTC, e.g., 03:00-04:00)"
  type        = string
  default     = "03:00-04:00"

  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]-([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.backup_window))
    error_message = "Backup window must be in format HH:MM-HH:MM (UTC)."
  }
}

variable "maintenance_window" {
  description = "Preferred maintenance window (UTC, e.g., sun:04:00-sun:05:00)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when deleting (not recommended for production)"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier_prefix" {
  description = "Prefix for final snapshot identifier"
  type        = string
  default     = "final-snapshot"
}

variable "copy_tags_to_snapshot" {
  description = "Copy all tags to snapshots"
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# Security Configuration
# ------------------------------------------------------------------------------

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "enable_kms_key_rotation" {
  description = "Enable automatic KMS key rotation"
  type        = bool
  default     = true
}

variable "kms_deletion_window_in_days" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "KMS deletion window must be between 7 and 30 days."
  }
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# Monitoring Configuration
# ------------------------------------------------------------------------------

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch (postgresql, upgrade)"
  type        = list(string)
  default     = ["postgresql", "upgrade"]

  validation {
    condition     = alltrue([for log in var.enabled_cloudwatch_logs_exports : contains(["postgresql", "upgrade"], log)])
    error_message = "Valid log types are: postgresql, upgrade."
  }
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days (7, 31-731)"
  type        = number
  default     = 7

  validation {
    condition     = var.performance_insights_retention_period == 7 || (var.performance_insights_retention_period >= 31 && var.performance_insights_retention_period <= 731)
    error_message = "Performance Insights retention must be 7 days or between 31-731 days."
  }
}

# ------------------------------------------------------------------------------
# Parameter Group Configuration
# ------------------------------------------------------------------------------

variable "parameter_group_family" {
  description = "PostgreSQL parameter group family (e.g., postgres16)"
  type        = string
  default     = "postgres16"
}

variable "parameters" {
  description = "Database parameters to apply"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements"
    },
    {
      name  = "log_statement"
      value = "ddl"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000" # Log queries taking longer than 1 second
    }
  ]
}

# ------------------------------------------------------------------------------
# Resource Tags
# ------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to all RDS resources"
  type        = map(string)
  default     = {}
}
