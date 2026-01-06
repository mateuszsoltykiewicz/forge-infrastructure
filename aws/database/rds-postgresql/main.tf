# ==============================================================================
# RDS PostgreSQL Module - Main Resources
# ==============================================================================
# This file creates the RDS PostgreSQL instance and supporting resources.
# ==============================================================================

# ------------------------------------------------------------------------------
# Random Password (if not provided)
# ------------------------------------------------------------------------------

resource "random_password" "master" {
  count = var.master_password == "" ? 1 : 0

  length  = 32
  special = true
  # Exclude characters that might cause issues in connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# ------------------------------------------------------------------------------
# DB Subnet Group
# ------------------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name       = "${local.db_identifier}-subnet-group"
  subnet_ids = aws_subnet.rds_private[*].id

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.db_identifier}-subnet-group"
    }
  )

  depends_on = [aws_subnet.rds_private]
}

# ------------------------------------------------------------------------------
# DB Parameter Group
# ------------------------------------------------------------------------------

resource "aws_db_parameter_group" "main" {
  name   = "${local.db_identifier}-params"
  family = var.parameter_group_family

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
      Name = "${local.db_identifier}-params"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------------------------
# RDS PostgreSQL Instance
# ------------------------------------------------------------------------------

resource "aws_db_instance" "main" {
  identifier = local.db_identifier

  # Engine Configuration
  engine         = "postgres"
  engine_version = var.engine_version

  # Instance Configuration
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = var.storage_type
  iops                  = var.iops > 0 ? var.iops : null
  storage_throughput    = var.storage_type == "gp3" ? var.storage_throughput : null

  # Database Configuration
  db_name  = var.database_name
  username = var.master_username
  password = local.master_password
  port     = var.port

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = var.publicly_accessible

  # High Availability
  multi_az          = var.multi_az
  availability_zone = var.multi_az ? null : (var.availability_zone != "" ? var.availability_zone : null)

  # Backup Configuration
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  maintenance_window        = var.maintenance_window
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = local.final_snapshot_identifier
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot

  # Security Configuration
  storage_encrypted                   = var.storage_encrypted
  kms_key_id                          = aws_kms_key.rds.arn
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  deletion_protection                 = var.deletion_protection

  # Monitoring Configuration
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = local.create_monitoring_role ? aws_iam_role.monitoring[0].arn : null

  # Performance Insights
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? aws_kms_key.rds.arn : null

  # Parameter Group
  parameter_group_name = aws_db_parameter_group.main.name

  # Auto Minor Version Upgrade
  auto_minor_version_upgrade = true

  # Apply changes immediately in non-production environments
  apply_immediately = var.environment != "production"

  tags = merge(
    local.merged_tags,
    {
      Name = local.db_identifier
    }
  )

  depends_on = [
    aws_kms_key.rds,
    aws_security_group.rds,
    aws_cloudwatch_log_group.postgresql,
    aws_cloudwatch_log_group.upgrade
  ]

  lifecycle {
    ignore_changes = [
      # Ignore password changes after initial creation
      password,
      # Ignore final snapshot identifier timestamp
      final_snapshot_identifier,
    ]
  }
}

# ------------------------------------------------------------------------------
# SSM Parameter Store (for master password and endpoint)
# ------------------------------------------------------------------------------

# Store RDS endpoint in SSM
resource "aws_ssm_parameter" "rds_endpoint" {
  name  = "/${var.environment}/${local.db_identifier}/endpoint"
  type  = "String"
  value = aws_db_instance.main.endpoint

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.db_identifier}-endpoint"
    }
  )
}

# Store master password in SSM (SecureString with KMS encryption)
resource "aws_ssm_parameter" "rds_master_password" {
  name   = "/${var.environment}/${local.db_identifier}/master-password"
  type   = "SecureString"
  key_id = aws_kms_key.rds.arn
  value = jsonencode({
    username = var.master_username
    password = local.master_password
    engine   = "postgres"
    host     = aws_db_instance.main.address
    port     = var.port
    dbname   = var.database_name
  })

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.db_identifier}-master-password"
    }
  )
}

# ------------------------------------------------------------------------------
# Enhanced Monitoring IAM Role
# ------------------------------------------------------------------------------

resource "aws_iam_role" "monitoring" {
  count = local.create_monitoring_role ? 1 : 0

  name = "${local.db_identifier}-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.merged_tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  count = local.create_monitoring_role ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  role       = aws_iam_role.monitoring[0].name
}
