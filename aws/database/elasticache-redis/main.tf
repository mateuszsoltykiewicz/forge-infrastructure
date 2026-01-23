# ==============================================================================
# ElastiCache Redis Module - Main Resources
# ==============================================================================
# This file creates the ElastiCache Redis replication group and supporting resources.
# ==============================================================================

# ------------------------------------------------------------------------------
# KMS Key for Redis Encryption
# ------------------------------------------------------------------------------

module "kms_redis" {
  source = "../../security/kms"

  # Pattern A variables
  common_prefix = var.common_prefix

  common_tags   = local.merged_tags

  # KMS Key configuration
  key_purpose     = "Redis"
  key_description = "ElastiCache Redis ${local.replication_group_id} encryption (data, logs, SSM)"
  key_usage       = "ENCRYPT_DECRYPT"

  # Security settings
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true

  # Service principals - Redis, CloudWatch Logs, SSM
  key_service_roles = [
    "elasticache.amazonaws.com",
    "logs.${local.aws_region}.amazonaws.com",
    "ssm.amazonaws.com"
  ]

  # Root account as administrator
  key_administrators = [
    "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
}

# ------------------------------------------------------------------------------
# Random Auth Token
# ------------------------------------------------------------------------------

resource "random_password" "auth_token" {
  length  = 32
  special = true
  # ElastiCache auth token allowed special characters
  override_special = "!&#$^<>-"
}

# ------------------------------------------------------------------------------
# Cache Subnet Group
# ------------------------------------------------------------------------------

resource "aws_elasticache_subnet_group" "main" {

  name       = local.sanitized_subnet_group_name
  subnet_ids = module.redis_subnets.subnet_ids

  tags = merge(
    local.merged_tags,
    {
      Name = local.sanitized_subnet_group_name
    }
  )

  depends_on = [module.redis_subnets]
}

# ------------------------------------------------------------------------------
# Parameter Group
# ------------------------------------------------------------------------------

resource "aws_elasticache_parameter_group" "main" {

  name        = local.sanitized_parameter_group_name
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
      Name = local.sanitized_parameter_group_name
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

  replication_group_id = local.sanitized_name_id
  description          = var.description

  # Engine Configuration
  engine               = "redis"
  engine_version       = var.engine_version
  port                 = var.port
  parameter_group_name = aws_elasticache_parameter_group.main.name

  # Node Configuration
  node_type          = var.node_type
  num_cache_clusters = var.num_cache_clusters

  # High Availability
  automatic_failover_enabled = true
  multi_az_enabled           = true

  # Network Configuration
  subnet_group_name           = aws_elasticache_subnet_group.main.name
  security_group_ids          = [module.redis_security_group.security_group_id]

  # make it dependent on var.availability_zones
  preferred_cache_cluster_azs = var.availability_zones

  # Security Configuration
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.auth_token.result
  kms_key_id                 = module.kms_redis.key_arn

  # Backup Configuration
  snapshot_retention_limit  = var.snapshot_retention_limit
  snapshot_window           = var.snapshot_window
  final_snapshot_identifier = var.final_snapshot_identifier != "" ? var.final_snapshot_identifier : null

  # Maintenance Configuration
  maintenance_window         = var.maintenance_window
  notification_topic_arn     = var.notification_topic_arn != "" ? var.notification_topic_arn : null
  apply_immediately          = false
  auto_minor_version_upgrade = false

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
      Name = local.sanitized_name_id
    }
  )

  lifecycle {
    ignore_changes = [
      # Ignore auth token changes to prevent unnecessary updates
      auth_token,
    ]
  }

  depends_on = [
    module.kms_redis,
    module.redis_security_group,
    aws_cloudwatch_log_group.redis_slow_log,
    aws_cloudwatch_log_group.redis_engine_log,
    module.redis_subnets,
    aws_elasticache_parameter_group.main,
    aws_elasticache_subnet_group.main,
    random_password.auth_token
  ]
}

# Auth token (SecureString)
resource "aws_ssm_parameter" "redis_auth_token" {

  name        = "/${local.sanitized_ssm_name}/auth-token"
  description = "Redis AUTH token for ${local.replication_group_id}"
  type        = "SecureString"
  value       = random_password.auth_token.result
  key_id      = module.kms_redis.key_arn

  tags = merge(
    local.merged_tags,
    {
      Name = "/${local.sanitized_ssm_name}/auth-token"
    }
  )
}
