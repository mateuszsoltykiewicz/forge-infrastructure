# ==============================================================================
# Core Infrastructure - Naming Convention
# ==============================================================================
# Centralized AWS naming sanitization module
# Pattern: {customer_code}-{project_code}-{dr_code}-{region_code}
# Example: san-cro-p-use1 (customer-project-primary-us-east-1)
#
# This module MUST be instantiated first as other modules depend on its outputs
# ==============================================================================

module "naming" {
  source = "../../core/naming-convention"

  customer_name      = var.customer_name
  project_name       = var.project_name
  current_region     = var.current_region
  primary_aws_region = var.primary_aws_region
}
