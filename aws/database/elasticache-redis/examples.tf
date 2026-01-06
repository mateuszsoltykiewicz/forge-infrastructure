# ==============================================================================
# ElastiCache Redis Module - Example Configurations
# ==============================================================================
# This file demonstrates different multi-tenant deployment scenarios.
# Uncomment ONE example at a time to test the module.
# ==============================================================================

# ------------------------------------------------------------------------------
# Example 1: Shared Platform Redis (No Customer/Project Isolation)
# ------------------------------------------------------------------------------
# Use case: Single Redis cluster shared across all customers/projects
# Naming: forge-{environment}-redis
# Tags: No Customer or Project tags
# ------------------------------------------------------------------------------

# module "redis_shared" {
#   source = "./forge-infrastructure/aws/database/elasticache-redis"
# 
#   # Environment & Workspace (required)
#   environment = "production"
#   workspace   = "forge-platform"
# 
#   # No customer_name or project_name = shared cluster
# 
#   # Redis Configuration
#   engine_version           = "7.1"
#   node_type                = "cache.r7g.large"
#   num_cache_clusters       = 3  # Multi-AZ
#   multi_az_enabled         = true
#   automatic_failover       = true
# 
#   # Security
#   at_rest_encryption_enabled = true
#   transit_encryption_enabled = true
#   auth_token_enabled         = true
# 
#   # Network (auto-discovery)
#   redis_subnet_az_count    = 3
#   redis_subnet_newbits     = 8  # /24 subnets from VPC CIDR
#   redis_subnet_netnum_start = 100
# 
#   # EKS Integration (auto-discovery)
#   # eks_cluster_name is optional - will auto-discover if not provided
# 
#   # Maintenance
#   maintenance_window     = "sun:05:00-sun:07:00"
#   snapshot_window        = "03:00-05:00"
#   snapshot_retention_limit = 7
#   final_snapshot_enabled   = true
# 
#   # Monitoring
#   enable_cloudwatch_logs    = true
#   cloudwatch_retention_days = 30
# 
#   # KMS (auto-created)
#   enable_kms_key_rotation    = true
#   kms_deletion_window_in_days = 30
# 
#   # Tags
#   tags = {
#     ManagedBy = "Terraform"
#     Owner     = "Platform-Team"
#   }
# }

# ------------------------------------------------------------------------------
# Example 2: Customer-Dedicated Redis (Customer Isolation)
# ------------------------------------------------------------------------------
# Use case: Dedicated Redis cluster per customer
# Naming: forge-{environment}-{customer_name}-redis
# Tags: Customer = {customer_name}
# ------------------------------------------------------------------------------

# module "redis_customer_acme" {
#   source = "./forge-infrastructure/aws/database/elasticache-redis"
# 
#   # Environment & Workspace (required)
#   environment = "production"
#   workspace   = "forge-platform"
# 
#   # Customer isolation
#   customer_name = "acme"
#   # No project_name = customer-level cluster
# 
#   # Redis Configuration
#   engine_version           = "7.1"
#   node_type                = "cache.r7g.xlarge"
#   num_cache_clusters       = 2  # Multi-AZ
#   multi_az_enabled         = true
#   automatic_failover       = true
# 
#   # Security
#   at_rest_encryption_enabled = true
#   transit_encryption_enabled = true
#   auth_token_enabled         = true
# 
#   # Network (auto-discovery)
#   redis_subnet_az_count    = 2
#   redis_subnet_newbits     = 8  # /24 subnets
#   redis_subnet_netnum_start = 110
# 
#   # EKS Integration (manual specification)
#   eks_cluster_name = "forge-production-acme-eks"
# 
#   # Maintenance
#   maintenance_window     = "mon:05:00-mon:07:00"
#   snapshot_window        = "03:00-05:00"
#   snapshot_retention_limit = 14
#   final_snapshot_enabled   = true
# 
#   # Monitoring
#   enable_cloudwatch_logs    = true
#   cloudwatch_retention_days = 60
# 
#   # KMS (auto-created per customer)
#   enable_kms_key_rotation    = true
#   kms_deletion_window_in_days = 30
# 
#   # Tags
#   tags = {
#     ManagedBy = "Terraform"
#     Owner     = "Customer-ACME"
#     Compliance = "PCI-DSS"
#   }
# }

