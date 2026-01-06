# ==============================================================================
# EKS Module - Kubernetes Namespaces Configuration
# ==============================================================================
# This file creates Kubernetes namespaces with:
# - Custom labels for organization and filtering
# - Resource quotas to limit CPU, memory, and pod count
# - Network policies for namespace isolation
#
# NOTE: These resources are COMMENTED OUT for module validation.
# They will be ENABLED when this module is called from the root module
# with a properly configured Kubernetes provider.
# ==============================================================================

# ------------------------------------------------------------------------------
# Kubernetes Namespaces
# ------------------------------------------------------------------------------

# IMPORTANT: Uncomment these resources when Kubernetes provider is configured
# in the root module that calls this EKS module.
#
# resource "kubernetes_namespace" "this" {
#   for_each = var.namespaces
#
#   metadata {
#     name = each.key
#     labels = merge(
#       {
#         name        = each.key
#         managed-by  = "terraform"
#         environment = var.environment
#       },
#       each.value.labels
#     )
#   }
#
#   depends_on = [module.eks]
# }

# ------------------------------------------------------------------------------
# Resource Quotas
# ------------------------------------------------------------------------------

# resource "kubernetes_resource_quota" "this" {
#   for_each = {
#     for ns_key, ns_config in var.namespaces :
#     ns_key => ns_config
#     if ns_config.resource_quota != null
#   }
#
#   metadata {
#     name      = "${each.key}-quota"
#     namespace = kubernetes_namespace.this[each.key].metadata[0].name
#   }
#
#   spec {
#     hard = each.value.resource_quota.hard
#   }
#
#   depends_on = [kubernetes_namespace.this]
# }

# ------------------------------------------------------------------------------
# Network Policies (Namespace Isolation)
# ------------------------------------------------------------------------------

# resource "kubernetes_network_policy" "this" {
#   for_each = {
#     for ns_key, ns_config in var.namespaces :
#     ns_key => ns_config
#     if ns_config.network_policy != null
#   }
#
#   metadata {
#     name      = "${each.key}-isolation"
#     namespace = kubernetes_namespace.this[each.key].metadata[0].name
#   }
#
#   spec {
#     pod_selector {}
#
#     policy_types = concat(
#       length(each.value.network_policy.ingress_from_namespaces) > 0 ? ["Ingress"] : [],
#       each.value.network_policy.egress_allowed ? ["Egress"] : []
#     )
#
#     # Ingress rules (allow from specified namespaces)
#     dynamic "ingress" {
#       for_each = length(each.value.network_policy.ingress_from_namespaces) > 0 ? [1] : []
#
#       content {
#         from {
#           # Allow from pods in the same namespace
#           namespace_selector {
#             match_labels = {
#               name = kubernetes_namespace.this[each.key].metadata[0].name
#             }
#           }
#         }
#
#         # Allow from specified namespaces
#         dynamic "from" {
#           for_each = each.value.network_policy.ingress_from_namespaces
#
#           content {
#             namespace_selector {
#               match_labels = {
#                 name = from.value
#               }
#             }
#           }
#         }
#       }
#     }
#
#     # Egress rules (allow all egress by default if enabled)
#     dynamic "egress" {
#       for_each = each.value.network_policy.egress_allowed ? [1] : []
#
#       content {
#         to {
#           # Allow egress to all destinations
#           ip_block {
#             cidr = "0.0.0.0/0"
#           }
#         }
#       }
#     }
#   }
#
#   depends_on = [kubernetes_namespace.this]
# }

# ==============================================================================
# Namespace Configuration Best Practices:
# ==============================================================================
# - Use namespaces for environment isolation (prod, staging, dev)
# - Apply resource quotas to prevent resource exhaustion
# - Configure network policies for security isolation
# - Label namespaces consistently for filtering and organization
# - Use ingress_from_namespaces to allow cross-namespace communication
#
# TO ENABLE: Uncomment the resources above after configuring the Kubernetes
# provider in your root module.
# ==============================================================================
