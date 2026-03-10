# HIPAA Feature Recommendations — Per AWS Component
## Forge Infrastructure — What to Implement to Achieve HIPAA Compliance

---

| | |
|---|---|
| **Report date** | 2026-02-25 |
| **Standard** | HIPAA Security Rule 45 CFR §164.308 / §164.312 |
| **Based on** | Code analysis: forge-infrastructure + forge-helpers |

---

## Legend

| Symbol | Meaning |
|---|---|
| ✅ **DONE** | Feature is already implemented in the codebase |
| 🔧 **ENABLE** | Feature exists as an optional toggle — needs to be turned on |
| ➕ **ADD** | Feature does not exist — new code must be written |
| ⚙️ **CONFIGURE** | Feature exists but requires a default value or parameter change |

---

## Component 1 — Amazon EKS

### HIPAA relevance
EKS is the compute layer — it processes PHI at runtime. Requires access control, workload isolation, secrets protection, and a complete audit trail.

---

### Feature checklist

| # | Feature | Status | HIPAA §164 | Implementation details |
|---|---|---|---|---|
| 1 | **Private cluster endpoint** | ✅ DONE | §164.312(e)(1) | `cluster_endpoint_public_access = false` — API accessible only from within the VPC |
| 2 | **KMS encryption of Kubernetes Secrets** | ✅ DONE | §164.312(a)(2)(iv) | `cluster_encryption_config.resources = ["secrets"]` with CMK |
| 3 | **CloudWatch control plane logging — all 5 types** | ✅ DONE | §164.312(b) | `api, audit, authenticator, controllerManager, scheduler` |
| 4 | **CloudWatch log group KMS encryption** | ✅ DONE | §164.312(a)(2)(iv) | `cloudwatch_log_group_kms_key_id = kms_eks.key_arn` |
| 5 | **IRSA (IAM Roles for Service Accounts)** | ✅ DONE | §164.312(a)(1) | OIDC-based, separate role per workload, `StringEquals` condition |
| 6 | **EKS Pod Identity Agent** | ✅ DONE | §164.312(a)(1) | Additional pod → AWS authentication mechanism |
| 7 | **EBS volume encryption (CSI + KMS)** | ✅ DONE | §164.312(a)(2)(iv) | `ebs_csi_kms` policy with `kms:CreateGrant` |
| 8 | **Security Groups — minimal ports** | ✅ DONE | §164.312(e)(1) | Control plane: 443; Nodes: 443, 10250, 53 |
| 9 | **CIS Benchmark node group AMI (AL2023)** | ✅ DONE | §164.308(a)(1) | `ami_type = "AL2023_ARM_64_STANDARD"` — hardened AMI |
| 10 | **CloudWatch log retention minimum 90 days** | ✅ DONE | §164.312(b) | Default 90, allowed values validated |
| 11 | **IMDSv2 required (token-based metadata)** | 🔧 ENABLE | §164.312(a)(1) | AL2023 requires IMDSv2 by default, but add explicit `metadata_options { http_tokens = "required" }` in the launch template |
| 12 | **Kubernetes Network Policies (namespace isolation)** | 🔧 ENABLE | §164.312(e)(1) | `namespaces.tf` has commented-out code — uncomment and apply deny-all + allowlist policies per namespace |
| 13 | **Resource Quotas per namespace** | 🔧 ENABLE | §164.308(a)(1) | Code is commented out in `namespaces.tf` — activate for namespaces with PHI workloads |
| 14 | **Pod Security Standards — Restricted/Baseline** | ➕ ADD | §164.312(a)(1) | Add `pod-security.kubernetes.io/enforce: restricted` label to PHI namespaces |
| 15 | **Kyverno / OPA Gatekeeper policies** | ➕ ADD | §164.312(a)(1) | Enforce: no `hostNetwork`, no `privileged`, no root containers, required labels |
| 16 | **EKS Add-ons versions pinned + auto-update policy** | ⚙️ CONFIGURE | §164.308(a)(8) | Pin versions for `vpc-cni`, `coredns`, `kube-proxy` — do not use `"LATEST"` |
| 17 | **Cluster Autoscaler with Graviton3 (ARM)** | ✅ DONE | §164.308(a)(7) | IRSA for autoscaler + `m7g.*` instances |
| 18 | **GuardDuty EKS Runtime Monitoring** | ➕ ADD | §164.308(a)(1) | Detects: exfiltration, privilege escalation, K8s anomalies |
| 19 | **CloudTrail — data events for EKS API calls** | ➕ ADD | §164.312(b) | Records who/when modified the cluster |
| 20 | **Audit log HIPAA 7-year retention (pipeline)** | ✅ DONE | §164.312(b) | EKS audit logs → Kinesis Firehose → S3 HIPAA lifecycle |

### Network Policy configuration — example

```yaml
# Add to namespaces.tf (uncomment and extend)
# PHI namespace: deny-all ingress by default, allow only from known sources
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: <phi-namespace>
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-internal-only
  namespace: <phi-namespace>
spec:
  podSelector: {}
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              hipaa-zone: "true"
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              hipaa-zone: "true"
    - ports:
        - port: 443  # AWS APIs (via VPC Endpoint)
        - port: 5432 # RDS PostgreSQL
```

