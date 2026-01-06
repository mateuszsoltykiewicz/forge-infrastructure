# Forge Infrastructure - Multi-Environment Deployment (us-east-1)

Production-ready infrastructure deployment for the Forge platform on AWS.

## Architecture Overview

### Single-Region, Multi-Environment Setup
- **Region**: us-east-1
- **Environments**: Production, Staging, Development
- **VPC**: Single shared VPC (10.0.0.0/16)
- **EKS**: Single Kubernetes cluster with namespace isolation
- **Cost Optimization**: Shared RDS and Redis between environments (~$600/month savings)

### Resources Deployed

| Resource | Quantity | Configuration | Purpose |
|----------|----------|---------------|---------|
| **VPC** | 1 | 10.0.0.0/16 | Network foundation |
| **EKS Cluster** | 1 | K8s 1.31, 3 nodes (t3.large) | Container orchestration |
| **EKS Namespaces** | 3 | prod-cronus, stag-cronus, dev-cronus | Environment isolation |
| **ALB** | 3 | Public HTTPS (443), HTTP->HTTPS redirect | Load balancing per environment |
| **RDS PostgreSQL** | 1 | db.r8g.xlarge, 500GB, Multi-AZ | Shared production database |
| **ElastiCache Redis** | 1 | cache.r7g.large, 2 nodes, Multi-AZ | Shared production cache |

### Domain Configuration

- **Production**: `prod.insighthealth.io`
- **Staging**: `stag.insighthealth.io`
- **Development**: `dev.insighthealth.io`

### Cost Estimate

**Total: ~$1,000/month**

- EKS Control Plane: $216/month (1 cluster @ $0.10/hour × 2,160 hours)
- EC2 Nodes: $219/month (3× t3.large @ $0.0832/hour)
- RDS PostgreSQL: $456/month (db.r8g.xlarge @ $0.619/hour)
- ElastiCache Redis: $127/month (2× cache.r7g.large @ $0.259/hour)
- Application Load Balancers: $54/month (3× ALB @ $0.0225/hour)
- Data Transfer & Storage: ~$30/month

**Savings from Resource Sharing**: ~$600/month
- Without sharing: 3× RDS + 3× Redis = ~$1,600/month
- With sharing: 1× RDS + 1× Redis = ~$600/month

## Prerequisites

### 1. AWS CLI Configured
```bash
aws configure
# Set region: us-east-1
# Ensure you have admin or sufficient IAM permissions
```

### 2. Terraform Installed
```bash
terraform version
# Required: >= 1.6.0
```

### 3. S3 Backend (Manual Setup Required)

Create S3 bucket and DynamoDB table for state management:

```bash
# Create S3 bucket
aws s3api create-bucket \
  --bucket insighthealth-terraform-state-us-east-1 \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket insighthealth-terraform-state-us-east-1 \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket insighthealth-terraform-state-us-east-1 \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 4. ACM Certificate for HTTPS

Request wildcard certificate for `*.insighthealth.io`:

```bash
aws acm request-certificate \
  --domain-name "*.insighthealth.io" \
  --validation-method DNS \
  --region us-east-1
```

**Important**: 
1. AWS will provide DNS validation records (CNAME)
2. Add these CNAME records to your Route53 hosted zone for `insighthealth.io`
3. Wait for validation to complete (~5-30 minutes)
4. Copy the certificate ARN and update `terraform.tfvars`:
   ```hcl
   alb_certificate_arn = "arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/CERTIFICATE_ID"
   ```

### 5. Route53 Hosted Zone

Ensure you have a hosted zone for `insighthealth.io`:

```bash
# Check if hosted zone exists
aws route53 list-hosted-zones --query "HostedZones[?Name=='insighthealth.io.']"

# If not, create it
aws route53 create-hosted-zone \
  --name insighthealth.io \
  --caller-reference $(date +%s)
