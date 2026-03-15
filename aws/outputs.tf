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
# Route 53 Outputs
# ------------------------------------------------------------------------------

output "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS records"
  value       = data.aws_route53_zone.main.zone_id
}

output "route53_zone_name" {
  description = "Route53 hosted zone name (domain)"
  value       = data.aws_route53_zone.main.name
}

output "route53_name_servers" {
  description = "Name servers for domain delegation (already configured)"
  value       = data.aws_route53_zone.main.name_servers
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

# ------------------------------------------------------------------------------
# ALB Outputs (Per Environment)
# ------------------------------------------------------------------------------

output "alb_dns_names" {
  description = "DNS names of the Application Load Balancers"
  value       = module.alb.dns_name
}

output "alb_arns" {
  description = "ARNs of the Application Load Balancers"
  value       = module.alb.alb_arn
}

output "alb_zone_ids" {
  description = "Route53 zone IDs for the ALBs (for alias records)"
  value       = module.alb.zone_id
}

# ------------------------------------------------------------------------------
# RDS Outputs
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Redis Outputs
# ------------------------------------------------------------------------------

output "redis_endpoint" {
  description = "Redis primary endpoint address"
  value       = module.redis.replication_group_primary_endpoint_address
}

output "redis_subnet_ids" {
  description = "Redis subnet IDs"
  value       = module.redis.redis_subnet_ids
}

# ------------------------------------------------------------------------------
# ECR Outputs
# ------------------------------------------------------------------------------
# ECR repository managed outside Terraform
# Manual reference: 398456183268.dkr.ecr.us-east-1.amazonaws.com/san-cro-p-use1-lambda-log-transformer-production:latest

# ------------------------------------------------------------------------------
# Observability Outputs (Logging & Monitoring)
# ------------------------------------------------------------------------------

output "s3_logs_bucket_name" {
  description = "S3 bucket name for HIPAA logs storage (primary region)"
  value       = module.s3_hipaa_logs.primary_bucket_id
}

output "s3_logs_bucket_arn" {
  description = "S3 bucket ARN for HIPAA logs storage (primary region)"
  value       = module.s3_hipaa_logs.primary_bucket_arn
}

output "s3_dr_logs_bucket_arn" {
  description = "S3 bucket ARN for HIPAA logs DR storage (secondary region)"
  value       = module.s3_hipaa_logs.dr_bucket_arn
}

output "s3_logs_kms_key_arn" {
  description = "KMS key ARN for S3 HIPAA logs encryption (primary region)"
  value       = module.s3_hipaa_logs.primary_kms_key_arn
}

output "s3_replication_role_arn" {
  description = "IAM role ARN for S3 cross-region replication"
  value       = module.s3_hipaa_logs.replication_role_arn
}

output "firehose_stream_arns" {
  description = "Map of all Kinesis Firehose delivery stream ARNs"
  value = {
    waf                = module.kinesis_firehose.waf_stream_arn
    metrics            = module.kinesis_firehose.metrics_stream_arn
    cloudwatch_generic = module.kinesis_firehose.cloudwatch_generic_stream_arn
  }
}

output "firehose_stream_names" {
  description = "Kinesis Firehose delivery stream names"
  value = {
    waf                = module.kinesis_firehose.waf_stream_name
    metrics            = module.kinesis_firehose.metrics_stream_name
    cloudwatch_generic = module.kinesis_firehose.cloudwatch_generic_stream_name
  }
}

# ==============================================================================
# AWS Client VPN Outputs - DISABLED for initial deployment
# ==============================================================================

# output "vpn_endpoint_id" {
#   description = "ID of AWS Client VPN endpoint"
#   value       = length(module.client_vpn) > 0 ? module.client_vpn[0].vpn_endpoint_id : null
# }
#
# output "vpn_endpoint_arn" {
#   description = "ARN of AWS Client VPN endpoint"
#   value       = length(module.client_vpn) > 0 ? module.client_vpn[0].vpn_endpoint_arn : null
# }
#
# output "vpn_endpoint_dns_name" {
#   description = "DNS name of VPN endpoint for client configuration (.ovpn file)"
#   value       = length(module.client_vpn) > 0 ? module.client_vpn[0].vpn_endpoint_dns_name : null
# }
#
# output "vpn_dashboard_url" {
#   description = "URL to VPN CloudWatch Dashboard for monitoring"
#   value       = length(module.client_vpn) > 0 ? module.client_vpn[0].dashboard_url : null
# }
#
# output "vpn_security_group_id" {
#   description = "Security Group ID for VPN endpoint access"
#   value       = length(module.client_vpn) > 0 ? module.client_vpn[0].security_group_id : null
# }
#
# output "vpn_hipaa_export_enabled" {
#   description = "Whether VPN logs are exported to HIPAA S3 bucket (7-year retention)"
#   value       = length(module.client_vpn) > 0 ? module.client_vpn[0].hipaa_s3_export_enabled : false
# }
#
# output "vpn_cloudwatch_log_group" {
#   description = "CloudWatch Log Group name for VPN connection logs (30-day retention)"
#   value       = length(module.client_vpn) > 0 ? module.client_vpn[0].cloudwatch_log_group_name : null
# }

# ==============================================================================
# Output Best Practices:
# ==============================================================================
# - Export all critical resource identifiers (IDs, ARNs, endpoints)
# - Provide DNS configuration for manual Route53 setup
# - Include kubectl commands for cluster access
# - Show resource sharing configuration for transparency
# - Provide next steps for deployment verification
# ==============================================================================
