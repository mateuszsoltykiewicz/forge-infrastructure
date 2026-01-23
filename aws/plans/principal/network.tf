# ==============================================================================
# Network Infrastructure
# ==============================================================================
# VPC, Internet Gateway, NAT Gateway, VPC Endpoints, and Client VPN
# ==============================================================================

# ------------------------------------------------------------------------------
# VPC - Single Shared VPC
# ------------------------------------------------------------------------------
# CIDR: 10.0.0.0/16
# Supports multi-environment deployment via namespace isolation
# ------------------------------------------------------------------------------

module "vpc" {
  source = "../../network/vpc"

  cidr_block    = var.vpc_cidr
  aws_region    = local.current_region
  common_prefix = local.common_prefix

  common_tags = local.merged_tags
}

# ------------------------------------------------------------------------------
# Internet Gateway
# ------------------------------------------------------------------------------
# Enables public internet access for ALB subnets
# ------------------------------------------------------------------------------

module "igw" {
  source = "../../network/internet_gateway"

  vpc_id        = module.vpc.vpc_id
  aws_region    = local.current_region
  common_prefix = local.common_prefix

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# ------------------------------------------------------------------------------
# NAT Gateway - Private Subnet Egress
# ------------------------------------------------------------------------------
# Creates NAT Gateway(s) in ALB public subnets for EKS pod internet egress
# Scales with AZs (1-3) for high availability
# Cost: ~$32/month per NAT GW + $0.045/GB transfer
# ------------------------------------------------------------------------------

module "nat_gateway" {
  source = "../../network/nat-gateway"

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.alb.subnet_ids
  availability_zones = local.subnet_allocations.alb.availability_zones

  common_prefix = local.common_prefix
  common_tags   = local.merged_tags

  depends_on = [module.vpc]
}

# ------------------------------------------------------------------------------
# VPC Endpoints Subnets
# ------------------------------------------------------------------------------

module "vpc_endpoints_subnets" {
  source = "../../network/subnet"

  vpc_id             = module.vpc.vpc_id
  subnet_cidrs       = local.subnet_allocations.vpc_endpoints.cidrs
  availability_zones = local.subnet_allocations.vpc_endpoints.availability_zones

  common_prefix = local.common_prefix
  environment   = "shared"
  purpose       = "vpc-endpoints"

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# ------------------------------------------------------------------------------
# VPC Endpoints - Private AWS Service Access
# ------------------------------------------------------------------------------

# S3 Gateway Endpoint (FREE)
module "vpc_endpoint_s3" {
  source = "../../network/vpc-endpoint"

  aws_region      = local.current_region
  vpc_id          = module.vpc.vpc_id
  common_prefix   = local.common_prefix
  service_name    = local.vpc_endpoints_config["s3"].service_name
  subnet_ids      = module.vpc_endpoints_subnets.subnet_ids
  route_table_ids = module.vpc_endpoints_subnets.route_table_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# ECR API Interface Endpoint
module "vpc_endpoint_ecr_api" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["ecr_api"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# ECR DKR Interface Endpoint
module "vpc_endpoint_ecr_dkr" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["ecr_dkr"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# EC2 Interface Endpoint
module "vpc_endpoint_ec2" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["ec2"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# EC2 Messages Interface Endpoint
module "vpc_endpoint_ec2messages" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["ec2messages"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# STS Interface Endpoint
module "vpc_endpoint_sts" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["sts"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# Autoscaling Interface Endpoint
module "vpc_endpoint_autoscaling" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["autoscaling"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# ELB Interface Endpoint
module "vpc_endpoint_elasticloadbalancing" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["elasticloadbalancing"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# CloudWatch Logs Interface Endpoint
module "vpc_endpoint_logs" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["logs"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# CloudWatch Monitoring Interface Endpoint
module "vpc_endpoint_monitoring" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["monitoring"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# SSM Interface Endpoint
module "vpc_endpoint_ssm" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["ssm"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# KMS Interface Endpoint
module "vpc_endpoint_kms" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["kms"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# EKS Interface Endpoint
module "vpc_endpoint_eks" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["eks"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# Lambda Interface Endpoint (CRITICAL - Firehose log transformation)
module "vpc_endpoint_lambda" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["lambda"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# Kinesis Streams Interface Endpoint (CRITICAL - CloudWatch subscription filters)
module "vpc_endpoint_kinesis_streams" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["kinesis_streams"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# Kinesis Firehose Interface Endpoint (Firehose delivery streams)
module "vpc_endpoint_kinesis_firehose" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["kinesis_firehose"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# EKS Auth Interface Endpoint (CRITICAL - EKS Pod Identity Agent)
module "vpc_endpoint_eks_auth" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["eks_auth"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# RDS Interface Endpoint (RDS API operations)
module "vpc_endpoint_rds" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["rds"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# ElastiCache Interface Endpoint (ElastiCache API operations)
module "vpc_endpoint_elasticache" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["elasticache"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# RDS Performance Insights Interface Endpoint (RDS Performance Insights)
module "vpc_endpoint_pi" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["pi"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# SSM Messages Interface Endpoint (SSM Session Manager)
module "vpc_endpoint_ssmmessages" {
  source = "../../network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["ssmmessages"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# ------------------------------------------------------------------------------
# Client VPN - Optional Private EKS Access
# ------------------------------------------------------------------------------
# Conditional deployment based on certificate ARN availability
# ------------------------------------------------------------------------------

module "client_vpn" {
  count  = var.vpn_server_certificate_arn != null && var.vpn_client_root_certificate_arn != null ? 1 : 0
  source = "../../security/client-vpn"

  # VPN Configuration
  client_cidr_block     = var.vpn_client_cidr_block
  dns_servers           = var.vpn_dns_servers
  split_tunnel          = var.vpn_split_tunnel
  session_timeout_hours = var.vpn_session_timeout_hours

  # Authentication (Mutual TLS by default)
  authentication_type         = var.vpn_authentication_type
  server_certificate_arn      = var.vpn_server_certificate_arn
  client_root_certificate_arn = var.vpn_client_root_certificate_arn

  # Network Configuration
  vpc_id             = module.vpc.vpc_id
  common_prefix      = local.common_prefix
  subnet_cidrs       = local.subnet_allocations.client_vpn.cidrs
  availability_zones = local.subnet_allocations.client_vpn.availability_zones

  # Authorization Rules
  authorize_all_groups = var.vpn_authorize_all_groups

  # Connection Logging
  enable_connection_logs        = var.vpn_enable_connection_logs
  cloudwatch_log_retention_days = var.vpn_cloudwatch_log_retention_days

  # Self-Service Portal
  enable_self_service_portal = var.vpn_enable_self_service_portal

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}
