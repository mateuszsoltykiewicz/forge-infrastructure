# ==============================================================================
# Route 53 Hosted Zone Module - Outputs
# ==============================================================================
# This file defines outputs for the Route 53 hosted zone.
# ==============================================================================

# ------------------------------------------------------------------------------
# Hosted Zone Identification
# ------------------------------------------------------------------------------

output "zone_id" {
  description = "ID of the Route 53 hosted zone"
  value       = var.create ? aws_route53_zone.this[0].zone_id : null
}

output "zone_arn" {
  description = "ARN of the Route 53 hosted zone"
  value       = var.create ? aws_route53_zone.this[0].arn : null
}

output "zone_name" {
  description = "Name of the hosted zone (domain name)"
  value       = var.create ? aws_route53_zone.this[0].name : null
}

# ------------------------------------------------------------------------------
# Name Servers
# ------------------------------------------------------------------------------

output "name_servers" {
  description = "List of name servers for the hosted zone"
  value       = var.create ? aws_route53_zone.this[0].name_servers : null
}

output "primary_name_server" {
  description = "Primary name server for the hosted zone"
  value       = var.create ? aws_route53_zone.this[0].primary_name_server : null
}

# ------------------------------------------------------------------------------
# Zone Configuration
# ------------------------------------------------------------------------------

output "zone_type" {
  description = "Type of hosted zone (public or private)"
  value       = var.zone_type
}

output "comment" {
  description = "Comment for the hosted zone"
  value       = var.create ? aws_route53_zone.this[0].comment : null
}

# ------------------------------------------------------------------------------
# VPC Associations (Private Zones)
# ------------------------------------------------------------------------------

output "primary_vpc_id" {
  description = "Primary VPC ID associated with the zone (private zones only)"
  value       = var.zone_type == "private" ? var.vpc_id : null
}

output "primary_vpc_region" {
  description = "Primary VPC region (private zones only)"
  value       = var.zone_type == "private" ? local.primary_vpc_region : null
}

output "additional_vpc_associations" {
  description = "Additional VPC associations (private zones only)"
  value = {
    for k, v in aws_route53_zone_association.additional : k => {
      id         = v.id
      vpc_id     = v.vpc_id
      vpc_region = v.vpc_region
      zone_id    = v.zone_id
    }
  }
}

output "vpc_association_count" {
  description = "Total number of VPC associations (private zones only)"
  value       = var.zone_type == "private" ? (1 + length(aws_route53_zone_association.additional)) : 0
}

# ------------------------------------------------------------------------------
# DNSSEC Configuration
# ------------------------------------------------------------------------------

output "dnssec_enabled" {
  description = "Whether DNSSEC is enabled for the zone"
  value       = var.enable_dnssec
}

output "dnssec_status" {
  description = "DNSSEC status for the zone"
  value       = var.enable_dnssec ? aws_route53_hosted_zone_dnssec.this[0].id : null
}

output "key_signing_key" {
  description = "Key signing key information"
  value = var.enable_dnssec ? {
    name                       = aws_route53_key_signing_key.this[0].name
    key_management_service_arn = aws_route53_key_signing_key.this[0].key_management_service_arn
    ds_record                  = aws_route53_key_signing_key.this[0].ds_record
    digest_algorithm_mnemonic  = aws_route53_key_signing_key.this[0].digest_algorithm_mnemonic
    digest_algorithm_type      = aws_route53_key_signing_key.this[0].digest_algorithm_type
    digest_value               = aws_route53_key_signing_key.this[0].digest_value
    dnskey_record              = aws_route53_key_signing_key.this[0].dnskey_record
    flag                       = aws_route53_key_signing_key.this[0].flag
    public_key                 = aws_route53_key_signing_key.this[0].public_key
    signing_algorithm_mnemonic = aws_route53_key_signing_key.this[0].signing_algorithm_mnemonic
    signing_algorithm_type     = aws_route53_key_signing_key.this[0].signing_algorithm_type
  } : null
}

# ------------------------------------------------------------------------------
# Query Logging
# ------------------------------------------------------------------------------

output "query_logging_enabled" {
  description = "Whether query logging is enabled"
  value       = var.enable_query_logging
}

output "query_log_config_id" {
  description = "Query logging configuration ID"
  value       = var.enable_query_logging ? aws_route53_query_log.this[0].id : null
}

output "query_log_group_arn" {
  description = "CloudWatch Log Group ARN for query logs"
  value       = var.enable_query_logging ? var.query_log_group_arn : null
}

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------

output "summary" {
  description = "Summary of Route 53 hosted zone configuration"
  value = {
    zone_id               = var.create ? aws_route53_zone.this[0].zone_id : null
    zone_arn              = var.create ? aws_route53_zone.this[0].arn : null
    zone_name             = var.create ? aws_route53_zone.this[0].name : null
    zone_type             = var.zone_type
    name_servers          = var.create ? aws_route53_zone.this[0].name_servers : null
    primary_name_server   = var.create ? aws_route53_zone.this[0].primary_name_server : null
    vpc_id                = var.zone_type == "private" ? var.vpc_id : null
    vpc_association_count = var.zone_type == "private" ? (1 + length(aws_route53_zone_association.additional)) : 0
    dnssec_enabled        = var.enable_dnssec
    query_logging_enabled = var.enable_query_logging
    environment           = var.environment
  }
}
