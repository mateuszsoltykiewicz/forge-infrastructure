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

  vpc_name      = local.vpc_name
  cidr_block    = var.vpc_cidr
  workspace     = var.workspace
  environment   = "shared" # Single VPC shared by all environments
  customer_name = var.customer_name
  project_name  = var.project_name

  common_tags = local.common_tags
}

# ------------------------------------------------------------------------------
# EKS Module (Single Cluster with Multi-Environment Namespaces)
# ------------------------------------------------------------------------------

module "eks" {
  source = "./compute/eks"

  workspace          = var.workspace
  environment        = "shared" # Single cluster shared by all environments
  customer_name      = var.customer_name != null ? var.customer_name : ""
  project_name       = var.project_name != null ? var.project_name : ""
  kubernetes_version = var.eks_kubernetes_version

  # Namespaces for environment isolation
  namespaces = local.eks_namespaces

  # Node group configuration
  system_node_group_instance_types = var.eks_node_instance_types
  system_node_group_desired_size   = var.eks_node_desired_size
  system_node_group_min_size       = var.eks_node_min_size
  system_node_group_max_size       = var.eks_node_max_size

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
  internal        = false # Public-facing
  ip_address_type = "ipv4"

  # HTTPS configuration
  https_listener = {
    enabled          = true
    port             = 443
    ssl_policy       = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    certificate_arn  = var.alb_certificate_arn
    target_group_key = "eks"
  }

  # HTTP listener (redirect to HTTPS)
  http_listener = {
    enabled        = true
    port           = 80
    redirect_https = true
  }

  # Target group pointing to EKS NodePort
  target_groups = {
    eks = {
      port        = each.value.nodeport
      protocol    = "HTTP"
      target_type = "instance"
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

  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
  engine_version    = "16.4"

  # Resource sharing configuration
  resource_sharing         = local.production_db_config.resource_sharing
  shared_with_environments = local.production_db_config.shared_with_environments

  # High availability for production
  multi_az                = true
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

  instance_class    = "db.r8g.large" # Smaller instance for staging
  allocated_storage = 100
  engine_version    = "16.4"

  # Dedicated staging database
  resource_sharing         = "dedicated"
  shared_with_environments = []

  multi_az                = false
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

  instance_class    = "db.r8g.large" # Smaller instance for dev
  allocated_storage = 50
  engine_version    = "16.4"

  # Dedicated development database
  resource_sharing         = "dedicated"
  shared_with_environments = []

  multi_az                = false
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
  aws_region    = var.aws_region
  customer_name = var.customer_name != null ? var.customer_name : ""
  project_name  = var.project_name != null ? var.project_name : ""

  node_type          = var.redis_node_type
  num_cache_clusters = var.redis_num_cache_nodes
  engine_version     = "7.1"

  # Resource sharing configuration
  resource_sharing         = local.production_redis_config.resource_sharing
  shared_with_environments = local.production_redis_config.shared_with_environments

  # High availability for production
  automatic_failover_enabled = true
  multi_az_enabled           = true

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
  aws_region    = var.aws_region
  customer_name = var.customer_name != null ? var.customer_name : ""
  project_name  = var.project_name != null ? var.project_name : ""

  node_type          = "cache.r7g.large" # Smaller instance for staging
  num_cache_clusters = 1
  engine_version     = "7.1"

  # Dedicated staging Redis
  resource_sharing         = "dedicated"
  shared_with_environments = []

  automatic_failover_enabled = false
  multi_az_enabled           = false

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
  aws_region    = var.aws_region
  customer_name = var.customer_name != null ? var.customer_name : ""
  project_name  = var.project_name != null ? var.project_name : ""

  node_type          = "cache.r7g.large" # Smaller instance for dev
  num_cache_clusters = 1
  engine_version     = "7.1"

  # Dedicated development Redis
  resource_sharing         = "dedicated"
  shared_with_environments = []

  automatic_failover_enabled = false
  multi_az_enabled           = false

  tags = merge(
    local.common_tags,
    {
      Component   = "Redis"
      Environment = "development"
    }
  )

  depends_on = [module.vpc]
}

# ------------------------------------------------------------------------------
# VPC Endpoints (Optional - For Private Deployment)
# ------------------------------------------------------------------------------

# S3 Gateway Endpoint (FREE)
module "vpc_endpoint_s3" {
  source = "./network/vpc-endpoint"
  count  = var.enable_vpc_endpoints ? 1 : 0

  workspace     = var.workspace
  region        = var.aws_region
  environment   = "shared"
  customer_name = var.customer_name
  project_name  = var.project_name

  service_name    = local.vpc_endpoints_config["s3"].service_name
  endpoint_type   = local.vpc_endpoints_config["s3"].endpoint_type
  vpc_id          = module.vpc.vpc_id
  route_table_ids = module.eks.private_route_table_ids

  tags = merge(
    local.common_tags,
    {
      Component = "VPC-Endpoints"
      Service   = "S3"
    }
  )

  depends_on = [module.vpc]
}

# ECR API Interface Endpoint
module "vpc_endpoint_ecr_api" {
  source = "./network/vpc-endpoint"
  count  = var.enable_vpc_endpoints ? 1 : 0

  workspace     = var.workspace
  region        = var.aws_region
  environment   = "shared"
  customer_name = var.customer_name
  project_name  = var.project_name

  service_name        = local.vpc_endpoints_config["ecr_api"].service_name
  endpoint_type       = local.vpc_endpoints_config["ecr_api"].endpoint_type
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.eks.eks_private_subnet_ids
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Component = "VPC-Endpoints"
      Service   = "ECR-API"
    }
  )

