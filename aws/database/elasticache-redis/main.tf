# ==============================================================================
# ElastiCache Redis Module - Main Resources
# ==============================================================================
# This file creates the ElastiCache Redis replication group and supporting resources.
# ==============================================================================

# ------------------------------------------------------------------------------
# Random Auth Token
# ------------------------------------------------------------------------------

resource "random_password" "auth_token" {
  count = var.auth_token_enabled ? 1 : 0

  length  = 32
  special = true
  # ElastiCache auth token allowed special characters
  override_special = "!&#$^<>-"
}

# ------------------------------------------------------------------------------
# Cache Subnet Group
# ------------------------------------------------------------------------------

resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.replication_group_id}-subnet-group"
  subnet_ids = aws_subnet.redis_private[*].id

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.replication_group_id}-subnet-group"
    }
  )

  depends_on = [aws_subnet.redis_private]
}

# ------------------------------------------------------------------------------
# Parameter Group
# ------------------------------------------------------------------------------

resource "aws_elasticache_parameter_group" "main" {
  count = var.create_parameter_group ? 1 : 0

  name        = local.parameter_group_name
  family      = var.parameter_group_family
  description = "Custom parameter group for ${local.replication_group_id}"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(
    local.merged_tags,
    {
      Name = local.parameter_group_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------------------------
# ElastiCache Replication Group
# ------------------------------------------------------------------------------

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = local.replication_group_id
  description          = var.description

  # Engine Configuration
  engine               = "redis"
  engine_version       = var.engine_version
  port                 = var.port
  parameter_group_name = var.create_parameter_group ? aws_elasticache_parameter_group.main[0].name : null

  # Node Configuration
  node_type          = var.node_type
  num_cache_clusters = var.num_cache_clusters

  # High Availability
  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  # Network Configuration
  subnet_group_name           = aws_elasticache_subnet_group.main.name
  security_group_ids          = [aws_security_group.redis.id]
  preferred_cache_cluster_azs = length(var.preferred_cache_cluster_azs) > 0 ? var.preferred_cache_cluster_azs : null

  # Security Configuration
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  auth_token                 = local.auth_token
  kms_key_id                 = aws_kms_key.redis.arn

  # Backup Configuration
  snapshot_retention_limit  = var.snapshot_retention_limit
  snapshot_window           = var.snapshot_window
  final_snapshot_identifier = var.final_snapshot_identifier != "" ? var.final_snapshot_identifier : null

  # Maintenance Configuration
  maintenance_window         = var.maintenance_window
  notification_topic_arn     = var.notification_topic_arn != "" ? var.notification_topic_arn : null
  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # Log Delivery Configuration
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_engine_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  tags = merge(
    local.merged_tags,
    {
      Name = local.replication_group_id
    }
  )

  lifecycle {
    ignore_changes = [
      # Ignore auth token changes to prevent unnecessary updates
      auth_token,
    ]
  }

  depends_on = [
    aws_kms_key.redis,
    aws_security_group.redis,
    aws_cloudwatch_log_group.redis_slow_log,
    aws_cloudwatch_log_group.redis_engine_log
  ]
}

# ------------------------------------------------------------------------------
# SSM Parameter Store (for Redis connection info and auth token)
# ------------------------------------------------------------------------------

# Redis primary endpoint
resource "aws_ssm_parameter" "redis_primary_endpoint" {
  name        = "/${var.environment}/${local.replication_group_id}/primary-endpoint"
  description = "Redis primary endpoint for ${local.replication_group_id}"
  type        = "String"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.replication_group_id}-primary-endpoint"
    }
  )
}

# Redis reader endpoint (if Multi-AZ)
resource "aws_ssm_parameter" "redis_reader_endpoint" {
  count = var.multi_az_enabled ? 1 : 0

  name        = "/${var.environment}/${local.replication_group_id}/reader-endpoint"
  description = "Redis reader endpoint for ${local.replication_group_id}"
  type        = "String"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.replication_group_id}-reader-endpoint"
    }
  )
}

# Redis port
resource "aws_ssm_parameter" "redis_port" {
  name        = "/${var.environment}/${local.replication_group_id}/port"
  description = "Redis port for ${local.replication_group_id}"
  type        = "String"
  value       = tostring(var.port)

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.replication_group_id}-port"
    }
  )
}

# Auth token (SecureString)
resource "aws_ssm_parameter" "redis_auth_token" {
  count = var.auth_token_enabled ? 1 : 0

  name        = "/${var.environment}/${local.replication_group_id}/auth-token"
  description = "Redis AUTH token for ${local.replication_group_id}"
  type        = "SecureString"
  value       = local.auth_token
  key_id      = aws_kms_key.redis.arn

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.replication_group_id}-auth-token"
    }
  )
}
