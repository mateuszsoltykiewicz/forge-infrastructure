# EKS Module

Terraform module for deploying Amazon Elastic Kubernetes Service (EKS) clusters with managed node groups in the Forge platform.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Usage](#usage)
  - [Basic Example](#basic-example)
  - [Customer-Dedicated Example](#customer-dedicated-example)
  - [Custom Node Groups](#custom-node-groups)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Customer-Aware Naming](#customer-aware-naming)
- [Add-ons](#add-ons)
- [IRSA (IAM Roles for Service Accounts)](#irsa-iam-roles-for-service-accounts)
- [Security](#security)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Migration from Source](#migration-from-source)

---

## Overview

This module creates a production-ready Amazon EKS cluster with:
- **EKS Control Plane**: Managed Kubernetes control plane across multiple AZs
- **Managed Node Groups**: Auto-scaling worker nodes with configurable instance types
- **IAM Roles for Service Accounts (IRSA)**: Secure pod-level AWS API access
- **EKS Add-ons**: Essential components (EBS CSI, VPC CNI, CoreDNS, kube-proxy)
- **CloudWatch Logging**: Comprehensive control plane audit and diagnostic logs
- **Customer-Aware Naming**: Support for shared and dedicated architectures

This module is designed for the **Forge platform** and supports multi-tenant deployments with customer-specific naming and tagging.

---

## Features

### Core Features
- ✅ **Kubernetes 1.28+** support with configurable versions
- ✅ **Multi-AZ high availability** for control plane and node groups
- ✅ **Managed node groups** with auto-scaling capabilities
- ✅ **IRSA (IAM Roles for Service Accounts)** for secure AWS API access
- ✅ **EKS-managed add-ons** (EBS CSI, VPC CNI, CoreDNS, kube-proxy)
- ✅ **CloudWatch integration** for logs and metrics
- ✅ **Customer-aware naming and tagging** for cost allocation

### Security Features
- ✅ **Private/public endpoint configuration** with CIDR restrictions
- ✅ **Security group integration** with customizable rules
- ✅ **IAM least-privilege** roles for cluster and nodes
- ✅ **OIDC provider** for secure service account authentication
- ✅ **Optional KMS encryption** for Kubernetes secrets (can be enabled)

### Operational Features
- ✅ **Node group auto-scaling** with min/max/desired size configuration
- ✅ **Spot and On-Demand** instance support
- ✅ **Custom labels and taints** for workload scheduling
- ✅ **Multiple node groups** for workload separation (system, application)
- ✅ **Lifecycle management** with create-before-destroy strategy

---

## Architecture

### Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        EKS Cluster                              │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │           Control Plane (Multi-AZ)                       │   │
│  │  • API Server  • Controller Manager  • Scheduler         │   │
│  │  • etcd (managed by AWS)                                 │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                  Managed Node Groups                     │   │
│  │                                                          │   │
│  │  ┌────────────────┐      ┌─────────────────┐            │   │
│  │  │ System Pool    │      │ Application Pool│            │   │
│  │  │ • 2-4 nodes    │      │ • 2-10 nodes    │            │   │
│  │  │ • t3.medium    │      │ • t3.large      │            │   │
│  │  │ • On-Demand    │      │ • On-Demand     │            │   │
│  │  └────────────────┘      └─────────────────┘            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    EKS Add-ons                           │   │
│  │  • EBS CSI Driver  • VPC CNI  • CoreDNS  • kube-proxy   │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         AWS Services                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ CloudWatch   │  │ OIDC Provider│  │  IAM Roles   │          │
│  │ • Logs       │  │ • IRSA       │  │ • Cluster    │          │
│  │ • Metrics    │  │              │  │ • Nodes      │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

### Network Architecture

```
VPC: forge-production-vpc (10.0.0.0/16)
│
├── Private Subnets (Control Plane + Nodes)
│   ├── us-east-1a: 10.0.1.0/24
│   ├── us-east-1b: 10.0.2.0/24
│   └── us-east-1c: 10.0.3.0/24
│
└── Public Subnets (Optional Public Endpoint)
    ├── us-east-1a: 10.0.101.0/24
    ├── us-east-1b: 10.0.102.0/24
    └── us-east-1c: 10.0.103.0/24
```

---

## Usage

### Basic Example

Deploy a shared EKS cluster for the Forge platform:

```hcl
module "eks" {
  source = "../../modules/eks"

  # Customer context (shared infrastructure)
  customer_id      = ""
  customer_name    = ""
  architecture_type = "shared"
  plan_tier        = ""

  # Environment configuration
  environment = "production"
  aws_region  = "us-east-1"

  # Cluster configuration
  kubernetes_version = "1.31"

  # Network configuration
  vpc_id                    = "vpc-0123456789abcdef0"
  control_plane_subnet_ids  = ["subnet-abc123", "subnet-def456", "subnet-ghi789"]
  node_group_subnet_ids     = ["subnet-abc123", "subnet-def456", "subnet-ghi789"]

  # Endpoint configuration
  endpoint_private_access = true
  endpoint_public_access  = true
  endpoint_public_access_cidrs = ["203.0.113.0/24"] # Your office/VPN CIDR

  # Use default node groups (system + application)
  # node_groups = <use defaults>

  # Enable essential add-ons
  enable_ebs_csi_driver = true
  enable_vpc_cni        = true
  enable_kube_proxy     = true
  enable_coredns        = true

  # Enable IRSA for service accounts
  enable_irsa = true

  tags = {
    Project     = "Forge Platform"
    CostCenter  = "Platform Engineering"
  }
}
```

**Generated cluster name**: `forge-production-eks`

### Customer-Dedicated Example

Deploy a dedicated EKS cluster for a specific customer:

```hcl
module "customer_eks" {
  source = "../../modules/eks"

  # Customer context (dedicated infrastructure)
  customer_id       = "cust-sanofi-001"
  customer_name     = "sanofi"
  architecture_type = "dedicated_regional"
  plan_tier         = "advanced"

  # Environment configuration
  environment = "production"
  aws_region  = "us-east-1"

  # Cluster configuration
  kubernetes_version = "1.31"

  # Network configuration
  vpc_id                    = "vpc-customer123"
  control_plane_subnet_ids  = ["subnet-cust-a", "subnet-cust-b", "subnet-cust-c"]
  node_group_subnet_ids     = ["subnet-cust-a", "subnet-cust-b", "subnet-cust-c"]

  # Private-only cluster
  endpoint_private_access = true
  endpoint_public_access  = false

  # Custom node groups for customer workload
  node_groups = {
    system = {
      desired_size   = 3
      min_size       = 3
      max_size       = 6
      instance_types = ["m5.large"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 100
      labels = {
        role = "system"
        customer = "sanofi"
      }
      taints = []
    }
    application = {
      desired_size   = 5
      min_size       = 3
      max_size       = 20
      instance_types = ["m5.xlarge", "m5.2xlarge"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 200
      labels = {
        role = "application"
        customer = "sanofi"
      }
      taints = []
    }
  }

  # Enable all add-ons
  enable_ebs_csi_driver = true
  enable_vpc_cni        = true
  enable_kube_proxy     = true
  enable_coredns        = true
  enable_irsa           = true

  tags = {
    Customer    = "Sanofi"
    CostCenter  = "Customer-Sanofi"
    Environment = "Production"
  }
}
```

**Generated cluster name**: `sanofi-us-east-1-eks`

### Custom Node Groups

Define custom node groups with specific configurations:

```hcl
module "eks" {
  source = "../../modules/eks"

  # ... other configuration ...

  node_groups = {
    # System workloads (monitoring, logging, etc.)
    system = {
      desired_size   = 2
      min_size       = 2
      max_size       = 4
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      labels = {
        role = "system"
        workload-type = "infrastructure"
      }
      taints = [{
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }

    # General application workloads
    application = {
      desired_size   = 3
      min_size       = 2
      max_size       = 10
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 100
      labels = {
        role = "application"
        workload-type = "general"
      }
      taints = []
    }

    # High-memory workloads
    memory_optimized = {
      desired_size   = 2
      min_size       = 1
      max_size       = 5
      instance_types = ["r5.xlarge", "r5.2xlarge"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 100
      labels = {
        role = "memory-optimized"
        workload-type = "data-processing"
      }
      taints = [{
        key    = "workload-type"
        value  = "memory-optimized"
        effect = "NO_SCHEDULE"
      }]
    }

    # Spot instances for cost optimization
    spot_workers = {
      desired_size   = 3
      min_size       = 0
      max_size       = 10
      instance_types = ["t3.large", "t3a.large"]
      capacity_type  = "SPOT"
      disk_size      = 100
      labels = {
        role = "spot"
        workload-type = "batch"
      }
      taints = [{
        key    = "spot-instance"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
  }
}
```

### Multi-Tenant Shared Cluster with Customer Node Groups

Deploy a shared Forge cluster with dedicated node groups for Basic plan customers:

```hcl
module "shared_eks" {
  source = "../../modules/eks"

  # Shared infrastructure context
  customer_id       = ""
  customer_name     = ""
  architecture_type = "shared"
  plan_tier         = ""

  environment = "production"
  aws_region  = "us-east-1"

  kubernetes_version = "1.31"

  vpc_id                    = "vpc-forge-shared"
  control_plane_subnet_ids  = ["subnet-a", "subnet-b", "subnet-c"]
  node_group_subnet_ids     = ["subnet-a", "subnet-b", "subnet-c"]

  # System node group for platform components (untainted)
  node_groups = {
    system = {
      desired_size   = 3
      min_size       = 3
      max_size       = 5
      instance_types = ["m5.xlarge"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 100
      labels = {
        node-role     = "system"
        workload-type = "platform"
        managed-by    = "forge"
      }
      taints = [] # No taints - runs platform components and Trial workloads
    }
  }

  # Customer-specific node groups for Basic plan customers
  customer_node_groups = {
    "globex-corp" = {
      customer_id    = "cust_001"
      customer_name  = "globex-corp"
      plan_tier      = "basic"
      desired_size   = 1
      min_size       = 1
      max_size       = 3
      instance_types = ["t3.medium", "t3.large"]
      capacity_type  = "SPOT"  # Cost optimization for Basic plan
      disk_size      = 50
    }
    "acme-inc" = {
      customer_id    = "cust_002"
      customer_name  = "acme-inc"
      plan_tier      = "basic"
      desired_size   = 2
      min_size       = 1
      max_size       = 5
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 80
    }
    "umbrella-corp" = {
      customer_id    = "cust_003"
      customer_name  = "umbrella-corp"
      plan_tier      = "basic"
      desired_size   = 1
      min_size       = 1
      max_size       = 4
      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
      disk_size      = 50
    }
  }

  enable_ebs_csi_driver = true
  enable_vpc_cni        = true
  enable_kube_proxy     = true
  enable_coredns        = true
  enable_irsa           = true

  tags = {
    Project        = "Forge Platform"
    ClusterType    = "Shared"
    MultiTenant    = "true"
  }
}
```

**Node Group Architecture**:
- **System node group** (`forge-production-system`): Runs Forge platform components (ArgoCD, CRD operators, monitoring) + Trial customer workloads
- **Customer node groups**:
  - `forge-production-customer-globex-corp`: Tainted with `customer=globex-corp:NoSchedule`
  - `forge-production-customer-acme-inc`: Tainted with `customer=acme-inc:NoSchedule`
  - `forge-production-customer-umbrella-corp`: Tainted with `customer=umbrella-corp:NoSchedule`

**Cost Tracking**: Each customer node group tagged with:
- `CustomerId`: cust_001, cust_002, cust_003
- `CustomerName`: globex-corp, acme-inc, umbrella-corp
- `CostCenter`: Customer:cust_001, Customer:cust_002, Customer:cust_003

**Isolation**:
- Trial customers: Share `system` node group (namespace isolation only)
- Basic customers: Dedicated node groups with taints (compute isolation + namespace isolation)

---

## Inputs

### Customer Context Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `customer_id` | Customer identifier (empty for shared infrastructure) | `string` | `""` | no |
| `customer_name` | Customer name for resource naming (empty for shared infrastructure) | `string` | `""` | no |
| `architecture_type` | Architecture deployment type: shared, dedicated_local, or dedicated_regional | `string` | `"shared"` | no |
| `plan_tier` | Customer plan tier (e.g., basic, pro, advanced) for cost allocation | `string` | `""` | no |

### Cluster Configuration Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `environment` | Environment name (production, staging, development) | `string` | n/a | yes |
| `aws_region` | AWS region where the EKS cluster will be deployed | `string` | n/a | yes |
| `cluster_name_override` | Optional override for cluster name (auto-generated if empty) | `string` | `""` | no |
| `kubernetes_version` | Kubernetes version for the EKS cluster | `string` | `"1.31"` | no |

### Network Configuration Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `vpc_id` | VPC ID where the EKS cluster will be deployed | `string` | n/a | yes |
| `control_plane_subnet_ids` | Subnet IDs for the EKS control plane (must span at least 2 AZs) | `list(string)` | n/a | yes |
| `node_group_subnet_ids` | Subnet IDs for EKS worker nodes (private subnets recommended) | `list(string)` | n/a | yes |

### Endpoint Configuration Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `endpoint_private_access` | Enable private API server endpoint | `bool` | `true` | no |
| `endpoint_public_access` | Enable public API server endpoint | `bool` | `true` | no |
| `endpoint_public_access_cidrs` | CIDR blocks allowed to access the public API endpoint | `list(string)` | `["0.0.0.0/0"]` | no |

### Logging Configuration Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `enabled_cluster_log_types` | List of control plane logging types to enable | `list(string)` | `["api", "audit", "authenticator", "controllerManager", "scheduler"]` | no |
| `cluster_log_retention_days` | Number of days to retain cluster logs in CloudWatch | `number` | `7` | no |

### Add-ons Configuration Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `enable_ebs_csi_driver` | Enable AWS EBS CSI driver add-on for persistent volumes | `bool` | `true` | no |
| `enable_vpc_cni` | Enable VPC CNI add-on for pod networking | `bool` | `true` | no |
| `enable_kube_proxy` | Enable kube-proxy add-on | `bool` | `true` | no |
| `enable_coredns` | Enable CoreDNS add-on for DNS resolution | `bool` | `true` | no |

### Node Groups Configuration Variable

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `node_groups` | Map of EKS managed node groups to create | `map(object)` | See [default node groups](#default-node-groups) | no |

#### Default Node Groups

```hcl
{
  system = {
    desired_size   = 2
    min_size       = 2
    max_size       = 4
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 50
    labels = {
      role = "system"
    }
    taints = []
  }
  application = {
    desired_size   = 3
    min_size       = 2
    max_size       = 10
    instance_types = ["t3.large"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 100
    labels = {
      role = "application"
    }
    taints = []
  }
}
```

### Security Configuration Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `security_group_ids` | Additional security group IDs to attach to the cluster | `list(string)` | `[]` | no |
| `node_security_group_ids` | Additional security group IDs to attach to worker nodes | `list(string)` | `[]` | no |

### IAM Configuration Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `enable_irsa` | Enable IAM Roles for Service Accounts (IRSA) | `bool` | `true` | no |
| `cluster_creator_admin_permissions` | Enable cluster creator admin permissions | `bool` | `true` | no |

### Tags Variable

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `tags` | Additional tags to apply to all EKS resources | `map(string)` | `{}` | no |

---

## Outputs

### Cluster Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | The ID/name of the EKS cluster |
| `cluster_arn` | The ARN of the EKS cluster |
| `cluster_name` | The name of the EKS cluster |
| `cluster_endpoint` | Endpoint for the EKS cluster API server |
| `cluster_version` | The Kubernetes server version of the cluster |
| `cluster_platform_version` | The platform version of the EKS cluster |
| `cluster_certificate_authority_data` | Base64 encoded certificate data (sensitive) |

### OIDC Provider Outputs

| Name | Description |
|------|-------------|
| `cluster_oidc_issuer_url` | The URL on the EKS cluster OIDC issuer |
| `oidc_provider_arn` | ARN of the OIDC provider for IRSA |
| `oidc_provider_url` | OIDC provider URL without https:// prefix |

### Security Group Outputs

| Name | Description |
|------|-------------|
| `cluster_security_group_id` | Security group ID attached to the EKS cluster |

### IAM Role Outputs

| Name | Description |
|------|-------------|
| `cluster_iam_role_arn` | IAM role ARN of the EKS cluster |
| `cluster_iam_role_name` | IAM role name of the EKS cluster |
| `node_group_iam_role_arn` | IAM role ARN of the EKS node groups |
| `node_group_iam_role_name` | IAM role name of the EKS node groups |
| `ebs_csi_driver_iam_role_arn` | IAM role ARN for the EBS CSI driver (IRSA) |

### Node Group Outputs

| Name | Description |
|------|-------------|
| `node_groups` | Map of node group names to their attributes |

### CloudWatch Outputs

| Name | Description |
|------|-------------|
| `cloudwatch_log_group_name` | Name of the CloudWatch log group for EKS cluster logs |
| `cloudwatch_log_group_arn` | ARN of the CloudWatch log group |

### Connection Information

| Name | Description |
|------|-------------|
| `kubeconfig_command` | Command to update kubeconfig for kubectl access |

---

## Customer-Aware Naming

The module automatically generates resource names based on the customer context:

### Shared Infrastructure

For shared Forge infrastructure (`architecture_type = "shared"`):

```
Cluster Name:     forge-{environment}-eks
Example:          forge-production-eks

IAM Roles:        forge-production-eks-cluster-role
                  forge-production-eks-node-group-role
                  forge-production-eks-ebs-csi-driver-role

CloudWatch Logs:  /aws/eks/forge-production-eks/cluster
```

### Dedicated Infrastructure

For customer-dedicated infrastructure (`architecture_type = "dedicated_*"`):

```
Cluster Name:     {customer_name}-{region}-eks
Example:          sanofi-us-east-1-eks

IAM Roles:        sanofi-us-east-1-eks-cluster-role
                  sanofi-us-east-1-eks-node-group-role
                  sanofi-us-east-1-eks-ebs-csi-driver-role

CloudWatch Logs:  /aws/eks/sanofi-us-east-1-eks/cluster
```

### Tagging Strategy

**Base tags** (applied to all resources):
```hcl
{
  Environment       = "production"
  ManagedBy         = "Terraform"
  TerraformModule   = "forge/modules/eks"
  Region            = "us-east-1"
  ClusterName       = "forge-production-eks"
  KubernetesVersion = "1.31"
}
```

**Customer tags** (applied for dedicated architectures):
```hcl
{
  CustomerId       = "cust-sanofi-001"
  CustomerName     = "sanofi"
  ArchitectureType = "dedicated_regional"
  PlanTier         = "advanced"
}
```

---

## Add-ons

The module installs and manages essential EKS add-ons:

### EBS CSI Driver

Enables persistent volumes backed by Amazon EBS:

```hcl
enable_ebs_csi_driver = true
```

**Features**:
- Dynamic volume provisioning
- Volume snapshots and restore
- Volume resize (online expansion)
- IRSA-enabled for secure AWS API access

**Storage Classes**:
After deployment, create storage classes:
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  fsType: ext4
volumeBindingMode: WaitForFirstConsumer
```

### VPC CNI

Provides native VPC networking for pods:

```hcl
enable_vpc_cni = true
```

**Features**:
- Pods get ENI IP addresses from VPC
- Direct pod-to-pod communication
- Security group per pod support
- Network policy enforcement

### CoreDNS

DNS resolution for Kubernetes services:

```hcl
enable_coredns = true
```

**Features**:
- Service discovery (service.namespace.svc.cluster.local)
- External DNS resolution
- Caching for performance
- Customizable via ConfigMap

### kube-proxy

Network proxying for Kubernetes services:

```hcl
enable_kube_proxy = true
```

**Features**:
- Service load balancing
- iptables or IPVS mode
- ClusterIP and NodePort support

---

## IRSA (IAM Roles for Service Accounts)

IAM Roles for Service Accounts (IRSA) enables Kubernetes pods to assume AWS IAM roles without static credentials.

### How IRSA Works

1. **OIDC Provider**: Module creates an OIDC identity provider linked to the EKS cluster
2. **Service Account Annotation**: Annotate Kubernetes service accounts with IAM role ARN
3. **Pod Identity**: AWS SDK automatically assumes the IAM role when running in the pod

### Example: ArgoCD with IRSA

Create an IAM role for ArgoCD to access AWS resources:

```hcl
# Create IAM role for ArgoCD
resource "aws_iam_role" "argocd" {
  name = "${module.eks.cluster_name}-argocd-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider_url}:sub" = "system:serviceaccount:argocd:argocd-server"
            "${module.eks.oidc_provider_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Attach policy for ECR access
resource "aws_iam_role_policy_attachment" "argocd_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.argocd.name
}
```

Annotate the ArgoCD service account:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: argocd-server
  namespace: argocd
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/forge-production-eks-argocd-role
```

### Pre-configured IRSA Roles

The module automatically creates IRSA roles for:

| Add-on | Service Account | Namespace | Permissions |
|--------|----------------|-----------|-------------|
| EBS CSI Driver | `ebs-csi-controller-sa` | `kube-system` | EBS volume management |

---

## Security

### Network Security

#### Private Cluster Configuration

For maximum security, disable public endpoint:

```hcl
endpoint_private_access = true
endpoint_public_access  = false
```

**Access methods**:
- VPN connection to VPC
- AWS Transit Gateway
- Bastion host in public subnet
- AWS Systems Manager Session Manager

#### Public Endpoint with CIDR Restrictions

Allow public access only from trusted networks:

```hcl
endpoint_private_access = true
endpoint_public_access  = true
endpoint_public_access_cidrs = [
  "203.0.113.0/24",  # Office network
  "198.51.100.0/24"  # VPN gateway
]
```

### IAM Security

#### Least-Privilege Roles

The module creates IAM roles with minimum required permissions:

- **Cluster role**: `AmazonEKSClusterPolicy`, `AmazonEKSVPCResourceController`
- **Node role**: `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`
- **Add-on roles**: Specific policies per add-on (e.g., EBS CSI driver)

#### RBAC Integration

Configure Kubernetes RBAC after cluster creation:

```bash
# Get kubeconfig
aws eks update-kubeconfig --region us-east-1 --name forge-production-eks

# Create read-only role
kubectl create clusterrolebinding readonly-binding \
  --clusterrole=view \
  --user=arn:aws:iam::ACCOUNT_ID:role/DeveloperRole
```

### Secrets Encryption

Enable KMS encryption for Kubernetes secrets (optional):

```hcl
# Uncomment in main.tf
encryption_config {
  provider {
    key_arn = var.kms_key_arn
  }
  resources = ["secrets"]
}
```

### Security Best Practices

1. ✅ **Use private subnets** for node groups
2. ✅ **Enable CloudWatch logging** for audit trails
3. ✅ **Restrict API endpoint access** with CIDR allowlists
4. ✅ **Use IRSA** instead of static IAM credentials
5. ✅ **Enable secrets encryption** with KMS
6. ✅ **Implement network policies** (Calico or AWS VPC CNI)
7. ✅ **Use Pod Security Standards** (restricted profile)
8. ✅ **Regular version updates** for Kubernetes and add-ons

---

## Monitoring

### CloudWatch Logs

The module enables comprehensive control plane logging:

```hcl
enabled_cluster_log_types = [
  "api",                 # API server logs
  "audit",               # Kubernetes audit logs
  "authenticator",       # Authentication logs
  "controllerManager",   # Controller manager logs
  "scheduler"            # Scheduler logs
]
```

**View logs**:
```bash
aws logs tail /aws/eks/forge-production-eks/cluster --follow
```

### CloudWatch Insights Queries

**Query failed authentication attempts**:
```
fields @timestamp, @message
| filter @logStream like /authenticator/
| filter @message like /failed/
| sort @timestamp desc
| limit 20
```

**Query API server errors**:
```
fields @timestamp, requestURI, responseStatus.code, user.username
| filter @logStream like /kube-apiserver-audit/
| filter responseStatus.code >= 400
| stats count() by responseStatus.code
```

### kubectl Access

After deployment, configure kubectl:

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name forge-production-eks

# Verify connection
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces
```

### Metrics and Dashboards

Install metrics server for resource monitoring:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# View node metrics
kubectl top nodes

# View pod metrics
kubectl top pods --all-namespaces
```

---

## Troubleshooting

### Common Issues

#### Issue: Cluster creation fails with "subnets must span at least 2 AZs"

**Solution**: Ensure `control_plane_subnet_ids` includes subnets from at least 2 different availability zones.

```hcl
control_plane_subnet_ids = [
  "subnet-abc123",  # us-east-1a
  "subnet-def456",  # us-east-1b
  "subnet-ghi789"   # us-east-1c
]
```

#### Issue: Node groups fail to join cluster

**Symptoms**: Nodes are created but don't appear in `kubectl get nodes`.

**Solution**: Check security group rules allow node-to-cluster communication:

```bash
# Check node group status
aws eks describe-nodegroup \
  --cluster-name forge-production-eks \
  --nodegroup-name forge-production-eks-system

# Check node instance security groups
aws ec2 describe-security-groups \
  --group-ids sg-xxxxxxxxxxxx
```

#### Issue: Pods can't pull images from ECR

**Symptoms**: ImagePullBackOff errors for ECR images.

**Solution**: Verify node IAM role has ECR permissions:

```bash
# Check role policies
aws iam list-attached-role-policies \
  --role-name forge-production-eks-node-group-role

# Should include: AmazonEC2ContainerRegistryReadOnly
```

#### Issue: EBS volumes fail to provision

**Symptoms**: PersistentVolumeClaim stuck in "Pending" state.

**Solution**: Verify EBS CSI driver is installed and IRSA role is configured:

```bash
# Check EBS CSI driver pods
kubectl get pods -n kube-system | grep ebs-csi

# Check IRSA annotation
kubectl describe sa ebs-csi-controller-sa -n kube-system

# Should show: eks.amazonaws.com/role-arn annotation
```

#### Issue: Can't access cluster API endpoint

**Symptoms**: `kubectl` commands timeout.

**Solution**: Check endpoint configuration and CIDR allowlist:

```bash
# Check cluster endpoint configuration
aws eks describe-cluster \
  --name forge-production-eks \
  --query 'cluster.resourcesVpcConfig'

# If public endpoint is enabled, verify your IP is in allowlist
curl -s https://checkip.amazonaws.com

# If private endpoint only, ensure you're connected via VPN or bastion
```

### Debugging Commands

```bash
# Check cluster status
aws eks describe-cluster --name forge-production-eks

# List node groups
aws eks list-nodegroups --cluster-name forge-production-eks

# Check node group health
aws eks describe-nodegroup \
  --cluster-name forge-production-eks \
  --nodegroup-name forge-production-eks-system

# View cluster logs
aws logs tail /aws/eks/forge-production-eks/cluster --follow

# Check OIDC provider
aws iam list-open-id-connect-providers

# Verify IAM roles
aws iam get-role --role-name forge-production-eks-cluster-role
aws iam get-role --role-name forge-production-eks-node-group-role
```

---

## Migration from Source

This Forge EKS module is a **simplified version** of the source `cloud-platform-features/iac/aws/terraform/modules/orchestration/eks` module. Key differences:

### Removed Features

- ❌ **Karpenter support**: Use managed node groups only (simpler, AWS-managed)
- ❌ **Fargate support**: Use managed node groups only
- ❌ **VPC endpoints automation**: Create separately if needed
- ❌ **CloudWatch dashboards**: Use CloudWatch Insights for custom queries
- ❌ **Terraform remote state lookups**: Use explicit variable passing
- ❌ **Complex auto-detection logic**: Explicit configuration preferred

### Simplified Features

- ✅ **Managed node groups**: Simplified configuration with sensible defaults
- ✅ **Add-ons**: Essential add-ons only (EBS CSI, VPC CNI, CoreDNS, kube-proxy)
- ✅ **IRSA**: Pre-configured for EBS CSI driver only (add more as needed)
- ✅ **Logging**: All log types enabled by default
- ✅ **Networking**: Explicit subnet IDs (no tag-based lookups)

### Migration Steps

If migrating from the source module:

1. **Remove Karpenter resources**: Use managed node groups instead
2. **Remove Fargate profiles**: Use managed node groups instead
3. **Update variables**: Remove Karpenter/Fargate-specific variables
4. **Simplify node group configuration**: Use the `node_groups` map
5. **Update IAM roles**: Remove Karpenter-specific IAM resources
6. **Update add-ons**: Use AWS-managed add-ons only
7. **Test deployment**: Validate in non-production first

### Why Simplified?

The Forge platform prioritizes:
- **Simplicity**: Easier to understand and maintain
- **AWS-managed components**: Less operational burden
- **Explicit configuration**: No hidden auto-detection
- **Database-driven orchestration**: CloudOrchestrator generates root modules

For advanced features (Karpenter, Fargate, VPC endpoints), they can be added later as P1 enhancements.

---

## License

This module is part of the Forge platform. Internal use only.

---

## Support

For issues or questions:
- **Documentation**: See `/docs/architecture/` in the repository
- **Issues**: Create a GitHub issue in the `cloud-platform-features` repository
- **Slack**: #forge-platform channel

---

**Last Updated**: December 2024  
**Module Version**: 1.0.0  
**Terraform Version**: >= 1.5.0  
**AWS Provider Version**: >= 6.9.0
