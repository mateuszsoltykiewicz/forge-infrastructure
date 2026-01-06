# ==============================================================================
# Root Module - Outputs
# ==============================================================================
# This file exports essential information about the deployed infrastructure.
# ==============================================================================

# ------------------------------------------------------------------------------
# VPC Outputs
# ------------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.cidr_block
}

# ------------------------------------------------------------------------------
# EKS Outputs
# ------------------------------------------------------------------------------

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = module.eks.cluster_version
}

output "eks_kubectl_config_command" {
  description = "Command to update kubeconfig for this cluster"
  value       = "aws eks update-kubeconfig --region us-east-1 --name ${module.eks.cluster_name}"
}

output "eks_namespaces" {
  description = "List of Kubernetes namespaces created"
  value       = keys(local.eks_namespaces)
}

# ------------------------------------------------------------------------------
# ALB Outputs (Per Environment)
# ------------------------------------------------------------------------------

output "alb_dns_names" {
  description = "DNS names of the Application Load Balancers"
  value = {
    for env_key, alb in module.alb :
    env_key => alb.alb_dns_name
  }
}

output "alb_arns" {
  description = "ARNs of the Application Load Balancers"
  value = {
    for env_key, alb in module.alb :
    env_key => alb.alb_arn
  }
}

output "alb_zone_ids" {
  description = "Route53 zone IDs for the ALBs (for alias records)"
  value = {
    for env_key, alb in module.alb :
    env_key => alb.alb_zone_id
  }
}

# ------------------------------------------------------------------------------
# RDS Outputs
# ------------------------------------------------------------------------------

output "rds_production_endpoint" {
  description = "Production RDS endpoint"
  value       = var.enable_production ? module.rds_production[0].endpoint : null
}

output "rds_production_port" {
  description = "Production RDS port"
  value       = var.enable_production ? module.rds_production[0].port : null
}

output "rds_production_identifier" {
  description = "Production RDS identifier"
  value       = var.enable_production ? module.rds_production[0].db_instance_identifier : null
}

output "rds_staging_endpoint" {
  description = "Staging RDS endpoint (if dedicated)"
  value       = local.create_staging_db && var.enable_staging ? module.rds_staging[0].endpoint : null
}

output "rds_development_endpoint" {
  description = "Development RDS endpoint (if dedicated)"
  value       = local.create_development_db && var.enable_development ? module.rds_development[0].endpoint : null
}

# ------------------------------------------------------------------------------
# Redis Outputs
# ------------------------------------------------------------------------------

output "redis_production_endpoint" {
  description = "Production Redis endpoint"
  value       = var.enable_production ? module.redis_production[0].primary_endpoint_address : null
}

output "redis_production_port" {
  description = "Production Redis port"
  value       = var.enable_production ? module.redis_production[0].port : null
}

output "redis_staging_endpoint" {
  description = "Staging Redis endpoint (if dedicated)"
  value       = local.create_staging_redis && var.enable_staging ? module.redis_staging[0].primary_endpoint_address : null
}

output "redis_development_endpoint" {
  description = "Development Redis endpoint (if dedicated)"
  value       = local.create_development_redis && var.enable_development ? module.redis_development[0].primary_endpoint_address : null
}

# ------------------------------------------------------------------------------
# DNS Configuration Outputs
# ------------------------------------------------------------------------------

output "dns_records_to_create" {
  description = "Route53 DNS records to create manually or via Route53 module"
  value = {
    for env_key, alb in module.alb :
    env_key => {
      name = "${local.all_environments[env_key].subdomain}.${var.domain_name}"
      type = "A"
      alias = {
        name    = alb.alb_dns_name
        zone_id = alb.alb_zone_id
      }
    }
  }
}

# ------------------------------------------------------------------------------
# Environment Configuration Summary
# ------------------------------------------------------------------------------

output "active_environments" {
  description = "List of active environments"
  value       = keys(local.active_environments)
}

output "resource_sharing_summary" {
  description = "Summary of resource sharing configuration"
  value = {
    database = {
      production_shared_with = var.shared_database_environments
      staging_dedicated      = local.create_staging_db
      development_dedicated  = local.create_development_db
    }
    redis = {
      production_shared_with = var.shared_redis_environments
      staging_dedicated      = local.create_staging_redis
      development_dedicated  = local.create_development_redis
    }
  }
}

# ------------------------------------------------------------------------------
# Deployment Instructions
# ------------------------------------------------------------------------------

output "next_steps" {
  description = "Next steps after infrastructure deployment"
  value = <<-EOT
    ========================================
    Infrastructure Deployment Complete!
    ========================================
    
    1. Configure kubectl:
       ${module.eks.kubectl_config_command}
    
    2. Create Route53 DNS records:
       %{for env_key, record in {
  for env_key, alb in module.alb :
  env_key => {
    name   = "${local.all_environments[env_key].subdomain}.${var.domain_name}"
    type   = "A (Alias)"
    target = alb.alb_dns_name
  }
} ~}
       - ${record.name} -> ${record.target} (${record.type})
       %{endfor~}
    
    3. Verify deployment:
       kubectl get namespaces
       kubectl get nodes
       kubectl get svc -n prod-cronus
    
    4. Deploy applications:
       kubectl apply -f manifests/ -n prod-cronus
    
    5. Access endpoints:
       %{for env_key in keys(local.active_environments)~}
       - ${local.all_environments[env_key].subdomain}.${var.domain_name}
       %{endfor~}
    
    ========================================
  EOT
}

# ==============================================================================
# Output Best Practices:
# ==============================================================================
# - Export all critical resource identifiers (IDs, ARNs, endpoints)
# - Provide DNS configuration for manual Route53 setup
# - Include kubectl commands for cluster access
# - Show resource sharing configuration for transparency
# - Provide next steps for deployment verification
# ==============================================================================
