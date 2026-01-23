# ==============================================================================
# Root Module Outputs
# ==============================================================================
# All outputs are passed through from the principal module
# ==============================================================================

# ------------------------------------------------------------------------------
# VPC Outputs
# ------------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.principal.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.principal.vpc_cidr
}

# ------------------------------------------------------------------------------
# Route 53 Outputs
# ------------------------------------------------------------------------------

output "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS records"
  value       = module.principal.route53_zone_id
}

output "route53_zone_name" {
  description = "Route53 hosted zone name (domain)"
  value       = module.principal.route53_zone_name
}

output "route53_name_servers" {
  description = "Name servers for domain delegation"
  value       = module.principal.route53_name_servers
}

# ------------------------------------------------------------------------------
# EKS Outputs
# ------------------------------------------------------------------------------

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.principal.eks_cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS cluster API server"
  value       = module.principal.eks_cluster_endpoint
}

output "eks_cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = module.principal.eks_cluster_version
}

output "eks_kubectl_config_command" {
  description = "Command to update kubeconfig for this cluster"
  value       = module.principal.eks_kubectl_config_command
}

# ------------------------------------------------------------------------------
# ALB Outputs (Per Environment)
# ------------------------------------------------------------------------------

output "alb_dns_names" {
  description = "DNS names of the Application Load Balancers"
  value       = module.principal.alb_dns_names
}

output "alb_arns" {
  description = "ARNs of the Application Load Balancers"
  value       = module.principal.alb_arns
}

output "alb_zone_ids" {
  description = "Route53 zone IDs for the ALBs (for alias records)"
  value       = module.principal.alb_zone_ids
}

# ------------------------------------------------------------------------------
# Redis Outputs
# ------------------------------------------------------------------------------

output "redis_endpoint" {
  description = "Redis primary endpoint address"
  value       = module.principal.redis_endpoint
}

output "redis_subnet_ids" {
  description = "Redis subnet IDs"
  value       = module.principal.redis_subnet_ids
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
  value       = module.principal.s3_logs_bucket_name
}

output "s3_logs_bucket_arn" {
  description = "S3 bucket ARN for HIPAA logs storage"
  value       = module.principal.s3_logs_bucket_arn
}

output "lambda_log_transformer_function_arn" {
  description = "Lambda Log Transformer function ARN"
  value       = module.principal.lambda_log_transformer_function_arn
}

output "firehose_stream_arns" {
  description = "Kinesis Firehose delivery stream ARNs"
  value       = module.principal.firehose_stream_arns
}

output "firehose_stream_names" {
  description = "Kinesis Firehose delivery stream names"
  value       = module.principal.firehose_stream_names
}