```

## Deployment Instructions

### Step 1: Initialize Terraform

```bash
cd /path/to/forge-infrastructure/aws
terraform init
```

Expected output:
```
Initializing the backend...
Successfully configured the backend "s3"!
Initializing modules...
Initializing provider plugins...
Terraform has been successfully initialized!
```

### Step 2: Review Configuration

Edit `terraform.tfvars` if needed:
- Update `alb_certificate_arn` with your ACM certificate ARN
- Adjust instance sizes for cost optimization
- Enable/disable environments with flags

### Step 3: Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the plan carefully:
- **VPC**: 1 VPC, subnets, route tables, IGW
- **EKS**: 1 cluster, 3 node groups, 3 namespaces
- **ALB**: 3 load balancers (prod, stag, dev)
- **RDS**: 1 PostgreSQL instance (shared)
- **Redis**: 1 ElastiCache cluster (shared)

### Step 4: Apply Infrastructure

```bash
terraform apply tfplan
```

**Duration**: ~20-30 minutes
- VPC: ~2 minutes
- EKS: ~15 minutes
- RDS: ~10 minutes
- Redis: ~5 minutes
- ALB: ~3 minutes

### Step 5: Configure kubectl

After deployment completes, configure kubectl:

```bash
aws eks update-kubeconfig --region us-east-1 --name <CLUSTER_NAME>
```

Verify cluster access:
```bash
kubectl get nodes
kubectl get namespaces
```

Expected namespaces:
- `prod-cronus`
- `stag-cronus`
- `dev-cronus`

### Step 6: Create DNS Records

Create Route53 A (Alias) records for each environment:

```bash
# Get ALB DNS names from Terraform outputs
terraform output alb_dns_names

# Create DNS records (example for production)
aws route53 change-resource-record-sets \
  --hosted-zone-id <HOSTED_ZONE_ID> \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "prod.insighthealth.io",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "<ALB_ZONE_ID>",
          "DNSName": "<ALB_DNS_NAME>",
          "EvaluateTargetHealth": true
        }
      }
    }]
  }'
```

Repeat for `stag.insighthealth.io` and `dev.insighthealth.io`.

### Step 7: Verify Deployment

```bash
# Check DNS resolution
nslookup prod.insighthealth.io
nslookup stag.insighthealth.io
nslookup dev.insighthealth.io

# Check HTTPS endpoints
curl -I https://prod.insighthealth.io/health
```

## Multi-Tenant Pattern

This infrastructure uses a **3-scenario naming pattern**:

### 1. Shared Infrastructure (Default)
```hcl
customer_name = null
project_name  = null
```
Resources named: `forge-{environment}-*`

### 2. Customer-Specific
```hcl
customer_name = "cronus"
project_name  = null
```
Resources named: `forge-{environment}-cronus-*`

### 3. Project-Specific
```hcl
customer_name = "cronus"
project_name  = "analytics"
```
Resources named: `forge-{environment}-cronus-analytics-*`

## Auto-Discovery Pattern

All modules use **tag-based auto-discovery**:

### VPC Discovery (in EKS, RDS, Redis, ALB modules)
```hcl
data "aws_vpc" "main" {
  tags = {
    ManagedBy   = "Terraform"
    Workspace   = var.workspace
    Environment = var.environment
    Customer    = var.customer_name  # Optional
    Project     = var.project_name   # Optional
  }
}
```

**No manual VPC ID required!** Modules automatically find the VPC.

## Environment Isolation

### Kubernetes Namespaces

Each environment has a dedicated namespace with:

1. **Resource Quotas**:
   - Production: 20 CPU, 40 GB RAM, 100 pods
   - Staging: 10 CPU, 20 GB RAM, 50 pods
   - Development: 10 CPU, 20 GB RAM, 50 pods

2. **Network Policies**:
   - Production: Fully isolated (no ingress from other namespaces)
   - Staging: Can receive traffic from production
   - Development: Can receive traffic from production

### ALB Routing

Each environment has a separate ALB:
- **Production ALB** → EKS NodePort 30082 (prod-cronus namespace)
- **Staging ALB** → EKS NodePort 30081 (stag-cronus namespace)
- **Development ALB** → EKS NodePort 30080 (dev-cronus namespace)

## Resource Sharing

### Database Sharing

By default, staging and development **share the production RDS instance**.

To create dedicated databases per environment:

```hcl
# terraform.tfvars
shared_database_environments = []  # Empty = no sharing
```

This will create 3 separate RDS instances (increases cost by ~$600/month).

### Redis Sharing

By default, staging and development **share the production Redis cluster**.

To create dedicated Redis per environment:

```hcl
# terraform.tfvars
shared_redis_environments = []  # Empty = no sharing
```

This will create 3 separate Redis clusters (increases cost by ~$200/month).

## Maintenance

### Scaling EKS Nodes

Update `terraform.tfvars`:
```hcl
eks_node_desired_size = 5  # Increase from 3 to 5
eks_node_max_size     = 10 # Increase from 6 to 10
```

Then apply:
```bash
terraform apply
```

### Upgrading Kubernetes Version

Update `terraform.tfvars`:
```hcl
eks_kubernetes_version = "1.32"  # Upgrade from 1.31
```

Then apply:
```bash
terraform apply
```

**Important**: Test upgrades in development first!

### Database Backups

RDS automated backups:
- **Production**: 30 days retention
- **Staging**: 7 days retention (if dedicated)
- **Development**: 3 days retention (if dedicated)

Manual snapshot:
```bash
aws rds create-db-snapshot \
  --db-instance-identifier <DB_IDENTIFIER> \
  --db-snapshot-identifier manual-snapshot-$(date +%Y%m%d-%H%M%S)
