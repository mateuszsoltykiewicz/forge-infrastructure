# ==============================================================================
# RDS PostgreSQL Module - Example Configurations
# ==============================================================================
# This file demonstrates different multi-tenant deployment scenarios.
# Uncomment ONE example at a time to test the module.
# ==============================================================================

# ------------------------------------------------------------------------------
# Example 1: Shared Platform RDS (No Customer/Project Isolation)
# ------------------------------------------------------------------------------
# Use case: Single RDS instance shared across all customers/projects
# Naming: forge-{environment}-db
# Tags: No Customer or Project tags
# ------------------------------------------------------------------------------

# module "rds_shared" {
#   source = "./forge-infrastructure/aws/database/rds-postgresql"
#
#   # Environment & Workspace (required)
#   environment = "production"
#   workspace   = "forge-platform"
#
#   # No customer_name or project_name = shared instance
#
#   # RDS Configuration
#   engine_version        = "16.4"
#   instance_class        = "db.r8g.xlarge"
#   allocated_storage     = 500
#   max_allocated_storage = 1000
#   storage_type          = "gp3"
#   storage_throughput    = 125
#
#   # Database
#   database_name   = "forge"
#   master_username = "forgeadmin"
#   port            = 5432
#
#   # High Availability
#   multi_az = true
#
#   # Backup
#   backup_retention_period = 7
#   backup_window           = "03:00-04:00"
#   maintenance_window      = "sun:04:00-sun:05:00"
#   skip_final_snapshot     = false
#
#   # Security
#   storage_encrypted                   = true
#   iam_database_authentication_enabled = true
#   deletion_protection                 = true
#
#   # Network (auto-discovery)
#   rds_subnet_az_count    = 2
#   rds_subnet_newbits     = 8  # /24 subnets from VPC CIDR
#   rds_subnet_netnum_start = 50
#
#   # EKS Integration (auto-discovery)
#   # eks_cluster_name is optional - will auto-discover if not provided
#
#   # Monitoring
#   enabled_cloudwatch_logs_exports        = ["postgresql", "upgrade"]
#   monitoring_interval                    = 60
#   performance_insights_enabled           = true
#   performance_insights_retention_period  = 7
#
#   # KMS (auto-created)
#   enable_kms_key_rotation     = true
#   kms_deletion_window_in_days = 30
#
#   # Tags
#   tags = {
#     Owner = "Platform-Team"
#   }
# }

# ------------------------------------------------------------------------------
# Example 2: Customer-Dedicated RDS (Customer Isolation)
# ------------------------------------------------------------------------------
# Use case: Dedicated RDS instance per customer
# Naming: forge-{environment}-{customer_name}-db
# Tags: Customer = {customer_name}
# ------------------------------------------------------------------------------

# module "rds_customer_acme" {
#   source = "./forge-infrastructure/aws/database/rds-postgresql"
#
#   # Environment & Workspace (required)
#   environment = "production"
#   workspace   = "forge-platform"
#
#   # Customer isolation
#   customer_id   = "cust-001"
#   customer_name = "acme"
#   plan_tier     = "pro"
#   # No project_name = customer-level instance
#
#   # RDS Configuration
#   engine_version        = "16.4"
#   instance_class        = "db.r8g.2xlarge"
#   allocated_storage     = 1000
#   max_allocated_storage = 2000
#   storage_type          = "gp3"
#   storage_throughput    = 250
#
#   # Database
#   database_name   = "forge"
#   master_username = "forgeadmin"
#   port            = 5432
#
#   # High Availability
#   multi_az = true
#
#   # Backup
#   backup_retention_period = 14
#   backup_window           = "03:00-04:00"
#   maintenance_window      = "mon:04:00-mon:05:00"
#   skip_final_snapshot     = false
#
#   # Security
#   storage_encrypted                   = true
#   iam_database_authentication_enabled = true
#   deletion_protection                 = true
#
#   # Network (auto-discovery)
#   rds_subnet_az_count    = 2
#   rds_subnet_newbits     = 8
#   rds_subnet_netnum_start = 60
#
#   # EKS Integration (manual specification)
#   eks_cluster_name = "forge-production-acme-eks"
#
#   # Monitoring
#   enabled_cloudwatch_logs_exports        = ["postgresql", "upgrade"]
#   monitoring_interval                    = 60
#   performance_insights_enabled           = true
#   performance_insights_retention_period  = 31
#
#   # KMS (auto-created per customer)
#   enable_kms_key_rotation     = true
#   kms_deletion_window_in_days = 30
#
#   # Tags
#   tags = {
#     Owner      = "Customer-ACME"
#     Compliance = "SOC2"
#   }
# }

