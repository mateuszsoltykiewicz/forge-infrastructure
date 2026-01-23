# ==============================================================================
# RDS PostgreSQL Module - Main Resources
# ==============================================================================
# This file creates the RDS PostgreSQL instance and supporting resources.
# ==============================================================================

# ------------------------------------------------------------------------------
# KMS Key for RDS Encryption
# ------------------------------------------------------------------------------

module "kms_rds" {
  source = "../../security/kms"

  # Pattern A variables
  common_prefix = var.common_prefix
  common_tags   = var.common_tags

  # Environment context
  environment = var.environment
  region      = var.aws_region

  # KMS Key configuration
  key_purpose     = "rds-postgresql"
  key_description = "RDS PostgreSQL ${local.db_identifier_clean} encryption (storage, Performance Insights, logs, SSM)"
  key_usage       = "ENCRYPT_DECRYPT"

  # Security settings
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = var.enable_kms_key_rotation

  # Service principals - RDS, CloudWatch Logs, SSM
  key_service_roles = [
    "rds.amazonaws.com",
    "logs.${data.aws_region.current.id}.amazonaws.com",
    "ssm.amazonaws.com"
  ]

  # Root account as administrator
  key_administrators = [
    "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
}

# ------------------------------------------------------------------------------
# Random Password (if not provided)
# ------------------------------------------------------------------------------

resource "random_password" "master" {

  length  = 32
  special = true
  # Exclude characters that might cause issues in connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# ------------------------------------------------------------------------------
# DB Subnet Group
# ------------------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name       = local.db_subnet_group_name
  subnet_ids = module.rds_subnets.subnet_ids

  tags = merge(
    local.merged_tags,
    {
      Name = local.db_subnet_group_name
    }
  )

  depends_on = [module.rds_subnets]
}

# ------------------------------------------------------------------------------
# DB Parameter Group
# ------------------------------------------------------------------------------

resource "aws_db_parameter_group" "main" {

  name   = local.db_parameter_group_name
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(
    local.merged_tags,
    {
      Name = local.db_parameter_group_name
    }
  )
}

# ------------------------------------------------------------------------------
# RDS PostgreSQL Instance
# ------------------------------------------------------------------------------

resource "aws_db_instance" "main" {

  identifier = local.db_identifier_clean

  # Engine Configuration
  engine         = "postgres"
  engine_version = var.engine_version

  # Instance Configuration
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = var.storage_type
  iops                  = var.iops > 0 ? var.iops : null
  storage_throughput    = var.storage_type == "gp3" && var.iops > 0 ? var.storage_throughput : null

  # Database Configuration
  db_name  = var.database_name
  username = var.master_username
  password = random_password.master.result
  port     = var.port

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [module.rds_security_group.security_group_id]
  publicly_accessible    = false

  # High Availability
  multi_az = true

  # Backup Configuration
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  maintenance_window        = var.maintenance_window
  skip_final_snapshot       = false
  final_snapshot_identifier = local.final_snapshot_identifier
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot

  # Security Configuration
  storage_encrypted                   = true
  kms_key_id                          = module.kms_rds.key_arn
  iam_database_authentication_enabled = true
  deletion_protection                 = var.deletion_protection

  # Monitoring Configuration
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = aws_iam_role.monitoring.arn

  # Performance Insights
  performance_insights_enabled          = true
  performance_insights_retention_period = var.performance_insights_retention_period
  performance_insights_kms_key_id       = module.kms_rds.key_arn

  # Parameter Group
  parameter_group_name = aws_db_parameter_group.main.name

  # Auto Minor Version Upgrade
  auto_minor_version_upgrade = false

  # Apply changes immediately in non-production environments
  apply_immediately = false

  tags = merge(
    local.merged_tags,
    {
      Name = local.db_identifier_clean
    }
  )

  depends_on = [
    module.kms_rds,
    module.rds_security_group
  ]

  lifecycle {
    # Validate DB identifier length
    precondition {
      condition     = local.identifier_validation.length_ok
      error_message = "RDS DB identifier '${local.db_identifier_clean}' must be 1-63 characters (current: ${length(local.db_identifier_clean)})"
    }

    # Validate DB identifier starts with letter
    precondition {
      condition     = local.identifier_validation.starts_with_letter
      error_message = "RDS DB identifier '${local.db_identifier_clean}' must start with a letter"
    }

    # Validate DB identifier pattern
    precondition {
      condition     = local.identifier_validation.pattern_ok
      error_message = "RDS DB identifier '${local.db_identifier_clean}' contains invalid characters. Allowed: a-z, 0-9, hyphens"
    }

    # Validate no double hyphens
    precondition {
      condition     = local.identifier_validation.no_double_dash
      error_message = "RDS DB identifier '${local.db_identifier_clean}' contains double hyphens (--)"
    }

    # Validate no trailing hyphen
    precondition {
      condition     = local.identifier_validation.no_trailing_dash
      error_message = "RDS DB identifier '${local.db_identifier_clean}' ends with a hyphen"
    }

    ignore_changes = [
      # Ignore password changes after initial creation
      password,
      # Ignore final snapshot identifier timestamp
      final_snapshot_identifier,
    ]
  }
}

# Read Replica removed - Multi-AZ provides HA, read replica not needed for current workload
# Cost savings: ~$400/month (db.r8g.xlarge)

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
  key_id = module.kms_rds.key_arn
  value = jsonencode({
    username = var.master_username
    password = random_password.master.result
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

  name_prefix = substr("${local.db_identifier_clean}-mon-", 0, 48)

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

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  role       = aws_iam_role.monitoring.name
}
