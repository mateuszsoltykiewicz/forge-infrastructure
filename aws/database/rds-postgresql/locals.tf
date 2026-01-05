# ==============================================================================
# RDS PostgreSQL Module - Local Values
# ==============================================================================
# This file defines local values for resource naming, tagging, and configuration.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Instance Naming
  # ------------------------------------------------------------------------------

  # Generate DB identifier based on customer context
  # Shared: forge-{environment}-db
  # Dedicated: {customer_name}-{region}-db
  db_identifier = var.identifier_override != "" ? var.identifier_override : (
    var.architecture_type == "shared"
    ? "forge-${var.environment}-db"
    : "${var.customer_name}-${var.aws_region}-db"
  )

  # ------------------------------------------------------------------------------
  # Final Snapshot Identifier
  # ------------------------------------------------------------------------------

  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.final_snapshot_identifier_prefix}-${local.db_identifier}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # ------------------------------------------------------------------------------
  # Base Resource Tags
  # ------------------------------------------------------------------------------

  base_tags = {
    Environment     = var.environment
    ManagedBy       = "Terraform"
    TerraformModule = "forge/modules/database/rds-postgresql"
    Region          = var.aws_region
    DBIdentifier    = local.db_identifier
    Engine          = "postgres"
    EngineVersion   = var.engine_version
  }

  # ------------------------------------------------------------------------------
  # Customer-Aware Tags
  # ------------------------------------------------------------------------------

  # Add customer tags for dedicated architectures
  customer_tags = var.architecture_type != "shared" && var.customer_id != "" ? {
    CustomerId       = var.customer_id
    CustomerName     = var.customer_name
    ArchitectureType = var.architecture_type
    PlanTier         = var.plan_tier
  } : {}

  # ------------------------------------------------------------------------------
  # Merged Tags
  # ------------------------------------------------------------------------------

  merged_tags = merge(
    local.base_tags,
    local.customer_tags,
    var.tags
  )

  # ------------------------------------------------------------------------------
  # Master Password
  # ------------------------------------------------------------------------------

  # Use provided password or generate random one
  master_password = var.master_password != "" ? var.master_password : random_password.master[0].result

  # ------------------------------------------------------------------------------
  # Monitoring Role
  # ------------------------------------------------------------------------------

  # Create monitoring role only if enhanced monitoring is enabled
  create_monitoring_role = var.monitoring_interval > 0
}
