# ==============================================================================
# EKS Module - Main EKS Cluster
# ==============================================================================
# This file creates the EKS cluster control plane and managed node groups.
# ==============================================================================

# ------------------------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# ------------------------------------------------------------------------------
# EKS Cluster
# ------------------------------------------------------------------------------

resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.control_plane_subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access_cidrs
    security_group_ids      = var.security_group_ids
  }

  enabled_cluster_log_types = var.enabled_cluster_log_types

  # Enable encryption of Kubernetes secrets using AWS KMS (optional enhancement)
  # encryption_config {
  #   provider {
  #     key_arn = var.kms_key_arn
  #   }
  #   resources = ["secrets"]
  # }

  tags = local.merged_tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_cloudwatch_log_group.cluster,
  ]
}

# ------------------------------------------------------------------------------
# CloudWatch Log Group for Cluster Logs
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_days

  tags = local.merged_tags
}

# ------------------------------------------------------------------------------
# OIDC Provider for IRSA (IAM Roles for Service Accounts)
# ------------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "cluster" {
  count = var.enable_irsa ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster[0].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = local.merged_tags
}

data "tls_certificate" "cluster" {
  count = var.enable_irsa ? 1 : 0
  url   = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# ------------------------------------------------------------------------------
# EKS Managed Node Groups
# ------------------------------------------------------------------------------

resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.cluster_name}-${each.key}"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.node_group_subnet_ids

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.disk_size

  labels = each.value.labels

  # Apply taints if specified
  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  # Ensure that IAM role permissions are created before and deleted after EKS node group
  depends_on = [
    aws_iam_role_policy_attachment.node_group_worker_policy,
    aws_iam_role_policy_attachment.node_group_cni_policy,
    aws_iam_role_policy_attachment.node_group_container_registry,
  ]

  tags = merge(
    local.merged_tags,
    {
      "Name"           = "${local.cluster_name}-${each.key}"
      "NodeGroupType"  = each.key
      "CapacityType"   = each.value.capacity_type
    }
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }
}

# ------------------------------------------------------------------------------
# Customer-Specific Node Groups (Basic Plan Only)
# ------------------------------------------------------------------------------

resource "aws_eks_node_group" "customer" {
  for_each = var.architecture_type == "shared" ? var.customer_node_groups : {}

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.cluster_name}-customer-${each.value.customer_name}"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.node_group_subnet_ids

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.disk_size

  # Customer-specific labels for node selection
  labels = {
    node-role     = "customer"
    customer      = each.value.customer_name
    customer_id   = each.value.customer_id
    plan_tier     = each.value.plan_tier
    workload-type = "application"
    managed-by    = "forge"
  }

  # Taint to prevent non-customer workloads from scheduling
  taint {
    key    = "customer"
    value  = each.value.customer_name
    effect = "NoSchedule"
  }

  # Ensure that IAM role permissions are created before and deleted after EKS node group
  depends_on = [
    aws_iam_role_policy_attachment.node_group_worker_policy,
    aws_iam_role_policy_attachment.node_group_cni_policy,
    aws_iam_role_policy_attachment.node_group_container_registry,
  ]

  tags = merge(
    local.merged_tags,
    {
      "Name"           = "${local.cluster_name}-customer-${each.value.customer_name}"
      "NodeGroupType"  = "customer"
      "CustomerId"     = each.value.customer_id
      "CustomerName"   = each.value.customer_name
      "PlanTier"       = each.value.plan_tier
      "CapacityType"   = each.value.capacity_type
      "CostCenter"     = "Customer:${each.value.customer_id}"
      "BillingEntity"  = each.value.customer_name
    }
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }
}

# ------------------------------------------------------------------------------
# EKS Add-ons
# ------------------------------------------------------------------------------

# EBS CSI Driver (for persistent volumes)
resource "aws_eks_addon" "ebs_csi_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.37.0-eksbuild.1" # Latest as of Dec 2024
  service_account_role_arn = var.enable_irsa ? aws_iam_role.ebs_csi_driver[0].arn : null

  tags = local.merged_tags

  depends_on = [aws_eks_node_group.main]
}

# VPC CNI (for pod networking)
resource "aws_eks_addon" "vpc_cni" {
  count = var.enable_vpc_cni ? 1 : 0

  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "vpc-cni"
  addon_version = "v1.19.0-eksbuild.1" # Latest as of Dec 2024

  tags = local.merged_tags

  depends_on = [aws_eks_node_group.main]
}

# kube-proxy (for network proxying)
resource "aws_eks_addon" "kube_proxy" {
  count = var.enable_kube_proxy ? 1 : 0

  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "kube-proxy"
  addon_version = "v1.31.2-eksbuild.3" # Latest as of Dec 2024

  tags = local.merged_tags

  depends_on = [aws_eks_node_group.main]
}

# CoreDNS (for DNS resolution)
resource "aws_eks_addon" "coredns" {
  count = var.enable_coredns ? 1 : 0

  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "coredns"
  addon_version = "v1.11.3-eksbuild.2" # Latest as of Dec 2024

  tags = local.merged_tags

  depends_on = [aws_eks_node_group.main]
}
