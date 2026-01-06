# ==============================================================================
# ElastiCache Redis Module - Local Values
# ==============================================================================
# This file defines local values for resource naming, tagging, and configuration.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Replication Group Naming (Multi-Tenant)
  # ------------------------------------------------------------------------------

  # Determine cluster ownership model
  has_customer = var.customer_name != null && var.customer_name != ""
  has_project  = var.project_name != null && var.project_name != ""

  # Multi-tenant cluster naming conventions:
  # 1. Shared (platform): forge-{environment}-redis
  # 2. Customer-dedicated: forge-{environment}-{customer}-redis
  # 3. Project-isolated: forge-{environment}-{customer}-{project}-redis
  replication_group_id = var.replication_group_id_override != "" ? var.replication_group_id_override : (
    local.has_project ? "forge-${var.environment}-${var.customer_name}-${var.project_name}-redis" :
    local.has_customer ? "forge-${var.environment}-${var.customer_name}-redis" :
    "forge-${var.environment}-redis"
  )

  # ------------------------------------------------------------------------------
  # Base Resource Tags
  # ------------------------------------------------------------------------------

  base_tags = {
    Environment      = var.environment
    ManagedBy        = "Terraform"
    TerraformModule  = "forge/aws/database/elasticache-redis"
    Region           = var.aws_region
    Workspace        = var.workspace
    ReplicationGroup = local.replication_group_id
    Engine           = "redis"
    EngineVersion    = var.engine_version
  }

  # ------------------------------------------------------------------------------
  # Multi-Tenant Tags
  # ------------------------------------------------------------------------------

  # Multi-tenant tags (Customer + Project)
  customer_tags = local.has_customer ? {
    Customer = var.customer_name
  } : {}

  project_tags = local.has_project ? {
    Project = var.project_name
  } : {}

  # Legacy tags for backward compatibility
  legacy_tags = merge(
    var.customer_id != "" ? { CustomerId = var.customer_id } : {},
    var.plan_tier != "" ? { PlanTier = var.plan_tier } : {}
  )

  # Resource sharing tags
  resource_sharing_tags = {
    ResourceSharing = var.resource_sharing
    SharedWith      = var.resource_sharing == "shared" ? join(",", var.shared_with_environments) : var.environment
  }

  # ------------------------------------------------------------------------------
  # Merged Tags (Multi-Tenant)
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
  # Auth Token
  # ------------------------------------------------------------------------------

  # Generate auth token if enabled
  auth_token = var.auth_token_enabled ? random_password.auth_token[0].result : null

  # ------------------------------------------------------------------------------
  # Parameter Group Naming
  # ------------------------------------------------------------------------------

  parameter_group_name = var.create_parameter_group ? "${local.replication_group_id}-params" : null
}
