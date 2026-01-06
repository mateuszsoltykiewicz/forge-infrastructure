#
# Application Load Balancer Module - Main Resources
# Purpose: HTTP/HTTPS load balancing with target groups and listeners
#

# ========================================
# Application Load Balancer
# ========================================

resource "aws_lb" "this" {
  name               = local.alb_name
  load_balancer_type = var.load_balancer_type
  internal           = var.internal
  ip_address_type    = var.ip_address_type

  # Network configuration
  subnets         = aws_subnet.alb_public[*].id
  security_groups = [aws_security_group.alb.id]

  # ALB attributes
  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  enable_http2                     = var.enable_http2
  enable_waf_fail_open             = var.enable_waf_fail_open

  idle_timeout               = var.idle_timeout
  desync_mitigation_mode     = var.desync_mitigation_mode
  drop_invalid_header_fields = var.drop_invalid_header_fields
  preserve_host_header       = var.preserve_host_header
  enable_xff_client_port     = var.enable_xff_client_port
  xff_header_processing_mode = var.xff_header_processing_mode

  # Access logs
  dynamic "access_logs" {
    for_each = local.access_logs_config != null ? [local.access_logs_config] : []

    content {
      bucket  = access_logs.value.bucket
      prefix  = access_logs.value.prefix
      enabled = access_logs.value.enabled
    }
  }

  tags = local.all_tags

  depends_on = [
    aws_subnet.alb_public,
    aws_security_group.alb,
    aws_route_table_association.alb_public
  ]

  # Lifecycle validations
  lifecycle {
    precondition {
      condition     = local.access_logs_valid
      error_message = "When enable_access_logs is true, access_logs_bucket must be provided"
    }

    precondition {
      condition     = local.target_groups_protocol_valid
      error_message = "All target groups must have valid protocols: ${join(", ", local.valid_protocols)}"
    }

    precondition {
      condition     = local.target_groups_type_valid
      error_message = "All target groups must have valid target types: ${join(", ", local.valid_target_types)}"
    }
  }
}

# ========================================
# WAF Association
# ========================================

resource "aws_wafv2_web_acl_association" "this" {
  count = var.web_acl_arn != null ? 1 : 0

  resource_arn = aws_lb.this.arn
  web_acl_arn  = var.web_acl_arn
}

# ========================================
# Target Groups
# ========================================

resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name        = "${local.tg_name_prefix}-${each.key}"
  port        = each.value.port
  protocol    = each.value.protocol
  vpc_id      = data.aws_vpc.main.id
  target_type = each.value.target_type

  # Deregistration and slow start
  deregistration_delay          = each.value.deregistration_delay
  slow_start                    = each.value.slow_start
  load_balancing_algorithm_type = each.value.load_balancing_algorithm_type

  # Health check configuration
  health_check {
    enabled             = each.value.health_check.enabled
    interval            = each.value.health_check.interval
    path                = each.value.health_check.path
    port                = each.value.health_check.port
    protocol            = each.value.health_check.protocol
    timeout             = each.value.health_check.timeout
    healthy_threshold   = each.value.health_check.healthy_threshold
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
    matcher             = each.value.health_check.matcher
  }

  # Stickiness configuration
  dynamic "stickiness" {
    for_each = each.value.stickiness != null ? [each.value.stickiness] : []

    content {
      enabled         = stickiness.value.enabled
      type            = stickiness.value.type
      cookie_duration = stickiness.value.cookie_duration
      cookie_name     = stickiness.value.cookie_name
    }
  }

  tags = merge(
    local.target_group_base_tags,
    {
      Name           = "${local.tg_name_prefix}-${each.key}"
      TargetGroupKey = each.key
      Port           = each.value.port
      Protocol       = each.value.protocol
      TargetType     = each.value.target_type
    }
  )

  # Prevent destruction of target groups with registered targets
  lifecycle {
    create_before_destroy = true
  }
}

# ========================================
# HTTP Listener (Port 80)
# ========================================

resource "aws_lb_listener" "http" {
  count = local.http_listener_enabled ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = var.http_listener.port
  protocol          = "HTTP"

  # Default action: redirect to HTTPS or forward to target group
  default_action {
    type = var.http_listener.redirect_https ? "redirect" : "forward"

    # Redirect to HTTPS
    dynamic "redirect" {
      for_each = var.http_listener.redirect_https ? [1] : []

      content {
        port        = tostring(var.https_listener.port)
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    # Forward to target group
    target_group_arn = !var.http_listener.redirect_https && var.http_listener.target_group_key != null ? (
      aws_lb_target_group.this[var.http_listener.target_group_key].arn
    ) : null
  }

  tags = merge(
    local.all_tags,
    {
      Name     = "${local.alb_name}-http"
      Protocol = "HTTP"
      Port     = var.http_listener.port
    }
  )

  lifecycle {
    precondition {
      condition     = var.http_listener.redirect_https || var.http_listener.target_group_key != null
      error_message = "HTTP listener must either redirect to HTTPS or have a target_group_key configured"
    }
  }
}

# ========================================
# HTTPS Listener (Port 443)
# ========================================

resource "aws_lb_listener" "https" {
  count = local.https_listener_enabled ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = var.https_listener.port
  protocol          = "HTTPS"
  ssl_policy        = var.https_listener.ssl_policy
  certificate_arn   = var.https_listener.certificate_arn
  alpn_policy       = var.https_listener.alpn_policy

  # Default action: forward to target group
  default_action {
    type = "forward"
    target_group_arn = var.https_listener.target_group_key != null ? (
      aws_lb_target_group.this[var.https_listener.target_group_key].arn
    ) : null
  }

  tags = merge(
    local.all_tags,
    {
      Name      = "${local.alb_name}-https"
      Protocol  = "HTTPS"
      Port      = var.https_listener.port
      SSLPolicy = var.https_listener.ssl_policy
    }
  )

  lifecycle {
    precondition {
      condition     = local.https_certificate_valid
      error_message = "HTTPS listener requires certificate_arn to be provided"
    }

    precondition {
      condition     = var.https_listener.target_group_key != null
      error_message = "HTTPS listener requires target_group_key to be configured"
    }
  }
}
