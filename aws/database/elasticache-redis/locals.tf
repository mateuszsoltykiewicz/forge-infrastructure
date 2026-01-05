# ==============================================================================
# ElastiCache Redis Module - Local Values
# ==============================================================================
# This file defines local values for resource naming, tagging, and configuration.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Replication Group Naming
  # ------------------------------------------------------------------------------

  # Generate replication group ID based on customer context
  # Shared: forge-{environment}-redis
  # Dedicated: {customer_name}-{region}-redis
  replication_group_id = var.replication_group_id_override != "" ? var.replication_group_id_override : (
    var.architecture_type == "shared"
    ? "forge-${var.environment}-redis"
    : "${var.customer_name}-${var.aws_region}-redis"
  )

  # ------------------------------------------------------------------------------
  # Base Resource Tags
  # ------------------------------------------------------------------------------

  base_tags = {
    Environment      = var.environment
    ManagedBy        = "Terraform"
    TerraformModule  = "forge/modules/cache/elasticache-redis"
    Region           = var.aws_region
    ReplicationGroup = local.replication_group_id
    Engine           = "redis"
    EngineVersion    = var.engine_version
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
  # Auth Token
  # ------------------------------------------------------------------------------

  # Generate auth token if enabled
  auth_token = var.auth_token_enabled ? random_password.auth_token[0].result : null

  # ------------------------------------------------------------------------------
  # Parameter Group Naming
  # ------------------------------------------------------------------------------

  parameter_group_name = var.create_parameter_group ? "${local.replication_group_id}-params" : null
}