# ------------------------------------------------------------------------------
# Example 3: Project-Isolated RDS (Customer + Project Isolation)
# ------------------------------------------------------------------------------
# Use case: Dedicated RDS instance per customer project
# Naming: forge-{environment}-{customer_name}-{project_name}-db
# Tags: Customer = {customer_name}, Project = {project_name}
# ------------------------------------------------------------------------------

# module "rds_project_acme_webapp" {
#   source = "./forge-infrastructure/aws/database/rds-postgresql"
#
#   # Environment & Workspace (required)
#   environment = "staging"
#   workspace   = "forge-platform"
#
#   # Project-level isolation
#   customer_id   = "cust-001"
#   customer_name = "acme"
#   project_name  = "webapp"
#   plan_tier     = "advanced"
#
#   # RDS Configuration
#   engine_version        = "16.4"
#   instance_class        = "db.r8g.xlarge"
#   allocated_storage     = 500
#   max_allocated_storage = 1000
#   storage_type          = "gp3"
#   storage_throughput    = 125
#
#   # Database
#   database_name   = "webapp"
#   master_username = "webappadmin"
#   port            = 5432
#
#   # High Availability
#   multi_az = true
#
#   # Backup
#   backup_retention_period = 5
#   backup_window           = "03:00-04:00"
#   maintenance_window      = "tue:04:00-tue:05:00"
#   skip_final_snapshot     = false
#
#   # Security
#   storage_encrypted                   = true
#   iam_database_authentication_enabled = true
#   deletion_protection                 = false  # Staging environment
#
#   # Network (auto-discovery)
#   rds_subnet_az_count    = 2
#   rds_subnet_newbits     = 8
#   rds_subnet_netnum_start = 70
#
#   # EKS Integration (auto-discovery by tags)
#   # Will find EKS cluster tagged with Customer=acme, Project=webapp
#
#   # Monitoring
#   enabled_cloudwatch_logs_exports        = ["postgresql", "upgrade"]
#   monitoring_interval                    = 60
#   performance_insights_enabled           = true
#   performance_insights_retention_period  = 7
#
#   # KMS (auto-created per project)
#   enable_kms_key_rotation     = true
#   kms_deletion_window_in_days = 7  # Faster cleanup for staging
#
#   # Tags
#   tags = {
#     Owner      = "Customer-ACME"
#     CostCenter = "ACME-WebApp"
#   }
# }

# ------------------------------------------------------------------------------
# Example 4: Development Environment (Single-AZ, Minimal Config)
# ------------------------------------------------------------------------------
# Use case: Dev/test environment with reduced costs
# ------------------------------------------------------------------------------

# module "rds_dev" {
#   source = "./forge-infrastructure/aws/database/rds-postgresql"
#
#   # Environment & Workspace (required)
#   environment = "development"
#   workspace   = "forge-dev"
#
#   # Dev isolation
#   customer_name = "internal"
#   project_name  = "testing"
#
#   # RDS Configuration (smaller instance for dev)
#   engine_version        = "16.4"
#   instance_class        = "db.t4g.medium"
#   allocated_storage     = 100
#   max_allocated_storage = 200
#   storage_type          = "gp3"
#   storage_throughput    = 125
#
#   # Database
#   database_name   = "forge_dev"
#   master_username = "devadmin"
#   port            = 5432
#
#   # High Availability (single-AZ for dev)
#   multi_az = false
#
#   # Backup (minimal for dev)
#   backup_retention_period = 1
#   backup_window           = "03:00-04:00"
#   maintenance_window      = "sun:04:00-sun:05:00"
#   skip_final_snapshot     = true  # No final snapshot for dev
#
#   # Security (enabled even in dev)
#   storage_encrypted                   = true
#   iam_database_authentication_enabled = true
#   deletion_protection                 = false
#
#   # Network (auto-discovery)
#   rds_subnet_az_count    = 2  # Still need 2 AZs for subnet group
#   rds_subnet_newbits     = 8
#   rds_subnet_netnum_start = 80
#
#   # Monitoring (reduced for dev)
#   enabled_cloudwatch_logs_exports        = ["postgresql"]
#   monitoring_interval                    = 0  # Disable enhanced monitoring
#   performance_insights_enabled           = false
#
#   # KMS (auto-created)
#   enable_kms_key_rotation     = true
#   kms_deletion_window_in_days = 7  # Fast cleanup
#
#   # Tags
#   tags = {
#     Owner = "Dev-Team"
#   }
# }

