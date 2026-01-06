# ==============================================================================
# Resource Creation Control
# ==============================================================================

variable "create" {
  description = "Whether to create resources. Set to false to skip resource creation."
  type        = bool
  default     = true
}


# ==============================================================================
# AWS Client VPN Module - Input Variables
# ==============================================================================

# ------------------------------------------------------------------------------
# Multi-Tenant Context
# ------------------------------------------------------------------------------

variable "workspace" {
  description = "Workspace identifier for all resources (e.g., 'forge-platform')"
  type        = string

  validation {
    condition     = length(var.workspace) > 0
    error_message = "Workspace must not be empty."
  }
}

variable "environment" {
  description = "Environment name (e.g., 'shared', 'production', 'staging')"
  type        = string
  default     = "shared"
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
# VPN Configuration
# ------------------------------------------------------------------------------

variable "client_cidr_block" {
  description = "CIDR block for VPN client IP addresses (e.g., '172.16.0.0/22')"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.client_cidr_block))
    error_message = "Client CIDR block must be a valid CIDR notation."
  }
}

variable "dns_servers" {
  description = "List of DNS server IP addresses for VPN clients (empty list = use VPC DNS resolver)"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.dns_servers) <= 2
    error_message = "Maximum 2 DNS servers are supported."
  }
}

variable "split_tunnel" {
  description = "Enable split tunneling (only VPC traffic routes through VPN)"
  type        = bool
  default     = true
}

variable "transport_protocol" {
  description = "Transport protocol for VPN connections (udp or tcp)"
  type        = string
  default     = "udp"

  validation {
    condition     = contains(["udp", "tcp"], var.transport_protocol)
    error_message = "Transport protocol must be 'udp' or 'tcp'."
  }
}

variable "vpn_port" {
  description = "VPN port number (default: 443 for tcp, 1194 for udp)"
  type        = number
  default     = null
}

variable "session_timeout_hours" {
  description = "Maximum VPN session timeout in hours (8-24)"
  type        = number
  default     = 24

  validation {
    condition     = var.session_timeout_hours >= 8 && var.session_timeout_hours <= 24
    error_message = "Session timeout must be between 8 and 24 hours."
  }
}

# ------------------------------------------------------------------------------
# Authentication Configuration
# ------------------------------------------------------------------------------

variable "authentication_type" {
  description = "Authentication type (certificate-authentication, directory-service-authentication, or federated-authentication)"
  type        = string
  default     = "certificate-authentication"

  validation {
    condition = contains([
      "certificate-authentication",
      "directory-service-authentication",
      "federated-authentication"
    ], var.authentication_type)
    error_message = "Authentication type must be certificate-authentication, directory-service-authentication, or federated-authentication."
  }
}

variable "server_certificate_arn" {
  description = "ACM certificate ARN for VPN server (required for mutual TLS)"
  type        = string
}

variable "client_root_certificate_arn" {
  description = "ACM certificate ARN for VPN client root CA (required for certificate-authentication)"
  type        = string
  default     = null
}

variable "saml_provider_arn" {
  description = "ARN of SAML provider for federated authentication"
  type        = string
  default     = null
}

variable "active_directory_id" {
  description = "ID of AWS Directory Service directory for AD authentication"
  type        = string
  default     = null
}

variable "self_service_saml_provider_arn" {
  description = "ARN of SAML provider for self-service portal"
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# Network Configuration
# ------------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID of VPC where VPN endpoint will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for VPN endpoint network associations (use private subnets)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1 && length(var.subnet_ids) <= 6
    error_message = "Must provide between 1 and 6 subnet IDs."
  }
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to VPN endpoint (empty list = auto-create)"
  type        = list(string)
  default     = []
}

variable "create_security_group" {
  description = "Create a security group for VPN access"
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Name for security group (if create_security_group = true)"
  type        = string
  default     = null
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block for authorization rules"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr_block))
    error_message = "VPC CIDR block must be a valid CIDR notation."
  }
}

# ------------------------------------------------------------------------------
# Authorization Configuration
# ------------------------------------------------------------------------------

variable "authorize_all_groups" {
  description = "Authorize all users to access VPC (true) or use specific access groups (false)"
  type        = bool
  default     = true
}

variable "access_group_id" {
  description = "Active Directory group ID for access authorization (if authorize_all_groups = false)"
  type        = string
  default     = null
}

variable "authorization_rules" {
  description = "Additional authorization rules for specific CIDR blocks"
  type = list(object({
    target_network_cidr = string
    access_group_id     = optional(string)
    description         = optional(string)
  }))
  default = []
}

# ------------------------------------------------------------------------------
# Logging Configuration
# ------------------------------------------------------------------------------

variable "enable_connection_logs" {
  description = "Enable CloudWatch Logs for VPN connection logs"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group name for VPN connection logs (null = auto-generate)"
  type        = string
  default     = null
}

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain VPN connection logs in CloudWatch"
  type        = number
  default     = 30

  validation {
    condition = contains([
      0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180,
      365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922,
      3288, 3653
    ], var.cloudwatch_log_retention_days)
    error_message = "Log retention must be a valid CloudWatch Logs retention period."
  }
}

variable "cloudwatch_kms_key_arn" {
  description = "KMS key ARN for CloudWatch Logs encryption (null = use AWS managed key)"
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# Client Configuration
# ------------------------------------------------------------------------------

variable "enable_self_service_portal" {
  description = "Enable self-service portal for client certificate management"
  type        = bool
  default     = false
}

variable "client_connect_options" {
  description = "Enable Lambda function for client connection authorization"
  type = object({
    enabled             = bool
    lambda_function_arn = optional(string)
  })
  default = {
    enabled = false
  }
}

# ------------------------------------------------------------------------------
# Tagging
# ------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
