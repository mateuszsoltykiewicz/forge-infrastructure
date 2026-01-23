#----------------------------------------------------------------------
# Variables for Subnet Module
#----------------------------------------------------------------------

# Common prefix for resource naming
variable "common_prefix" {
  description = "Common prefix for resource naming"
  type        = string
  nullable    = false
}

# Set of common tags passed from root module
variable "common_tags" {
  description = "Common tags passed from root module (ManagedBy, Workspace, Region, DomainName, Customer, Project)"
  type        = map(string)
  nullable    = false
}

# VPC ID where the subnet will be created
variable "vpc_id" {
  description = "VPC ID where the subnet will be created"
  type        = string
  nullable    = false

  # Validate with regex if VPC Id format is correct
  validation {
    condition     = can(regex("^vpc-[0-9a-f]{8,17}$", var.vpc_id))
    error_message = "vpc_id must be a valid VPC ID (e.g., vpc-xxxxxxxx or vpc-xxxxxxxxxxxxxxxxx)"
  }
}

# ------------------------------------------------------------------------------
# Environment and Purpose Configuration
# ------------------------------------------------------------------------------

# variable "environment" {
#   description = "Environment name (e.g., shared, production, staging, development)"
#   type        = string

#   validation {
#     condition     = length(var.environment) <= 20
#     error_message = "environment must not exceed 20 characters"
#   }
# }

# ------------------------------------------------------------------------------
# Purpose Configuration
# ------------------------------------------------------------------------------

variable "purpose" {
  description = "Subnet purpose (e.g., eks, rds, redis, alb, vpn, vpc-endpoints)"
  type        = string

  # Validate if purpose is allowed from the list of accepted purposes
  # RDS, EKSCluster, EKSNodeGroup, ALB, Redis, VPN, VPCEndpoints
  validation {
    condition     = contains(["EKSCluster", "EKSNodeGroup", "RDS", "Redis", "ALB", "VPN", "VPCEndpoints"], var.purpose)
    error_message = "purpose must be one of the following: eks, rds, redis, alb, vpn, vpc-endpoints"
  }
}


# ------------------------------------------------------------------------------
# Subnet Configuration
# ------------------------------------------------------------------------------
variable "subnet_cidrs" {
  description = "List of CIDR blocks for the subnets to be created"
  type        = list(string)
  nullable    = false
}

variable "availability_zones" {
  description = "List of availability zones for the subnets"
  type        = list(string)
  nullable    = false

  # Validate with regex if each AZ format is correct
  validation {
    condition     = alltrue([for az in var.availability_zones : can(regex("^[a-z]{2}-[a-z]+-\\d[a-z]?-\\d$", az))])
    error_message = "Each availability zone in availability_zones must be a valid AWS availability zone (e.g., us-east-1a)"
  }
}

# ------------------------------------------------------------------------------
# Routing Configuration
# ------------------------------------------------------------------------------

variable "internet_gateway_id" {
  description = "Internet Gateway ID for public subnet routing (0.0.0.0/0 → IGW). Required when tier = 'Public'"
  type        = string
  default     = ""

  # Validate with regex if IGW Id format is correct
  validation {
    condition     = var.tier == "Public" ? can(regex("^igw-[0-9a-f]{8,17}$", var.internet_gateway_id)) : true
    error_message = "internet_gateway_id must be a valid Internet Gateway ID (e.g., igw-xxxxxxxx or igw-xxxxxxxxxxxxxxxxx) when tier is 'Public'"
  }
}

variable "nat_gateway_ids" {
  description = "List of NAT Gateway IDs for private subnet egress (0.0.0.0/0 → NAT). Optional for private subnets. If omitted, no internet egress (VPC Endpoints only)"
  type        = list(string)
  default     = []

  # Validate with regex if each NAT GW Id format is correct
  validation {
    condition     = var.tier == "Private" && length(var.nat_gateway_ids) > 0 ? alltrue([for id in var.nat_gateway_ids : can(regex("^nat-[0-9a-f]{8,17}$", id))]) : true
    error_message = "Each NAT Gateway ID in nat_gateway_ids must be a valid NAT Gateway ID (e.g., nat-xxxxxxxx or nat-xxxxxxxxxxxxxxxxx) when tier is 'Private'"
  }
}

# ------------------------------------------------------------------------------
# Additional Features
# ------------------------------------------------------------------------------

variable "enable_s3_gateway_route" {
  description = "Enable automatic route to S3 Gateway VPC Endpoint. Requires s3_gateway_endpoint_id"
  type        = bool
  default     = false
}

variable "s3_gateway_endpoint_id" {
  description = "S3 Gateway VPC Endpoint ID for route table association"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# Tier Configuration
# ------------------------------------------------------------------------------

variable "tier" {
  description = "Type of subnet: 'public' (route to IGW) or 'private' (route to NAT GW or VPC-only)"
  type        = string
  default     = "Private"

  validation {
    condition     = contains(["Public", "Private"], var.tier)
    error_message = "tier must be either 'Public' or 'Private'."
  }
}