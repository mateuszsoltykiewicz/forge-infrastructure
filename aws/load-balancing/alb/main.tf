#
# Application Load Balancer Module - Main Resources
# Purpose: HTTP/HTTPS load balancing with target groups and listeners
#

# ========================================
# Application Load Balancer
# ========================================

resource "aws_lb" "this" {
  count = length(var.environments)

  name               = local.alb_names[count.index]
  load_balancer_type = "application"
  internal           = false
  ip_address_type    = "ipv4"

  # Network configuration - shared subnets across all ALBs
  subnets         = module.alb_subnet.subnet_ids
  security_groups = [module.security_group[count.index].security_group_id]

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
      prefix  = "${access_logs.value.prefix}/${var.environments[count.index]}"
      enabled = access_logs.value.enabled
    }
  }

  tags = merge(
    local.merged_tags,
    {
      Name        = local.alb_names[count.index]
      Environment = var.environments[count.index]
      Subdomain   = local.subdomains[count.index]
    }
  )

  depends_on = [
    module.alb_subnet,
    module.security_group
  ]
}

# ========================================
# WAF Association
# ========================================

resource "aws_wafv2_web_acl_association" "this" {
  count = length(var.environments)

  resource_arn = aws_lb.this[count.index].arn
  web_acl_arn  = var.web_acl_arn

  depends_on = [
    aws_lb.this,
    aws_lb_listener.http,
    aws_lb_listener.https
  ]
}

# ========================================
# HTTP Listener (Port 80)
# ========================================

resource "aws_lb_listener" "http" {
  count = length(var.environments)

  load_balancer_arn = aws_lb.this[count.index].arn
  port              = var.http_listener.port
  protocol          = "HTTP"

  # Default action: redirect to HTTPS
  default_action {
    type = "redirect"

    redirect {
      port        = tostring(var.https_listener.port)
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(
    local.merged_tags,
    {
      Name          = "${local.alb_names[count.index]}-http"
      Environment   = var.environments[count.index]
      Protocol      = "HTTP"
      DefaultAction = "RedirectToHTTPS"
      Port          = var.http_listener.port
    }
  )
}

# ========================================
# HTTPS Listener (Port 443)
# ========================================

resource "aws_lb_listener" "https" {
  count = length(var.environments)

  load_balancer_arn = aws_lb.this[count.index].arn
  port              = var.https_listener.port
  protocol          = "HTTPS"
  ssl_policy        = var.https_listener.ssl_policy
  certificate_arn   = var.https_listener.certificate_arn
  alpn_policy       = var.https_listener.alpn_policy

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<!DOCTYPE html><html><head><title>404</title><style>body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;display:flex;justify-content:center;align-items:center;height:100vh;margin:0;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:#fff}h1{font-size:120px;margin:0;font-weight:700}p{font-size:24px;margin:20px 0}.details{font-size:14px;opacity:.8;margin-top:40px}</style></head><body><div style='text-align:center'><h1>404</h1><p>Page Not Found</p><div class='details'>The requested resource could not be found on this server.</div></div></body></html>"
      status_code  = "404"
    }
  }

  tags = merge(
    local.merged_tags,
    {
      Name          = "${local.alb_names[count.index]}-https"
      Environment   = var.environments[count.index]
      Protocol      = "HTTPS"
      Port          = var.https_listener.port
      SSLPolicy     = var.https_listener.ssl_policy
      DefaultAction = "FixedResponse404"
    }
  )
}
