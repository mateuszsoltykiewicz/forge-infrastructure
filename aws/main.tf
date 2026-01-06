# ==============================================================================
# Root Module - Main Infrastructure Deployment
# ==============================================================================
# This file orchestrates multi-environment infrastructure deployment including:
# - VPC (single shared VPC)
# - EKS (single cluster with namespace isolation)
# - ALB (one per environment: prod, stag, dev)
# - RDS PostgreSQL (production + optional staging/dev)
# - ElastiCache Redis (production + optional staging/dev)
# ==============================================================================

# ------------------------------------------------------------------------------
# VPC Module (Single Shared VPC)
# ------------------------------------------------------------------------------

module "vpc" {
  source = "./network/vpc"

  vpc_name       = local.vpc_name
  cidr_block     = var.vpc_cidr
  workspace      = var.workspace
  environment    = "shared"  # Single VPC shared by all environments
  customer_name  = var.customer_name
  project_name   = var.project_name

  common_tags = local.common_tags
}

# ------------------------------------------------------------------------------
# EKS Module (Single Cluster with Multi-Environment Namespaces)
# ------------------------------------------------------------------------------

module "eks" {
  source = "./compute/eks"

  workspace           = var.workspace
  environment         = "shared"  # Single cluster shared by all environments
  customer_name       = var.customer_name != null ? var.customer_name : ""
  project_name        = var.project_name != null ? var.project_name : ""
  kubernetes_version  = var.eks_kubernetes_version

  # Namespaces for environment isolation
  namespaces = local.eks_namespaces

  # Node group configuration
  node_groups = {
    general = {
      instance_types = var.eks_node_instance_types
      desired_size   = var.eks_node_desired_size
      min_size       = var.eks_node_min_size
      max_size       = var.eks_node_max_size
    }
  }

  tags = merge(
    local.common_tags,
    {
      Component = "EKS"
    }
  )

  depends_on = [module.vpc]
}

# ------------------------------------------------------------------------------
# Application Load Balancers (One Per Environment)
# ------------------------------------------------------------------------------

module "alb" {
  source   = "./load-balancing/alb"
  for_each = local.active_environments

  workspace     = var.workspace
  environment   = each.key
  customer_name = var.customer_name
  project_name  = var.project_name

  # ALB configuration
  internal        = false  # Public-facing
  ip_address_type = "ipv4"

  # HTTPS configuration
  https_listener = {
    enabled         = true
    port            = 443
    ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    certificate_arn = var.alb_certificate_arn
    target_group_key = "eks"
  }

  # HTTP listener (redirect to HTTPS)
  http_listener = {
    enabled       = true
    port          = 80
    redirect_https = true
  }

  # Target group pointing to EKS NodePort
  target_groups = {
    eks = {
      port            = each.value.nodeport
      protocol        = "HTTP"
      target_type     = "instance"
      health_check = {
        enabled             = true
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        matcher             = "200-299"
      }
      deregistration_delay = 30
    }
  }

  tags = merge(
    local.common_tags,
    {
      Component   = "ALB"
      Environment = each.key
      Subdomain   = "${each.value.subdomain}.${var.domain_name}"
    }
  )

  depends_on = [module.vpc, module.eks]
}

# ------------------------------------------------------------------------------
# RDS PostgreSQL (Production + Optional Staging/Dev)
# ------------------------------------------------------------------------------

# Production RDS (shared with staging/dev by default)
module "rds_production" {
  source = "./database/rds-postgresql"
  count  = var.enable_production ? 1 : 0

  workspace     = var.workspace
  environment   = "production"
  customer_name = var.customer_name != null ? var.customer_name : ""
  project_name  = var.project_name != null ? var.project_name : ""

  instance_class      = var.rds_instance_class
  allocated_storage   = var.rds_allocated_storage
  engine_version      = "16.4"

  # Resource sharing configuration
  resource_sharing         = local.production_db_config.resource_sharing
  shared_with_environments = local.production_db_config.shared_with_environments

  # High availability for production
  multi_az               = true
  backup_retention_period = 30

  tags = merge(
    local.common_tags,
    {
      Component   = "RDS"
      Environment = "production"
    }
  )

  depends_on = [module.vpc]
}

# Staging RDS (optional - only if not sharing production)
module "rds_staging" {
  source = "./database/rds-postgresql"
  count  = local.create_staging_db && var.enable_staging ? 1 : 0

  workspace     = var.workspace
  environment   = "staging"
  customer_name = var.customer_name != null ? var.customer_name : ""
  project_name  = var.project_name != null ? var.project_name : ""

