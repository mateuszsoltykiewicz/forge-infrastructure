# ==============================================================================
# EKS Module - Provider Configuration (Kubernetes)
# ==============================================================================
# This file configures the Kubernetes provider to communicate with the EKS cluster.
# The provider is configured after the EKS cluster is created.
# ==============================================================================

# NOTE: Kubernetes provider configuration should be done in the ROOT module
# that calls this EKS module, not here.
#
# Root module should configure the provider like this:
#
# provider "kubernetes" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args = [
#       "eks",
#       "get-token",
#       "--cluster-name",
#       module.eks.cluster_name,
#       "--region",
#       var.aws_region
#     ]
#   }
# }
#
# This ensures the provider is configured AFTER the EKS cluster exists.

# ==============================================================================
# Provider Configuration Best Practices:
# ==============================================================================
# - Configure Kubernetes provider in root module, not in child modules
# - Use exec auth with aws eks get-token for authentication
# - Ensure provider depends on EKS cluster creation
# - Reference cluster_endpoint and cluster_certificate_authority_data outputs
# ==============================================================================
