# EKS Module - Production-Grade Kubernetes Cluster

This module creates a production-ready Amazon EKS cluster with Graviton3-powered managed node groups, comprehensive security features, and complete observability.

## Features

- ✅ **Graviton3 Instances** - ARM64 architecture for 60% better price/performance
- ✅ **KMS Encryption** - Secrets encrypted at rest with automatic key rotation
- ✅ **IRSA Support** - IAM Roles for Service Accounts for pod-level permissions
- ✅ **Pod Identity Agent** - Modern alternative to IRSA
- ✅ **Managed Add-ons** - CoreDNS, VPC-CNI, Kube-Proxy, EBS CSI
- ✅ **CloudWatch Integration** - Control plane logging with KMS encryption
- ✅ **Cluster Autoscaler** - Automatic node scaling based on demand
- ✅ **IMDSv2 Required** - Enhanced security for EC2 metadata
- ✅ **Multi-Tenant** - Supports shared, customer-specific, and project-specific clusters

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         EKS Cluster                         │
│  ┌─────────────────────────────────────────────────────┐   │
│  │           Control Plane (Managed by AWS)            │   │
│  │  - Kubernetes API Server (HA, Multi-AZ)             │   │
│  │  - etcd (Encrypted with KMS)                        │   │
│  │  - CloudWatch Logs (api, audit, authenticator...)   │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                │
│  ┌─────────────────────────┴───────────────────────────┐   │
│  │              Managed Node Group                      │   │
│  │  - Graviton3 Instances (m7g.large, m7g.xlarge)      │   │
│  │  - Auto Scaling Group (1-5 nodes)                   │   │
│  │  - EBS Volumes (gp3, encrypted with KMS)            │   │
│  │  - IMDSv2 (Security best practice)                  │   │
│  │  - System workloads taint (optional)                │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Example - Shared Cluster

```hcl
module "eks" {
  source = "./compute/eks"

  workspace    = "production"
  environment  = "production"
  aws_region   = "us-west-2"
  
  kubernetes_version = "1.31"
  
  common_tags = {
    Project     = "MyApp"
    CostCenter  = "Engineering"
  }
}
```

### Customer-Specific Cluster

```hcl
module "eks_customer" {
  source = "./compute/eks"

  workspace     = "production"
  environment   = "production"
  customer_name = "acme-corp"
  aws_region    = "us-west-2"
  
  kubernetes_version = "1.31"
  
  # Custom node configuration
  system_node_group_instance_types = ["m7g.xlarge"]
  system_node_group_min_size       = 2
  system_node_group_max_size       = 10
  
  common_tags = {
    Customer = "Acme Corp"
  }
}
```

### Project-Specific Cluster

```hcl
module "eks_project" {
  source = "./compute/eks"

  workspace     = "production"
  environment   = "production"
  customer_name = "acme-corp"
  project_name  = "analytics-platform"
  aws_region    = "us-west-2"
  
  kubernetes_version = "1.31"
  
  common_tags = {
    Customer = "Acme Corp"
    Project  = "Analytics Platform"
  }
}
```

## Graviton3 Configuration

This module defaults to **AWS Graviton3 processors** for optimal price/performance:

### Default Instance Types
- **Primary:** `m7g.large` (2 vCPU, 8 GiB RAM)
- **Secondary:** `m7g.xlarge` (4 vCPU, 16 GiB RAM)

### Benefits
- **60%** better energy efficiency vs x86
- **25%** better performance vs Graviton2
- **40%** better price/performance vs x86

### Container Image Requirements
- Must support **ARM64/aarch64** architecture
- Use multi-arch images: `--platform linux/arm64,linux/amd64`
- Example: `public.ecr.aws/docker/library/nginx:latest` (multi-arch)

### Building ARM64 Images

```bash
# Docker buildx for multi-arch
docker buildx build --platform linux/arm64,linux/amd64 -t myapp:latest .

# Verify architecture
docker manifest inspect myapp:latest
```

## Node Group Sizing Strategies

### Development Environment
```hcl
system_node_group_instance_types = ["m7g.large"]
system_node_group_min_size       = 1
system_node_group_max_size       = 3
system_node_group_desired_size   = 1
```

### Staging Environment
```hcl
system_node_group_instance_types = ["m7g.large", "m7g.xlarge"]
system_node_group_min_size       = 2
system_node_group_max_size       = 5
system_node_group_desired_size   = 2
```

### Production Environment
```hcl
system_node_group_instance_types = ["m7g.xlarge", "m7g.2xlarge"]
system_node_group_min_size       = 3
system_node_group_max_size       = 10
system_node_group_desired_size   = 3
```

## EKS Add-ons Management

### Included Add-ons

