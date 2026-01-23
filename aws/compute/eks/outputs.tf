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
  value       = module.eks_subnets.subnet_ids
}

output "eks_private_subnet_cidrs" {
  description = "EKS private subnet CIDR blocks"
  value       = module.eks_subnets.subnet_cidrs
}

output "availability_zones" {
  description = "Availability zones used for EKS subnets"
  value       = module.eks_subnets.availability_zones
}

output "private_route_table_ids" {
  description = "IDs of private route tables for VPC Endpoints (Gateway)"
  value       = module.eks_subnets.route_table_ids
}

# ------------------------------------------------------------------------------
# Security Groups
# ------------------------------------------------------------------------------

output "cluster_security_group_id" {
  description = "Security group ID for EKS cluster control plane"
  value       = module.eks_security_group.security_group_id
}

# ------------------------------------------------------------------------------
# Cluster Outputs
# ------------------------------------------------------------------------------

output "cluster_id" {
  description = "The ID/name of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "The Kubernetes server version of the cluster"
  value       = module.eks.cluster_version
}

output "cluster_platform_version" {
  description = "The platform version of the EKS cluster"
  value       = module.eks.cluster_platform_version
}

# ------------------------------------------------------------------------------
# Node Group Outputs
# ------------------------------------------------------------------------------

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.nodes_security_group.security_group_id
}

output "eks_managed_node_groups" {
  description = "Map of attribute maps for all EKS managed node groups"
  value       = module.eks.eks_managed_node_groups
}

output "eks_managed_node_groups_autoscaling_group_names" {
  description = "List of the autoscaling group names for EKS managed node groups"
  value       = module.eks.eks_managed_node_groups_autoscaling_group_names
}

# ------------------------------------------------------------------------------
# KMS Outputs
# ------------------------------------------------------------------------------

output "kms_key_id" {
  description = "The ID of the KMS key used for EKS encryption"
  value       = module.kms_eks.key_id
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for EKS encryption"
  value       = module.kms_eks.key_arn
}

output "kms_key_alias" {
  description = "The alias of the KMS key used for EKS encryption"
  value       = module.kms_eks.alias_name
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
  value       = aws_iam_role.cluster_autoscaler_irsa.arn
}

output "cluster_autoscaler_irsa_role_name" {
  description = "Name of the Cluster Autoscaler IRSA role (if enabled)"
  value       = aws_iam_role.cluster_autoscaler_irsa.name
}

# ------------------------------------------------------------------------------
# CloudWatch Outputs
# ------------------------------------------------------------------------------

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for cluster logs"
  value       = module.eks.cloudwatch_log_group_name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for cluster logs"
  value       = module.eks.cloudwatch_log_group_arn
}

# ------------------------------------------------------------------------------
# Cluster Add-ons Outputs
# ------------------------------------------------------------------------------

output "cluster_addons" {
  description = "Map of attribute maps for all EKS cluster addons"
  value       = module.eks.cluster_addons
}

# ------------------------------------------------------------------------------
# Access Entries Outputs
# ------------------------------------------------------------------------------

output "access_entries" {
  description = "Map of access entries for cluster access management"
  value       = module.eks.access_entries
}
