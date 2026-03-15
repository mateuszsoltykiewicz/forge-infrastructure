# ==============================================================================
# Load Balancing - Application Load Balancers
# ==============================================================================
# One ALB per environment (prod, staging, dev)
# Shared WAF Web ACL for DDoS protection
# ==============================================================================

module "alb" {
  source = "./load-balancing/alb"

  # VPC Configuration
  vpc_id = module.vpc.vpc_id

  # Common naming prefix
  common_prefix = local.common_prefix

  # Domain Configuration
  domain_name = var.domain_name

  # Subnet Configuration
  subnet_cidrs       = local.subnet_allocations.alb.cidrs
  availability_zones = local.subnet_allocations.alb.availability_zones

  # Routing
  internet_gateway_id = module.igw.internet_gateway_id

  # WAF Web ACL (Shared - Mandatory)
  web_acl_arn = module.waf.web_acl_arn

  # Target Groups
  target_groups = {
    eks = {
      port        = 80
      protocol    = "HTTP"
      target_type = "ip" # EKS pods use IP target type

      health_check = {
        enabled             = true
        interval            = 30
        path                = "/health"
        protocol            = "HTTP"
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        matcher             = "200"
      }

      stickiness = {
        enabled         = false
        type            = "lb_cookie"
        cookie_duration = 86400
      }
    }
  }

  # HTTPS configuration
  https_listener = {
    enabled          = true
    port             = 443
    ssl_policy       = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    certificate_arn  = module.alb_certificate.certificate_arn
    target_group_key = "eks"
  }

  # HTTP listener (redirect to HTTPS)
  http_listener = {
    enabled        = true
    port           = 80
    redirect_https = true
  }

  # Tags configuration
  common_tags = local.merged_tags

  # IGW dependency is implicit via internet_gateway_id parameter
  depends_on = [module.waf]
}
