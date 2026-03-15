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
  source = "./network/vpc"

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
  source = "./network/internet_gateway"

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
  source = "./network/nat-gateway"

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
  source = "./network/subnet"

  vpc_id             = module.vpc.vpc_id
  subnet_cidrs       = local.subnet_allocations.vpc_endpoints.cidrs
  availability_zones = local.subnet_allocations.vpc_endpoints.availability_zones

  common_prefix = local.common_prefix
  purpose       = "vpc-endpoints"

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# ------------------------------------------------------------------------------
# VPC Endpoints - Private AWS Service Access
# ------------------------------------------------------------------------------

# S3 Gateway Endpoint (FREE)
module "vpc_endpoint_s3" {
  source = "./network/vpc-endpoint"

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
  source = "./network/vpc-endpoint"

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
  source = "./network/vpc-endpoint"

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
  source = "./network/vpc-endpoint"

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
  source = "./network/vpc-endpoint"

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
  source = "./network/vpc-endpoint"

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
  source = "./network/vpc-endpoint"

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
  source = "./network/vpc-endpoint"

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
  source = "./network/vpc-endpoint"

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
  source = "./network/vpc-endpoint"

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
  source = "./network/vpc-endpoint"

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
  source = "./network/vpc-endpoint"

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
  source = "./network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["eks"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# Kinesis Streams Interface Endpoint (CRITICAL - CloudWatch subscription filters)
module "vpc_endpoint_kinesis_streams" {
  source = "./network/vpc-endpoint"

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
  source = "./network/vpc-endpoint"

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
  source = "./network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["eks_auth"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc, module.eks]
}

# RDS Interface Endpoint (RDS API operations)
module "vpc_endpoint_rds" {
  source = "./network/vpc-endpoint"

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
  source = "./network/vpc-endpoint"

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
  source = "./network/vpc-endpoint"

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
  source = "./network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["ssmmessages"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# SQS Interface Endpoint (Amazon Simple Queue Service)
module "vpc_endpoint_sqs" {
  source = "./network/vpc-endpoint"

  aws_region    = local.current_region
  vpc_id        = module.vpc.vpc_id
  common_prefix = local.common_prefix
  service_name  = local.vpc_endpoints_config["sqs"].service_name
  subnet_ids    = module.vpc_endpoints_subnets.subnet_ids

  common_tags = local.merged_tags

  depends_on = [module.vpc]
}

# ------------------------------------------------------------------------------
# VPN Certificate Generator - Automated Certificate Management
# ------------------------------------------------------------------------------
# Generates and manages VPN certificates with automatic ACM import and SSM storage
# DISABLED for initial deployment - enable after infrastructure is stable
# ------------------------------------------------------------------------------

# module "vpn_certificates" {
#   source = "./security/vpn-certificate-generator"
#
#   providers = {
#     aws.dr_region = aws.dr_region
#   }
#
#   # Pattern A Variables
#   common_prefix = local.common_prefix
#   common_tags   = local.merged_tags
#
#   # Certificate Configuration
#   cert_common_name   = "vpn.${local.common_prefix}.internal"
#   cert_org_name      = "Forge Platform"
#   cert_validity_days = 730 # 2 years
#
#   # KMS Configuration
#   enable_kms_key_rotation     = true
#   kms_deletion_window_in_days = 30
#
#   # Cross-Region Backup
#   enable_dr_backup = true
#   dr_region        = var.secondary_aws_region
#
#   # IAM Policy for Rotation Job
#   create_rotation_policy = true
# }

# ------------------------------------------------------------------------------
# Client VPN - Optional Private EKS Access
# ------------------------------------------------------------------------------
# Conditional deployment based on certificate availability from vpn_certificates module
# DISABLED for initial deployment - enable after infrastructure is stable
# ------------------------------------------------------------------------------

# module "client_vpn" {
#   count  = module.vpn_certificates.certificates_ready ? 1 : 0
#   source = "./security/client-vpn"
#
#   # VPN Configuration
#   client_cidr_block     = var.vpn_client_cidr_block
#   dns_servers           = var.vpn_dns_servers
#   split_tunnel          = var.vpn_split_tunnel
#   session_timeout_hours = var.vpn_session_timeout_hours
#
#   # Authentication (Mutual TLS by default) - From vpn_certificates module
#   authentication_type         = var.vpn_authentication_type
#   server_certificate_arn      = module.vpn_certificates.server_cert_arn
#   client_root_certificate_arn = module.vpn_certificates.client_ca_arn
#
#   # Network Configuration
#   vpc_id             = module.vpc.vpc_id
#   common_prefix      = local.common_prefix
#   subnet_cidrs       = local.subnet_allocations.client_vpn.cidrs
#   availability_zones = local.subnet_allocations.client_vpn.availability_zones
#
#   # Authorization Rules
#   authorize_all_groups = var.vpn_authorize_all_groups
#
#   # Connection Logging
#   enable_connection_logs        = var.vpn_enable_connection_logs
#   cloudwatch_log_retention_days = var.vpn_cloudwatch_log_retention_days
#
#   # Self-Service Portal
#   enable_self_service_portal = var.vpn_enable_self_service_portal
#
#   # HIPAA S3 Integration (7-year compliance)
#   enable_hipaa_s3_export         = true
#   kinesis_cloudwatch_stream_arn  = aws_kinesis_stream.cloudwatch_logs.arn
#   cloudwatch_to_kinesis_role_arn = aws_iam_role.cloudwatch_to_kinesis.arn
#
#   common_tags = local.merged_tags
#
#   depends_on = [
#     module.vpc,
#     module.vpn_certificates,
#     aws_kinesis_stream.cloudwatch_logs,
#     aws_iam_role.cloudwatch_to_kinesis
#   ]
# }
