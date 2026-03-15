# ==============================================================================
# EKS Module - Local Values
# ==============================================================================
# This file defines local values for resource naming, tagging, and configuration.
# ==============================================================================

locals {

  # ============================================================================
  # SECTION 1: RESOURCE NAMING (Pattern A)
  # ============================================================================
  # Note: common_prefix = "{customer}-{project}-{environment}"
  # For path-like naming: replace "-" with "/"
  # For EKS cluster names: use PascalCase (no hyphens)

  # Path-like prefix for resources (replace hyphens with slashes)
  path_prefix = replace(var.common_prefix, "-", "/")

  # PascalCase prefix for resource names (capitalize each word, remove hyphens)
  pascal_prefix = join("", [for part in split("-", var.common_prefix) : title(part)])

  # EKS Cluster name (PascalCase)
  cluster_name = "${local.pascal_prefix}Eks"

  # IAM Role Names (PascalCase)
  vpc_cni_role_name              = "${local.pascal_prefix}EksVpcCniRole"
  ebs_csi_role_name              = "${local.pascal_prefix}EksEbsCsiRole"
  ebs_csi_kms_policy_name        = "${local.pascal_prefix}EksEbsCsiKmsPolicy"
  cluster_autoscaler_role_name   = "${local.pascal_prefix}EksClusterAutoscalerRole"
  cluster_autoscaler_policy_name = "${local.pascal_prefix}EksClusterAutoscalerPolicy"
  lb_controller_role_name        = "${local.pascal_prefix}EksLbControllerRole"

  # Get VPC CIDR block
  vpc_cidr = data.aws_vpc.main.cidr_block

  # CloudWatch Dashboard and Alarms
  dashboard_name             = "${var.common_prefix}-eks-monitoring"
  alarm_cluster_failed_nodes = "${var.common_prefix}-eks-cluster-failed-nodes"
  alarm_node_high_cpu        = "${var.common_prefix}-eks-node-high-cpu"

  # ============================================================================
  # SECTION 2: TAG MANAGEMENT (Pattern A)
  # ============================================================================

  # Module-specific tags (only EKS-specific metadata)
  module_tags = {
    TerraformModule   = "forge/aws/compute/eks"
    ClusterName       = local.cluster_name
    KubernetesVersion = "1.31"
    Module            = "EKS"
    Family            = "Compute"
  }

  # Merge common tags from root + module-specific tags
  merged_tags = merge(
    var.common_tags,   # Common tags from root (ManagedBy, Workspace, Region, etc.)
    local.module_tags, # Module-specific tags
  )
}