# ------------------------------------------------------------------------------
# Example 5: High-Performance Production Instance
# ------------------------------------------------------------------------------
# Use case: Large-scale production with optimized settings and io2 storage
# ------------------------------------------------------------------------------

# module "rds_production_highperf" {
#   source = "./forge-infrastructure/aws/database/rds-postgresql"
#
#   # Environment & Workspace (required)
#   environment = "production"
#   workspace   = "forge-platform"
#
#   # Customer isolation
#   customer_id   = "cust-002"
#   customer_name = "enterprise"
#   project_name  = "analytics"
#   plan_tier     = "enterprise"
#
#   # RDS Configuration (large instance with io2)
#   engine_version        = "16.4"
#   instance_class        = "db.r8g.8xlarge"
#   allocated_storage     = 2000
#   max_allocated_storage = 5000
#   storage_type          = "io2"
#   iops                  = 64000  # High IOPS for io2
#
#   # Database
#   database_name   = "analytics"
#   master_username = "analyticsadmin"
#   port            = 5432
#
#   # High Availability
#   multi_az = true
#
#   # Backup (extended retention)
#   backup_retention_period = 35  # Max retention
#   backup_window           = "02:00-04:00"
#   maintenance_window      = "sun:04:00-sun:06:00"
#   skip_final_snapshot     = false
#
#   # Security
#   storage_encrypted                   = true
#   iam_database_authentication_enabled = true
#   deletion_protection                 = true
#
#   # Network (3-AZ deployment)
#   rds_subnet_az_count    = 3
#   rds_subnet_newbits     = 8
#   rds_subnet_netnum_start = 90
#
#   # EKS Integration
#   eks_cluster_name = "forge-production-enterprise-analytics-eks"
#
#   # Monitoring (extended retention)
#   enabled_cloudwatch_logs_exports        = ["postgresql", "upgrade"]
#   monitoring_interval                    = 15  # More frequent monitoring
#   performance_insights_enabled           = true
#   performance_insights_retention_period  = 731  # Max retention
#
#   # KMS (enterprise security)
#   enable_kms_key_rotation     = true
#   kms_deletion_window_in_days = 30
#
#   # PostgreSQL Parameters (optimized for analytics)
#   parameters = [
#     {
#       name  = "shared_preload_libraries"
#       value = "pg_stat_statements,pg_hint_plan"
#     },
#     {
#       name  = "max_connections"
#       value = "500"
#     },
#     {
#       name  = "work_mem"
#       value = "262144"  # 256 MB
#     },
#     {
#       name  = "maintenance_work_mem"
#       value = "2097152"  # 2 GB
#     },
#     {
#       name  = "effective_cache_size"
#       value = "67108864"  # 64 GB
#     },
#     {
#       name  = "log_statement"
#       value = "ddl"
#     },
#     {
#       name  = "log_min_duration_statement"
#       value = "1000"
#     }
#   ]
#
#   # Tags
#   tags = {
#     Owner      = "Enterprise-Team"
#     Compliance = "SOC2"
#     BackupPlan = "Critical"
#   }
# }

# ==============================================================================
# Usage Notes
# ==============================================================================
#
# 1. Zero-Config Auto-Discovery:
#    - VPC: Auto-discovered by tags (Workspace, Environment, Customer, Project)
#    - EKS: Auto-discovered by tags (or specify eks_cluster_name manually)
#    - Subnets: Created automatically from VPC CIDR
#    - Security Groups: Created automatically with EKS integration
#    - KMS Keys: Created automatically per instance
#
# 2. Multi-Tenant Naming Patterns:
#    - Shared: forge-{environment}-db
#    - Customer: forge-{environment}-{customer_name}-db
#    - Project: forge-{environment}-{customer_name}-{project_name}-db
#
# 3. SSM Parameter Paths:
#    - Endpoint: /{environment}/{db_identifier}/endpoint
#    - Password: /{environment}/{db_identifier}/master-password (SecureString)
#
# 4. Required AWS Resources (must exist):
#    - VPC with appropriate tags
#    - EKS cluster (optional, for security group integration)
#
# 5. Created Resources:
#    - RDS PostgreSQL instance
#    - DB subnet group with private subnets (one per AZ)
#    - Route tables and associations
#    - Security group with EKS integration
#    - KMS key and alias
#    - CloudWatch log groups (postgresql, upgrade)
#    - CloudWatch dashboard
#    - CloudWatch alarms (7 metrics)
#    - SSM parameters (endpoint, master-password)
#    - Enhanced monitoring IAM role (if enabled)
#
# ==============================================================================
