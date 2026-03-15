# ==============================================================================
# ElastiCache Redis Module - Local Values
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

  # PascalCase prefix for resource names (e.g., "AcmeForgeDevDatabaseRedis")
  pascal_prefix = join("", [for part in split("-", var.common_prefix) : title(part)])

  # Path-like prefix for IAM roles (e.g., "/acme/forge/dev/database/")
  path_prefix = "/${replace(var.common_prefix, "-", "/")}/"

  # ------------------------------------------------------------------------------
  # Replication Group Naming
  # ------------------------------------------------------------------------------

  # Redis naming pattern: {PascalPrefix}Redis (e.g., "AcmeForgeDevDatabaseRedis")
  redis_name = "${local.pascal_prefix}Redis"

  # ElastiCache replication group ID: lowercase with hyphens, max 40 characters
  # Prepend "redis-" to ensure uniqueness
  replication_group_id = substr(lower(replace(replace("redis-${local.redis_name}", "/[^a-zA-Z0-9-]/", "-"), "/--+/", "-")), 0, 40)

  sanitized_name_id = local.replication_group_id

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
  # CloudWatch Resources (PascalCase)
  # ----------------------------------------------------------------------------
  dashboard_name             = "${local.pascal_prefix}RedisDashboard"
  alarm_high_cpu             = "${local.pascal_prefix}RedisHighCpu"
  alarm_high_memory          = "${local.pascal_prefix}RedisHighMemory"
  alarm_high_evictions       = "${local.pascal_prefix}RedisHighEvictions"
  alarm_high_replication_lag = "${local.pascal_prefix}RedisHighReplicationLag"
  alarm_high_connections     = "${local.pascal_prefix}RedisHighConnections"

  # ----------------------------------------------------------------------------
  # SSM parameters prefix (path-like)
  # ----------------------------------------------------------------------------
  ssm_parameter_prefix = "${local.path_prefix}redis"

  # ------------------------------------------------------------------------------
  # Sanitized cloudwatch monitoring groups build from sanitized name id and converted as a path like structure
  # ------------------------------------------------------------------------------
  sanitized_cloudwatch_log_group_name = "/aws/elasticache/redis/${local.sanitized_name_id}"

}
