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

output "customer_name" {
  description = "Customer name (if applicable)"
  value       = var.customer_name != "" ? var.customer_name : null
}

output "project_name" {
  description = "Project name (if applicable)"
  value       = var.project_name != "" ? var.project_name : null
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
  value       = [aws_security_group.redis.id]
}

# ------------------------------------------------------------------------------
# SSM Parameter Store Outputs
# ------------------------------------------------------------------------------

output "ssm_parameter_primary_endpoint" {
  description = "SSM parameter name for Redis primary endpoint"
  value       = aws_ssm_parameter.redis_primary_endpoint.name
}

output "ssm_parameter_reader_endpoint" {
  description = "SSM parameter name for Redis reader endpoint (Multi-AZ only)"
  value       = var.multi_az_enabled ? aws_ssm_parameter.redis_reader_endpoint[0].name : ""
}

output "ssm_parameter_port" {
  description = "SSM parameter name for Redis port"
  value       = aws_ssm_parameter.redis_port.name
}

output "ssm_parameter_auth_token" {
  description = "SSM parameter name for Redis AUTH token (SecureString)"
  value       = var.auth_token_enabled ? aws_ssm_parameter.redis_auth_token[0].name : ""
  sensitive   = true
}

# ------------------------------------------------------------------------------
# Parameter Group Outputs
# ------------------------------------------------------------------------------

output "parameter_group_id" {
  description = "The name of the parameter group"
  value       = var.create_parameter_group ? aws_elasticache_parameter_group.main[0].id : ""
}

output "parameter_group_arn" {
  description = "The ARN of the parameter group"
  value       = var.create_parameter_group ? aws_elasticache_parameter_group.main[0].arn : ""
}

# ------------------------------------------------------------------------------
# Connection String Output
# ------------------------------------------------------------------------------

output "redis_cli_command" {
  description = "Command to connect using redis-cli (requires AUTH token from SSM)"
  value       = var.auth_token_enabled ? "redis-cli -h ${aws_elasticache_replication_group.main.primary_endpoint_address} -p ${var.port} --tls -a $(aws ssm get-parameter --name ${aws_ssm_parameter.redis_auth_token[0].name} --with-decryption --query Parameter.Value --output text)" : "redis-cli -h ${aws_elasticache_replication_group.main.primary_endpoint_address} -p ${var.port} --tls"
  sensitive   = true
}

# ------------------------------------------------------------------------------
# Network Outputs
# ------------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID (auto-discovered)"
  value       = data.aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block (auto-discovered)"
  value       = data.aws_vpc.main.cidr_block
}

output "redis_subnet_ids" {
  description = "Redis private subnet IDs created by this module"
  value       = aws_subnet.redis_private[*].id
}

output "redis_subnet_cidrs" {
  description = "Redis private subnet CIDR blocks"
  value       = aws_subnet.redis_private[*].cidr_block
}

output "availability_zones" {
  description = "Availability zones used for Redis subnets"
  value       = aws_subnet.redis_private[*].availability_zone
}

output "redis_security_group_id" {
  description = "Security group ID for Redis cluster"
  value       = aws_security_group.redis.id
}

output "eks_cluster_name" {
  description = "EKS cluster name (if integrated)"
  value       = local.eks_cluster_name
}

# ------------------------------------------------------------------------------
# KMS Outputs
# ------------------------------------------------------------------------------

output "kms_key_id" {
  description = "KMS key ID for Redis encryption"
  value       = aws_kms_key.redis.id
}

output "kms_key_arn" {
  description = "KMS key ARN for Redis encryption"
  value       = aws_kms_key.redis.arn
}

output "kms_alias_name" {
  description = "KMS key alias"
  value       = aws_kms_alias.redis.name
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
    high_replication_lag = var.multi_az_enabled ? aws_cloudwatch_metric_alarm.high_replication_lag[0].alarm_name : null
    high_connections     = aws_cloudwatch_metric_alarm.high_connections.alarm_name
  }
}
