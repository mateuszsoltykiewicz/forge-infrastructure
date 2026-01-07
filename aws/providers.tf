# ==============================================================================
# Terraform Provider Configuration
# ==============================================================================
# This file configures the AWS and Kubernetes providers for multi-environment
# infrastructure deployment in us-east-1.
# ==============================================================================

terraform {
  required_version = "~> 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
}

# ==============================================================================
# AWS Provider Configuration
# ==============================================================================

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Project     = "Forge Infrastructure"
      Environment = "Multi-Environment"
      Region      = "us-east-1"
      Owner       = "InsightHealth"
    }
  }
}

# ==============================================================================
# Kubernetes Provider Configuration (EKS)
# ==============================================================================
# NOTE: This provider is configured AFTER the EKS cluster is created.
# It uses the EKS cluster endpoint and certificate for authentication.
# ==============================================================================

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      "us-east-1"
    ]
  }
}

# ==============================================================================
# Provider Configuration Best Practices:
# ==============================================================================
# - Use specific provider versions to ensure reproducibility
# - Configure default tags for all AWS resources
# - Use exec authentication for Kubernetes provider (AWS EKS)
# - Ensure Kubernetes provider depends on EKS cluster creation
# - Set region explicitly to avoid ambiguity
# ==============================================================================
