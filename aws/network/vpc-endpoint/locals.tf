# ==============================================================================
# VPC Endpoint Module - Local Values
# ==============================================================================
# This file defines local values for computed resource attributes.
# ==============================================================================

locals {

  # ------------------------------------------------------------------------------
  # Service Name Processing
  # ------------------------------------------------------------------------------

  # Determine if this is a standard AWS service or PrivateLink service
  is_aws_service = !can(regex("^com\\.amazonaws\\.vpce\\.", var.service_name))

  # Extract service short name from full service name
  # For AWS services: "com.amazonaws.us-east-1.s3" -> "s3"
  # For PrivateLink: use "privatelink"
  service_short_name = local.is_aws_service ? (
    length(regexall("^com\\.amazonaws\\.[^.]+\\.(.+)$", var.service_name)) > 0 ? (
      regexall("^com\\.amazonaws\\.[^.]+\\.(.+)$", var.service_name)[0][0]
    ) : var.service_name
  ) : "privatelink"

  # Sanitized version of service_short_name for validation-constrained fields
  # Replaces dots with hyphens for use in security group purpose, subnet purpose, etc.
  # Examples: "ecr.api" -> "ecr-api", "ecr.dkr" -> "ecr-dkr"
  service_short_name_sanitized = replace(local.service_short_name, ".", "-")

  # Build full service name for AWS services (com.amazonaws.region.service)
  # For PrivateLink services, use the provided service name as-is
  full_service_name = var.service_name

  # ------------------------------------------------------------------------------
  # Endpoint Naming (Multi-Tenant Pattern)
  # ------------------------------------------------------------------------------

  endpoint_name = "${var.common_prefix}-${local.service_short_name}-vpce"

  # ------------------------------------------------------------------------------
  # Endpoint Type Validation
  # ------------------------------------------------------------------------------

  # Gateway endpoints only support S3 and DynamoDB
  is_gateway_service = contains(["s3", "dynamodb"], local.service_short_name)
  # Interface endpoints support a wide range of services
  is_interface_service = contains([
    "ec2", "ec2messages", "sns", "sqs", "kms", "secretsmanager", "ssm", "ssmmessages",
    "cloudwatch", "logs", "monitoring", "ecr.api", "ecr.dkr", "codebuild",
    "codepipeline", "elasticloadbalancing", "elasticfilesystem", "cloudformation",
    "cloudfront", "appmesh", "appconfig", "sts", "autoscaling", "eks", "eks-auth",
    "lambda", "kinesis-streams", "kinesis-firehose", "rds", "elasticache", "pi"
  ], local.service_short_name)
  # Gateway Load Balancer endpoints support specific services
  is_gwlb_service = contains(["gwlb"], local.service_short_name)


  # Determine endpoint type based on is_gateway_service, is_interface_service, is_gwlb_service
  # there is no var.endpoint_type variable anymore. Following zero config
  # Check which type from local.is_{} is true and assign the endpoint type accordingly
  endpoint_type = local.is_gateway_service ? "Gateway" : local.is_interface_service ? "Interface" : local.is_gwlb_service ? "GatewayLoadBalancer" : "Unknown"

  # Check if endpoint type is valid
  endpoint_type_valid = local.endpoint_type != "Unknown"

  # Validate if subnets are required
  subnets_required_types = ["Interface", "GatewayLoadBalancer"]
  subnets_required       = contains(local.subnets_required_types, local.endpoint_type)
  # Validate if subnets are provided when required
  has_subnets = local.subnets_required ? length(var.subnet_ids) > 0 : true


  # Validate if security groups are required
  security_group_required = local.endpoint_type == "Interface"
  # Has security groups created when required

  # Validate if route tables are required
  route_tables_required = local.endpoint_type == "Gateway"
  # Validate if route tables are provided when required
  has_route_tables = local.route_tables_required ? length(var.route_table_ids) > 0 : true

  # ------------------------------------------------------------------------------
  # Tagging Strategy (Multi-Tenant)
  # ------------------------------------------------------------------------------

  # Base tags applied to all resources
  module_tags = {
    TerraformModule = "forge/aws/network/vpc-endpoint"
    ServiceName     = local.service_short_name
    EndpointType    = local.endpoint_type
    Module          = "VPCEndpoint"
    Family          = "Network"
  }

  # Merge all tags
  merged_tags = merge(
    local.module_tags,
    var.common_tags
  )
}
