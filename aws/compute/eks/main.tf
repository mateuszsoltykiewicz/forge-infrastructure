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
# KMS Key for EKS Encryption
# ------------------------------------------------------------------------------

module "kms_eks" {
  source = "../../security/kms"

  # Pattern A variables
  common_prefix = var.common_prefix
  common_tags   = var.common_tags

  # Environment context
  environment = "production" # EKS runs in production environment
  region      = var.aws_region

  # KMS Key configuration
  key_purpose     = "eks-cluster"
  key_description = "EKS cluster ${local.cluster_name} encryption (secrets, logs, EBS volumes)"
  key_usage       = "ENCRYPT_DECRYPT"

  # Security settings
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = var.enable_kms_key_rotation

  # Service principals - EKS, CloudWatch Logs, EC2 AutoScaling, EC2
  # autoscaling.amazonaws.com: CRITICAL - Required for ASG to create encrypted EBS volumes in managed node groups
  # ec2.amazonaws.com: RECOMMENDED - For EC2 operations on encrypted volumes
  key_service_roles = [
    "eks.amazonaws.com",
    "logs.amazonaws.com",
    "autoscaling.amazonaws.com", # Required for EKS managed node groups with encrypted EBS
    "ec2.amazonaws.com"          # Best practice for EC2 encrypted volume operations
  ]

  # Root account as administrator
  key_administrators = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
}

# ------------------------------------------------------------------------------
# EKS Cluster
# ------------------------------------------------------------------------------

module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31" # Stable version compatible with AWS provider 5.x

  cluster_name    = local.cluster_name
  cluster_version = "1.31"

  # VPC Configuration (auto-discovered)
  vpc_id                   = data.aws_vpc.main.id
  control_plane_subnet_ids = module.eks_subnets.subnet_ids
  subnet_ids               = module.eks_subnets.subnet_ids

  # Security Groups (managed externally)
  create_cluster_security_group = false
  create_node_security_group    = false

  # Cluster Security Group ID (managed externally)
  cluster_security_group_id = module.eks_security_group.security_group_id

  # Cluster Endpoint Access
  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = true

  # Encryption Configuration
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = module.kms_eks.key_arn
  }

  # CloudWatch Logging
  cluster_enabled_log_types              = var.cluster_enabled_log_types
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id        = module.kms_eks.key_arn

  # IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # Access Management (API & ConfigMap hybrid mode)
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  # Dynamic Access Entries - additional users/roles beyond cluster creator
  # NOTE: Cluster creator is automatically added with admin permissions via enable_cluster_creator_admin_permissions
  access_entries = var.additional_access_entries

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    system = {
      name            = "system-graviton3"
      use_name_prefix = false

      vpc_security_group_ids = [module.nodes_security_group.security_group_id]

      # Instance Configuration
      instance_types = var.system_node_group_instance_types
      capacity_type  = "ON_DEMAND"
      ami_type       = "AL2023_ARM_64_STANDARD" # Graviton3 (m7g.*) requires ARM64 AMI

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
            kms_key_id            = module.kms_eks.key_arn
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
        max_unavailable_percentage = 50
      }

      # Labels
      labels = {
        role                      = "system"
        "node.kubernetes.io/role" = "system"
        workload-type             = "platform"
        managed-by                = "terraform"
      }

      # Taints for system workloads
      taints = {
        system = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }

      # Tags for Cluster Autoscaler Discovery
      tags = {
        "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
        "k8s.io/cluster-autoscaler/enabled"               = "true"
      }

      # IAM
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }
  }

  # EKS Add-ons
  cluster_addons = {
    # CoreDNS
    coredns = {
      addon_version = "v1.11.3-eksbuild.1" # AWS default stable version for EKS 1.31
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
        tolerations = [{
          key      = "CriticalAddonsOnly"
          operator = "Exists"
          effect   = "NoSchedule"
        }]
      })
    }

    # VPC CNI
    vpc-cni = {
      addon_version            = "v1.20.4-eksbuild.2" # AWS default stable version for EKS 1.31
      before_compute           = true
      service_account_role_arn = aws_iam_role.vpc_cni_irsa.arn
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION          = "true"
          ENABLE_POD_ENI                    = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
        tolerations = [{
          key      = "CriticalAddonsOnly"
          operator = "Exists"
          effect   = "NoSchedule"
        }]
      })
    }

    # Kube-proxy
    kube-proxy = {
      addon_version = "v1.31.10-eksbuild.12" # AWS default stable version for EKS 1.31 (includes CVE fixes)
      configuration_values = jsonencode({
        tolerations = [{
          key      = "CriticalAddonsOnly"
          operator = "Exists"
          effect   = "NoSchedule"
        }]
      })
    }

    # EBS CSI Driver
    aws-ebs-csi-driver = {
      addon_version            = "v1.54.0-eksbuild.1" # AWS default stable version for EKS 1.31
      service_account_role_arn = aws_iam_role.ebs_csi_irsa.arn
      configuration_values = jsonencode({
        controller = {
          tolerations = [{
            key      = "CriticalAddonsOnly"
            operator = "Exists"
            effect   = "NoSchedule"
          }]
        }
      })
    }

    # Pod Identity Agent (newer alternative to IRSA)
    eks-pod-identity-agent = {
      addon_version = "v1.3.10-eksbuild.2" # AWS default stable version for EKS 1.31
      configuration_values = jsonencode({
        tolerations = [{
          key      = "CriticalAddonsOnly"
          operator = "Exists"
          effect   = "NoSchedule"
        }]
      })
    }

    # NOTE: AWS Load Balancer Controller is NOT a native EKS addon
    # Install via Helm after cluster creation:
    # helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    #   --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=<IRSA_ROLE_ARN>
    # See scripts/install-aws-load-balancer-controller.sh
  }

  tags = local.merged_tags

  # Ensure subnets are created before EKS cluster
  depends_on = [
    module.eks_subnets,
    module.eks_security_group,
    module.nodes_security_group
  ]
}
