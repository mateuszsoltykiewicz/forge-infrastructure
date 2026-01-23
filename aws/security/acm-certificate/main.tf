# ========================================
# ACM Certificate
# ========================================

resource "aws_acm_certificate" "main" {

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = var.validation_method
  key_algorithm             = var.key_algorithm

  options {
    certificate_transparency_logging_preference = var.certificate_transparency_logging ? "ENABLED" : "DISABLED"
  }

  lifecycle {
    create_before_destroy = true

    # Prevent accidental deletion of certificates in use
    precondition {
      condition     = var.domain_name != null && var.domain_name != ""
      error_message = "domain_name must be provided."
    }

    # Warn about validation method
    precondition {
      condition     = local.is_dns_validation || local.is_email_validation
      error_message = "validation_method must be either 'DNS' or 'EMAIL'."
    }
  }

  tags = merge(
    local.merged_tags,
    {
      Name = local.certificate_name
    }
  )
}

# ========================================
# Route 53 Validation Records (DNS Validation)
# ========================================

# Create validation records in Route 53
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    } if var.create_route53_records && var.route53_zone_id != null
  }

  zone_id         = var.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = var.validation_record_ttl
  allow_overwrite = true

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_acm_certificate.main]
}

# ========================================
# Certificate Validation
# ========================================

# Wait for certificate validation to complete
resource "aws_acm_certificate_validation" "main" {
  count = var.wait_for_validation && var.create_route53_records && var.route53_zone_id != null ? 1 : 0

  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]

  timeouts {
    create = var.validation_timeout
  }

  lifecycle {
    create_before_destroy = true

    # Validation timeout warning
    precondition {
      condition     = can(regex("^[0-9]+[mh]$", var.validation_timeout))
      error_message = "validation_timeout must be in format '45m' or '2h'."
    }
  }

  depends_on = [aws_route53_record.validation]
}

# ========================================
# CloudWatch Metric Alarm (Optional)
# ========================================

# Alarm for certificate expiration (30 days before)
# Note: ACM automatically renews certificates ~60 days before expiration
# This is a safety net for monitoring
resource "aws_cloudwatch_metric_alarm" "certificate_expiration" {
  count = var.environment == "production" ? 1 : 0

  alarm_name          = "${local.certificate_name}-expiration"
  alarm_description   = "ACM certificate ${var.domain_name} is approaching expiration"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DaysToExpiry"
  namespace           = "AWS/CertificateManager"
  period              = 86400 # 1 day
  statistic           = "Minimum"
  threshold           = 30 # Alert 30 days before expiration
  treat_missing_data  = "notBreaching"

  dimensions = {
    CertificateArn = aws_acm_certificate.main.arn
  }

  alarm_actions = [] # Add SNS topic ARN for notifications

  tags = local.merged_tags
}