  instance_class      = "db.r8g.large"  # Smaller instance for staging
  allocated_storage   = 100
  engine_version      = "16.4"

  # Dedicated staging database
  resource_sharing         = "dedicated"
  shared_with_environments = []

  multi_az               = false
  backup_retention_period = 7

  tags = merge(
    local.common_tags,
    {
      Component   = "RDS"
      Environment = "staging"
    }
  )

  depends_on = [module.vpc]
}

# Development RDS (optional - only if not sharing production)
module "rds_development" {
  source = "./database/rds-postgresql"
  count  = local.create_development_db && var.enable_development ? 1 : 0

  workspace     = var.workspace
  environment   = "development"
  customer_name = var.customer_name != null ? var.customer_name : ""
  project_name  = var.project_name != null ? var.project_name : ""

  instance_class      = "db.r8g.large"  # Smaller instance for dev
  allocated_storage   = 50
  engine_version      = "16.4"

  # Dedicated development database
  resource_sharing         = "dedicated"
  shared_with_environments = []

  multi_az               = false
  backup_retention_period = 3

  tags = merge(
    local.common_tags,
    {
      Component   = "RDS"
      Environment = "development"
    }
  )

  depends_on = [module.vpc]
}

# ------------------------------------------------------------------------------
# ElastiCache Redis (Production + Optional Staging/Dev)
# ------------------------------------------------------------------------------

# Production Redis (shared with staging/dev by default)
module "redis_production" {
  source = "./database/elasticache-redis"
  count  = var.enable_production ? 1 : 0

  workspace     = var.workspace
  environment   = "production"
  customer_name = var.customer_name != null ? var.customer_name : ""
  project_name  = var.project_name != null ? var.project_name : ""

  node_type         = var.redis_node_type
  num_cache_nodes   = var.redis_num_cache_nodes
  engine_version    = "7.1"

  # Resource sharing configuration
  resource_sharing         = local.production_redis_config.resource_sharing
  shared_with_environments = local.production_redis_config.shared_with_environments

  # High availability for production
  automatic_failover_enabled = true
  multi_az_enabled          = true

  tags = merge(
    local.common_tags,
    {
      Component   = "Redis"
      Environment = "production"
    }
  )

  depends_on = [module.vpc]
}

# Staging Redis (optional - only if not sharing production)
module "redis_staging" {
  source = "./database/elasticache-redis"
  count  = local.create_staging_redis && var.enable_staging ? 1 : 0

  workspace     = var.workspace
  environment   = "staging"
  customer_name = var.customer_name != null ? var.customer_name : ""
  project_name  = var.project_name != null ? var.project_name : ""

  node_type         = "cache.r7g.large"  # Smaller instance for staging
  num_cache_nodes   = 1
  engine_version    = "7.1"

  # Dedicated staging Redis
  resource_sharing         = "dedicated"
  shared_with_environments = []

  automatic_failover_enabled = false
  multi_az_enabled          = false

  tags = merge(
    local.common_tags,
    {
      Component   = "Redis"
      Environment = "staging"
    }
  )

  depends_on = [module.vpc]
}

# Development Redis (optional - only if not sharing production)
module "redis_development" {
  source = "./database/elasticache-redis"
  count  = local.create_development_redis && var.enable_development ? 1 : 0

  workspace     = var.workspace
  environment   = "development"
  customer_name = var.customer_name != null ? var.customer_name : ""
  project_name  = var.project_name != null ? var.project_name : ""

  node_type         = "cache.r7g.large"  # Smaller instance for dev
  num_cache_nodes   = 1
  engine_version    = "7.1"

  # Dedicated development Redis
  resource_sharing         = "dedicated"
  shared_with_environments = []

  automatic_failover_enabled = false
  multi_az_enabled          = false

  tags = merge(
    local.common_tags,
    {
      Component   = "Redis"
      Environment = "development"
    }
  )

  depends_on = [module.vpc]
}

# ==============================================================================
# Deployment Architecture Summary:
# ==============================================================================
# - VPC: Single shared VPC (10.0.0.0/16)
# - EKS: Single cluster with namespaces (prod-cronus, stag-cronus, dev-cronus)
# - ALB: 3 instances (prod.insighthealth.io, stag.insighthealth.io, dev.insighthealth.io)
# - RDS: 1 production instance (shared by staging/dev)
# - Redis: 1 production instance (shared by staging/dev)
#
# Cost Optimization:
# - Sharing RDS/Redis saves ~$600/month
# - Single EKS cluster saves ~$144/month (2 extra control planes)
# - Total estimated cost: ~$1,000/month
# ==============================================================================
