# ==============================================================================
# RDS PostgreSQL Module - Local Values
# ==============================================================================
# This file defines local values for resource naming, tagging, and configuration.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # RDS Identifier Construction with Validation and Sanitization
  # ------------------------------------------------------------------------------

  # Step 1: Build raw identifier from components
  raw_identifier = "${var.common_prefix}-${var.environment}-rds"

  # Step 2: Sanitize - lowercase and replace invalid characters with hyphens
  # RDS allows only: a-z, 0-9, and hyphens
  sanitized_identifier = lower(replace(replace(local.raw_identifier, "/[^a-z0-9-]/", "-"), "/--+/", "-"))

  # Step 3: Ensure starts with letter (RDS requirement)
  # If starts with non-letter, prepend 'db-'
  starts_with_letter     = can(regex("^[a-z]", local.sanitized_identifier))
  identifier_with_prefix = local.starts_with_letter ? local.sanitized_identifier : "db-${local.sanitized_identifier}"

  # Step 4: Apply AWS 63-character limit for RDS
  db_identifier = substr(local.identifier_with_prefix, 0, 63)

  # Step 5: Remove trailing hyphen if substr created one
  db_identifier_clean = can(regex("-$", local.db_identifier)) ? substr(local.db_identifier, 0, length(local.db_identifier) - 1) : local.db_identifier

  # Step 6: Validation checks
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

  db_subnet_group_name    = "${local.db_identifier_clean}-subnet-group"
  db_parameter_group_name = "${local.db_identifier_clean}-params"
  replica_identifier      = "${local.db_identifier_clean}-replica"

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
    Environment     = var.environment
  }

  # Merge common tags from root + module-specific tags
  merged_tags = merge(
    var.common_tags, # Common tags from root (ManagedBy, Workspace, Region, etc.)
    local.module_tags
  )
}