### Pod Security Standards — example

```bash
# Add this label to every namespace containing PHI workloads:
kubectl label namespace <phi-namespace> \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

---

## Component 2 — Network (VPC, Subnets, VPC Endpoints, VPN)

### HIPAA relevance
The network is the foundation of isolation — PHI must never leave through unencrypted channels or be reachable from the internet without controls.

---

### Feature checklist

| # | Feature | Status | HIPAA §164 | Implementation details |
|---|---|---|---|---|
| 1 | **VPC with DNS support + DNS hostnames** | ✅ DONE | §164.312(e)(1) | `enable_dns_support = true`, `enable_dns_hostnames = true` |
| 2 | **VPC Flow Logs → CloudWatch (KMS encrypted)** | ✅ DONE | §164.312(b) | `flow-logs.tf`: log group with `kms_key_id`, dedicated IAM role |
| 3 | **VPC Endpoints for AWS services (no internet)** | ✅ DONE | §164.312(e)(1) | Interface/Gateway endpoints, `private_dns_enabled = true` |
| 4 | **NAT Gateway (workloads without public IPs)** | ✅ DONE | §164.312(e)(1) | Egress only through NAT |
| 5 | **Client VPN with mTLS / SAML federation** | ✅ DONE | §164.312(d) | `transport_protocol = "tcp"`, `authentication_options` for cert/AD/SAML |
| 6 | **VPN Connection Logs → CloudWatch (KMS)** | ✅ DONE | §164.312(b) | `logging.tf`: log group + stream with `kms_key_id` |
| 7 | **Private subnets for all PHI workloads** | ✅ DONE | §164.312(e)(1) | Module architecture — RDS, EKS nodes, Lambda in private subnets |
| 8 | **Flow Logs retention minimum 1 year** | ⚙️ CONFIGURE | §164.312(b) | `var.flow_logs_retention_days` — set to minimum **365** |
| 9 | **VPN log retention minimum 1 year** | ⚙️ CONFIGURE | §164.312(b) | `var.cloudwatch_log_retention_days` — set to minimum **365** |
| 10 | **VPC Endpoints for all used AWS services** | ⚙️ CONFIGURE | §164.312(e)(1) | Add endpoints for: `com.amazonaws.*.sqs`, `com.amazonaws.*.kms`, `com.amazonaws.*.ssm`, `com.amazonaws.*.secretsmanager`, `com.amazonaws.*.s3`, `com.amazonaws.*.logs` |
| 11 | **VPN Session timeout — restricted** | ✅ DONE | §164.312(a)(2)(iii) | `session_timeout_hours = var.session_timeout_hours` — set max 8h |
| 12 | **Security Groups — no `0.0.0.0/0` inbound on private resources** | ✅ DONE | §164.312(e)(1) | SGs for EKS, RDS, VPN have no wildcard inbound rules |
| 13 | **Route53 Private Hosted Zone for service discovery** | 🔧 ENABLE | §164.312(e)(1) | `route53-zone/` module exists — use for internal DNS aliases |
| 14 | **GuardDuty VPC Flow Log analysis** | ➕ ADD | §164.308(a)(1) | GuardDuty analyzes Flow Logs for network anomalies |
| 15 | **AWS Network Firewall (optional)** | ➕ ADD | §164.308(a)(1) | Layer 7 inspection of east-west traffic between VPC segments |
| 16 | **VPC CIDR planning — non-overlapping** | ✅ DONE | §164.308(a)(1) | Comment in `vpc/main.tf` documents CIDR isolation |

### Minimum VPC Endpoints for HIPAA

```hcl
# Required for PHI environments — traffic should not leave to the internet for AWS APIs
locals {
  required_hipaa_endpoints = [
    "com.amazonaws.{region}.s3",             # S3 (Gateway)
    "com.amazonaws.{region}.sqs",            # SQS
    "com.amazonaws.{region}.kms",            # KMS (all encrypt/decrypt)
    "com.amazonaws.{region}.ssm",            # SSM Parameter Store
    "com.amazonaws.{region}.secretsmanager", # Secrets Manager
    "com.amazonaws.{region}.logs",           # CloudWatch Logs
    "com.amazonaws.{region}.monitoring",     # CloudWatch Metrics
    "com.amazonaws.{region}.sts",            # STS (IRSA token exchange)
    "com.amazonaws.{region}.ecr.api",        # ECR (pull images)
    "com.amazonaws.{region}.ecr.dkr",        # ECR Docker registry
  ]
}
```

---

## Component 3 — Amazon RDS (PostgreSQL)

### HIPAA relevance
RDS stores PHI — highest priority for encryption, access, backup, and audit controls.

---

### Feature checklist

| # | Feature | Status | HIPAA §164 | Implementation details |
|---|---|---|---|---|
| 1 | **Storage encryption (KMS CMK)** | ✅ DONE | §164.312(a)(2)(iv) | `storage_encrypted = true`, dedicated `kms_rds` CMK |
| 2 | **KMS auto-rotation** | ✅ DONE | §164.312(a)(2)(iv) | `enable_key_rotation = true` in KMS module |
| 3 | **IAM database authentication** | ✅ DONE | §164.312(a)(1) | `iam_database_authentication_enabled = true` |
| 4 | **Multi-AZ deployment (HA + DR)** | ✅ DONE | §164.308(a)(7) | `multi_az = true` hardcoded |
| 5 | **Publicly accessible = false** | ✅ DONE | §164.312(e)(1) | `publicly_accessible = false` |
| 6 | **Performance Insights (KMS encrypted)** | ✅ DONE | §164.312(b) | `performance_insights_enabled = true`, `kms_key_id` set |
| 7 | **Enhanced Monitoring (1–60s granularity)** | ✅ DONE | §164.312(b) | `monitoring_interval`, dedicated IAM role |
| 8 | **CloudWatch Logs exports (postgresql, upgrade)** | ✅ DONE | §164.312(b) | `enabled_cloudwatch_logs_exports` — logs to CW with KMS |
| 9 | **CloudWatch Alarms (CPU, Memory, Storage, Connections, Latency)** | ✅ DONE | §164.308(a)(6) | 7 alarms defined |
| 10 | **Deletion protection** | ✅ DONE | §164.312(c)(1) | `deletion_protection = true` |
| 11 | **Final snapshot on deletion** | ✅ DONE | §164.308(a)(7) | `skip_final_snapshot = false` |
| 12 | **Credentials in SSM SecureString (KMS)** | ✅ DONE | §164.312(a)(1) | Master password stored as SecureString |
| 13 | **Private subnets (subnet group)** | ✅ DONE | §164.312(e)(1) | Dedicated RDS subnets |
| 14 | **`rds.force_ssl = 1` (force TLS)** | ➕ ADD | §164.312(e)(2)(ii) | Missing from default parameters — add to `aws_db_parameter_group` |
| 15 | **`log_connections = 1`** | ➕ ADD | §164.312(b) | Log every new connection to PostgreSQL logs |
| 16 | **`log_disconnections = 1`** | ➕ ADD | §164.312(b) | Log every disconnection |
| 17 | **`log_min_duration_statement` (slow query)** | ➕ ADD | §164.312(b) | e.g. `1000` ms — audit long-running queries |
| 18 | **`pgaudit` extension** | ➕ ADD | §164.312(b) | PostgreSQL audit extension — DDL + DML audit trail per user |
| 19 | **SNS alarm_actions (notifications)** | ➕ ADD | §164.308(a)(6)(ii) | Add `alarm_actions = var.sns_alarm_topic_arns` to all 7 alarms |
| 20 | **Backup retention = 35 days (production)** | ⚙️ CONFIGURE | §164.308(a)(7) | Default = 7 → change to **35** for prod |
| 21 | **AWS Backup Plan (retention > 35 days)** | ➕ ADD | §164.308(a)(7) | Snapshots retained > 35 days (AWS Backup Vault with KMS) |
| 22 | **`auto_minor_version_upgrade = false`** | ✅ DONE | §164.312(c)(1) | Controlled upgrades |
| 23 | **Restore testing (recovery point validation)** | ➕ ADD | §164.308(a)(7)(ii)(D) | Automated PITR restore test — e.g. weekly cron job |
| 24 | **CloudTrail — data events for RDS** | ➕ ADD | §164.312(b) | Records instance modifications, parameter changes, snapshots |

### Required PostgreSQL parameters for HIPAA

```hcl
# forge-infrastructure/aws/database/rds-postgresql/main.tf
# Add to the "parameters" variable or as local defaults:

