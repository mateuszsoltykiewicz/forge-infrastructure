# ==============================================================================
# Resource Creation Control
# ==============================================================================

variable "create" {
  description = "Whether to create resources. Set to false to skip resource creation."
  type        = bool
  default     = true
}


# ==============================================================================
# VPC Endpoint Module - Variables
# ==============================================================================
# This file defines input variables for the VPC endpoint module.
# ==============================================================================

# ------------------------------------------------------------------------------
# Multi-Tenant Context
# ------------------------------------------------------------------------------

variable "workspace" {
  description = "Workspace name for resource discovery (e.g., 'forge-platform')"
  type        = string
}

variable "customer_name" {
  description = "Customer name for resource naming (null for shared infrastructure)"
  type        = string
  default     = null
}

variable "project_name" {
  description = "Project name for resource naming (null for customer or shared infrastructure)"
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string
}

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
}

# ------------------------------------------------------------------------------
# VPC Configuration
# ------------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID of the VPC where the endpoint will be created"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]{8,}$", var.vpc_id))
    error_message = "vpc_id must be a valid VPC ID format (vpc-xxxxxxxx)"
  }
}

# ------------------------------------------------------------------------------
# Endpoint Configuration
# ------------------------------------------------------------------------------

variable "service_name" {
  description = "AWS service name for the endpoint (e.g., 's3', 'ec2', 'dynamodb', 'com.amazonaws.vpce.region.vpce-svc-xxxxx' for PrivateLink)"
  type        = string
}

variable "endpoint_type" {
  description = "Type of VPC endpoint: 'Gateway' (S3, DynamoDB) or 'Interface' (most AWS services) or 'GatewayLoadBalancer'"
  type        = string
  default     = "Interface"

  validation {
    condition     = contains(["Gateway", "Interface", "GatewayLoadBalancer"], var.endpoint_type)
    error_message = "endpoint_type must be one of: Gateway, Interface, GatewayLoadBalancer"
  }
}

variable "auto_accept" {
  description = "Accept the VPC endpoint (for PrivateLink endpoints)"
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# Network Configuration (Interface & GatewayLoadBalancer endpoints)
# ------------------------------------------------------------------------------

variable "subnet_ids" {
  description = "List of subnet IDs for Interface/GatewayLoadBalancer endpoints (required for Interface/GWLB, ignored for Gateway)"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.subnet_ids : can(regex("^subnet-[a-z0-9]{8,}$", id))])
    error_message = "All subnet_ids must be valid subnet ID format (subnet-xxxxxxxx)"
  }
}

variable "security_group_ids" {
  description = "List of security group IDs for Interface endpoints (required for Interface, ignored for Gateway/GWLB)"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.security_group_ids : can(regex("^sg-[a-z0-9]{8,}$", id))])
    error_message = "All security_group_ids must be valid security group ID format (sg-xxxxxxxx)"
  }
}

variable "private_dns_enabled" {
  description = "Enable private DNS for Interface endpoints (allows using AWS service DNS names)"
  type        = bool
  default     = true
}

variable "ip_address_type" {
  description = "IP address type for Interface endpoints: 'ipv4', 'dualstack', or 'ipv6'"
  type        = string
  default     = "ipv4"

  validation {
    condition     = contains(["ipv4", "dualstack", "ipv6"], var.ip_address_type)
    error_message = "ip_address_type must be one of: ipv4, dualstack, ipv6"
  }
}

# ------------------------------------------------------------------------------
# Route Table Configuration (Gateway endpoints)
# ------------------------------------------------------------------------------

variable "route_table_ids" {
  description = "List of route table IDs for Gateway endpoints (required for Gateway, ignored for Interface/GWLB)"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.route_table_ids : can(regex("^rtb-[a-z0-9]{8,}$", id))])
    error_message = "All route_table_ids must be valid route table ID format (rtb-xxxxxxxx)"
  }
}

# ------------------------------------------------------------------------------
# DNS Configuration
# ------------------------------------------------------------------------------

variable "dns_options" {
  description = "DNS options for the endpoint"
  type = object({
    dns_record_ip_type                             = optional(string, "ipv4") # ipv4, dualstack, service-defined, ipv6
    private_dns_only_for_inbound_resolver_endpoint = optional(bool, false)
  })
  default = {
    dns_record_ip_type = "ipv4"
  }
}

# ------------------------------------------------------------------------------
# Policy Configuration
# ------------------------------------------------------------------------------

variable "policy" {
  description = "IAM policy document (JSON) to attach to the endpoint (restricts access to specific resources/actions)"
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# Tags
# ------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
