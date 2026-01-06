# ==============================================================================
# ElastiCache Redis Module - Data Sources for Auto-Discovery
# ==============================================================================
# This file discovers VPC, EKS, and network resources using tags.
# No manual vpc_id, subnet_ids, or security_group_ids required!
# ==============================================================================

# ------------------------------------------------------------------------------
# AWS Account and Partition
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# ------------------------------------------------------------------------------
# VPC Discovery (Multi-Tenant)
# ------------------------------------------------------------------------------

data "aws_vpc" "main" {
  tags = merge(
    {
      ManagedBy   = "Forge"
      Workspace   = var.workspace
      Environment = var.environment
      Region      = var.aws_region
    },
    var.customer_name != "" ? { Customer = var.customer_name } : {},
    var.project_name != "" ? { Project = var.project_name } : {}
  )
}

# ------------------------------------------------------------------------------
# Availability Zones
# ------------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# ------------------------------------------------------------------------------
# EKS Cluster Discovery (for Security Group Integration)
# ------------------------------------------------------------------------------

data "aws_eks_cluster" "main" {
  count = var.eks_cluster_name != "" ? 1 : 0
  name  = var.eks_cluster_name
}

# If EKS cluster name not provided, try to discover by tags
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

# ------------------------------------------------------------------------------
# EKS Node Security Group Discovery
# ------------------------------------------------------------------------------

data "aws_security_groups" "eks_nodes" {
  count = local.eks_cluster_exists ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:kubernetes.io/cluster/${local.eks_cluster_name}"
    values = ["owned"]
  }

  filter {
    name   = "tag:Name"
    values = ["*node*", "*Node*"]
  }
}

locals {
  eks_node_security_group_id = (
    local.eks_cluster_exists &&
    length(data.aws_security_groups.eks_nodes) > 0 &&
    length(data.aws_security_groups.eks_nodes[0].ids) > 0
  ) ? data.aws_security_groups.eks_nodes[0].ids[0] : ""
}
