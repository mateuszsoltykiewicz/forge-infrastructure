# ==============================================================================
# Security Infrastructure
# ==============================================================================
# ACM Certificates and WAF Web ACL
# ==============================================================================

# ------------------------------------------------------------------------------
# ACM Certificate - SSL/TLS for ALB
# ------------------------------------------------------------------------------
# Domain: project-backend.com
# SAN: *.project-backend.com
# Validation: DNS via Route 53 (automatic)
# ------------------------------------------------------------------------------

module "alb_certificate" {
  source = "../../security/acm-certificate"

  common_prefix = local.common_prefix
  common_tags   = local.merged_tags

  # Certificate configuration
  environment = "production"
  region      = var.current_region

  # Domain configuration
  domain_name               = var.domain_name          # project-backend.com
  subject_alternative_names = ["*.${var.domain_name}"] # *.project-backend.com

  # DNS validation via Route53 (automatic)
  validation_method      = "DNS"
  route53_zone_id        = data.aws_route53_zone.main.zone_id
  create_route53_records = true

  # Certificate settings
  key_algorithm                    = "RSA_2048"
  certificate_transparency_logging = true
}

# ------------------------------------------------------------------------------
# WAF Web ACL - DDoS Protection
# ------------------------------------------------------------------------------
# Shared across all ALBs (prod/staging/dev)
# Rate limit: 2000 requests per 5 minutes per IP
# Default action: Allow
# ------------------------------------------------------------------------------

module "waf" {
  source = "../../security/waf-web-acl"

  common_prefix = local.common_prefix
  common_tags   = local.merged_tags

  # WAF Configuration
  scope          = "REGIONAL" # For ALB/API Gateway
  default_action = "allow"    # Allow by default, block with rules

  # Rate limiting (DDoS protection)
  rate_limit_requests = 2000 # 2000 requests per 5 minutes per IP

  # Logging - WAFv2 requires Kinesis Firehose (does not support direct CloudWatch)
  firehose_delivery_stream_arn = module.kinesis_firehose.waf_stream_arn
  log_retention_days           = 30   # 30 days CloudWatch retention
  create_kms_key               = true # Create internal KMS key for log encryption

  depends_on = [module.vpc, module.kinesis_firehose]
}