  depends_on = [module.vpc]
}

# ECR DKR Interface Endpoint
module "vpc_endpoint_ecr_dkr" {
  source = "./network/vpc-endpoint"
  count  = var.enable_vpc_endpoints ? 1 : 0

  workspace     = var.workspace
  region        = var.aws_region
  environment   = "shared"
  customer_name = var.customer_name
  project_name  = var.project_name

  service_name        = local.vpc_endpoints_config["ecr_dkr"].service_name
  endpoint_type       = local.vpc_endpoints_config["ecr_dkr"].endpoint_type
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.eks.eks_private_subnet_ids
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Component = "VPC-Endpoints"
      Service   = "ECR-DKR"
    }
  )

  depends_on = [module.vpc]
}

# EC2 Interface Endpoint
module "vpc_endpoint_ec2" {
  source = "./network/vpc-endpoint"
  count  = var.enable_vpc_endpoints ? 1 : 0

  workspace     = var.workspace
  region        = var.aws_region
  environment   = "shared"
  customer_name = var.customer_name
  project_name  = var.project_name

  service_name        = local.vpc_endpoints_config["ec2"].service_name
  endpoint_type       = local.vpc_endpoints_config["ec2"].endpoint_type
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.eks.eks_private_subnet_ids
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Component = "VPC-Endpoints"
      Service   = "EC2"
    }
  )

  depends_on = [module.vpc]
}

# EC2 Messages Interface Endpoint
module "vpc_endpoint_ec2messages" {
  source = "./network/vpc-endpoint"
  count  = var.enable_vpc_endpoints ? 1 : 0

  workspace     = var.workspace
  region        = var.aws_region
  environment   = "shared"
  customer_name = var.customer_name
  project_name  = var.project_name

  service_name        = local.vpc_endpoints_config["ec2messages"].service_name
  endpoint_type       = local.vpc_endpoints_config["ec2messages"].endpoint_type
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.eks.eks_private_subnet_ids
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Component = "VPC-Endpoints"
      Service   = "EC2Messages"
    }
  )

  depends_on = [module.vpc]
}