variable "parameters" {
  default = [
    # Encryption in transit — CRITICAL
    {
      name         = "rds.force_ssl"
      value        = "1"
      apply_method = "pending-reboot"
    },
    # Connection audit
    {
      name         = "log_connections"
      value        = "1"
      apply_method = "pending-reboot"
    },
    {
      name         = "log_disconnections"
      value        = "1"
      apply_method = "pending-reboot"
    },
    # Slow query audit
    {
      name         = "log_min_duration_statement"
      value        = "1000"   # 1 second
      apply_method = "pending-reboot"
    },
    # pgAudit — DDL/DML audit
    {
      name         = "shared_preload_libraries"
      value        = "pgaudit"
      apply_method = "pending-reboot"
    },
    {
      name         = "pgaudit.log"
      value        = "ddl,write,role"
      apply_method = "pending-reboot"
    }
  ]
}
```

---

## Component 4 — Amazon S3

### HIPAA relevance
S3 stores logs containing PHI (VPC Flow, WAF, RDS, EKS) and potentially PHI files directly. Requires encryption, integrity controls, and transmission security.

---

### Feature checklist

| # | Feature | Status | HIPAA §164 | Implementation details |
|---|---|---|---|---|
| 1 | **SSE-KMS (mandatory, CMK per bucket)** | ✅ DONE | §164.312(a)(2)(iv) | `sse_algorithm = "aws:kms"` hardcoded, `kms_master_key_id = kms_s3.key_arn` |
| 2 | **KMS auto-rotation** | ✅ DONE | §164.312(a)(2)(iv) | `enable_key_rotation = true` |
| 3 | **Block public access (all 4 flags)** | ✅ DONE | §164.312(e)(1) | `block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets` |
| 4 | **Bucket versioning** | ✅ DONE | §164.312(c)(1) | `versioning_enabled = "Enabled"` |
| 5 | **HIPAA 7-year lifecycle (S3 → Glacier → Deep Archive)** | ✅ DONE | §164.312(b) | `hipaa-logs-lifecycle.tf` — WAF, VPC, RDS, EKS, Metrics |
| 6 | **Abort incomplete multipart uploads** | ✅ DONE | §164.312(c)(1) | `abort_incomplete_multipart_upload_days` in lifecycle rules |
| 7 | **Bucket Access Logging** | 🔧 ENABLE | §164.312(b) | `var.logging_enabled = true` — enable for all PHI buckets |
| 8 | **Deny non-TLS bucket policy** | ➕ ADD | §164.312(e)(1) | **MISSING** — add `aws_s3_bucket_policy` with `aws:SecureTransport = false → Deny` |
| 9 | **Object Lock (WORM) — COMPLIANCE mode** | 🔧 ENABLE | §164.312(c)(1) | `var.object_lock_enabled = true` + `mode = "COMPLIANCE"` for PHI buckets |
| 10 | **Cross-Region Replication (DR)** | 🔧 ENABLE | §164.308(a)(7) | `var.replication_enabled = true` — required for PHI disaster recovery |
| 11 | **Replication with KMS re-encryption** | 🔧 ENABLE | §164.312(a)(2)(iv) | `replica_kms_key_id` in destination — encrypt replicas with a separate CMK |
| 12 | **Intelligent-Tiering for PHI data** | 🔧 ENABLE | §164.308(a)(7) | `var.intelligent_tiering_enabled = true` — cost optimization with Archive Access |
| 13 | **Bucket policy — Deny PutObject without encryption** | ➕ ADD | §164.312(a)(2)(iv) | Deny upload if `x-amz-server-side-encryption` is not `aws:kms` |
| 14 | **Bucket policy — Deny delete on HIPAA log buckets** | ➕ ADD | §164.312(c)(1) | Prevent accidental deletion of compliance logs |
| 15 | **S3 Access Analyzer** | ➕ ADD | §164.308(a)(1) | Detects accidental public or cross-account access |
| 16 | **Notifications for anomalies (EventBridge)** | ➕ ADD | §164.308(a)(6) | Alert when bucket policy is changed or versioning is disabled |

### Required bucket policies

```hcl
# Policy 1: Enforce HTTPS (add to forge-infrastructure/aws/storage/s3/main.tf)
resource "aws_s3_bucket_policy" "enforce_tls" {
  bucket = aws_s3_bucket.main.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.main.arn, "${aws_s3_bucket.main.arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
      {
        Sid       = "DenyUnencryptedPutObject"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.main.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.main]
}
```

---

## Component 5 — Amazon SQS

### HIPAA relevance
SQS transports messages between microservices — if they contain PHI (e.g. patient identifiers, clinical events), encryption and access controls are required.

---

### Feature checklist

| # | Feature | Status | HIPAA §164 | Implementation details |
|---|---|---|---|---|
| 1 | **FIFO queues (exactly-once, ordered)** | ✅ DONE | §164.312(c)(1) | `sqs.sh`: FIFO with content-based deduplication |
| 2 | **KMS encryption at rest (CMK)** | ✅ DONE | §164.312(a)(2)(iv) | `create_kms_key_for_sqs` + `SqsManagedSseEnabled = false` |
| 3 | **IRSA per service (producer/consumer separation)** | ✅ DONE | §164.312(a)(1) | `forge-sqs-operations.sh`: separate IRSA roles for producer and consumer |
| 4 | **SSM — queue URL and ARN stored as SecureString** | ✅ DONE | §164.312(a)(1) | `sqs.sh` integration with SSM Parameter Store |
| 5 | **VPC Endpoint for SQS** | 🔧 ENABLE | §164.312(e)(1) | Route SQS traffic through the private network, not the internet — add `com.amazonaws.{region}.sqs` endpoint |
| 6 | **Dead Letter Queue (DLQ) with KMS** | ➕ ADD | §164.312(c)(1) | DLQ for failed messages — encrypted with the same CMK |
| 7 | **Queue Policy — Deny non-HTTPS** | ➕ ADD | §164.312(e)(1) | Enforce TLS: `Condition: { Bool: { "aws:SecureTransport": "false" } } → Deny` |
| 8 | **Queue Policy — Deny without IRSA (no anonymous access)** | ➕ ADD | §164.312(a)(1) | Policy with `Principal: { AWS: [allowed_role_arns] }` — deny everything else |
| 9 | **Message retention — short (HIPAA data minimization)** | ⚙️ CONFIGURE | §164.308(a)(3) | `MessageRetentionPeriod = 345600` (4 days) ✅ — do not increase without justification |
| 10 | **CloudWatch Alarms for DLQ** | ➕ ADD | §164.308(a)(6)(ii) | Alert when `ApproximateNumberOfMessagesNotVisible` > 0 in DLQ — may indicate PHI processing failure |
| 11 | **CloudTrail — data events for SQS** | ➕ ADD | §164.312(b) | Records SendMessage, ReceiveMessage, DeleteMessage on PHI queues |
| 12 | **Redrive policy (DLQ integration)** | ➕ ADD | §164.312(c)(1) | Max receive count before DLQ — prevents "lost" PHI messages |

### Required SQS queue policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyNonTLS",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "sqs:*",
      "Resource": "arn:aws:sqs:{region}:{account}:{queue-name}.fifo",
      "Condition": {
        "Bool": { "aws:SecureTransport": "false" }
      }
    },
    {
      "Sid": "AllowProducerIRSA",
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::{account}:role/{producer-irsa-role}" },
      "Action": ["sqs:SendMessage", "sqs:GetQueueAttributes"],
      "Resource": "arn:aws:sqs:{region}:{account}:{queue-name}.fifo"
    },
    {
      "Sid": "AllowConsumerIRSA",
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::{account}:role/{consumer-irsa-role}" },
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:ChangeMessageVisibility"
      ],
      "Resource": "arn:aws:sqs:{region}:{account}:{queue-name}.fifo"
    }
  ]
}
```

