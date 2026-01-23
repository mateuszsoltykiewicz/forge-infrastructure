# ==============================================================================
# EKS Module - Local Values
# ==============================================================================
# This file defines local values for resource naming, tagging, and configuration.
# ==============================================================================

locals {

  # Get VPC CIDR block
  vpc_cidr = data.aws_vpc.main.cidr_block

  # ------------------------------------------------------------------------------
  # EKS Cluster Naming (Multi-Tenant)
  # ------------------------------------------------------------------------------
  cluster_name = "${var.common_prefix}-EKS"

  # ------------------------------------------------------------------------------
  # Resource Tags
  # ------------------------------------------------------------------------------

  # Module-specific tags (only EKS-specific metadata)
  module_tags = {
    TerraformModule   = "forge/aws/compute/eks"
    ClusterName       = local.cluster_name
    KubernetesVersion = "1.31"
    Module            = "EKS"
    Family            = "Compute"
    # CommunicationTier removed - deprecated, use FirewallTier instead
  }

  # Merge common tags from root + module-specific tags
  merged_tags = merge(
    var.common_tags,   # Common tags from root (ManagedBy, Workspace, Region, etc.)
    local.module_tags, # Module-specific tags
  )
}
