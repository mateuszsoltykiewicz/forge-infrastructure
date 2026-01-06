# ==============================================================================
# EKS Module - Dedicated Subnets
# ==============================================================================
# This file creates dedicated subnets for EKS:
# - Private subnets for EKS nodes (with NAT Gateway routing)
# - Public subnets for NAT Gateways (temporary, can be removed later)
#
# Subnets are distributed across available AZs with proper tagging for:
# - Kubernetes auto-discovery
# - Karpenter discovery
# - AWS Load Balancer Controller
# ==============================================================================

# ------------------------------------------------------------------------------
# Calculate Subnet CIDR Blocks
# ------------------------------------------------------------------------------

locals {
  # Get VPC CIDR block
  vpc_cidr = data.aws_vpc.main.cidr_block

  # Calculate number of AZs to use (minimum 2, maximum 3)
  az_count = min(var.eks_subnet_az_count, length(data.aws_availability_zones.available.names))

  # Selected AZs for EKS subnets
  azs = slice(data.aws_availability_zones.available.names, 0, local.az_count)

  # Calculate subnet CIDR blocks based on VPC CIDR
  # Example: VPC 10.0.0.0/16:
  #   - Public subnets:  10.0.0.0/24, 10.0.1.0/24, 10.0.2.0/24  (256 IPs each)
  #   - Private subnets: 10.0.32.0/19, 10.0.64.0/19, 10.0.96.0/19 (8,192 IPs each)

  # Public subnets for NAT Gateway (small /24 blocks)
  public_subnet_cidrs = [
    for idx in range(local.az_count) :
    cidrsubnet(local.vpc_cidr, 8, idx)
  ]

  # Private subnets for EKS nodes (large /19 blocks)
  # Each subnet gets /19 (8,192 IPs) which is enough for ~500 nodes with prefix delegation
  eks_subnet_cidrs = [
    for idx in range(local.az_count) :
    cidrsubnet(local.vpc_cidr, var.eks_subnet_newbits, var.eks_subnet_netnum_start + idx)
  ]
}

# ------------------------------------------------------------------------------
# Internet Gateway (for NAT Gateway)
# ------------------------------------------------------------------------------

data "aws_internet_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# ------------------------------------------------------------------------------
# Public Subnets (for NAT Gateway)
# ------------------------------------------------------------------------------

resource "aws_subnet" "eks_public" {
  count = var.enable_nat_gateway ? local.az_count : 0

  vpc_id                  = data.aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.cluster_name}-public-${local.azs[count.index]}"
      Type = "public"
      Tier = "eks-nat"

      # Kubernetes public subnet tag
      "kubernetes.io/role/elb" = "1"
    }
  )
}

# ------------------------------------------------------------------------------
# Public Route Table
# ------------------------------------------------------------------------------

resource "aws_route_table" "eks_public" {
  count = var.enable_nat_gateway ? 1 : 0

  vpc_id = data.aws_vpc.main.id

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.cluster_name}-public"
      Type = "public"
    }
  )
}

resource "aws_route" "eks_public_internet" {
  count = var.enable_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.eks_public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = data.aws_internet_gateway.main[0].id
}

resource "aws_route_table_association" "eks_public" {
  count = var.enable_nat_gateway ? local.az_count : 0

  subnet_id      = aws_subnet.eks_public[count.index].id
  route_table_id = aws_route_table.eks_public[0].id
}

# ------------------------------------------------------------------------------
# EKS Private Subnets
# ------------------------------------------------------------------------------

resource "aws_subnet" "eks_private" {
  count = local.az_count

  vpc_id                  = data.aws_vpc.main.id
  cidr_block              = local.eks_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  # Enable auto-assign IPv6 if VPC has IPv6
  ipv6_cidr_block                 = var.enable_ipv6 && data.aws_vpc.main.ipv6_cidr_block != null ? cidrsubnet(data.aws_vpc.main.ipv6_cidr_block, 8, var.eks_subnet_netnum_start + count.index) : null
  assign_ipv6_address_on_creation = var.enable_ipv6 && data.aws_vpc.main.ipv6_cidr_block != null

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.cluster_name}-private-${local.azs[count.index]}"
      Type = "private"
      Tier = "eks"

      # Kubernetes auto-discovery tags
      "kubernetes.io/role/internal-elb"             = "1"
      "kubernetes.io/cluster/${local.cluster_name}" = var.kubernetes_cluster_tag_value

      # Karpenter discovery tag
      "karpenter.sh/discovery" = local.cluster_name

      # EKS-specific tag
      "eks.amazonaws.com/cluster/${local.cluster_name}" = "owned"
    }
  )
}

# ------------------------------------------------------------------------------
# NAT Gateway EIP
# ------------------------------------------------------------------------------

resource "aws_eip" "eks_nat" {
  count = var.enable_nat_gateway ? local.az_count : 0

  domain = "vpc"

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.cluster_name}-nat-eip-${local.azs[count.index]}"
      Type = "nat-gateway"
    }
  )

  depends_on = [data.aws_internet_gateway.main]
}

# ------------------------------------------------------------------------------
# NAT Gateway
# ------------------------------------------------------------------------------

# Note: This creates NAT Gateways for temporary public access during setup
# Can be destroyed after cluster is operational to save costs (~$32/month per NAT Gateway)

resource "aws_nat_gateway" "eks" {
  count = var.enable_nat_gateway ? local.az_count : 0

  allocation_id = aws_eip.eks_nat[count.index].id
  subnet_id     = aws_subnet.eks_public[count.index].id

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.cluster_name}-nat-${local.azs[count.index]}"
      Type = "nat-gateway"
    }
  )

  depends_on = [aws_eip.eks_nat]
}

# ------------------------------------------------------------------------------
# Private Route Tables (one per AZ for NAT Gateway)
# ------------------------------------------------------------------------------

resource "aws_route_table" "eks_private" {
  count = local.az_count

  vpc_id = data.aws_vpc.main.id

  tags = merge(
    local.merged_tags,
    {
      Name = "${local.cluster_name}-private-${local.azs[count.index]}"
      Type = "private"
    }
  )
}

resource "aws_route" "eks_private_nat" {
  count = var.enable_nat_gateway ? local.az_count : 0

  route_table_id         = aws_route_table.eks_private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.eks[count.index].id
}

resource "aws_route_table_association" "eks_private" {
  count = local.az_count

  subnet_id      = aws_subnet.eks_private[count.index].id
  route_table_id = aws_route_table.eks_private[count.index].id
}