---

## Component 6 — IAM (Identity & Access Management)

### HIPAA relevance
IAM is the fundamental access control layer — misconfiguration can grant unauthorized access to PHI. HIPAA requires least privilege, separation of duties, and an audit trail.

---

### Feature checklist

| # | Feature | Status | HIPAA §164 | Implementation details |
|---|---|---|---|---|
| 1 | **IRSA for all EKS workloads** | ✅ DONE | §164.312(a)(1) | VPC CNI, EBS CSI, Cluster Autoscaler — each with OIDC condition |
| 2 | **Separate IAM role per service (no sharing)** | ✅ DONE | §164.312(a)(1) | `sqs.sh`: producer and consumer role separation |
| 3 | **IAM role for Firehose with minimum permissions** | ✅ DONE | §164.312(a)(1) | Separate policies: S3, Lambda, CloudWatch, Kinesis |
| 4 | **IAM role for RDS Enhanced Monitoring** | ✅ DONE | §164.312(b) | Dedicated `monitoring.rds.amazonaws.com` role |
| 5 | **IAM role for VPN Connection Logs** | ✅ DONE | §164.312(b) | `clientvpn.amazonaws.com` role scoped to CloudWatch log group only |
| 6 | **KMS key policies — least privilege** | ✅ DONE | §164.312(a)(1) | Key policies with service principals + root account only |
| 7 | **No hardcoded credentials in code** | ✅ DONE | §164.312(a)(1) | All credentials via IRSA, SSM, Vault |
| 8 | **IAM Access Analyzer** | ➕ ADD | §164.308(a)(1) | Detects unexpected cross-account and public access |
| 9 | **IAM Permission Boundaries** | ➕ ADD | §164.312(a)(1) | Caps maximum permissions on roles — prevents privilege escalation |
| 10 | **SCP (Service Control Policies) — AWS Organizations** | ➕ ADD | §164.312(a)(1) | Account-level guardrails: `Deny s3:DeleteBucketEncryption`, `Deny kms:ScheduleKeyDeletion` without MFA |
| 11 | **IAM role for DB provisioning — time-limited** | ⚙️ CONFIGURE | §164.312(a)(1) | `database-provision.sh` uses ambient credentials — consider assumed role with `MaxSessionDuration` |
| 12 | **MFA required for console/CLI for human users** | ➕ ADD | §164.312(d) | IAM policy: `Deny *` if `"MultiFactorAuthPresent": "false"` |
| 13 | **CloudTrail for IAM events** | ➕ ADD | §164.312(b) | Audit CreateRole, AttachPolicy, AssumeRole |
| 14 | **AWS Config IAM rules** | ➕ ADD | §164.308(a)(8) | `iam-root-access-key-check`, `iam-no-inline-policy-check`, `iam-password-policy` |
| 15 | **Access key rotation** | ➕ ADD | §164.312(a)(1) | Policy: max 90 days, alert via Config rule |
| 16 | **Separation of Duties — Admin vs Operator vs Developer** | ➕ ADD | §164.308(a)(3) | Separate IAM roles: `ForgeAdmin`, `ForgeOperator`, `ForgeDeveloper` with different permissions |

