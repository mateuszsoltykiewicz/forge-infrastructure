#!/bin/bash
# ==============================================================================
# EKS Node Bootstrap Script
# ==============================================================================
# This script is used to bootstrap EKS worker nodes during launch.
# It joins the node to the EKS cluster using the AWS EKS bootstrap script.
# ==============================================================================

set -o xtrace

# Bootstrap the node to join the EKS cluster
/etc/eks/bootstrap.sh '${cluster_name}' \
  --apiserver-endpoint '${cluster_endpoint}' \
  --b64-cluster-ca '${cluster_ca}'
