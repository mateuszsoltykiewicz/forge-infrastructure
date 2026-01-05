# ==============================================================================
# EKS Module - Local Values
# ==============================================================================
# This file defines local values for resource naming, tagging, and configuration.
# ==============================================================================

locals {
  # ------------------------------------------------------------------------------
  # Cluster Naming
  # ------------------------------------------------------------------------------

  # Generate cluster name based on customer context
  # Shared: forge-{environment}-eks
  # Dedicated: {customer_name}-{region}-eks
  cluster_name = var.cluster_name_override != "" ? var.cluster_name_override : (
    var.architecture_type == "shared"
    ? "forge-${var.environment}-eks"
    : "${var.customer_name}-${var.aws_region}-eks"
  )

  # ------------------------------------------------------------------------------
  # Base Resource Tags
  # ------------------------------------------------------------------------------

  base_tags = {
    Environment      = var.environment
    ManagedBy        = "Terraform"
    TerraformModule  = "forge/modules/compute/eks"
    Region           = var.aws_region
    ClusterName      = local.cluster_name
    KubernetesVersion = var.kubernetes_version
  }

  # ------------------------------------------------------------------------------
  # Customer-Aware Tags
  # ------------------------------------------------------------------------------

  # Add customer tags for dedicated architectures
  customer_tags = var.architecture_type != "shared" && var.customer_id != "" ? {
    CustomerId       = var.customer_id
    CustomerName     = var.customer_name
    ArchitectureType = var.architecture_type
    PlanTier         = var.plan_tier
  } : {}

  # ------------------------------------------------------------------------------
  # Merged Tags
  # ------------------------------------------------------------------------------

  merged_tags = merge(
    local.base_tags,
    local.customer_tags,
    var.tags
  )

  # ------------------------------------------------------------------------------
  # OIDC Provider Configuration
  # ------------------------------------------------------------------------------

  # Extract OIDC provider URL without https:// prefix
  oidc_provider_url = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")

  # OIDC provider ARN for IRSA
  oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_provider_url}"

  # ------------------------------------------------------------------------------
  # Node Group Configuration
  # ------------------------------------------------------------------------------

  # Common launch template user data for all node groups
  node_userdata = base64encode(templatefile("${path.module}/templates/node-userdata.sh.tpl", {
    cluster_name     = local.cluster_name
    cluster_endpoint = aws_eks_cluster.main.endpoint
    cluster_ca       = aws_eks_cluster.main.certificate_authority[0].data
  }))
}