### Reference IAM structure for HIPAA

```
IAM Roles:
├── ForgeAdmin          → Full access (MFA required, CloudTrail logged)
├── ForgeSecurityAudit  → Read-only for security review (CloudTrail, Config, IAM)
├── ForgeOperator       → Ops: EKS, RDS monitoring, SSM read, no PHI delete
├── ForgeDeveloper      → EKS deploy, ECR push, SSM read (specific paths)
├── ForgeCI             → IRSA for CI/CD pipeline (ECR push, S3 specific prefix)
│
└── IRSA Roles (per Kubernetes service account):
    ├── {service}-producer-irsa   → SQS SendMessage, SSM read (service secrets)
    ├── {service}-consumer-irsa   → SQS ReceiveMessage/Delete, RDS IAM auth
    ├── {service}-api-irsa        → SSM read, KMS decrypt, specific S3 prefix
    └── {service}-worker-irsa     → SQS consume, RDS write, S3 write (specific bucket)
```

### SCP — example guardrails

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyDisableEncryption",
      "Effect": "Deny",
      "Action": [
        "s3:PutEncryptionConfiguration",
        "rds:ModifyDBInstance",
        "kms:ScheduleKeyDeletion",
        "kms:DisableKey"
      ],
      "Resource": "*",
      "Condition": {
        "BoolIfExists": { "aws:MultiFactorAuthPresent": "false" }
      }
    },
    {
      "Sid": "DenyRootAccountUsage",
      "Effect": "Deny",
      "NotAction": ["iam:CreateVirtualMFADevice", "iam:EnableMFADevice"],
      "Resource": "*",
      "Condition": {
        "StringLike": { "aws:PrincipalArn": "arn:aws:iam::*:root" }
      }
    }
  ]
}
```

---

## Component 7 — Secrets Management (SSM + HashiCorp Vault)

### HIPAA relevance
Secrets (DB passwords, API keys, tokens) must be stored encrypted, rotated, and accessed with a full audit trail.

---

### Feature checklist

| # | Feature | Status | HIPAA §164 | Implementation details |
|---|---|---|---|---|
| 1 | **SSM SecureString with KMS CMK** | ✅ DONE | §164.312(a)(2)(iv) | `forge-ssm-operations.sh`: default type = SecureString |
| 2 | **SSM path hierarchy (`/env/service/section/key`)** | ✅ DONE | §164.312(a)(1) | `forge-patterns.sh` + `get_ssm_base_path` — full traceability |
| 3 | **YAML → SSM push/pull (no inline secrets)** | ✅ DONE | §164.312(a)(1) | `ssm-push.sh` / `ssm-pull.sh` — no secrets in repo or CI |
| 4 | **Secret availability verification before deployment** | ✅ DONE | §164.308(a)(7) | `ssm-verify.sh` — health check before startup |
| 5 | **Vault K8s auth backend (IRSA-based)** | ✅ DONE | §164.312(a)(1) | `forge-vault-operations.sh`: `create_vault_role` with K8s SA binding |
| 6 | **Vault policies — least privilege per service** | ✅ DONE | §164.312(a)(1) | `create_vault_policy` with `path "secret/data/..." { capabilities = ["read"] }` |
| 7 | **Vault KV v2 (versioned secrets)** | ✅ DONE | §164.312(c)(1) | Versioning enables state recovery — soft delete, not hard |
| 8 | **Bulk sync SSM → Vault** | ✅ DONE | §164.308(a)(7) | `vault-sync.sh` — synchronization between secret layers |
| 9 | **Vault audit logging** | ➕ ADD | §164.312(b) | Enable `vault audit enable file file_path=/vault/audit/audit.log` — every secret access is logged |
| 10 | **Vault audit log → Kinesis → S3 (HIPAA 7-year retention)** | ➕ ADD | §164.312(b) | Vault audit logs must be included in the HIPAA lifecycle pipeline |
| 11 | **Automatic secret rotation (RDS password)** | ➕ ADD | §164.312(a)(1) | Rotate master password every 90 days — Vault dynamic secrets or AWS Secrets Manager |
| 12 | **AWS Secrets Manager (alternative/complement to SSM)** | ➕ ADD | §164.312(a)(1) | Secrets Manager offers: native rotation, fine-grained resource policy, cross-account access |
| 13 | **ssm-clean.sh — audit before deletion** | ⚙️ CONFIGURE | §164.312(b) | Add pre-deletion audit log: "who, when, what was deleted" before the parameter is removed |
| 14 | **Deny SSM:GetParameter without IRSA (resource policy)** | ➕ ADD | §164.312(a)(1) | Resource-based policy on SSM namespace — only known IRSA roles have read access |
| 15 | **Vault response wrapping for secret delivery** | ➕ ADD | §164.312(a)(1) | Token response wrapping — secret accessible only once, for a limited time |
| 16 | **Centralized rotation schedule** | ➕ ADD | §164.308(a)(3)(ii)(A) | Document describing rotation policy: DB passwords every 90 days, API keys every 180 days |

### Secrets architecture for HIPAA

```
Layer 1: AWS SSM Parameter Store (infrastructure secrets)
  ├── /{env}/{service}/database/host         → String
  ├── /{env}/{service}/database/password     → SecureString (KMS CMK)
  ├── /{env}/{service}/database/username     → SecureString
  └── /{env}/{service}/api/external-key      → SecureString (KMS CMK)

