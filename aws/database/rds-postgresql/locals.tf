# ==============================================================================
# RDS PostgreSQL Module - Local Values
# ==============================================================================
# This file defines local values for resource naming, tagging, and configuration.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Multi-Tenant Naming Convention
  # ------------------------------------------------------------------------------

  # Determine cluster type based on customer_name and project_name
  is_customer_cluster = var.customer_name != ""
  is_project_cluster  = var.customer_name != "" && var.project_name != ""

  # Generate DB identifier based on multi-tenant context:
  # - Shared: forge-{environment}-db
  # - Customer: forge-{environment}-{customer_name}-db
  # - Project: forge-{environment}-{customer_name}-{project_name}-db
  db_identifier = var.identifier_override != "" ? var.identifier_override : (
    local.is_project_cluster
    ? "forge-${var.environment}-${var.customer_name}-${var.project_name}-db"
    : (local.is_customer_cluster
      ? "forge-${var.environment}-${var.customer_name}-db"
      : "forge-${var.environment}-db"
    )
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
    Workspace       = var.workspace
    DBIdentifier    = local.db_identifier
    Engine          = "postgres"
    EngineVersion   = var.engine_version
  }

  # ------------------------------------------------------------------------------
  # Multi-Tenant Tags
  # ------------------------------------------------------------------------------

  # Add customer/project tags when applicable
  customer_tags = local.is_customer_cluster ? {
    Customer = var.customer_name
  } : {}

  project_tags = local.is_project_cluster ? {
    Project = var.project_name
  } : {}

  # Legacy tags for backward compatibility
  legacy_tags = var.customer_id != "" ? {
    CustomerId = var.customer_id
    PlanTier   = var.plan_tier
  } : {}

  # Resource sharing tags
  resource_sharing_tags = {
    ResourceSharing = var.resource_sharing
    SharedWith      = var.resource_sharing == "shared" ? join(",", var.shared_with_environments) : var.environment
  }

  # ------------------------------------------------------------------------------
  # Merged Tags
  # ------------------------------------------------------------------------------

  merged_tags = merge(
    local.base_tags,
    local.customer_tags,
    local.project_tags,
    local.legacy_tags,
    local.resource_sharing_tags,
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