```

## Troubleshooting

### Issue: Terraform Backend Not Found

**Error**: `Error configuring the backend "s3": NoSuchBucket`

**Solution**: Create S3 bucket manually (see Prerequisites step 3)

### Issue: ACM Certificate Not Found

**Error**: `Error creating ALB Listener: CertificateNotFound`

**Solution**: 
1. Request ACM certificate (see Prerequisites step 4)
2. Validate via DNS
3. Update `alb_certificate_arn` in `terraform.tfvars`

### Issue: VPC Not Found (Auto-Discovery)

**Error**: `Error: no matching VPC found`

**Solution**: Ensure VPC has correct tags:
```hcl
ManagedBy   = "Terraform"
Workspace   = "forge-platform"
Environment = "shared"
```

### Issue: EKS Nodes Not Joining Cluster

**Error**: `Nodes stuck in NotReady state`

**Solution**:
1. Check security groups allow EKS control plane communication
2. Verify IAM roles have correct policies
3. Check CloudWatch logs: `/aws/eks/<cluster-name>/cluster`

## Security Considerations

1. **Network Isolation**:
   - Private subnets for EKS nodes, RDS, Redis
   - Public subnets only for ALBs
   - Network policies isolate Kubernetes namespaces

2. **Encryption**:
   - RDS: Encrypted at rest with KMS
   - Redis: Encrypted at rest with KMS
   - ALB: TLS 1.3 only (HTTPS)
   - Terraform State: Encrypted in S3

3. **Access Control**:
   - EKS: RBAC per namespace
   - RDS: Security groups limit access to EKS nodes only
   - Redis: Security groups + auth token

4. **Secrets Management**:
   - RDS passwords: Stored in AWS Secrets Manager
   - Redis auth tokens: Stored in AWS Secrets Manager
   - Kubernetes secrets: Use external-secrets operator

## Terraform Outputs

After deployment, view outputs:

```bash
terraform output
```

Key outputs:
- `eks_kubectl_config_command`: Command to configure kubectl
- `alb_dns_names`: ALB DNS names for Route53 configuration
- `rds_production_endpoint`: Database connection endpoint
- `redis_production_endpoint`: Redis connection endpoint
- `dns_records_to_create`: DNS records needed in Route53

## Cleanup

To destroy all infrastructure:

```bash
terraform destroy
```

**Warning**: This will delete:
- All data in RDS (unless final snapshot is enabled)
- All data in Redis
- EKS cluster and all workloads
- VPC and networking

**Recommendation**: Take backups before destroying!

## Support

For issues or questions:
- **Documentation**: See `/docs/` directory
- **GitHub Issues**: [forge-infrastructure/issues](https://github.com/your-org/forge-infrastructure/issues)
- **Slack**: #infrastructure channel

## License

Copyright © 2025 InsightHealth. All rights reserved.