Layer 2: HashiCorp Vault (application secrets, dynamic credentials)
  ├── secret/data/{customer}/{project}/{env}/{service}/app
  │   ├── Kubernetes SA auth (IRSA-based)
  │   ├── KV v2 (versioned)
  │   └── Audit logging (EVERY read is recorded)
  └── Dynamic secrets (optional):
      ├── RDS dynamic credentials (short-lived, auto-revoked)
      └── AWS credentials (sts:AssumeRole via Vault AWS backend)

Layer 3: IAM / IRSA (workload identity, not secrets)
  └── Pods use IRSA roles — do not need AWS credentials in secrets
```

---

## Component 8 — Kubernetes Microservice

### HIPAA relevance
The microservice is a direct processor of PHI — it must satisfy application-level controls: isolation, encrypted communication, authentication, authorization, and error handling without PHI leakage.

---

### Feature checklist

| # | Feature | Status | HIPAA §164 | Implementation details |
|---|---|---|---|---|
| 1 | **IRSA instead of passing credentials** | ✅ DONE | §164.312(a)(1) | Each service has its own IRSA role — no AWS keys inside pods |
| 2 | **Secrets from Vault / SSM (not plaintext env vars)** | ✅ DONE | §164.312(a)(1) | `vault-sync.sh` + Vault K8s auth — secrets mounted via Vault agent sidecar or External Secrets |
| 3 | **Deployment in private namespaces** | ✅ DONE | §164.312(e)(1) | `namespaces.tf` — namespace isolation per service |
| 4 | **Liveness / Readiness probes (do not expose PHI)** | ⚙️ CONFIGURE | §164.312(c)(1) | Probes must return only a status code (200/503), never patient data |
| 5 | **Network Policy — deny-all + allowlist** | 🔧 ENABLE | §164.312(e)(1) | `namespaces.tf` commented out — enable Network Policies |
| 6 | **Pod Security Context — non-root, read-only filesystem** | ➕ ADD | §164.312(a)(1) | `securityContext: { runAsNonRoot: true, readOnlyRootFilesystem: true, allowPrivilegeEscalation: false }` |
| 7 | **Resource Limits (CPU/Memory) on all pods** | 🔧 ENABLE | §164.308(a)(7) | `namespaces.tf` ResourceQuota commented out — activate |
| 8 | **Structured logging with no PHI in logs** | ➕ ADD | §164.312(b) | Logs must not contain: name, surname, date of birth, patient ID, diagnosis |
| 9 | **Health endpoint does not expose configuration** | ⚙️ CONFIGURE | §164.312(a)(1) | Spring Boot Actuator: disable `/actuator/env`, `/actuator/beans` or protect with authorization |
| 10 | **mTLS between microservices (service mesh)** | ➕ ADD | §164.312(e)(2)(ii) | Istio / AWS App Mesh — mutual TLS between pods, no plaintext east-west traffic |
| 11 | **Service-to-service authorization (RBAC/ABAC)** | ➕ ADD | §164.312(a)(1) | Istio AuthorizationPolicy or OPA — which service can call which endpoint |
| 12 | **PHI field encryption in payload (application-level)** | ➕ ADD | §164.312(a)(2)(iv) | PHI fields encrypted before writing to DB/SQS (`field-level encryption`) |
| 13 | **Audit log for every PHI access** | ➕ ADD | §164.312(b) | Every request to a PHI endpoint logged: user, time, IP, action, resource |
| 14 | **Graceful error handling — no stack trace in response** | ➕ ADD | §164.312(b) | Errors: return only an error code, never a stack trace with configuration data |
| 15 | **Container image scanning (Trivy/Inspector)** | ➕ ADD | §164.308(a)(1) | ECR image scanning automatic on push — block images with critical CVEs |
| 16 | **Immutable containers (read-only root filesystem)** | ➕ ADD | §164.312(c)(1) | Prevents runtime modification of the container |
| 17 | **SBOM (Software Bill of Materials)** | ➕ ADD | §164.308(a)(1) | Generate SBOM at build time — visibility into dependencies with CVEs |
| 18 | **Signed container images (cosign/Sigstore)** | ➕ ADD | §164.312(c)(1) | Signed images — verify that the image has not been tampered with |
| 19 | **Graceful shutdown — no PHI lost on restart** | ⚙️ CONFIGURE | §164.312(c)(1) | `terminationGracePeriodSeconds` + handle `SIGTERM` → flush queues before exit |
| 20 | **Horizontal Pod Autoscaling (HPA)** | ➕ ADD | §164.308(a)(7) | DR/HA — scale under load |

### Reference Pod Security Context for a PHI microservice

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: video-calling-service
  namespace: phi-services
spec:
  template:
    spec:
      serviceAccountName: video-calling-service-sa   # IRSA role
      automountServiceAccountToken: true              # required for IRSA
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: app
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
          resources:
            limits:
              cpu: "1000m"
              memory: "512Mi"
            requests:
              cpu: "100m"
              memory: "256Mi"
          volumeMounts:
            - name: tmp
              mountPath: /tmp              # Only writable directory
            - name: vault-secrets
              mountPath: /vault/secrets
              readOnly: true
      volumes:
        - name: tmp
          emptyDir: {}
        - name: vault-secrets
          emptyDir:
            medium: Memory                 # Secrets in RAM only, not on disk
```