# ------------------------------------------------------------------------------
# Example 3: Project-Isolated Redis (Customer + Project Isolation)
# ------------------------------------------------------------------------------
# Use case: Dedicated Redis cluster per customer project
# Naming: forge-{environment}-{customer_name}-{project_name}-redis
# Tags: Customer = {customer_name}, Project = {project_name}
# ------------------------------------------------------------------------------

# module "redis_project_acme_webapp" {
#   source = "./forge-infrastructure/aws/database/elasticache-redis"
# 
#   # Environment & Workspace (required)
#   environment = "staging"
#   workspace   = "forge-platform"
# 
#   # Project-level isolation
#   customer_name = "acme"
#   project_name  = "webapp"
# 
#   # Redis Configuration
#   engine_version           = "7.1"
#   node_type                = "cache.r7g.large"
#   num_cache_clusters       = 2  # Multi-AZ
#   multi_az_enabled         = true
#   automatic_failover       = true
# 
#   # Security
#   at_rest_encryption_enabled = true
#   transit_encryption_enabled = true
#   auth_token_enabled         = true
# 
#   # Network (auto-discovery)
#   redis_subnet_az_count    = 2
#   redis_subnet_newbits     = 8  # /24 subnets
#   redis_subnet_netnum_start = 120
# 
#   # EKS Integration (auto-discovery by tags)
#   # Will find EKS cluster tagged with Customer=acme, Project=webapp
# 
#   # Maintenance
#   maintenance_window     = "tue:05:00-tue:07:00"
#   snapshot_window        = "03:00-05:00"
#   snapshot_retention_limit = 5
#   final_snapshot_enabled   = false  # Staging environment
# 
#   # Monitoring
#   enable_cloudwatch_logs    = true
#   cloudwatch_retention_days = 30
# 
#   # KMS (auto-created per project)
#   enable_kms_key_rotation    = true
#   kms_deletion_window_in_days = 7  # Faster cleanup for staging
# 
#   # Tags
#   tags = {
#     ManagedBy = "Terraform"
#     Owner     = "Customer-ACME"
#     CostCenter = "ACME-WebApp"
#   }
# }

# ------------------------------------------------------------------------------
# Example 4: Development Environment (Minimal Config)
# ------------------------------------------------------------------------------
# Use case: Dev/test environment with reduced costs
# Naming: forge-{environment}-{customer_name}-{project_name}-redis
# ------------------------------------------------------------------------------

# module "redis_dev" {
#   source = "./forge-infrastructure/aws/database/elasticache-redis"
# 
#   # Environment & Workspace (required)
#   environment = "development"
#   workspace   = "forge-dev"
# 
#   # Dev isolation
#   customer_name = "internal"
#   project_name  = "testing"
# 
#   # Redis Configuration (single-node for dev)
#   engine_version           = "7.1"
#   node_type                = "cache.t4g.micro"
#   num_cache_clusters       = 1  # Single-node (no HA)
#   multi_az_enabled         = false
#   automatic_failover       = false
# 
#   # Security (enabled even in dev)
#   at_rest_encryption_enabled = true
#   transit_encryption_enabled = true
#   auth_token_enabled         = true
# 
#   # Network (auto-discovery)
#   redis_subnet_az_count    = 1
#   redis_subnet_newbits     = 8
#   redis_subnet_netnum_start = 200
# 
#   # Maintenance
#   maintenance_window     = "sun:05:00-sun:07:00"
#   snapshot_window        = "03:00-05:00"
#   snapshot_retention_limit = 1  # Minimal retention
#   final_snapshot_enabled   = false
# 
#   # Monitoring (reduced retention)
#   enable_cloudwatch_logs    = true
#   cloudwatch_retention_days = 7
# 
#   # KMS (auto-created)
#   enable_kms_key_rotation    = true
#   kms_deletion_window_in_days = 7  # Fast cleanup
# 
#   # Tags
#   tags = {
#     ManagedBy = "Terraform"
#     Owner     = "Dev-Team"
#   }
# }

