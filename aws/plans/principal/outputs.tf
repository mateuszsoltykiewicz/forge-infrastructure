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
  value = {
    for idx, env in var.environments :
    env => module.alb.dns_names[idx]
  }
}

output "alb_arns" {
  description = "ARNs of the Application Load Balancers"
  value = {
    for idx, env in var.environments :
    env => module.alb.alb_arns[idx]
  }
}

output "alb_zone_ids" {
  description = "Route53 zone IDs for the ALBs (for alias records)"
  value = {
    for idx, env in var.environments :
    env => module.alb.zone_ids[idx]
  }
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
  description = "S3 bucket name for HIPAA logs storage"
  value       = module.s3_logs.bucket_id
}

output "s3_logs_bucket_arn" {
  description = "S3 bucket ARN for HIPAA logs storage"
  value       = module.s3_logs.bucket_arn
}

output "lambda_log_transformer_function_arn" {
  description = "Lambda Log Transformer function ARN"
  value       = module.lambda_log_transformer.function_arn
}

output "lambda_log_transformer_invoke_arn" {
  description = "Lambda Log Transformer invoke ARN (for Firehose)"
  value       = module.lambda_log_transformer.invoke_arn
}

output "firehose_stream_arns" {
  description = "Map of all Kinesis Firehose delivery stream ARNs"
  value = {
    waf                = module.kinesis_firehose.waf_stream_arn
    vpc                = module.kinesis_firehose.vpc_stream_arn
    rds                = module.kinesis_firehose.rds_stream_arn
    eks_events         = module.kinesis_firehose.eks_events_stream_arn
    eks_pods           = module.kinesis_firehose.eks_pods_stream_arn
    metrics            = module.kinesis_firehose.metrics_stream_arn
    cloudwatch_generic = module.kinesis_firehose.cloudwatch_generic_stream_arn
  }
}

output "firehose_stream_names" {
  description = "Kinesis Firehose delivery stream names"
  value = {
    waf        = module.kinesis_firehose.waf_stream_name
    vpc        = module.kinesis_firehose.vpc_stream_name
    rds        = module.kinesis_firehose.rds_stream_name
    eks_events = module.kinesis_firehose.eks_events_stream_name
    eks_pods   = module.kinesis_firehose.eks_pods_stream_name
    metrics    = module.kinesis_firehose.metrics_stream_name
  }
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