#### CoreDNS
- DNS service for Kubernetes
- Resource limits: 100m CPU, 150Mi memory
- Auto-updated to latest compatible version

#### VPC-CNI
- AWS CNI plugin for pod networking
- **IRSA enabled** - Dedicated IAM role
- IP address management for pods
- Installed before compute nodes

#### Kube-Proxy
- Network proxy running on each node
- Maintains network rules for Services
- Auto-updated with cluster version

#### EBS CSI Driver
- Persistent volume support using EBS
- **IRSA enabled** - Dedicated IAM role
- Automatic volume provisioning
- Snapshot support

#### Pod Identity Agent
- Modern alternative to IRSA
- Simplified pod authentication
- Installed before compute nodes

### Updating Add-ons

```bash
# View current versions
aws eks list-addons --cluster-name <cluster-name>

# Update add-on
aws eks update-addon \
  --cluster-name <cluster-name> \
  --addon-name vpc-cni \
  --addon-version v1.18.0-eksbuild.1
```

## IRSA Examples

### S3 Access for Application

```hcl
# 1. Create IAM role
resource "aws_iam_role" "app_s3_access" {
  name = "eks-app-s3-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${module.eks.oidc_provider}:sub" = "system:serviceaccount:default:my-app"
          "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

# 2. Attach S3 policy
resource "aws_iam_role_policy_attachment" "app_s3" {
  role       = aws_iam_role.app_s3_access.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# 3. Create Kubernetes ServiceAccount
# kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/eks-app-s3-access
```

### RDS Access for Backend

```yaml
# Service Account with IRSA annotation
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backend-app
  namespace: production
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/eks-backend-rds-access
---
# Deployment using the ServiceAccount
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: production
spec:
  template:
    spec:
      serviceAccountName: backend-app  # Links to IRSA role
      containers:
      - name: app
        image: backend:latest
        # AWS SDK will automatically use IRSA credentials
```

## Upgrade Guide - Module v21.x

This module uses `terraform-aws-modules/eks/aws` version **~> 21.0**. Key changes from v20.x:

### Renamed Variables

| v20.x | v21.x |
|-------|-------|
| `cluster_name` | `name` |
| `cluster_version` | `kubernetes_version` |
| `cluster_endpoint_*` | `endpoint_*` |
| `cluster_encryption_config` | `encryption_config` |
| `cluster_enabled_log_types` | `enabled_log_types` |
| `cluster_security_group_*` | `security_group_*` |
| `cluster_addons` | `addons` |

### Migration Example

```hcl
# OLD (v20.x)
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"
  
  cluster_name    = "my-cluster"
  cluster_version = "1.30"
  cluster_addons  = { ... }
}

# NEW (v21.x)
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"
  
  name               = "my-cluster"
  kubernetes_version = "1.30"
  addons             = { ... }
}
```

### State Migration (if upgrading)

```bash
# No state migration needed - variable renames are handled internally
terraform plan  # Review changes
terraform apply # Apply if changes look correct
```

## Networking Configuration

### VPC Requirements

- **Minimum 2 subnets** in different AZs (3 recommended for HA)
- **Private subnets** for node groups
- **Public subnets** for Load Balancers (if needed)
- **NAT Gateway** for outbound internet access
- **VPC endpoints** for AWS services (optional, cost savings)

### Auto-Discovery

This module auto-discovers VPC and subnets using tags:

```hcl
# VPC tags (required)
ManagedBy   = "Terraform"
Workspace   = var.workspace
Environment = var.environment
Customer    = var.customer_name  # If customer-specific
Project     = var.project_name   # If project-specific

# Subnet tags (required)
"kubernetes.io/role/internal-elb" = "1"  # For private subnets
```

### Custom Subnet Selection

Create custom subnets in the module (automatic):

```terraform
# Module creates private subnets automatically
# Naming: forge-{env}-{customer}-{project}-eks-private-{az}
# CIDR: Auto-calculated within VPC CIDR
```

## Security Best Practices

### 1. Encryption
- ✅ Secrets encrypted with KMS
- ✅ EBS volumes encrypted
- ✅ CloudWatch Logs encrypted
- ✅ Automatic key rotation for production

### 2. Network Security
- ✅ Private API endpoint by default
- ✅ Restricted security groups
- ✅ VPC isolation
- ✅ Network policies (via Calico/Cilium)

### 3. Access Control
- ✅ RBAC enabled
- ✅ API authentication mode: `API_AND_CONFIG_MAP`
- ✅ Terraform caller gets admin access automatically
- ✅ Additional access entries via variable

### 4. Instance Security
- ✅ IMDSv2 required (prevents SSRF attacks)
- ✅ SSM access for troubleshooting (no SSH needed)
- ✅ Latest AL2023 AMI with security patches