# ------------------------------------------------------------------------------
# Example 5: High-Performance Production Cluster
# ------------------------------------------------------------------------------
# Use case: Large-scale production with optimized settings
# ------------------------------------------------------------------------------

# module "redis_production_highperf" {
#   source = "./forge-infrastructure/aws/database/elasticache-redis"
# 
#   # Environment & Workspace (required)
#   environment = "production"
#   workspace   = "forge-platform"
# 
#   # Customer isolation
#   customer_name = "enterprise"
#   project_name  = "analytics"
# 
#   # Redis Configuration (large cluster)
#   engine_version           = "7.1"
#   node_type                = "cache.r7g.4xlarge"
#   num_cache_clusters       = 3  # Multi-AZ with read replicas
#   multi_az_enabled         = true
#   automatic_failover       = true
# 
#   # Redis Parameters (custom)
#   parameter_group_family = "redis7"
#   parameters = [
#     {
#       name  = "maxmemory-policy"
#       value = "allkeys-lru"
#     },
#     {
#       name  = "timeout"
#       value = "300"
#     },
#     {
#       name  = "tcp-keepalive"
#       value = "300"
#     },
#     {
#       name  = "notify-keyspace-events"
#       value = "Ex"
#     }
#   ]
# 
#   # Security (all enabled)
#   at_rest_encryption_enabled = true
#   transit_encryption_enabled = true
#   auth_token_enabled         = true
# 
#   # Network (3-AZ deployment)
#   redis_subnet_az_count    = 3
#   redis_subnet_newbits     = 8
#   redis_subnet_netnum_start = 130
# 
#   # EKS Integration
#   eks_cluster_name = "forge-production-enterprise-analytics-eks"
# 
#   # Maintenance (long windows for large clusters)
#   maintenance_window     = "sun:02:00-sun:06:00"
#   snapshot_window        = "00:00-02:00"
#   snapshot_retention_limit = 30  # Long retention
#   final_snapshot_enabled   = true
# 
#   # Monitoring (extended retention)
#   enable_cloudwatch_logs    = true
#   cloudwatch_retention_days = 90
# 
#   # KMS (enterprise security)
#   enable_kms_key_rotation    = true
#   kms_deletion_window_in_days = 30
# 
#   # Tags
#   tags = {
#     ManagedBy = "Terraform"
#     Owner     = "Enterprise-Team"
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
#    - KMS Keys: Created automatically per cluster
# 
# 2. Multi-Tenant Naming Patterns:
#    - Shared: forge-{environment}-redis
#    - Customer: forge-{environment}-{customer_name}-redis
#    - Project: forge-{environment}-{customer_name}-{project_name}-redis
# 
# 3. SSM Parameter Paths:
#    - Shared: /{environment}/forge-{environment}-redis/endpoint
#    - Customer: /{environment}/forge-{environment}-{customer_name}-redis/endpoint
#    - Project: /{environment}/forge-{environment}-{customer_name}-{project_name}-redis/endpoint
# 
# 4. Required AWS Resources (must exist):
#    - VPC with appropriate tags
#    - EKS cluster (optional, for security group integration)
# 
# 5. Created Resources:
#    - ElastiCache Replication Group
#    - Redis private subnets (one per AZ)
#    - Route tables and associations
#    - Security group with EKS integration
#    - KMS key and alias
#    - CloudWatch log groups (slow-log, engine-log)
#    - CloudWatch dashboard
#    - CloudWatch alarms (5 metrics)
#    - SSM parameters (endpoint, auth_token)
# 
# ==============================================================================
