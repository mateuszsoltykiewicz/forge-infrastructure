# ==============================================================================
# EKS Module - IAM Roles and Policies
# ==============================================================================
# This file creates IAM roles for:
# - VPC CNI (IRSA)
# - EBS CSI Driver (IRSA)
# - Cluster Autoscaler (IRSA)
# ==============================================================================

# ------------------------------------------------------------------------------
# VPC CNI IAM Role (IRSA)
# ------------------------------------------------------------------------------

resource "aws_iam_role" "vpc_cni_irsa" {
  name = "${local.cluster_name}-vpc-cni-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:aws-node"
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    local.merged_tags,
    {
      Name                           = "${local.cluster_name}-vpc-cni-irsa"
      "eks.amazonaws.com/component"  = "vpc-cni"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  )
}

resource "aws_iam_role_policy_attachment" "vpc_cni_irsa" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni_irsa.name
}

# ------------------------------------------------------------------------------
# EBS CSI Driver IAM Role (IRSA)
# ------------------------------------------------------------------------------

resource "aws_iam_role" "ebs_csi_irsa" {
  name = "${local.cluster_name}-ebs-csi-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    local.merged_tags,
    {
      Name                           = "${local.cluster_name}-ebs-csi-irsa"
      "eks.amazonaws.com/component"  = "ebs-csi-driver"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ebs_csi_irsa" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_irsa.name
}

# Optional: Add KMS permissions if using encrypted volumes
resource "aws_iam_policy" "ebs_csi_kms" {

  name        = "${local.cluster_name}-ebs-csi-kms"
  description = "Additional KMS permissions for EBS CSI driver"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]
        Resource = [module.kms_eks.key_arn]
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = [module.kms_eks.key_arn]
      }
    ]
  })

  tags = local.merged_tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi_kms" {

  policy_arn = aws_iam_policy.ebs_csi_kms.arn
  role       = aws_iam_role.ebs_csi_irsa.name
}

# ------------------------------------------------------------------------------
# Cluster Autoscaler IAM Role (IRSA)
# ------------------------------------------------------------------------------

resource "aws_iam_role" "cluster_autoscaler_irsa" {

  name = "${local.cluster_name}-cluster-autoscaler-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    local.merged_tags,
    {
      Name                           = "${local.cluster_name}-cluster-autoscaler-irsa"
      "eks.amazonaws.com/component"  = "cluster-autoscaler"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  )
}

resource "aws_iam_policy" "cluster_autoscaler" {

  name        = "${local.cluster_name}-cluster-autoscaler"
  description = "IAM policy for Cluster Autoscaler to manage EKS node groups"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ClusterAutoscalerDescribe"
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Sid    = "ClusterAutoscalerModify"
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
          }
        }
      }
    ]
  })

  tags = local.merged_tags
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {

  policy_arn = aws_iam_policy.cluster_autoscaler.arn
  role       = aws_iam_role.cluster_autoscaler_irsa.name
}

# ------------------------------------------------------------------------------
# AWS Load Balancer Controller IAM Role (IRSA)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "${local.cluster_name}-aws-load-balancer-controller-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    local.merged_tags,
    {
      Name                           = "${local.cluster_name}-aws-load-balancer-controller-irsa"
      "eks.amazonaws.com/component"  = "aws-load-balancer-controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  )
}
