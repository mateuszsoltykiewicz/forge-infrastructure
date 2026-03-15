# ==============================================================================
# RDS PostgreSQL Module - Local Values
# ==============================================================================
# This file defines local values for resource naming, tagging, and configuration.
# ==============================================================================

# ==============================================================================
# SECTION 1: Data Sources (Auto-Discovery)
# ==============================================================================

# Note: Data sources are defined in data.tf
# - aws_region.current
# - aws_caller_identity.current
# - aws_partition.current
# - aws_availability_zones.available
# - aws_vpc.main

locals {
  # ------------------------------------------------------------------------------
  # Pattern A: Common Prefix Transformations
  # ------------------------------------------------------------------------------

  # PascalCase prefix for resource names (e.g., "AcmeForgeDevDatabaseRds")
  pascal_prefix = join("", [for part in split("-", var.common_prefix) : title(part)])

  # Path-like prefix for IAM roles (e.g., "/acme/forge/dev/database/")
  path_prefix = "/${replace(var.common_prefix, "-", "/")}/"

  # ------------------------------------------------------------------------------
  # RDS Identifier Construction with Validation and Sanitization
  # ------------------------------------------------------------------------------

  # RDS naming pattern: {PascalPrefix}Rds (e.g., "AcmeForgeDevDatabaseRds")
  rds_name = "${local.pascal_prefix}Rds"

  # Step 1: Convert to lowercase and sanitize (RDS allows only: a-z, 0-9, hyphens)
  sanitized_identifier = lower(replace(replace(local.rds_name, "/[^a-zA-Z0-9-]/", "-"), "/--+/", "-"))

  # Step 2: Ensure starts with letter (RDS requirement)
  starts_with_letter     = can(regex("^[a-z]", local.sanitized_identifier))
  identifier_with_prefix = local.starts_with_letter ? local.sanitized_identifier : "db-${local.sanitized_identifier}"

  # Step 3: Apply AWS 63-character limit for RDS
  db_identifier = substr(local.identifier_with_prefix, 0, 63)

  # Step 4: Remove trailing hyphen if substr created one
  db_identifier_clean = can(regex("-$", local.db_identifier)) ? substr(local.db_identifier, 0, length(local.db_identifier) - 1) : local.db_identifier

  # Step 5: Validation checks
  identifier_validation = {
    length_ok          = length(local.db_identifier_clean) <= 63 && length(local.db_identifier_clean) >= 1
    starts_with_letter = can(regex("^[a-z]", local.db_identifier_clean))
    pattern_ok         = can(regex("^[a-z][a-z0-9-]*$", local.db_identifier_clean))
    no_double_dash     = !can(regex("--", local.db_identifier_clean))
    no_trailing_dash   = !can(regex("-$", local.db_identifier_clean))
  }

  # ------------------------------------------------------------------------------
  # Final Snapshot Identifier
  # ------------------------------------------------------------------------------
  # Static identifier to prevent drift - timestamp will be added automatically by AWS
  final_snapshot_identifier = "final-snapshot-${local.db_identifier_clean}"

  # ------------------------------------------------------------------------------
  # Derived Resource Names
  # ------------------------------------------------------------------------------

  # DB Resources (lowercase with hyphens - AWS RDS requirement)
  db_subnet_group_name    = "${local.db_identifier_clean}-subnet-group"
  db_parameter_group_name = "${local.db_identifier_clean}-params"
  replica_identifier      = "${local.db_identifier_clean}-replica"

  # IAM Role Names (PascalCase)
  monitoring_role_name = "${local.pascal_prefix}RdsMonitoring"

  # CloudWatch Resources (PascalCase)
  dashboard_name           = "${local.pascal_prefix}RdsDashboard"
  alarm_high_cpu           = "${local.pascal_prefix}RdsHighCpu"
  alarm_low_memory         = "${local.pascal_prefix}RdsLowMemory"
  alarm_low_storage        = "${local.pascal_prefix}RdsLowStorage"
  alarm_high_connections   = "${local.pascal_prefix}RdsHighConnections"
  alarm_high_read_latency  = "${local.pascal_prefix}RdsHighReadLatency"
  alarm_high_write_latency = "${local.pascal_prefix}RdsHighWriteLatency"
  alarm_high_replica_lag   = "${local.pascal_prefix}RdsHighReplicaLag"

  # ------------------------------------------------------------------------------
  # SSM parameters prefix
  # ------------------------------------------------------------------------------
  ssm_parameter_prefix = "${local.path_prefix}rds"

  # ------------------------------------------------------------------------------
  # Resource Tags
  # ------------------------------------------------------------------------------

  # Module-specific tags (only RDS-specific metadata)
  module_tags = {
    TerraformModule = "forge/aws/database/rds-postgresql"
    DBIdentifier    = local.db_identifier_clean
    Module          = "RDS"
    Family          = "Database"
    Engine          = "postgres"
    EngineVersion   = var.engine_version
  }

  # Merge common tags from root + module-specific tags
  merged_tags = merge(
    var.common_tags, # Common tags from root (ManagedBy, Workspace, Region, etc.)
    local.module_tags
  )
}
