# ==============================================================================
# Root Module - Local Values (Environment Logic)
# ==============================================================================
# This file defines local values for multi-environment deployment logic.
# Environments are dynamically enabled/disabled via variables.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Active Environments (Based on Flags)
  # ------------------------------------------------------------------------------

  all_environments = {
    production = {
      enabled    = var.enable_production
      short_name = "prod"
      subdomain  = "prod"
      nodeport   = var.nodeport_production
    }
    staging = {
      enabled    = var.enable_staging
      short_name = "stag"
      subdomain  = "stag"
      nodeport   = var.nodeport_staging
    }
    development = {
      enabled    = var.enable_development
      short_name = "dev"
      subdomain  = "dev"
      nodeport   = var.nodeport_development
    }
  }

  # Filter to only enabled environments
  active_environments = {
    for env_key, env_config in local.all_environments :
    env_key => env_config
    if env_config.enabled
  }

  # ------------------------------------------------------------------------------
  # Resource Sharing Logic
  # ------------------------------------------------------------------------------

  # Production database configuration
  production_db_config = {
    resource_sharing        = "shared"
    shared_with_environments = var.shared_database_environments
  }

  # Production Redis configuration
  production_redis_config = {
    resource_sharing        = "shared"
    shared_with_environments = var.shared_redis_environments
  }

  # Staging and development use production resources (no separate DB/Redis)
  create_staging_db    = !contains(var.shared_database_environments, "staging")
  create_development_db = !contains(var.shared_database_environments, "development")
  
  create_staging_redis    = !contains(var.shared_redis_environments, "staging")
  create_development_redis = !contains(var.shared_redis_environments, "development")

  # ------------------------------------------------------------------------------
  # ALB Target Group Configuration (per environment)
  # ------------------------------------------------------------------------------

  # Each environment gets an ALB pointing to its EKS NodePort
  alb_configs = {
    for env_key, env_config in local.active_environments :
    env_key => {
      subdomain = env_config.subdomain
      nodeport  = env_config.nodeport
      target_group_key = "eks-${env_config.short_name}"
    }
  }

  # ------------------------------------------------------------------------------
  # EKS Namespace Configuration
  # ------------------------------------------------------------------------------

  # Create namespaces for each active environment
  eks_namespaces = {
    for env_key, env_config in local.active_environments :
    "${env_config.short_name}-cronus" => {
      labels = {
        team        = "cronus"
        environment = env_key
        tier        = env_config.short_name
      }
      resource_quota = {
        hard = {
          "requests.cpu"    = env_key == "production" ? "20" : "10"
          "requests.memory" = env_key == "production" ? "40Gi" : "20Gi"
          "pods"            = env_key == "production" ? "100" : "50"
        }
      }
      network_policy = {
        # Production namespace is isolated
        ingress_from_namespaces = env_key == "production" ? [] : [
          "${local.all_environments.production.short_name}-cronus"
        ]
        egress_allowed = true
      }
    }
  }

  # ------------------------------------------------------------------------------
  # VPC Name
  # ------------------------------------------------------------------------------

  vpc_name = var.customer_name != null && var.project_name != null ? (
    "forge-${var.customer_name}-${var.project_name}-vpc"
  ) : var.customer_name != null ? (
    "forge-${var.customer_name}-vpc"
  ) : "forge-vpc"

  # ------------------------------------------------------------------------------
  # Common Tags
  # ------------------------------------------------------------------------------

  common_tags = merge(
    {
      ManagedBy  = "Terraform"
      Workspace  = var.workspace
      DomainName = var.domain_name
    },
    var.customer_name != null ? { Customer = var.customer_name } : {},
    var.project_name != null ? { Project = var.project_name } : {},
    var.tags
  )
}

# ==============================================================================
# Environment Logic Best Practices:
# ==============================================================================
# - Use for_each over active_environments to dynamically deploy resources
# - Share production RDS/Redis with staging/development for cost savings
# - Create separate ALBs per environment for traffic isolation
# - Configure EKS namespaces with resource quotas and network policies
# - Use environment-specific NodePorts for routing (prod=30082, stag=30081, dev=30080)
# ==============================================================================
