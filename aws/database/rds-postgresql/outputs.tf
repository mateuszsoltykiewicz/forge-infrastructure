# ==============================================================================
# RDS PostgreSQL Module - Outputs
# ==============================================================================
# This file exports essential information about the created RDS instance.
# ==============================================================================

# ------------------------------------------------------------------------------
# Multi-Tenant Identification
# ------------------------------------------------------------------------------

output "db_identifier" {
  description = "The DB identifier (multi-tenant aware)"
  value       = local.db_identifier
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
# Instance Outputs
# ------------------------------------------------------------------------------

output "db_instance_id" {
  description = "The RDS instance identifier"
  value       = var.create ? aws_db_instance.main[0].id : null
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = var.create ? aws_db_instance.main[0].arn : null
}

output "db_instance_endpoint" {
  description = "The connection endpoint (address:port)"
  value       = var.create ? aws_db_instance.main[0].endpoint : null
}

output "db_instance_address" {
  description = "The hostname of the RDS instance"
  value       = var.create ? aws_db_instance.main[0].address : null
}

output "db_instance_port" {
  description = "The database port"
  value       = var.create ? aws_db_instance.main[0].port : null
}

output "db_instance_resource_id" {
  description = "The RDS resource ID"
  value       = var.create ? aws_db_instance.main[0].resource_id : null
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = var.create ? aws_db_instance.main[0].status : null
}

output "db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = var.create ? aws_db_instance.main[0].availability_zone : null
}

# ------------------------------------------------------------------------------
# Database Configuration Outputs
# ------------------------------------------------------------------------------

output "db_name" {
  description = "The name of the default database"
  value       = var.create ? aws_db_instance.main[0].db_name : null
}

output "master_username" {
  description = "The master username"
  value       = var.create ? aws_db_instance.main[0].username : null
  sensitive   = true
}

output "engine_version" {
  description = "The running version of the database engine"
  value       = var.create ? aws_db_instance.main[0].engine_version_actual : null
}

# ------------------------------------------------------------------------------
# Network Outputs
# ------------------------------------------------------------------------------

output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = var.create ? aws_db_subnet_group.main[0].id : null
}

output "db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = var.create ? aws_db_subnet_group.main[0].arn : null
}

output "security_group_id" {
  description = "The security group ID attached to the RDS instance"
  value       = aws_security_group.rds.id
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

output "rds_subnet_ids" {
  description = "RDS private subnet IDs created by this module"
  value       = aws_subnet.rds_private[*].id
}

output "rds_subnet_cidrs" {
  description = "RDS private subnet CIDR blocks"
  value       = aws_subnet.rds_private[*].cidr_block
}

output "availability_zones" {
  description = "Availability zones used for RDS subnets"
  value       = aws_subnet.rds_private[*].availability_zone
}

output "eks_cluster_name" {
  description = "EKS cluster name (if integrated)"
  value       = local.eks_cluster_name
}

# ------------------------------------------------------------------------------
# KMS Outputs
# ------------------------------------------------------------------------------

output "kms_key_id" {
  description = "KMS key ID for RDS encryption"
  value       = aws_kms_key.rds.id
}

output "kms_key_arn" {
  description = "KMS key ARN for RDS encryption"
  value       = aws_kms_key.rds.arn
}

output "kms_alias_name" {
  description = "KMS key alias"
  value       = aws_kms_alias.rds.name
}

# ------------------------------------------------------------------------------
# SSM Parameter Store Outputs
# ------------------------------------------------------------------------------

output "ssm_parameter_endpoint" {
  description = "SSM parameter name for RDS endpoint"
  value       = var.create ? aws_ssm_parameter.rds_endpoint[0].name : null
}

output "ssm_parameter_master_password" {
  description = "SSM parameter name for master password (SecureString)"
  value       = var.create ? aws_ssm_parameter.rds_master_password[0].name : null
  sensitive   = true
}

# ------------------------------------------------------------------------------
# CloudWatch Outputs
# ------------------------------------------------------------------------------

output "cloudwatch_log_group_postgresql" {
  description = "CloudWatch log group for PostgreSQL logs"
  value       = aws_cloudwatch_log_group.postgresql.name
}

output "cloudwatch_log_group_upgrade" {
  description = "CloudWatch log group for RDS upgrade logs"
  value       = aws_cloudwatch_log_group.upgrade.name
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.rds.dashboard_name
}

output "cloudwatch_alarms" {
  description = "CloudWatch alarm names"
  value = {
    high_cpu           = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
    low_memory         = aws_cloudwatch_metric_alarm.low_memory.alarm_name
    low_storage        = aws_cloudwatch_metric_alarm.low_storage.alarm_name
    high_connections   = aws_cloudwatch_metric_alarm.high_connections.alarm_name
    high_read_latency  = aws_cloudwatch_metric_alarm.high_read_latency.alarm_name
    high_write_latency = aws_cloudwatch_metric_alarm.high_write_latency.alarm_name
    high_replica_lag   = var.multi_az ? aws_cloudwatch_metric_alarm.high_replica_lag[0].alarm_name : null
  }
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
  value       = var.create ? aws_db_instance.main[0].performance_insights_enabled : null
}

# ------------------------------------------------------------------------------
# Connection Information
# ------------------------------------------------------------------------------

output "connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = "postgresql://${var.master_username}@${var.create ? aws_db_instance.main[0].address : null}:${var.port}/${var.database_name}"
  sensitive   = true
}

output "psql_command" {
  description = "Command to connect using psql (password from SSM)"
  value       = "psql -h ${var.create ? aws_db_instance.main[0].address : null} -p ${var.port} -U ${var.master_username} -d ${var.database_name}"
  sensitive   = true
}

# ------------------------------------------------------------------------------
# Parameter Group Outputs
# ------------------------------------------------------------------------------

output "parameter_group_id" {
  description = "The db parameter group name"
  value       = var.create ? aws_db_parameter_group.main[0].id : null
}

output "parameter_group_arn" {
  description = "The ARN of the db parameter group"
  value       = var.create ? aws_db_parameter_group.main[0].arn : null
}
