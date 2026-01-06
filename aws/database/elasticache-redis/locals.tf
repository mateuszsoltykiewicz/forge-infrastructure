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
  is_customer_cluster = var.customer_id != ""
  is_project_cluster  = var.project_name != ""

  # Multi-tenant cluster naming conventions:
  # 1. Shared (platform): forge-{environment}-redis
  # 2. Customer-dedicated: {customer_name}-{region}-redis
  # 3. Customer + Project: {customer_name}-{project_name}-{region}-redis
  replication_group_id = var.replication_group_id_override != "" ? var.replication_group_id_override : (
    local.is_customer_cluster && local.is_project_cluster ? "${var.customer_name}-${var.project_name}-${var.aws_region}-redis" :
    local.is_customer_cluster ? "${var.customer_name}-${var.aws_region}-redis" :
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
  customer_tags = local.is_customer_cluster ? {
    Customer = var.customer_name
  } : {}

  project_tags = local.is_project_cluster ? {
    Project = var.project_name
  } : {}

  # Legacy tags for backward compatibility
  legacy_tags = local.is_customer_cluster ? {
    CustomerId       = var.customer_id
    CustomerName     = var.customer_name
    ArchitectureType = var.architecture_type
    PlanTier         = var.plan_tier
  } : {}

  # ------------------------------------------------------------------------------
  # Merged Tags (Multi-Tenant)
  # ------------------------------------------------------------------------------

  merged_tags = merge(
    local.base_tags,
    local.customer_tags,
    local.project_tags,
    local.legacy_tags,
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
