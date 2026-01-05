# ==============================================================================
# ElastiCache Redis Module - Outputs
# ==============================================================================
# This file exports essential information about the created ElastiCache cluster.
# ==============================================================================

# ------------------------------------------------------------------------------
# Replication Group Outputs
# ------------------------------------------------------------------------------

output "replication_group_id" {
  description = "The ID of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.main.id
}

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
  value       = var.security_group_ids
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
}
