# ==============================================================================
# EKS Module - Security Groups
# ==============================================================================
# Custom security groups for granular control over EKS cluster and node traffic.
# Separates Control Plane and Worker Node security groups for better isolation.
# ==============================================================================

module "eks_security_group" {
  source = "../../security/security-group"

  common_prefix = var.common_prefix
  vpc_id        = data.aws_vpc.main.id
  environment   = "shared"

  firewall_tier = "EKSCluster"
  firewall_type = var.firewall_type
  purpose       = "control-plane"
  ports         = [443, 1025, 65535]

  common_tags = var.common_tags
}

module "nodes_security_group" {
  source = "../../security/security-group"

  common_prefix = var.common_prefix
  vpc_id        = data.aws_vpc.main.id
  environment   = "shared"

  firewall_tier = "EKSNodes"
  firewall_type = var.firewall_type
  purpose       = "worker-nodes"
  ports         = [443, 10250, 53]

  # Only self-referencing and VPC CIDR rules (no circular dependencies)
  ingress_rules = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "-1"
      self        = true
      description = "Node to node all traffic (CNI, CoreDNS, inter-pod)"
    }
  ]

  # NOTE: Egress rules are automatically managed by EKS module's recommended rules
  # (node_security_group_enable_recommended_rules = true by default in terraform-aws-modules/eks)
  # The EKS module adds ALL necessary egress rules including:
  # - UDP 53 (DNS to VPC resolver)
  # - TCP 443 (HTTPS for registries, APIs)
  # - TCP 80 (HTTP for package managers)
  # - All protocol egress to 0.0.0.0/0 (full internet access via NAT Gateway)
  # DO NOT add egress_rules here to prevent ResourceConflictException
  egress_rules = []

  common_tags = merge(
    var.common_tags,
    {
      "kubernetes.io/cluster/${local.cluster_name}" = "owned"
      "karpenter.sh/discovery"                      = local.cluster_name
    }
  )
}