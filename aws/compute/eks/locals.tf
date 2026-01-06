# ==============================================================================
# EKS Module - Local Values
# ==============================================================================
# This file defines local values for resource naming, tagging, and configuration.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Cluster Naming (Multi-Tenant)
  # ------------------------------------------------------------------------------

  # Determine cluster ownership model
  is_customer_cluster = var.customer_id != ""
  is_project_cluster  = var.project_name != ""

  # Multi-tenant cluster naming conventions:
  # 1. Shared (platform): forge-{environment}-eks
  # 2. Customer-dedicated: {customer_name}-{environment}-eks
  # 3. Customer + Project: {customer_name}-{project_name}-{environment}-eks
  cluster_name = var.cluster_name_override != "" ? var.cluster_name_override : (
    local.is_customer_cluster && local.is_project_cluster ? "${var.customer_name}-${var.project_name}-${var.environment}-eks" :
    local.is_customer_cluster ? "${var.customer_name}-${var.environment}-eks" :
    "forge-${var.environment}-eks"
  )

  # ------------------------------------------------------------------------------
  # Base Resource Tags
  # ------------------------------------------------------------------------------

  base_tags = {
    Environment       = var.environment
    ManagedBy         = "Terraform"
    TerraformModule   = "forge/aws/compute/eks"
    ClusterName       = local.cluster_name
    KubernetesVersion = var.kubernetes_version
  }

  # ------------------------------------------------------------------------------
  # Multi-Tenant Tags
  # ------------------------------------------------------------------------------

  # Multi-tenant tags (Customer + Project)
  customer_tags = local.is_customer_cluster ? {
    Customer = var.customer_name
  } : {}

  project_tags = local.is_project_cluster ? {
    Project = var.project_name
  } : {}

  # Legacy tags for backward compatibility (CustomerId, PlanTier)
  legacy_tags = merge(
    var.customer_id != "" ? { CustomerId = var.customer_id } : {},
    var.plan_tier != "" ? { PlanTier = var.plan_tier } : {}
  )

  # ------------------------------------------------------------------------------
  # Merged Tags (Multi-Tenant)
  # ------------------------------------------------------------------------------

  merged_tags = merge(
    local.base_tags,
    local.customer_tags,
    local.project_tags,
    local.legacy_tags,
    var.tags
  )
}
