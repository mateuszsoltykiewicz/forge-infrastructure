# ========================================
# Certificate Outputs
# ========================================

output "certificate_arn" {
  description = "ARN of the ACM certificate. Use this with ALB, CloudFront, API Gateway, etc."
  value       = aws_acm_certificate.main.arn
}

output "certificate_id" {
  description = "ID of the ACM certificate (same as ARN)"
  value       = aws_acm_certificate.main.id
}

output "certificate_domain_name" {
  description = "Primary domain name of the certificate"
  value       = aws_acm_certificate.main.domain_name
}

output "certificate_status" {
  description = "Status of the certificate (PENDING_VALIDATION, ISSUED, INACTIVE, EXPIRED, VALIDATION_TIMED_OUT, REVOKED, FAILED)"
  value       = aws_acm_certificate.main.status
}

# ========================================
# Domain Information
# ========================================

output "domain_name" {
  description = "Primary domain name"
  value       = var.domain_name
}

output "subject_alternative_names" {
  description = "List of Subject Alternative Names (SANs)"
  value       = var.subject_alternative_names
}

output "all_domain_names" {
  description = "All domain names covered by this certificate (primary + SANs)"
  value       = local.all_domain_names
}

output "is_wildcard" {
  description = "Whether this is a wildcard certificate"
  value       = local.is_wildcard
}

output "base_domain" {
  description = "Base domain (without wildcard prefix if applicable)"
  value       = local.base_domain
}

# ========================================
# Validation Information
# ========================================

output "validation_method" {
  description = "Validation method used (DNS or EMAIL)"
  value       = var.validation_method
}

output "validation_record_fqdns" {
  description = "FQDNs of the Route 53 validation records created (DNS validation only)"
  value       = local.should_create_dns_records ? [for record in aws_route53_record.validation : record.fqdn] : []
}

output "domain_validation_options" {
  description = "Domain validation options for manual DNS configuration (if not using automatic Route 53 validation)"
  value = [
    for dvo in aws_acm_certificate.main.domain_validation_options : {
      domain_name           = dvo.domain_name
      resource_record_name  = dvo.resource_record_name
      resource_record_type  = dvo.resource_record_type
      resource_record_value = dvo.resource_record_value
    }
  ]
  sensitive = false
}

output "is_validated" {
  description = "Whether the certificate has been validated (true if wait_for_validation is enabled and validation completed)"
  value       = var.wait_for_validation && local.is_dns_validation && local.should_create_dns_records ? true : null
}

# ========================================
# Certificate Configuration
# ========================================

output "key_algorithm" {
  description = "Key algorithm used for the certificate"
  value       = var.key_algorithm
}

output "key_type" {
  description = "Key type (RSA or EC)"
  value       = local.key_type
}

output "key_size" {
  description = "Key size in bits (for RSA keys only)"
  value       = local.key_size
}

output "certificate_transparency_logging" {
  description = "Whether Certificate Transparency logging is enabled"
  value       = var.certificate_transparency_logging
}

# ========================================
# Route 53 Information
# ========================================

output "route53_zone_id" {
  description = "Route 53 hosted zone ID used for DNS validation"
  value       = var.route53_zone_id
}

output "validation_records_created" {
  description = "Whether Route 53 validation records were automatically created"
  value       = local.should_create_dns_records
}

# ========================================
# Expiration Monitoring
# ========================================

output "expiration_alarm_arn" {
  description = "ARN of the CloudWatch alarm for certificate expiration (production only)"
  value       = var.environment == "production" ? try(aws_cloudwatch_metric_alarm.certificate_expiration[0].arn, null) : null
}

output "not_before" {
  description = "Certificate validity start time"
  value       = aws_acm_certificate.main.not_before
}

output "not_after" {
  description = "Certificate validity end time (expiration)"
  value       = aws_acm_certificate.main.not_after
}

# ========================================
# Integration Outputs
# ========================================

output "alb_listener_config" {
  description = "Configuration object for ALB HTTPS listener"
  value = {
    certificate_arn = aws_acm_certificate.main.arn
    ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06" # Recommended for ALB
    alpn_policy     = "HTTP2Preferred"
  }
}

output "cloudfront_config" {
  description = "Configuration object for CloudFront (requires certificate in us-east-1)"
  value = {
    acm_certificate_arn      = aws_acm_certificate.main.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

output "api_gateway_config" {
  description = "Configuration object for API Gateway custom domain"
  value = {
    certificate_arn = aws_acm_certificate.main.arn
    security_policy = "TLS_1_2"
  }
}

# ========================================
# Summary Output
# ========================================

output "certificate_summary" {
  description = "Summary of the certificate configuration"
  value = {
    # Identification
    certificate_arn = aws_acm_certificate.main.arn
    certificate_id  = aws_acm_certificate.main.id
    name            = local.certificate_name
    status          = aws_acm_certificate.main.status

    # Domains
    domain_name               = var.domain_name
    subject_alternative_names = var.subject_alternative_names
    all_domains               = local.all_domain_names
    is_wildcard               = local.is_wildcard

    # Validation
    validation_method         = var.validation_method
    validation_records_created = local.should_create_dns_records
    is_validated              = var.wait_for_validation && local.is_dns_validation && local.should_create_dns_records

    # Configuration
    key_algorithm                     = var.key_algorithm
    certificate_transparency_logging  = var.certificate_transparency_logging

    # Validity
    not_before = aws_acm_certificate.main.not_before
    not_after  = aws_acm_certificate.main.not_after

    # Tags
    tags = local.all_tags
  }
}
