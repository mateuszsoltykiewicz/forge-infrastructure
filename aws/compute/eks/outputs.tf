# ==============================================================================
# EKS Module - Outputs
# ==============================================================================
# This file exports essential information about the created EKS cluster.
# ==============================================================================

# ------------------------------------------------------------------------------
# Cluster Outputs
# ------------------------------------------------------------------------------

output "cluster_id" {
  description = "The ID/name of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "The Kubernetes server version of the cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_platform_version" {
  description = "The platform version of the EKS cluster"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

# ------------------------------------------------------------------------------
# OIDC Provider Outputs (for IRSA)
# ------------------------------------------------------------------------------

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC issuer"
  value       = try(aws_eks_cluster.main.identity[0].oidc[0].issuer, "")
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = try(aws_iam_openid_connect_provider.cluster[0].arn, "")
}

output "oidc_provider_url" {
  description = "OIDC provider URL without https:// prefix (for IRSA trust policies)"
  value       = local.oidc_provider_url
}

# ------------------------------------------------------------------------------
# Security Group Outputs
# ------------------------------------------------------------------------------

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

# ------------------------------------------------------------------------------
# IAM Role Outputs
# ------------------------------------------------------------------------------

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = aws_iam_role.cluster.name
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN of the EKS node groups"
  value       = aws_iam_role.node_group.arn
}

output "node_group_iam_role_name" {
  description = "IAM role name of the EKS node groups"
  value       = aws_iam_role.node_group.name
}

output "ebs_csi_driver_iam_role_arn" {
  description = "IAM role ARN for the EBS CSI driver (IRSA)"
  value       = try(aws_iam_role.ebs_csi_driver[0].arn, "")
}

# ------------------------------------------------------------------------------
# Node Group Outputs
# ------------------------------------------------------------------------------

output "node_groups" {
  description = "Map of node group names to their attributes"
  value = {
    for k, ng in aws_eks_node_group.main : k => {
      id                = ng.id
      arn               = ng.arn
      status            = ng.status
      capacity_type     = ng.capacity_type
      instance_types    = ng.instance_types
      scaling_config    = ng.scaling_config
      node_group_name   = ng.node_group_name
    }
  }
}

output "customer_node_groups" {
  description = "Map of customer node group names to their attributes (Basic plan customers only)"
  value = {
    for k, ng in aws_eks_node_group.customer : k => {
      id                = ng.id
      arn               = ng.arn
      status            = ng.status
      capacity_type     = ng.capacity_type
      instance_types    = ng.instance_types
      scaling_config    = ng.scaling_config
      node_group_name   = ng.node_group_name
      customer_id       = ng.tags["CustomerId"]
      customer_name     = ng.tags["CustomerName"]
      plan_tier         = ng.tags["PlanTier"]
    }
  }
}

# ------------------------------------------------------------------------------
# CloudWatch Outputs
# ------------------------------------------------------------------------------

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for EKS cluster logs"
  value       = aws_cloudwatch_log_group.cluster.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for EKS cluster logs"
  value       = aws_cloudwatch_log_group.cluster.arn
}

# ------------------------------------------------------------------------------
# Connection Information
# ------------------------------------------------------------------------------

output "kubeconfig_command" {
  description = "Command to update kubeconfig for kubectl access"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}
