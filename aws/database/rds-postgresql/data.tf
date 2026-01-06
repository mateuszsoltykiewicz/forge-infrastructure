# ==============================================================================
# RDS PostgreSQL Module - Data Sources
# ==============================================================================
# This file handles auto-discovery of VPC, EKS, and network resources.
# ==============================================================================

# ------------------------------------------------------------------------------
# Current AWS Region and Account
# ------------------------------------------------------------------------------

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# ------------------------------------------------------------------------------
# VPC Auto-Discovery
# ------------------------------------------------------------------------------

# Auto-discover VPC by tags
data "aws_vpc" "main" {
  tags = merge(
    {
      ManagedBy   = "Terraform"
      Workspace   = var.workspace
      Environment = var.environment
    },
    local.is_customer_cluster ? { Customer = var.customer_name } : {},
    local.is_project_cluster ? { Project = var.project_name } : {}
  )
}

# ------------------------------------------------------------------------------
# Availability Zones
# ------------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

# ------------------------------------------------------------------------------
# EKS Cluster Auto-Discovery (Optional)
# ------------------------------------------------------------------------------

# List all EKS clusters in the account (if no cluster name provided)
data "aws_eks_clusters" "main" {
  count = var.eks_cluster_name == "" ? 1 : 0
}

# Get the first EKS cluster in the account (if auto-discovering)
locals {
  eks_cluster_name = var.eks_cluster_name != "" ? var.eks_cluster_name : (
    length(data.aws_eks_clusters.main) > 0 && length(data.aws_eks_clusters.main[0].names) > 0 ?
    tolist(data.aws_eks_clusters.main[0].names)[0] : ""
  )

  eks_cluster_exists = local.eks_cluster_name != ""
}

# Get EKS cluster details
data "aws_eks_cluster" "discovered" {
  count = local.eks_cluster_exists && var.eks_cluster_name == "" ? 1 : 0
  name  = local.eks_cluster_name
}

data "aws_eks_cluster" "manual" {
  count = local.eks_cluster_exists && var.eks_cluster_name != "" ? 1 : 0
  name  = var.eks_cluster_name
}

# ------------------------------------------------------------------------------
# EKS Node Security Group Discovery
# ------------------------------------------------------------------------------

# Find EKS node security group (for allowing RDS access from EKS pods)
data "aws_security_groups" "eks_nodes" {
  count = local.eks_cluster_exists ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*${local.eks_cluster_name}*node*", "*${local.eks_cluster_name}*Node*"]
  }
}

locals {
  # Get the first matching EKS node security group
  eks_node_security_group_id = local.eks_cluster_exists && length(data.aws_security_groups.eks_nodes[0].ids) > 0 ? (
    data.aws_security_groups.eks_nodes[0].ids[0]
  ) : null
}