### Structured Audit Log — required format

```json
{
  "timestamp": "2026-02-25T15:30:00.000Z",
  "service": "video-calling-service",
  "version": "1.2.3",
  "event_type": "PHI_ACCESS",
  "action": "READ",
  "resource_type": "CALL_RECORDING",
  "resource_id": "rec-uuid-xxxx",          // Resource ID — NOT the PHI data itself
  "user_id": "usr-uuid-yyyy",              // User ID — NOT name or surname
  "session_id": "sess-uuid-zzzz",
  "source_ip": "10.0.1.45",               // Private IP from VPC
  "request_id": "req-uuid-aaaa",
  "outcome": "SUCCESS",
  "hipaa_relevance": true
}
```

---

## Summary — Quick Reference

| Component | Compliant Features | Key missing items (ADD/ENABLE) | Priority |
|---|---|---|---|
| **EKS** | IRSA, Private endpoint, KMS secrets, All 5 log types, AL2023 | Network Policies (ENABLE), PSS (ADD), GuardDuty Runtime (ADD) | 🟠 HIGH |
| **Network** | VPC Flow Logs KMS, VPC Endpoints, VPN mTLS, NAT | Flow Logs retention ≥365d (CONFIGURE), SQS/KMS/SSM endpoints (ENABLE) | 🟡 MEDIUM |
| **RDS** | IAM auth, KMS, Multi-AZ, Enhanced Mon., Performance Insights | force_ssl (ADD), pgaudit (ADD), SNS alarms (ADD), backup 35d (CONFIGURE) | 🔴 CRITICAL |
| **S3** | SSE-KMS mandatory, Block public, 7y lifecycle, Versioning | Deny non-TLS policy (ADD), Object Lock COMPLIANCE (ENABLE), CRR (ENABLE) | 🔴 CRITICAL |
| **SQS** | FIFO+KMS, IRSA per service, SSM integration | VPC Endpoint (ENABLE), DLQ+KMS (ADD), Queue policy deny-non-TLS (ADD) | 🟠 HIGH |
| **IAM** | IRSA everywhere, Least privilege per role, No hardcoded creds | IAM Access Analyzer (ADD), SCP guardrails (ADD), MFA policy (ADD) | 🟠 HIGH |
| **Secrets** | SSM SecureString+KMS, Vault K8s auth, YAML→SSM pipeline | Vault audit logs (ADD), Secret rotation automation (ADD), Deny SSM without IRSA (ADD) | 🟠 HIGH |
| **K8s Microservice** | IRSA, Vault secrets, Namespace isolation | Pod Security Context (ADD), mTLS east-west (ADD), PHI audit log (ADD), No PHI in logs (CONFIGURE) | 🔴 CRITICAL |