# STS Interface Endpoint
module "vpc_endpoint_sts" {
  source = "./network/vpc-endpoint"
  count  = var.enable_vpc_endpoints ? 1 : 0

  workspace     = var.workspace
  region        = var.aws_region
  environment   = "shared"
  customer_name = var.customer_name
  project_name  = var.project_name

  service_name        = local.vpc_endpoints_config["sts"].service_name
  endpoint_type       = local.vpc_endpoints_config["sts"].endpoint_type
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.eks.eks_private_subnet_ids
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Component = "VPC-Endpoints"
      Service   = "STS"
    }
  )

  depends_on = [module.vpc]
}

# Autoscaling Interface Endpoint
module "vpc_endpoint_autoscaling" {
  source = "./network/vpc-endpoint"
  count  = var.enable_vpc_endpoints ? 1 : 0

  workspace     = var.workspace
  region        = var.aws_region
  environment   = "shared"
  customer_name = var.customer_name
  project_name  = var.project_name

  service_name        = local.vpc_endpoints_config["autoscaling"].service_name
  endpoint_type       = local.vpc_endpoints_config["autoscaling"].endpoint_type
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.eks.eks_private_subnet_ids
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Component = "VPC-Endpoints"
      Service   = "Autoscaling"
    }
  )

  depends_on = [module.vpc]
}

# ELB Interface Endpoint
module "vpc_endpoint_elasticloadbalancing" {
  source = "./network/vpc-endpoint"
  count  = var.enable_vpc_endpoints ? 1 : 0

  workspace     = var.workspace
  region        = var.aws_region
  environment   = "shared"
  customer_name = var.customer_name
  project_name  = var.project_name

  service_name        = local.vpc_endpoints_config["elasticloadbalancing"].service_name
  endpoint_type       = local.vpc_endpoints_config["elasticloadbalancing"].endpoint_type
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.eks.eks_private_subnet_ids
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Component = "VPC-Endpoints"
      Service   = "ELB"
    }
  )

  depends_on = [module.vpc]
}

# CloudWatch Logs Interface Endpoint
module "vpc_endpoint_logs" {
  source = "./network/vpc-endpoint"
  count  = var.enable_vpc_endpoints ? 1 : 0

  workspace     = var.workspace
  region        = var.aws_region
  environment   = "shared"
  customer_name = var.customer_name
  project_name  = var.project_name

  service_name        = local.vpc_endpoints_config["logs"].service_name
  endpoint_type       = local.vpc_endpoints_config["logs"].endpoint_type
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.eks.eks_private_subnet_ids
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Component = "VPC-Endpoints"
      Service   = "CloudWatch-Logs"
    }
  )

  depends_on = [module.vpc]
}

# CloudWatch Monitoring Interface Endpoint
module "vpc_endpoint_monitoring" {
  source = "./network/vpc-endpoint"
  count  = var.enable_vpc_endpoints ? 1 : 0

  workspace     = var.workspace
  region        = var.aws_region
  environment   = "shared"
  customer_name = var.customer_name
  project_name  = var.project_name

  service_name        = local.vpc_endpoints_config["monitoring"].service_name
  endpoint_type       = local.vpc_endpoints_config["monitoring"].endpoint_type
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.eks.eks_private_subnet_ids
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Component = "VPC-Endpoints"
      Service   = "CloudWatch-Monitoring"
    }
  )

  depends_on = [module.vpc]
}

# SSM Interface Endpoint
module "vpc_endpoint_ssm" {
  source = "./network/vpc-endpoint"
  count  = var.enable_vpc_endpoints ? 1 : 0

  workspace     = var.workspace
  region        = var.aws_region
  environment   = "shared"
  customer_name = var.customer_name
  project_name  = var.project_name

