# ==============================================================================
# Compute Infrastructure - EKS Cluster
# ==============================================================================
# Single EKS cluster with multi-environment namespace isolation
# Namespaces: prod-cronus, stag-cronus, dev-cronus
# ==============================================================================

module "eks" {
  source = "./compute/eks"

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
    module.vpc_endpoint_kinesis_streams,
    module.vpc_endpoint_kinesis_firehose,
    module.igw,
    module.nat_gateway
  ]
}