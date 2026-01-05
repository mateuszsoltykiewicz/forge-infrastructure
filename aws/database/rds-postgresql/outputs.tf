# ==============================================================================
# RDS PostgreSQL Module - Outputs
# ==============================================================================
# This file exports essential information about the created RDS instance.
# ==============================================================================

# ------------------------------------------------------------------------------
# Instance Outputs
# ------------------------------------------------------------------------------

output "db_instance_id" {
  description = "The RDS instance identifier"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "db_instance_endpoint" {
  description = "The connection endpoint (address:port)"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.main.address
}

output "db_instance_port" {
  description = "The database port"
  value       = aws_db_instance.main.port
}

output "db_instance_resource_id" {
  description = "The RDS resource ID"
  value       = aws_db_instance.main.resource_id
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = aws_db_instance.main.status
}

output "db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = aws_db_instance.main.availability_zone
}

# ------------------------------------------------------------------------------
# Database Configuration Outputs
# ------------------------------------------------------------------------------

output "db_name" {
  description = "The name of the default database"
  value       = aws_db_instance.main.db_name
}

output "master_username" {
  description = "The master username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "engine_version" {
  description = "The running version of the database engine"
  value       = aws_db_instance.main.engine_version_actual
}

# ------------------------------------------------------------------------------
# Network Outputs
# ------------------------------------------------------------------------------

output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = aws_db_subnet_group.main.id
}

output "db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = aws_db_subnet_group.main.arn
}

output "vpc_security_group_ids" {
  description = "The security group IDs attached to the instance"
  value       = aws_db_instance.main.vpc_security_group_ids
}

# ------------------------------------------------------------------------------
# Secrets Manager Outputs
# ------------------------------------------------------------------------------

output "master_password_secret_arn" {
  description = "ARN of the Secrets Manager secret containing master credentials"
  value       = aws_secretsmanager_secret.master_password.arn
}

output "master_password_secret_name" {
  description = "Name of the Secrets Manager secret containing master credentials"
  value       = aws_secretsmanager_secret.master_password.name
}

# ------------------------------------------------------------------------------
# Monitoring Outputs
# ------------------------------------------------------------------------------

output "monitoring_role_arn" {
  description = "ARN of the enhanced monitoring IAM role"
  value       = local.create_monitoring_role ? aws_iam_role.monitoring[0].arn : ""
}

output "performance_insights_enabled" {
  description = "Whether Performance Insights is enabled"
  value       = aws_db_instance.main.performance_insights_enabled
}

# ------------------------------------------------------------------------------
# Connection Information
# ------------------------------------------------------------------------------

output "connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = "postgresql://${var.master_username}@${aws_db_instance.main.address}:${var.port}/${var.database_name}"
  sensitive   = true
}

output "psql_command" {
  description = "Command to connect using psql (password from Secrets Manager)"
  value       = "psql -h ${aws_db_instance.main.address} -p ${var.port} -U ${var.master_username} -d ${var.database_name}"
}

# ------------------------------------------------------------------------------
# Parameter Group Outputs
# ------------------------------------------------------------------------------

output "parameter_group_id" {
  description = "The db parameter group name"
  value       = aws_db_parameter_group.main.id
}

output "parameter_group_arn" {
  description = "The ARN of the db parameter group"
  value       = aws_db_parameter_group.main.arn
}
