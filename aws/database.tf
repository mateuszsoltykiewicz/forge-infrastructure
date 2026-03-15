# ==============================================================================
# Database Infrastructure
# ==============================================================================
# RDS PostgreSQL and ElastiCache Redis instances
# ==============================================================================

# ------------------------------------------------------------------------------
# RDS PostgreSQL - Shared Database
# ------------------------------------------------------------------------------
# Shared instance across all environments (prod/staging/dev)
# Engine: PostgreSQL 16.6
# Backup retention: 30 days
# ------------------------------------------------------------------------------

module "rds" {
  source = "./database/rds-postgresql"

  common_prefix = local.common_prefix
  common_tags   = local.merged_tags

  aws_region = local.current_region
  vpc_id     = module.vpc.vpc_id

  subnet_cidrs       = local.subnet_allocations.rds.cidrs
  availability_zones = local.subnet_allocations.rds.availability_zones

  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
  storage_type      = "gp3"
  # iops not specified = baseline 3000 IOPS (free, included in storage price)
  engine_version = "16.6"

  backup_retention_period = 30

  depends_on = [module.vpc]
}

# ------------------------------------------------------------------------------
# ElastiCache Redis - Shared Cache
# ------------------------------------------------------------------------------
# Production Redis shared with staging/dev environments by default
# Engine: Redis 7.1
# High availability with multiple cache clusters
# ------------------------------------------------------------------------------

module "redis" {
  source = "./database/elasticache-redis"

  common_prefix = local.common_prefix
  common_tags   = local.merged_tags

  vpc_id = module.vpc.vpc_id

  subnet_cidrs       = local.subnet_allocations.redis.cidrs
  availability_zones = local.subnet_allocations.redis.availability_zones

  node_type          = var.redis_node_type
  num_cache_clusters = var.redis_num_cache_nodes
  engine_version     = "7.1"

  depends_on = [module.vpc]
}
