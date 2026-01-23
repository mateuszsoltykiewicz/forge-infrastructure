module "eks_subnets" {
  source = "../../network/subnet"

  vpc_id             = data.aws_vpc.main.id
  subnet_cidrs       = var.subnet_cidrs
  availability_zones = var.availability_zones

  common_prefix = var.common_prefix
  environment   = "shared"
  purpose       = "eks"

  common_tags = merge(
    var.common_tags,
    {
      Type                                              = "private"
      Tier                                              = "eks"
      "kubernetes.io/role/internal-elb"                 = "1"
      "kubernetes.io/cluster/${local.cluster_name}"     = "owned"
      "karpenter.sh/discovery"                          = local.cluster_name
      "eks.amazonaws.com/cluster/${local.cluster_name}" = "owned"
    }
  )

  # Private subnet routing
  subnet_type             = "private"
  nat_gateway_ids         = var.nat_gateway_ids
  enable_s3_gateway_route = true # Enable S3 Gateway endpoint for ECR access
  s3_gateway_endpoint_id  = var.s3_gateway_endpoint_id
}