### 5. Audit Logging
- ✅ Control plane logs to CloudWatch
- ✅ Log types: api, audit, authenticator, controllerManager, scheduler
- ✅ 90-day retention (configurable)

## Monitoring & Observability

### CloudWatch Logs

```bash
# View API server logs
aws logs tail /aws/eks/forge-prod-eks/cluster --follow

# Query authentication failures
aws logs filter-pattern \
  --log-group-name /aws/eks/forge-prod-eks/cluster \
  --filter-pattern "Forbidden"
```

### CloudWatch Container Insights

```bash
# Install Container Insights
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml
```

### Cluster Autoscaler

Automatically installed and configured. Monitor with:

```bash
# View autoscaler logs
kubectl logs -n kube-system deployment/cluster-autoscaler

# Check scaling activity
kubectl get events --sort-by='.lastTimestamp' | grep cluster-autoscaler
```

## Troubleshooting

### Nodes Not Joining Cluster

```bash
# Check node IAM role
aws iam get-role --role-name <node-role-name>

# Verify security groups
aws ec2 describe-security-groups --group-ids <sg-id>

# Check CloudWatch logs
aws logs tail /aws/eks/<cluster-name>/cluster --follow
```

### Pod Can't Access AWS Services (IRSA Issues)

```bash
# Verify OIDC provider
aws eks describe-cluster --name <cluster-name> \
  --query "cluster.identity.oidc.issuer" --output text

# Check ServiceAccount annotation
kubectl describe sa <sa-name> -n <namespace>

# Test from pod
kubectl run test --rm -it --image=amazon/aws-cli \
  --serviceaccount=<sa-name> -- sts get-caller-identity
```

### Upgrade Failed

```bash
# Check upgrade status
aws eks describe-update \
  --name <cluster-name> \
  --update-id <update-id>

# Rollback not possible - fix issues and retry
# Common issues:
# - Incompatible add-on versions
# - PSP policies (removed in 1.25+)
# - Deprecated API versions
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `workspace` | Workspace identifier | `string` | - | yes |
| `environment` | Environment (production/staging/development) | `string` | - | yes |
| `customer_name` | Customer name for multi-tenant setup | `string` | `null` | no |
| `project_name` | Project name for project-specific cluster | `string` | `null` | no |
| `kubernetes_version` | EKS cluster version | `string` | `"1.31"` | no |
| `system_node_group_instance_types` | Instance types for node group | `list(string)` | `["m7g.large", "m7g.xlarge"]` | no |
| `system_node_group_min_size` | Minimum nodes | `number` | `1` | no |
| `system_node_group_max_size` | Maximum nodes | `number` | `5` | no |
| `system_node_group_desired_size` | Desired nodes | `number` | `2` | no |
| `enable_system_node_taints` | Enable CriticalAddonsOnly taint | `bool` | `false` | no |

See `variables.tf` for complete list.

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | EKS cluster ID |
| `cluster_name` | EKS cluster name |
| `cluster_arn` | EKS cluster ARN |
| `cluster_endpoint` | Kubernetes API endpoint |
| `cluster_certificate_authority_data` | CA certificate (base64) |
| `cluster_version` | Kubernetes version |
| `oidc_provider_arn` | OIDC provider ARN for IRSA |
| `node_security_group_id` | Node security group ID |

See `outputs.tf` for complete list.

## Cost Optimization Tips

1. **Use Graviton3** - 40% better price/performance (already default)
2. **Spot Instances** - Set `capacity_type = "SPOT"` for non-critical workloads
3. **Cluster Autoscaler** - Automatically scales down unused nodes
4. **Right-size nodes** - Monitor and adjust instance types
5. **Reserved Instances** - Commit for 1-3 years for production
6. **Fargate** - Serverless option for bursty workloads (separate module)

## Performance Tuning

### Large Clusters (>100 nodes)

```hcl
# Increase control plane capacity
# Note: AWS manages this, but you can request quota increases

# Optimize VPC-CNI
system_node_group_max_size = 100

# Use larger instance types for system nodes
system_node_group_instance_types = ["m7g.2xlarge"]
```

### High Pod Density

```bash
# Increase max pods per node (requires VPC-CNI update)
kubectl set env daemonset aws-node -n kube-system ENABLE_PREFIX_DELEGATION=true
kubectl set env daemonset aws-node -n kube-system WARM_PREFIX_TARGET=1
```

## References

- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [EKS Workshop](https://www.eksworkshop.com/)
- [terraform-aws-modules/eks](https://github.com/terraform-aws-modules/terraform-aws-eks)
- [Graviton3 Performance](https://aws.amazon.com/ec2/graviton/)
- [IRSA Documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)

## License

See parent directory LICENSE file.
