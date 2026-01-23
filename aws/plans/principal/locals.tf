# ==============================================================================
# Root Module - Local Values (Environment Logic)
# ==============================================================================
# This file defines local values for multi-environment deployment logic.
# Environments are dynamically enabled/disabled via variables.
# ==============================================================================

locals {

  # Naming Convention (from centralized module)
  # Pattern: san-cro-p-use1 (customer-project-dr-region)
  common_prefix = module.naming.common_prefix

  # ------------------------------------------------------------------------------
  # EKS Namespace Configuration
  # ------------------------------------------------------------------------------

  # ------------------------------------------------------------------------------
  # VPC Endpoints Configuration (for future private deployment)
  # ------------------------------------------------------------------------------

  # VPC Endpoints for private AWS service access
  # NOTE: Currently disabled (enable_vpc_endpoints = false by default)
  # When enabled, these provide private connectivity to AWS services without internet
  vpc_endpoints_config = {
    s3 = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.s3"
      endpoint_type = "Gateway"
    },
    ecr_api = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.ecr.api"
      endpoint_type = "Interface"
    },
    ecr_dkr = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.ecr.dkr"
      endpoint_type = "Interface"
    },
    ec2 = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.ec2"
      endpoint_type = "Interface"
    },
    ec2messages = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.ec2messages"
      endpoint_type = "Interface"
    },
    sts = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.sts"
      endpoint_type = "Interface"
    },
    autoscaling = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.autoscaling"
      endpoint_type = "Interface"
    },
    elasticloadbalancing = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.elasticloadbalancing"
      endpoint_type = "Interface"
    },
    logs = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.logs"
      endpoint_type = "Interface"
    },
    monitoring = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.monitoring"
      endpoint_type = "Interface"
    },
    ssm = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.ssm"
      endpoint_type = "Interface"
    },
    kms = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.kms"
      endpoint_type = "Interface"
    },
    eks = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.eks"
      endpoint_type = "Interface"
    },
    lambda = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.lambda"
      endpoint_type = "Interface"
    },
    kinesis_streams = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.kinesis-streams"
      endpoint_type = "Interface"
    },
    kinesis_firehose = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.kinesis-firehose"
      endpoint_type = "Interface"
    },
    eks_auth = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.eks-auth"
      endpoint_type = "Interface"
    },
    rds = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.rds"
      endpoint_type = "Interface"
    },
    elasticache = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.elasticache"
      endpoint_type = "Interface"
    },
    pi = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.pi"
      endpoint_type = "Interface"
    },
    ssmmessages = {
      service_name  = "com.amazonaws.${var.primary_aws_region}.ssmmessages"
      endpoint_type = "Interface"
    }
  }

  # ------------------------------------------------------------------------------
  # Common Tags (Source of Truth from terraform.tfvars)
  # ------------------------------------------------------------------------------
  # Tags hierarchy:
  # 1. Base tags (ManagedBy, Workspace, DomainName, Region)
  # 2. Multi-tenant tags (Customer, Project) - conditional
  # 3. User-provided tags from terraform.tfvars (Owner, Project, Environment, CostCenter, etc.)
  # 4. Module-specific overrides (e.g., Environment="production" for RDS production)

  common_tags = {
    ManagedBy   = "Terraform"
    DomainName  = var.domain_name
    Region      = var.current_region
    Customer    = var.customer_name
    Project     = var.project_name
    Workspace   = var.workspace
  }

  dr_tags = {
    PrimaryRegion     = var.primary_aws_region
    SecondaryRegion   = var.secondary_aws_region
    CurrentRegion     = var.current_region
    DRType            = var.dr_type
    DRTenant          = var.dr_tenant
  }

  merged_tags = merge(
    local.common_tags,
    var.additional_tags,
    local.dr_tags
  )

  vpc_cidr       = var.vpc_cidr
  current_region = var.current_region

  # Available AZs in region (limit to 3 for cost optimization)
  available_azs = data.aws_availability_zones.available.names
  az_count      = min(length(local.available_azs), 3)

  # ------------------------------------------------------------------------------
  # CIDR Allocation Map - VPC 10.0.0.0/16 (65,536 IPs)
  # ------------------------------------------------------------------------------
  # Subnet size guide:
  # - /19 = 8,192 IPs (EKS - needs many IPs for pods)
  # - /24 = 256 IPs   (RDS, Redis, ALB, VPC-E, VPN - smaller footprint)
  # ------------------------------------------------------------------------------

  subnet_allocations = {
    # EKS Subnets: 3x /19 = 24,576 IPs total
    # Range: 10.0.0.0 - 10.0.95.255
    eks = {
      availability_zones = slice(local.available_azs, 0, local.az_count)
      cidrs = [
        cidrsubnet(local.vpc_cidr, 3, 0), # 10.0.0.0/19   (us-east-1a)
        cidrsubnet(local.vpc_cidr, 3, 1), # 10.0.32.0/19  (us-east-1b)
        cidrsubnet(local.vpc_cidr, 3, 2), # 10.0.64.0/19  (us-east-1c)
      ]
    }

    # RDS Subnets: 3x /24 = 768 IPs total
    # Range: 10.0.96.0 - 10.0.98.255
    rds = {
      availability_zones = slice(local.available_azs, 0, local.az_count)
      cidrs = [
        cidrsubnet(local.vpc_cidr, 8, 96), # 10.0.96.0/24  (us-east-1a)
        cidrsubnet(local.vpc_cidr, 8, 97), # 10.0.97.0/24  (us-east-1b)
        cidrsubnet(local.vpc_cidr, 8, 98), # 10.0.98.0/24  (us-east-1c)
      ]
    }

    # Redis Subnets: 3x /24 = 768 IPs total
    # Range: 10.0.99.0 - 10.0.101.255
    redis = {
      availability_zones = slice(local.available_azs, 0, local.az_count)
      cidrs = [
        cidrsubnet(local.vpc_cidr, 8, 99),  # 10.0.99.0/24  (us-east-1a)
        cidrsubnet(local.vpc_cidr, 8, 100), # 10.0.100.0/24 (us-east-1b)
        cidrsubnet(local.vpc_cidr, 8, 101), # 10.0.101.0/24 (us-east-1c)
      ]
    }

    # ALB Subnets: 3x /24 = 768 IPs total
    # Range: 10.0.102.0 - 10.0.104.255
    alb = {
      availability_zones = slice(local.available_azs, 0, local.az_count)
      cidrs = [
        cidrsubnet(local.vpc_cidr, 8, 102), # 10.0.102.0/24 (us-east-1a)
        cidrsubnet(local.vpc_cidr, 8, 103), # 10.0.103.0/24 (us-east-1b)
        cidrsubnet(local.vpc_cidr, 8, 104), # 10.0.104.0/24 (us-east-1c)
      ]
    }

    # VPC Endpoints Subnets: 3x /24 = 768 IPs total
    # Range: 10.0.240.0 - 10.0.242.255
    vpc_endpoints = {
      availability_zones = slice(local.available_azs, 0, local.az_count)
      cidrs = [
        cidrsubnet(local.vpc_cidr, 8, 240), # 10.0.240.0/24 (us-east-1a)
        cidrsubnet(local.vpc_cidr, 8, 241), # 10.0.241.0/24 (us-east-1b)
        cidrsubnet(local.vpc_cidr, 8, 242), # 10.0.242.0/24 (us-east-1c)
      ]
    }

    # Client VPN Subnets: 3x /24 = 768 IPs total
    # Range: 10.0.243.0 - 10.0.245.255
    client_vpn = {
      availability_zones = slice(local.available_azs, 0, local.az_count)
      cidrs = [
        cidrsubnet(local.vpc_cidr, 8, 243), # 10.0.243.0/24 (us-east-1a)
        cidrsubnet(local.vpc_cidr, 8, 244), # 10.0.244.0/24 (us-east-1b)
        cidrsubnet(local.vpc_cidr, 8, 245), # 10.0.245.0/24 (us-east-1c)
      ]
    }
  }
}

# ==============================================================================
# Environment Logic Best Practices:
# ==============================================================================
# - Use for_each over active_environments to dynamically deploy resources
# - Share production RDS/Redis with staging/development for cost savings
# - Create separate ALBs per environment for traffic isolation
# - Configure EKS namespaces with resource quotas and network policies
# - Use environment-specific NodePorts for routing (prod=30082, stag=30081, dev=30080)
# ==============================================================================