  service_name        = local.vpc_endpoints_config["ssm"].service_name
  endpoint_type       = local.vpc_endpoints_config["ssm"].endpoint_type
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.eks.eks_private_subnet_ids
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Component = "VPC-Endpoints"
      Service   = "SSM"
    }
  )

  depends_on = [module.vpc]
}

# KMS Interface Endpoint
module "vpc_endpoint_kms" {
  source = "./network/vpc-endpoint"
  count  = var.enable_vpc_endpoints ? 1 : 0

  workspace     = var.workspace
  region        = var.aws_region
  environment   = "shared"
  customer_name = var.customer_name
  project_name  = var.project_name

  service_name        = local.vpc_endpoints_config["kms"].service_name
  endpoint_type       = local.vpc_endpoints_config["kms"].endpoint_type
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.eks.eks_private_subnet_ids
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Component = "VPC-Endpoints"
      Service   = "KMS"
    }
  )

  depends_on = [module.vpc]
}

# ------------------------------------------------------------------------------
# AWS Client VPN Module (Optional - Private EKS Access)
# ------------------------------------------------------------------------------

module "client_vpn" {
  count  = var.enable_vpn ? 1 : 0
  source = "./network/client-vpn"

  # Multi-tenant configuration
  workspace     = var.workspace
  environment   = "shared"
  customer_name = var.customer_name
  project_name  = var.project_name

  # VPN Configuration
  client_cidr_block     = var.vpn_client_cidr_block
  dns_servers           = var.vpn_dns_servers
  split_tunnel          = var.vpn_split_tunnel
  transport_protocol    = var.vpn_transport_protocol
  session_timeout_hours = var.vpn_session_timeout_hours

  # Authentication (Mutual TLS by default)
  authentication_type         = var.vpn_authentication_type
  server_certificate_arn      = var.vpn_server_certificate_arn
  client_root_certificate_arn = var.vpn_client_root_certificate_arn

  # Network Configuration
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.eks.eks_private_subnet_ids
  vpc_cidr_block = var.vpc_cidr

  # Authorization Rules
  authorize_all_groups = var.vpn_authorize_all_groups

  # Connection Logging
  enable_connection_logs        = var.vpn_enable_connection_logs
  cloudwatch_log_retention_days = var.vpn_cloudwatch_log_retention_days

  # Security Group
  create_security_group = true

  # Self-Service Portal
  enable_self_service_portal = var.vpn_enable_self_service_portal

  tags = merge(
    local.common_tags,
    {
      Component = "VPN"
      Service   = "AWS-Client-VPN"
    }
  )

  depends_on = [module.vpc, module.eks]
}

# ==============================================================================
# Deployment Architecture Summary:
# ==============================================================================
# - VPC: Single shared VPC (10.0.0.0/16)
# - EKS: Single cluster with namespaces (prod-cronus, stag-cronus, dev-cronus)
# - ALB: 3 instances (prod.insighthealth.io, stag.insighthealth.io, dev.insighthealth.io)
# - RDS: 1 production instance (shared by staging/dev)
# - Redis: 1 production instance (shared by staging/dev)
# - VPC Endpoints: 12 endpoints (disabled by default, enable_vpc_endpoints = false)
# - AWS Client VPN: Optional (disabled by default, enable_vpn = false)
#
# Cost Optimization:
# - Sharing RDS/Redis saves ~$600/month
# - Single EKS cluster saves ~$144/month (2 extra control planes)
# - VPC Endpoints disabled: $0/month (enable for +$715/month when using VPN)
# - AWS Client VPN disabled: $0/month (enable for +$73/month base + $36/month per user)
# - Total estimated cost: ~$1,000/month (public endpoint mode)
#
# Private Deployment (Phase 2):
# - Set enable_vpc_endpoints = true
# - Set enable_vpn = true
# - Set eks_endpoint_public_access = false
# - Generate VPN certificates: scripts/generate-vpn-certificates.sh
# - Total cost with VPN + endpoints: ~$1,788/month (1 VPN user)
# ==============================================================================

