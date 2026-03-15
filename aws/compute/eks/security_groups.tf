# ==============================================================================
# EKS Module - Security Groups
# ==============================================================================
# Custom security groups for granular control over EKS cluster and node traffic.
# Separates Control Plane and Worker Node security groups for better isolation.
# ==============================================================================

module "eks_security_group" {
  source = "../../security/security-group"

  common_prefix = local.pascal_prefix
  vpc_id        = data.aws_vpc.main.id
  purpose       = "control-plane"
  ports         = [443]

  ingress_rules = [
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.nodes_security_group.security_group_id
      description              = "Allow Kubernetes API access from worker nodes"
    }
  ]

  egress_rules = [
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.nodes_security_group.security_group_id
      description              = "Allow HTTPS to worker nodes (webhooks, admission controllers)"
    },
    {
      from_port                = 10250
      to_port                  = 10250
      protocol                 = "tcp"
      source_security_group_id = module.nodes_security_group.security_group_id
      description              = "Allow kubelet communication to worker nodes"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTPS to internet (ECR, AWS APIs, container registries)"
    }
  ]

  common_tags = var.common_tags
}

module "nodes_security_group" {
  source = "../../security/security-group"

  common_prefix = local.pascal_prefix
  vpc_id        = data.aws_vpc.main.id
  purpose       = "worker-nodes"
  ports         = [443, 10250, 53]

  ingress_rules = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "-1"
      self        = true
      description = "Node to node all traffic (CNI, CoreDNS, inter-pod)"
    },
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.eks_security_group.security_group_id
      description              = "Allow HTTPS from control plane (webhooks)"
    },
    {
      from_port                = 10250
      to_port                  = 10250
      protocol                 = "tcp"
      source_security_group_id = module.eks_security_group.security_group_id
      description              = "Allow kubelet API from control plane"
    }
  ]

  egress_rules = [
    # Control Plane communication
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.eks_security_group.security_group_id
      description              = "Allow HTTPS to EKS control plane"
    },
    # Internet access for external services
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTPS to internet (ECR, Docker Hub, external APIs)"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTP to internet (package managers, repositories)"
    },
    # DNS resolution
    {
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
      description = "Allow DNS queries to VPC resolver"
    },
    # Database access
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
      description = "Allow PostgreSQL to RDS"
    },
    {
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
      description = "Allow Redis to ElastiCache"
    },
    # Node to node communication
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "-1"
      self        = true
      description = "Allow all traffic to other worker nodes (CNI, pod-to-pod)"
    }
  ]

  common_tags = merge(
    var.common_tags,
    {
      "kubernetes.io/cluster/${local.cluster_name}" = "owned"
      "karpenter.sh/discovery"                      = local.cluster_name
    }
  )
}