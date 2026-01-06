# ==============================================================================
# EKS Module - Outputs
# ==============================================================================
# This file exports essential information about the created EKS cluster.
# ==============================================================================

# ------------------------------------------------------------------------------
# Network Outputs
# ------------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID (auto-discovered)"
  value       = data.aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block (auto-discovered)"
  value       = data.aws_vpc.main.cidr_block
}

output "eks_private_subnet_ids" {
  description = "EKS private subnet IDs created by this module"
  value       = aws_subnet.eks_private[*].id
}

output "eks_private_subnet_cidrs" {
  description = "EKS private subnet CIDR blocks"
  value       = aws_subnet.eks_private[*].cidr_block
}

output "eks_public_subnet_ids" {
  description = "EKS public subnet IDs (for NAT Gateway)"
  value       = var.enable_nat_gateway ? aws_subnet.eks_public[*].id : []
}

output "eks_public_subnet_cidrs" {
  description = "EKS public subnet CIDR blocks"
  value       = var.enable_nat_gateway ? aws_subnet.eks_public[*].cidr_block : []
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs (if enabled)"
  value       = var.enable_nat_gateway ? aws_nat_gateway.eks[*].id : []
}

output "nat_gateway_eips" {
  description = "NAT Gateway Elastic IP addresses"
  value       = var.enable_nat_gateway ? aws_eip.eks_nat[*].public_ip : []
}

output "availability_zones" {
  description = "Availability zones used for EKS subnets"
  value       = aws_subnet.eks_private[*].availability_zone
}

output "private_route_table_ids" {
  description = "IDs of private route tables for VPC Endpoints (Gateway)"
  value       = aws_route_table.eks_private[*].id
}

output "public_route_table_id" {
  description = "ID of public route table for VPC Endpoints (Gateway)"
  value       = var.enable_nat_gateway ? aws_route_table.eks_public[0].id : null
}

# ------------------------------------------------------------------------------
# Cluster Outputs
# ------------------------------------------------------------------------------

output "cluster_id" {
  description = "The ID/name of the EKS cluster"
  value       = var.create ? module.eks.cluster_id : null
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = var.create ? module.eks.cluster_arn : null
}

output "project_name" {
  description = "Project name (if applicable)"
  value       = var.project_name != "" ? var.project_name : null
}

output "customer_name" {
  description = "Customer name (if applicable)"
  value       = var.customer_name != "" ? var.customer_name : null
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = var.create ? module.eks.cluster_name : null
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster API server"
  value       = var.create ? module.eks.cluster_endpoint : null
}

output "cluster_version" {
  description = "The Kubernetes server version of the cluster"
  value       = var.create ? module.eks.cluster_version : null
}

output "cluster_platform_version" {
  description = "The platform version of the EKS cluster"
  value       = var.create ? module.eks.cluster_platform_version : null
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = var.create ? module.eks.cluster_certificate_authority_data : null
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = var.create ? module.eks.cluster_security_group_id : null
}

# ------------------------------------------------------------------------------
# OIDC Provider Outputs (for IRSA)
# ------------------------------------------------------------------------------

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  value       = var.create ? module.eks.oidc_provider_arn : null
}

output "oidc_provider" {
  description = "OIDC provider URL (without https://)"
  value       = var.create ? module.eks.oidc_provider : null
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = try(module.eks.cluster_oidc_issuer_url, "")
}

# ------------------------------------------------------------------------------
# Node Group Outputs
# ------------------------------------------------------------------------------

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = var.create ? module.eks.node_security_group_id : null
}

output "eks_managed_node_groups" {
  description = "Map of attribute maps for all EKS managed node groups"
  value       = var.create ? module.eks.eks_managed_node_groups : null
}

output "eks_managed_node_groups_autoscaling_group_names" {
  description = "List of the autoscaling group names for EKS managed node groups"
  value       = var.create ? module.eks.eks_managed_node_groups_autoscaling_group_names : null
}

# ------------------------------------------------------------------------------
# KMS Outputs
# ------------------------------------------------------------------------------

output "kms_key_id" {
  description = "The ID of the KMS key used for EKS encryption"
  value       = var.create ? aws_kms_key.eks[0].key_id : null
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for EKS encryption"
  value       = var.create ? aws_kms_key.eks[0].arn : null
}

output "kms_key_alias" {
  description = "The alias of the KMS key used for EKS encryption"
  value       = var.create ? aws_kms_alias.eks[0].name : null
}

# ------------------------------------------------------------------------------
# IAM Role Outputs (IRSA)
# ------------------------------------------------------------------------------

output "vpc_cni_irsa_role_arn" {
  description = "ARN of the VPC CNI IRSA role"
  value       = aws_iam_role.vpc_cni_irsa.arn
}

output "vpc_cni_irsa_role_name" {
  description = "Name of the VPC CNI IRSA role"
  value       = aws_iam_role.vpc_cni_irsa.name
}

output "ebs_csi_irsa_role_arn" {
  description = "ARN of the EBS CSI IRSA role"
  value       = aws_iam_role.ebs_csi_irsa.arn
}

output "ebs_csi_irsa_role_name" {
  description = "Name of the EBS CSI IRSA role"
  value       = aws_iam_role.ebs_csi_irsa.name
}

output "cluster_autoscaler_irsa_role_arn" {
  description = "ARN of the Cluster Autoscaler IRSA role (if enabled)"
  value       = var.enable_cluster_autoscaler_iam ? aws_iam_role.cluster_autoscaler_irsa[0].arn : null
}

output "cluster_autoscaler_irsa_role_name" {
  description = "Name of the Cluster Autoscaler IRSA role (if enabled)"
  value       = var.enable_cluster_autoscaler_iam ? aws_iam_role.cluster_autoscaler_irsa[0].name : null
}

# ------------------------------------------------------------------------------
# CloudWatch Outputs
# ------------------------------------------------------------------------------

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for cluster logs"
  value       = var.create ? module.eks.cloudwatch_log_group_name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for cluster logs"
  value       = var.create ? module.eks.cloudwatch_log_group_arn : null
}

# ------------------------------------------------------------------------------
# Cluster Add-ons Outputs
# ------------------------------------------------------------------------------

output "cluster_addons" {
  description = "Map of attribute maps for all EKS cluster addons"
  value       = var.create ? module.eks.cluster_addons : null
}

# ------------------------------------------------------------------------------
# Access Entries Outputs
# ------------------------------------------------------------------------------

output "access_entries" {
  description = "Map of access entries for cluster access management"
  value       = var.create ? module.eks.access_entries : null
}

# ------------------------------------------------------------------------------
# Useful Commands Output
# ------------------------------------------------------------------------------

output "kubectl_config_command" {
  description = "Command to update kubeconfig for this cluster"
  value       = "aws eks update-kubeconfig --region <AWS_REGION> --name ${module.eks.cluster_name}"
}

output "cluster_autoscaler_helm_values" {
  description = "Helm values for installing Cluster Autoscaler (if IAM role created)"
  value = var.enable_cluster_autoscaler_iam ? {
    autoDiscovery = {
      clusterName = module.eks.cluster_name
    }
    awsRegion = "<AWS_REGION>" # Set this to your AWS region (e.g., us-east-1)
    rbac = {
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler_irsa[0].arn
        }
      }
    }
  } : null
}
