# ==============================================================================
# Route 53 Hosted Zone Module - Main Resources
# ==============================================================================
# This file defines the Route 53 hosted zone and associated resources.
# ==============================================================================

# ------------------------------------------------------------------------------
# Route 53 Hosted Zone
# ------------------------------------------------------------------------------

resource "aws_route53_zone" "this" {
  count = var.create ? 1 : 0

  name              = local.zone_name
  comment           = local.auto_comment
  delegation_set_id = var.delegation_set_id
  force_destroy     = var.force_destroy

  # Private zone VPC association
  dynamic "vpc" {
    for_each = var.zone_type == "private" && var.vpc_id != null ? [1] : []
    content {
      vpc_id     = var.vpc_id
      vpc_region = local.primary_vpc_region
    }
  }

  tags = local.merged_tags

  lifecycle {
    create_before_destroy = true

    # Validate private zone has VPC
    precondition {
      condition     = local.private_zone_valid
      error_message = "Private hosted zones require vpc_id to be specified"
    }

    # Validate DNSSEC configuration
    precondition {
      condition     = local.dnssec_valid
      error_message = "DNSSEC signing requires kms_key_id to be specified"
    }

    precondition {
      condition     = local.dnssec_type_valid
      error_message = "DNSSEC is only supported for public hosted zones"
    }

    # Validate query logging configuration
    precondition {
      condition     = local.query_logging_valid
      error_message = "Query logging requires query_log_group_arn to be specified"
    }
  }
}

# ------------------------------------------------------------------------------
# Additional VPC Associations (Private Zones Only)
# ------------------------------------------------------------------------------

resource "aws_route53_zone_association" "additional" {
  for_each = {
    for idx, vpc in var.additional_vpc_associations : idx => vpc
    if var.zone_type == "private"
  }

  zone_id    = aws_route53_zone.this[0].zone_id
  vpc_id     = each.value.vpc_id
  vpc_region = coalesce(each.value.vpc_region, var.region)
}

# ------------------------------------------------------------------------------
# DNSSEC Signing (Public Zones Only)
# ------------------------------------------------------------------------------

resource "aws_route53_hosted_zone_dnssec" "this" {
  count = var.create && var.enable_dnssec && var.zone_type == "public" ? 1 : 0

  hosted_zone_id = aws_route53_zone.this[0].zone_id
}

resource "aws_route53_key_signing_key" "this" {
  count = var.create && var.enable_dnssec && var.zone_type == "public" ? 1 : 0

  hosted_zone_id             = aws_route53_zone.this[0].zone_id
  key_management_service_arn = var.kms_key_id
  name                       = replace(var.domain_name, ".", "-")

  depends_on = [aws_route53_hosted_zone_dnssec.this]
}

# ------------------------------------------------------------------------------
# Query Logging Configuration
# ------------------------------------------------------------------------------

resource "aws_route53_query_log" "this" {
  count = var.create && var.enable_query_logging ? 1 : 0

  zone_id                  = aws_route53_zone.this[0].zone_id
  cloudwatch_log_group_arn = var.query_log_group_arn
}
