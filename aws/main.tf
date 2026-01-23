# ==============================================================================
# Root Module - Infrastructure Wrapper
# ==============================================================================
# This module calls the plans/principal module with all necessary variables
# ==============================================================================

module "principal" {
  source = "./plans/principal"

  # Project Configuration
  customer_name      = var.customer_name
  project_name       = var.project_name

  # VPC CIDR Configuration
  vpc_cidr           = var.vpc_cidr

  # Domain Configuration
  domain_name           = var.domain_name

  # EKS Configuration
  eks_kubernetes_version  = var.eks_kubernetes_version
  eks_node_instance_types = var.eks_node_instance_types
  eks_node_desired_size   = var.eks_node_desired_size
  eks_node_min_size       = var.eks_node_min_size
  eks_node_max_size       = var.eks_node_max_size

  # RDS Configuration
  rds_instance_class    = var.rds_instance_class
  rds_allocated_storage = var.rds_allocated_storage

  # Redis Configuration
  redis_node_type       = var.redis_node_type
  redis_num_cache_nodes = var.redis_num_cache_nodes

  # Tags
  dr_tags         = var.dr_tags

  # VPN Configuration (Optional)
  vpn_server_certificate_arn        = var.vpn_server_certificate_arn
  vpn_client_root_certificate_arn   = var.vpn_client_root_certificate_arn
  vpn_client_cidr_block             = var.vpn_client_cidr_block
  vpn_dns_servers                   = var.vpn_dns_servers
  vpn_split_tunnel                  = var.vpn_split_tunnel
  vpn_session_timeout_hours         = var.vpn_session_timeout_hours
  vpn_authentication_type           = var.vpn_authentication_type
  vpn_authorize_all_groups          = var.vpn_authorize_all_groups
  vpn_enable_connection_logs        = var.vpn_enable_connection_logs
  vpn_cloudwatch_log_retention_days = var.vpn_cloudwatch_log_retention_days
  vpn_enable_self_service_portal    = var.vpn_enable_self_service_portal

  # Regions configuration
  current_region        = var.current_region
  primary_aws_region    = var.primary_aws_region
  secondary_aws_region  = var.secondary_aws_region

  # Environment Configuration
  environments = var.environments

  # Workspace Configuration
  workspace = var.workspace

  # DR Tenant Name
  dr_tenant = var.dr_tenant

  # DR Type
  dr_type = var.dr_type
}

