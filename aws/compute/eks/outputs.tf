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

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

# ------------------------------------------------------------------------------
# OIDC Provider Outputs (for IRSA)
# ------------------------------------------------------------------------------

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider" {
  description = "OIDC provider URL (without https://)"
  value       = module.eks.oidc_provider
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
  value       = module.eks.node_security_group_id
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
  value       = aws_kms_key.eks.key_id
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for EKS encryption"
  value       = aws_kms_key.eks.arn
}

output "kms_key_alias" {
  description = "The alias of the KMS key used for EKS encryption"
  value       = aws_kms_alias.eks.name
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
    awsRegion = "<AWS_REGION>"  # Set this to your AWS region (e.g., us-east-1)
    rbac = {
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler_irsa[0].arn
        }
      }
    }
  } : null
}
