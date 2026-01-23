# ==============================================================================
# ElastiCache Redis Module - Local Values
# ==============================================================================
# This file defines local values for resource naming, tagging, and configuration.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Replication Group Naming (Multi-Tenant)
  # ------------------------------------------------------------------------------

  # Multi-tenant cluster naming conventions:
  # 1. Shared (platform): forge-{environment}-redis
  # 2. Customer-dedicated: forge-{environment}-{customer}-redis
  # 3. Project-isolated: forge-{environment}-{customer}-{project}-redis
  replication_group_id = substr("redis-${var.common_prefix}", 0, 64)

  sanitized_name_id = lower(replace(replace(local.replication_group_id, "/[^a-z0-9-]/", "-"), "/--+/", "-"))

  # AWs region taken from tags
  aws_region = lookup(var.common_tags, "Region", "unknown-region")

  # ------------------------------------------------------------------------------
  # Resource Tags
  # ------------------------------------------------------------------------------

  # Module-specific tags (only Redis-specific metadata)
  module_tags = {
    TerraformModule  = "forge/aws/database/elasticache-redis"
    ReplicationGroup = local.sanitized_name_id
    Engine           = "Redis"
    EngineVersion    = var.engine_version
    Module           = "ElastiCache"
    Family           = "Database"
  }

  # Merge common tags from root + module-specific tags
  merged_tags = merge(
    var.common_tags,  # Common tags from root (ManagedBy, Workspace, Region, etc.)
    local.module_tags # Module-specific tags
  )

  # ------------------------------------------------------------------------------
  # Parameter Group Naming
  # ------------------------------------------------------------------------------

  sanitized_parameter_group_name = substr("param-group-${local.replication_group_id}", 0, 64)

  # ----------------------------------------------------------------------------
  # Subnet group naming
  # ----------------------------------------------------------------------------
  sanitized_subnet_group_name = substr("subnet-group-${local.replication_group_id}", 0, 64)

  # ----------------------------------------------------------------------------
  # SSM parameters naming for redis. Build from common prefix
  # Replace with regex to allign with path like naming conventions
  # ----------------------------------------------------------------------------
  sanitized_ssm_name = lower(replace(replace(local.sanitized_name_id, "/[^a-z0-9._\\-\\/+=@ ]/", "-"), "/--+/", "-"))

  # ------------------------------------------------------------------------------
  # Sanitized cloudwatch monitoring groups build from sanitized name id and converted as a path like structure
  # ------------------------------------------------------------------------------
  sanitized_cloudwatch_log_group_name = "/aws/elasticache/redis/${local.sanitized_name_id}"

}
