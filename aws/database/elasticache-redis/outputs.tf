# ==============================================================================
# ElastiCache Redis Module - Outputs
# ==============================================================================
# This file exports essential information about the created ElastiCache cluster.
# ==============================================================================

# ------------------------------------------------------------------------------
# Multi-Tenant Identification
# ------------------------------------------------------------------------------

output "replication_group_id" {
  description = "The ID of the ElastiCache replication group (multi-tenant aware)"
  value       = aws_elasticache_replication_group.main.id
}

# ------------------------------------------------------------------------------
# Replication Group Outputs
# ------------------------------------------------------------------------------

output "replication_group_arn" {
  description = "The ARN of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.main.arn
}

output "replication_group_primary_endpoint_address" {
  description = "The address of the primary endpoint"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "replication_group_reader_endpoint_address" {
  description = "The address of the reader endpoint (Multi-AZ only)"
  value       = try(aws_elasticache_replication_group.main.reader_endpoint_address, "")
}

output "replication_group_member_clusters" {
  description = "The member clusters of the replication group"
  value       = aws_elasticache_replication_group.main.member_clusters
}

# ------------------------------------------------------------------------------
# Connection Information Outputs
# ------------------------------------------------------------------------------

output "port" {
  description = "The Redis port"
  value       = var.port
}

output "engine_version" {
  description = "The running version of the Redis engine"
  value       = aws_elasticache_replication_group.main.engine_version_actual
}

# ------------------------------------------------------------------------------
# Network Outputs
# ------------------------------------------------------------------------------

output "subnet_group_name" {
  description = "The name of the cache subnet group"
  value       = aws_elasticache_subnet_group.main.name
}

output "security_group_ids" {
  description = "The security group IDs attached to the cluster"
  value       = [module.redis_security_group.security_group_id]
}

output "redis_subnet_ids" {
  description = "Redis private subnet IDs created by this module"
  value       = module.redis_subnets.subnet_ids
}

output "redis_subnet_cidrs" {
  description = "Redis private subnet CIDR blocks"
  value       = module.redis_subnets.subnet_cidrs
}

output "availability_zones" {
  description = "Availability zones used for Redis subnets"
  value       = module.redis_subnets.availability_zones
}

output "redis_route_table_ids" {
  description = "Route table IDs for Redis subnets"
  value       = module.redis_subnets.route_table_ids
}

# ------------------------------------------------------------------------------
# SSM Parameter Store Outputs
# ------------------------------------------------------------------------------

output "ssm_parameter_auth_token" {
  description = "SSM parameter name for Redis AUTH token (SecureString)"
  value       = aws_ssm_parameter.redis_auth_token.name
  sensitive   = true
}

# ------------------------------------------------------------------------------
# Parameter Group Outputs
# ------------------------------------------------------------------------------

output "parameter_group_id" {
  description = "The name of the parameter group"
  value       = aws_elasticache_parameter_group.main.id
}

output "parameter_group_arn" {
  description = "The ARN of the parameter group"
  value       = aws_elasticache_parameter_group.main.arn
}


# ------------------------------------------------------------------------------
# Network Outputs
# ------------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID (auto-discovered)"
  value       = var.vpc_id
}

output "redis_security_group_id" {
  description = "Security group ID for Redis cluster"
  value       = module.redis_security_group.security_group_id
}

# ------------------------------------------------------------------------------
# KMS Outputs
# ------------------------------------------------------------------------------

output "kms_key_id" {
  description = "KMS key ID for Redis encryption"
  value       = module.kms_redis.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN for Redis encryption"
  value       = module.kms_redis.key_arn
}

output "kms_alias_name" {
  description = "KMS key alias"
  value       = module.kms_redis.alias_name
}

# ------------------------------------------------------------------------------
# CloudWatch Outputs
# ------------------------------------------------------------------------------

output "cloudwatch_log_group_slow_log" {
  description = "CloudWatch log group for Redis slow log"
  value       = aws_cloudwatch_log_group.redis_slow_log.name
}

output "cloudwatch_log_group_engine_log" {
  description = "CloudWatch log group for Redis engine log"
  value       = aws_cloudwatch_log_group.redis_engine_log.name
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.redis.dashboard_name
}

output "cloudwatch_alarms" {
  description = "CloudWatch alarm names"
  value = {
    high_cpu             = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
    high_memory          = aws_cloudwatch_metric_alarm.high_memory.alarm_name
    high_evictions       = aws_cloudwatch_metric_alarm.high_evictions.alarm_name
    high_replication_lag = aws_cloudwatch_metric_alarm.high_replication_lag.alarm_name
    high_connections     = aws_cloudwatch_metric_alarm.high_connections.alarm_name
  }
}
