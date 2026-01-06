# ==============================================================================
# EKS Module - Production-Grade Kubernetes Cluster
# ==============================================================================
# This module creates a production-ready EKS cluster using the official
# terraform-aws-modules/eks/aws module with:
# - Graviton3 managed node groups with Cluster Autoscaler support
# - KMS encryption for secrets
# - IRSA and Pod Identity Agent
# - Comprehensive security groups
# - CloudWatch logging with encryption
# - Dynamic access management
# ==============================================================================

# ------------------------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# ------------------------------------------------------------------------------
# KMS Key for EKS Encryption
# ------------------------------------------------------------------------------

resource "aws_kms_key" "eks" {
  description             = "EKS cluster ${local.cluster_name} encryption key"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = var.enable_kms_key_rotation

  tags = merge(
    local.merged_tags,
    {
      Name    = "${local.cluster_name}-eks-encryption"
      Purpose = "EKS Secrets Encryption"
    }
  )
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${local.cluster_name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# ------------------------------------------------------------------------------
# EKS Cluster
# ------------------------------------------------------------------------------

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"  # Updated to support AWS provider >= 6.0

  name               = local.cluster_name
  kubernetes_version = var.kubernetes_version

  # VPC Configuration (auto-discovered)
  vpc_id                   = data.aws_vpc.main.id
  subnet_ids               = aws_subnet.eks_private[*].id
  control_plane_subnet_ids = aws_subnet.eks_private[*].id

  # Cluster Endpoint Access
  endpoint_public_access       = var.cluster_endpoint_public_access
  endpoint_private_access      = var.cluster_endpoint_private_access
  endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Encryption Configuration
  encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = aws_kms_key.eks.arn
  }

  # CloudWatch Logging
  enabled_log_types                      = var.cluster_enabled_log_types
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id        = aws_kms_key.eks.arn

  # IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # Access Management (API & ConfigMap hybrid mode)
  authentication_mode                      = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = true

  # Dynamic Access Entries - automatically add Terraform caller as admin
  access_entries = merge(
    {
      # Current Terraform caller (user or role executing terraform apply)
      terraform_caller = {
        principal_arn = data.aws_caller_identity.current.arn

        policy_associations = {
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    },
    var.additional_access_entries
  )

  # Cluster Security Group
  security_group_additional_rules = {
    ingress_nodes_ephemeral = {
      description                = "Nodes to cluster API (ephemeral ports)"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  # Node Security Group
  node_security_group_additional_rules = {
    # Inter-node communication
    ingress_self_all = {
      description = "Node to node all traffic"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }

    # Control plane to nodes (webhooks)
    ingress_cluster_443 = {
      description                   = "Cluster to node 443 (webhooks)"
      protocol                      = "tcp"
      from_port                     = 443
      to_port                       = 443
      type                          = "ingress"
      source_cluster_security_group = true
    }

    # Control plane to nodes (kubelet)
    ingress_cluster_kubelet = {
      description                   = "Cluster to node kubelet"
      protocol                      = "tcp"
      from_port                     = 10250
      to_port                       = 10250
      type                          = "ingress"
      source_cluster_security_group = true
    }

    # CoreDNS TCP
    ingress_cluster_coredns_tcp = {
      description                   = "Cluster to node CoreDNS TCP"
      protocol                      = "tcp"
      from_port                     = 53
      to_port                       = 53
      type                          = "ingress"
      source_cluster_security_group = true
    }

    # CoreDNS UDP
    ingress_cluster_coredns_udp = {
      description                   = "Cluster to node CoreDNS UDP"
      protocol                      = "udp"
      from_port                     = 53
      to_port                       = 53
      type                          = "ingress"
      source_cluster_security_group = true
    }

    # Egress all
    egress_all = {
      description = "Node all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    system = {
      name            = "system-graviton3"
      use_name_prefix = false

      # Instance Configuration
      instance_types = var.system_node_group_instance_types
      capacity_type  = var.system_node_group_capacity_type

      # Scaling Configuration
      min_size     = var.system_node_group_min_size
      max_size     = var.system_node_group_max_size
      desired_size = var.system_node_group_desired_size

      # Disk Configuration with Encryption
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.system_node_group_disk_size
            volume_type           = var.system_node_group_disk_type
            iops                  = var.system_node_group_disk_iops
            throughput            = var.system_node_group_disk_throughput
            encrypted             = true
            kms_key_id            = aws_kms_key.eks.arn
            delete_on_termination = true
          }
        }
      }

      # IMDSv2 - Security Best Practice (prevents SSRF attacks)
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required" # IMDSv2 only
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "enabled"
      }

      # Update Strategy
      update_config = {
        max_unavailable_percentage = 33
      }

      # Labels
      labels = {
        role                      = "system"
        "node.kubernetes.io/role" = "system"
        workload-type             = "platform"
        managed-by                = "terraform"
      }

      # Taints for system workloads
      taints = var.enable_system_node_taints ? {
        system = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      } : {}

      # Tags for Cluster Autoscaler Discovery
      tags = {
        "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
        "k8s.io/cluster-autoscaler/enabled"               = "true"
      }

      # IAM
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      # Bootstrap User Data (optional customization)
      enable_bootstrap_user_data = var.enable_bootstrap_user_data
      pre_bootstrap_user_data    = var.pre_bootstrap_user_data
    }
  }

  # EKS Add-ons
  addons = {
    # CoreDNS
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        resources = {
          limits = {
            cpu    = "100m"
            memory = "150Mi"
          }
          requests = {
            cpu    = "100m"
            memory = "150Mi"
          }
        }
      })
    }

    # VPC CNI
    vpc-cni = {
      most_recent              = true
      before_compute           = true
      service_account_role_arn = aws_iam_role.vpc_cni_irsa.arn
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION          = "true"
          ENABLE_POD_ENI                    = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
      })
    }

    # Kube-proxy
    kube-proxy = {
      most_recent = true
    }

    # EBS CSI Driver
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = aws_iam_role.ebs_csi_irsa.arn
    }

    # Pod Identity Agent (newer alternative to IRSA)
    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  tags = local.merged_tags

  # Ensure subnets are created before EKS cluster
  depends_on = [
    aws_subnet.eks_private,
    aws_route_table_association.eks_private
  ]
}