---

## Implementation Roadmap

### Phase 1 — Foundations (Weeks 1–2) 🔴 CRITICAL

```
[ ] RDS: Add rds.force_ssl=1 + log_connections + log_disconnections + pgaudit
[ ] RDS: Wire SNS to all 7 CloudWatch alarms
[ ] S3: Add bucket policy enforce_tls + deny_unencrypted_putobject
[ ] K8s: Enable Network Policies (uncomment namespaces.tf)
[ ] K8s: Add securityContext to all PHI deployments
```

### Phase 2 — Monitoring & Detection (Weeks 3–4) 🟠 HIGH

```
[ ] Add module: aws/security/cloudtrail (multi-region, log validation, KMS)
[ ] Add module: aws/security/guardduty (S3, EKS runtime, malware scan)
[ ] SQS: Add VPC Endpoint + DLQ + queue policy deny-non-TLS
[ ] IAM: Add IAM Access Analyzer + SCP guardrails
[ ] Secrets: Enable Vault audit logging
```

### Phase 3 — Hardening (Weeks 5–8) 🟡 MEDIUM

```
[ ] Add module: aws/security/aws-config (HIPAA conformance pack)
[ ] S3: Enable Object Lock COMPLIANCE for PHI buckets
[ ] S3: Enable Cross-Region Replication for PHI data
[ ] Network: Set Flow Logs retention ≥365 days
[ ] Network: Add missing VPC Endpoints (SQS, SSM, KMS)
[ ] K8s: Deploy mTLS (Istio / AWS App Mesh)
[ ] K8s: Add PHI audit log per microservice
[ ] Secrets: Automated RDS master password rotation (every 90 days)
[ ] RDS: Add AWS Backup Plan with retention > 35 days
```

### Phase 4 — Advanced (Weeks 9–12) 🟢 NICE TO HAVE

```
[ ] K8s: Container image signing (cosign/Sigstore)
[ ] K8s: SBOM generation at build time
[ ] IAM: Permission Boundaries for developer roles
[ ] SQS: CloudTrail data events for PHI queues
[ ] Security: AWS Security Hub (centralize findings)
[ ] K8s: Kyverno policies (enforce security standards)
```

---

*Report generated by: GitHub Copilot — Automated HIPAA IaC Analysis*
*Date: 2026-02-25 | Based on: forge-infrastructure + forge-helpers static code analysis*
