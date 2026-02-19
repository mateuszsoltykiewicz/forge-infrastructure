# ==============================================================================
# Compute Infrastructure - EKS Cluster
# ==============================================================================
# Single EKS cluster with multi-environment namespace isolation
# Namespaces: prod-project, stag-project, dev-project
# ==============================================================================

module "eks" {
  source = "../../compute/eks"

  aws_region         = local.current_region
  vpc_id             = module.vpc.vpc_id
  subnet_cidrs       = local.subnet_allocations.eks.cidrs
  availability_zones = local.subnet_allocations.eks.availability_zones

  # Common prefix for naming convention
  common_prefix = local.common_prefix

  # Node group configuration
  system_node_group_instance_types = var.eks_node_instance_types
  system_node_group_desired_size   = var.eks_node_desired_size
  system_node_group_min_size       = var.eks_node_min_size
  system_node_group_max_size       = var.eks_node_max_size

  # Routing configuration
  nat_gateway_ids        = module.nat_gateway.nat_gateway_ids
  s3_gateway_endpoint_id = module.vpc_endpoint_s3.endpoint_id

  # Tags: Environment="Multi-Environment" from tfvars (shared cluster)
  common_tags = local.merged_tags

  # Depends on network infrastructure only
  depends_on = [
    module.vpc,
    module.vpc_endpoint_s3,
    module.vpc_endpoint_ecr_api,
    module.vpc_endpoint_ecr_dkr,
    module.vpc_endpoint_ec2,
    module.vpc_endpoint_ec2messages,
    module.vpc_endpoint_sts,
    module.vpc_endpoint_autoscaling,
    module.vpc_endpoint_elasticloadbalancing,
    module.vpc_endpoint_logs,
    module.vpc_endpoint_monitoring,
    module.vpc_endpoint_ssm,
    module.vpc_endpoint_kms,
    module.vpc_endpoint_eks,
    module.vpc_endpoint_lambda,
    module.vpc_endpoint_kinesis_streams,
    module.vpc_endpoint_kinesis_firehose,
    module.igw,
    module.nat_gateway
  ]
}

# ==============================================================================
# ECR Repository - Lambda Log Transformer
# ==============================================================================
# ECR repository managed outside Terraform (manual or CI/CD)
# Repository: 398456183268.dkr.ecr.us-east-1.amazonaws.com/san-cro-p-use1-lambda-log-transformer-production
# ==============================================================================

# ==============================================================================

# Deployment Architecture Summary
# ==============================================================================
# - VPC: Single shared VPC (10.0.0.0/16)
# - EKS: Single cluster with namespaces (prod-project, stag-project, dev-project)
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
