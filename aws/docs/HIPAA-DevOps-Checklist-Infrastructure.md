# HIPAA Compliance Checklist for DevOps Engineers & AWS Cloud Architects
## Design & Implementation Guidelines for HIPAA-Compliant Platforms

---

> **Purpose:** This checklist serves as both an implementation guide and a design review tool.
> Use it during architecture design, infrastructure provisioning, code review, and compliance audits.
>
> **Standard:** HIPAA Security Rule — 45 CFR Part 164 (Technical, Administrative & Physical Safeguards)
>
> **Scope:** AWS-hosted platforms processing Protected Health Information (PHI)

---

## How to Use This Checklist

| Symbol | Meaning |
|---|---|
| `[ ]` | Not implemented — action required |
| `[x]` | Implemented and verified |
| `[~]` | Partially implemented — requires follow-up |
| 🔴 **CRITICAL** | Must be in place before processing any PHI in production |
| 🟠 **HIGH** | Must be in place before go-live |
| 🟡 **MEDIUM** | Implement within 30 days of go-live |
| 🟢 **LOW** | Best practice — implement within 90 days |

---

## Section 1 — Identity & Access Management (IAM)
> **HIPAA:** §164.312(a)(1) Access Control | §164.312(d) Authentication | §164.308(a)(3) Workforce Authorization

### 1.1 Workload Identity

- [ ] 🔴 All EKS workloads use **IRSA (IAM Roles for Service Accounts)** — no static AWS credentials in pods
- [ ] 🔴 Each microservice has its **own dedicated IRSA role** — no shared roles between services
- [ ] 🔴 IRSA trust policies use **OIDC `StringEquals` condition** scoped to specific namespace + service account
- [ ] 🔴 IAM roles follow **least privilege principle** — only the exact permissions required
- [ ] 🟠 IAM roles are **documented** with purpose, owner, and data classification
- [ ] 🟠 **Producer and Consumer roles are separate** for every SQS queue handling PHI
- [ ] 🟡 **Permission Boundaries** are applied to developer and operator roles to prevent privilege escalation

### 1.2 Human User Access

- [ ] 🔴 **MFA is required** for all human IAM users with console or CLI access
- [ ] 🔴 IAM policy enforces `Deny *` when `"aws:MultiFactorAuthPresent": "false"` for PHI-related actions
- [ ] 🔴 **No active root account access keys** — root account used only for account-level emergencies
- [ ] 🔴 Root account has **MFA enabled**
- [ ] 🟠 Human users are separated into roles: `Admin`, `SecurityAudit`, `Operator`, `Developer` — no all-powerful single role
- [ ] 🟠 **Access keys rotation** policy: maximum 90-day lifetime, enforced by AWS Config rule
- [ ] 🟡 Inactive IAM users are **automatically disabled** after 45 days (AWS Config rule: `iam-user-unused-credentials-check`)

### 1.3 Service Control Policies (Organizations)

- [ ] 🟠 **SCP guardrails** prevent disabling encryption: `Deny s3:PutEncryptionConfiguration`, `Deny rds:ModifyDBInstance` to remove encryption
- [ ] 🟠 SCP prevents `kms:ScheduleKeyDeletion` and `kms:DisableKey` without MFA
- [ ] 🟠 SCP denies creation of **public S3 buckets** at organization level
- [ ] 🟡 SCP restricts allowed AWS regions to the set of approved regions only

### 1.4 Access Auditing

- [ ] 🔴 **CloudTrail is enabled** for all regions, including global service events
- [ ] 🔴 CloudTrail **log file validation is enabled** (SHA-256 hash chain for integrity)
- [ ] 🔴 CloudTrail logs are **KMS-encrypted** with a CMK
- [ ] 🔴 CloudTrail logs are delivered to an **S3 bucket with deny-delete policy**
- [ ] 🟠 CloudTrail is configured as a **multi-region trail**
- [ ] 🟠 **IAM Access Analyzer** is enabled — detects unintended cross-account or public access
- [ ] 🟡 CloudTrail events are **streamed to SIEM or CloudWatch Logs** for real-time alerting

---

## Section 2 — Encryption at Rest
> **HIPAA:** §164.312(a)(2)(iv) Encryption & Decryption

### 2.1 KMS Key Management

- [ ] 🔴 All encryption uses **Customer Managed Keys (CMK)** — never AWS-managed default keys for PHI data
- [ ] 🔴 **Automatic KMS key rotation is enabled** (annual rotation minimum)
- [ ] 🔴 Each service has its **own dedicated KMS key** (EKS, RDS, S3, WAF logs, VPN logs, Firehose)
- [ ] 🔴 KMS **deletion window is set to 30 days** minimum — never 7 days for production keys
- [ ] 🔴 KMS key policies follow **least privilege** — only specific service principals granted access
- [ ] 🟠 KMS key administrators are explicitly listed — **root account only for emergency**
- [ ] 🟠 KMS key **aliases follow naming convention** (e.g., `alias/{customer}/{project}/{env}/{service}/{purpose}`)
- [ ] 🟡 For multi-region disaster recovery: **multi-region KMS keys** enabled for PHI data CMKs
- [ ] 🟡 KMS key usage is **monitored via CloudTrail** — alert on unauthorized decrypt attempts

### 2.2 Database (RDS)

- [ ] 🔴 `storage_encrypted = true` with **CMK** (not default AWS KMS key)
- [ ] 🔴 **Performance Insights encryption** enabled with CMK (`performance_insights_kms_key_id`)
- [ ] 🔴 **CloudWatch Logs encryption** enabled with CMK for all exported log groups
- [ ] 🟠 SSM Parameter Store secrets for RDS use **SecureString type with CMK**
- [ ] 🟠 RDS **snapshots are encrypted** — verified by `copy_tags_to_snapshot = true`

### 2.3 Object Storage (S3)

- [ ] 🔴 **SSE-KMS is mandatory** on all S3 buckets — never SSE-S3 for PHI buckets
- [ ] 🔴 `bucket_key_enabled = true` — reduces KMS API calls while maintaining CMK encryption
- [ ] 🟠 **Bucket policy denies `PutObject` without `x-amz-server-side-encryption: aws:kms`** header
- [ ] 🟠 S3 replication uses **separate CMK for replica** in destination region

### 2.4 Compute (EKS)

- [ ] 🔴 **Kubernetes Secrets are encrypted at rest** using `cluster_encryption_config` with CMK
- [ ] 🔴 **EBS volumes are encrypted** — EBS CSI Driver has `kms:CreateGrant` on the EKS CMK
- [ ] 🟠 **CloudWatch Log Groups** for EKS control plane are KMS-encrypted

### 2.5 Messaging (SQS / Kinesis)

- [ ] 🔴 All SQS queues use **CMK encryption** (`SqsManagedSseEnabled = false`, explicit KMS key)
- [ ] 🟠 **Kinesis Firehose delivery streams** have explicit `server_side_encryption { key_type = "CUSTOMER_MANAGED_CMK" }`
- [ ] 🟡 DLQ (Dead Letter Queue) uses the **same CMK** as the source queue

---

## Section 3 — Encryption in Transit
> **HIPAA:** §164.312(e)(1) Transmission Security | §164.312(e)(2)(ii) Encryption

### 3.1 Public Traffic (Internet-facing)

- [ ] 🔴 **HTTP → HTTPS redirect** on all Application Load Balancers (HTTP 301)
- [ ] 🔴 **TLS 1.2 minimum** — recommended: `ELBSecurityPolicy-TLS13-1-2-2021-06` (TLS 1.3 preferred)
- [ ] 🔴 **ACM certificate** attached to all HTTPS listeners
- [ ] 🟠 ACM certificates are **auto-renewed** — alert on expiry < 30 days
- [ ] 🟠 **HSTS header** is returned by the application (`Strict-Transport-Security`)

### 3.2 Internal Traffic (VPC)

- [ ] 🔴 **EKS API endpoint is private** — `cluster_endpoint_public_access = false`
- [ ] 🔴 **RDS `publicly_accessible = false`** — accessible only within VPC
- [ ] 🔴 **`rds.force_ssl = 1`** in RDS parameter group — rejects unencrypted connections
- [ ] 🔴 **S3 bucket policy denies non-TLS requests** (`aws:SecureTransport: false → Deny`)
- [ ] 🔴 **SQS queue policy denies non-TLS requests** (`aws:SecureTransport: false → Deny`)
- [ ] 🟠 **mTLS between microservices** (Istio / AWS App Mesh) — no plaintext east-west traffic
- [ ] 🟡 VPC Endpoints use **private DNS** — AWS service APIs resolved to private IPs

### 3.3 Remote Access

- [ ] 🔴 **AWS Client VPN** is the only way to access private resources — no SSH bastion over internet
- [ ] 🔴 VPN uses **mutual TLS (certificate-auth) or SAML federated auth** — no password-only auth
- [ ] 🔴 VPN uses **TCP transport** (not UDP) for reliable audit logging
- [ ] 🟠 VPN **session timeout** is configured (max 8 hours)
- [ ] 🟠 VPN connection logs are sent to **CloudWatch Logs with KMS encryption**

---

## Section 4 — Network Isolation & Perimeter Security
> **HIPAA:** §164.312(e)(1) Transmission Security | §164.310(a)(1) Facility Access Controls

### 4.1 VPC Design

- [ ] 🔴 **All PHI workloads are in private subnets** — no public IP on EKS nodes, RDS, Lambda
- [ ] 🔴 **NAT Gateway** for egress — workloads have no direct internet access
- [ ] 🔴 **VPC Flow Logs are enabled** — captures all network traffic (ACCEPT + REJECT)
- [ ] 🔴 VPC Flow Logs are **KMS-encrypted** with a dedicated CMK
- [ ] 🟠 VPC Flow Logs **retention ≥ 365 days** in CloudWatch (then archived to S3 for 7 years)
- [ ] 🟠 **No inbound 0.0.0.0/0 rules** in any Security Group for private resources
- [ ] 🟡 **VPC CIDR blocks are documented** and non-overlapping across environments

### 4.2 VPC Endpoints (PrivateLink)

- [ ] 🔴 **S3 Gateway endpoint** — prevents S3 traffic leaving the VPC
- [ ] 🔴 **STS Interface endpoint** — IRSA token exchange stays within VPC
- [ ] 🔴 **KMS Interface endpoint** — all encrypt/decrypt calls stay within VPC
- [ ] 🟠 **SSM Interface endpoint** — SSM GetParameter calls stay within VPC
- [ ] 🟠 **SQS Interface endpoint** — queue operations stay within VPC
- [ ] 🟠 **CloudWatch Logs Interface endpoint** — log writes stay within VPC
- [ ] 🟠 **ECR endpoints** (`ecr.api`, `ecr.dkr`) — image pulls stay within VPC
- [ ] 🟡 **Secrets Manager Interface endpoint** — if using Secrets Manager
- [ ] 🟡 VPC Endpoint **policies are restrictive** — only allow specific principals and actions

### 4.3 WAF (Web Application Firewall)

- [ ] 🔴 **WAF is associated with all ALBs** handling PHI traffic
- [ ] 🔴 **AWS Managed Core Rule Set (CRS / OWASP Top 10)** is enabled
- [ ] 🔴 **SQL Injection rule set** (`AWSManagedRulesSQLiRuleSet`) is enabled
- [ ] 🔴 **WAF logging is always on** — logs delivered to Kinesis Firehose → S3
- [ ] 🔴 **Sensitive headers are redacted** in WAF logs (`Authorization`, `Cookie`)
- [ ] 🟠 **Rate limiting rule** prevents DDoS / brute force
- [ ] 🟠 **Geographic allowlist** — only allow traffic from approved countries
- [ ] 🟠 **Known Bad Inputs** (`AWSManagedRulesKnownBadInputsRuleSet`) is enabled
- [ ] 🟠 **IP Reputation list** (`AWSManagedRulesAmazonIpReputationList`) is enabled
- [ ] 🟡 WAF **CloudWatch metrics per rule** are enabled — alert on rule match spikes

### 4.4 Security Groups

- [ ] 🔴 Security groups follow **allowlist model** — deny by default, explicit allow rules only
- [ ] 🔴 RDS Security Group allows port 5432 **only from EKS node/pod Security Groups**
- [ ] 🔴 EKS control plane Security Group allows **only required ports** (443, 1025-65535)
- [ ] 🟠 Security Groups are **tagged with purpose and owner**
- [ ] 🟡 **AWS Config rule `restricted-common-ports`** alerts on overly permissive SG rules

---

## Section 5 — Audit Logging & Monitoring
> **HIPAA:** §164.312(b) Audit Controls | §164.308(a)(6) Security Incident Procedures

### 5.1 Required Log Sources

- [ ] 🔴 **CloudTrail** — all API calls, all regions, management + data events
- [ ] 🔴 **VPC Flow Logs** — all network traffic in PHI VPCs
- [ ] 🔴 **RDS PostgreSQL logs** — exported to CloudWatch (`postgresql`, `upgrade`)
- [ ] 🔴 **EKS control plane logs** — all 5 types: `api`, `audit`, `authenticator`, `controllerManager`, `scheduler`
- [ ] 🔴 **WAF logs** — all requests to PHI-facing endpoints
- [ ] 🔴 **ALB access logs** — all HTTP/HTTPS requests
- [ ] 🟠 **Client VPN connection logs** — every connect/disconnect event
- [ ] 🟠 **Application audit logs** — every access to PHI resources (see Section 8)
- [ ] 🟡 **Vault audit logs** — every secret access, read, write, delete

### 5.2 Log Security

- [ ] 🔴 All CloudWatch Log Groups are **KMS-encrypted with CMK**
- [ ] 🔴 Log Groups have a defined **retention policy** (minimum: 90 days hot, 7 years cold)
- [ ] 🔴 **Log integrity** is protected — S3 log buckets have `deny-delete` policy and versioning
- [ ] 🟠 CloudTrail logs use **log file validation** (`enable_log_file_validation = true`)
- [ ] 🟠 Logs are **immutable** — Object Lock `COMPLIANCE` mode on log S3 buckets

### 5.3 Log Retention (HIPAA 7-Year Requirement)

- [ ] 🔴 S3 lifecycle rules implement **7-year retention** for all compliance logs:
  - Days 0–90: S3 Standard
  - Days 91–365: S3 Standard-IA
  - Days 366–2555: S3 Glacier Instant Retrieval
  - Days 2556+: S3 Glacier Deep Archive
  - Day 2558: Expire (auto-delete after 7 years + buffer)
- [ ] 🔴 Lifecycle rules cover: WAF, VPC Flow, RDS, EKS events, Pod logs, CloudTrail
- [ ] 🟠 Noncurrent version expiration is also configured (versioned buckets)

### 5.4 Alerting & Incident Response

- [ ] 🔴 **CloudWatch Alarms have SNS `alarm_actions`** configured — alerts are never silent
- [ ] 🔴 **On-call notification** is reachable from SNS (PagerDuty / OpsGenie / email)
- [ ] 🔴 RDS alarms notify on: High CPU, Low Memory, Low Storage, High Connections, High Latency
- [ ] 🟠 **GuardDuty findings** trigger SNS notifications
- [ ] 🟠 **AWS Config non-compliance** triggers SNS notifications
- [ ] 🟠 Incident response **runbook exists** for PHI breach scenarios
- [ ] 🟠 **HIPAA Breach Notification** process is documented and tested (§164.400-414)
- [ ] 🟡 CloudWatch **Metric Filters** on application logs detect PHI leakage patterns

---

## Section 6 — Threat Detection & Continuous Compliance
> **HIPAA:** §164.308(a)(1) Risk Analysis | §164.308(a)(8) Evaluation

### 6.1 GuardDuty

- [ ] 🔴 **GuardDuty is enabled** in all AWS accounts and regions processing PHI
- [ ] 🔴 **S3 protection** is enabled — detects unusual S3 access patterns
- [ ] 🔴 **EKS runtime monitoring** is enabled — detects K8s privilege escalation, exfiltration
- [ ] 🟠 **Malware protection** is enabled for EBS volumes
- [ ] 🟠 GuardDuty findings are sent to **Security Hub**
- [ ] 🟡 GuardDuty is enabled at **AWS Organizations level** — coverage for all member accounts

### 6.2 AWS Config

- [ ] 🔴 **AWS Config recorder is enabled** — all supported resource types
- [ ] 🔴 **HIPAA Operational Best Practices conformance pack** is deployed
- [ ] 🔴 Config rules enforce: `s3-bucket-server-side-encryption-enabled`, `rds-storage-encrypted`, `cloudtrail-enabled`
- [ ] 🟠 Config rules enforce: `vpc-flow-logs-enabled`, `guardduty-enabled-centralized`, `mfa-enabled-for-iam-console-access`
- [ ] 🟠 Config rules enforce: `iam-root-access-key-check`, `iam-no-inline-policy-check`
- [ ] 🟠 **Config remediation actions** auto-fix detectable violations (e.g., enable versioning)
- [ ] 🟡 Config delivers to **S3 with HIPAA 7-year lifecycle**

### 6.3 Security Hub

- [ ] 🟠 **AWS Security Hub is enabled** — centralizes GuardDuty + Config + Inspector findings
- [ ] 🟠 **HIPAA Security Standard** is enabled in Security Hub
- [ ] 🟠 **AWS Foundational Security Best Practices standard** is enabled
- [ ] 🟡 Security Hub findings integrate with **ticketing system** (Jira / ServiceNow)

### 6.4 Inspector

- [ ] 🟠 **Amazon Inspector** scans ECR images for CVEs on push
- [ ] 🟠 Inspector scans **EKS node EC2 instances** for OS-level vulnerabilities
- [ ] 🟡 CI/CD pipeline **blocks deployment** of images with CRITICAL CVEs

---

## Section 7 — Data Backup & Disaster Recovery
> **HIPAA:** §164.308(a)(7) Contingency Plan

### 7.1 RDS Backup

- [ ] 🔴 **Automated backups enabled** — `backup_retention_period = 35` (maximum) for production
- [ ] 🔴 `skip_final_snapshot = false` — final snapshot on instance deletion
- [ ] 🔴 **Multi-AZ deployment** — automatic failover within the same region
- [ ] 🟠 **AWS Backup Plan** for long-term RDS snapshot retention (> 35 days, up to 7 years)
- [ ] 🟠 AWS Backup Vault uses **CMK encryption**
- [ ] 🟠 Backup Vault has **delete protection** enabled (`aws_backup_vault_lock_configuration`)
- [ ] 🟠 **Restore test is automated** — weekly or monthly point-in-time recovery test with data validation
- [ ] 🟡 Cross-region backup copy is configured for disaster recovery

### 7.2 S3 Data Protection

- [ ] 🔴 **Versioning is enabled** on all PHI S3 buckets
- [ ] 🔴 **Object Lock COMPLIANCE mode** on buckets with HIPAA logs and PHI files
- [ ] 🟠 **Cross-Region Replication** is enabled for PHI buckets
- [ ] 🟠 Replication uses **separate CMK** in the destination region
- [ ] 🟡 **S3 Intelligent-Tiering** is configured for cost-optimized long-term PHI storage

### 7.3 DR Planning

- [ ] 🔴 **RPO and RTO targets are defined** and documented for PHI systems
- [ ] 🟠 **DR runbook** is documented and versioned in source control
- [ ] 🟠 **DR drill is conducted** at minimum annually
- [ ] 🟡 **Pilot light or warm standby** environment exists in secondary region for critical PHI services

---

## Section 8 — Kubernetes & Container Security
> **HIPAA:** §164.312(a)(1) Access Control | §164.312(e)(1) Transmission Security

### 8.1 Cluster Security

- [ ] 🔴 **EKS cluster endpoint is private** — `cluster_endpoint_public_access = false`
- [ ] 🔴 **Kubernetes Secrets encryption** with CMK via `cluster_encryption_config`
- [ ] 🔴 **All 5 control plane log types** are enabled and KMS-encrypted
- [ ] 🔴 **Authentication mode = API** (not legacy ConfigMap aws-auth)
- [ ] 🟠 **EKS cluster version** is within 2 minor versions of latest — patching policy enforced
- [ ] 🟡 **Node group AMI version** is updated within 30 days of new release

### 8.2 Workload Isolation

- [ ] 🔴 **Network Policies** are applied to every PHI namespace — default-deny-all ingress and egress
- [ ] 🔴 PHI namespaces have explicit **allowlist rules** for required traffic only (RDS port, SQS via endpoint)
- [ ] 🔴 **Resource Quotas** are set per namespace — prevents noisy-neighbor resource exhaustion
- [ ] 🟠 **Pod Security Standards** label on PHI namespaces: `pod-security.kubernetes.io/enforce: restricted`
- [ ] 🟡 **Kyverno or OPA Gatekeeper** policies enforce: no `hostNetwork`, no `privileged`, required labels

### 8.3 Pod Security Context

- [ ] 🔴 `runAsNonRoot: true` on all PHI workload containers
- [ ] 🔴 `readOnlyRootFilesystem: true` — containers cannot modify their filesystem at runtime
- [ ] 🔴 `allowPrivilegeEscalation: false` on all containers
- [ ] 🔴 `capabilities.drop: ["ALL"]` — no Linux capabilities unless explicitly required
- [ ] 🟠 `seccompProfile.type: RuntimeDefault` applied to all pods
- [ ] 🟠 Writable directories mounted as `emptyDir` — not persistent volumes unless required
- [ ] 🟠 **Secrets mounted as in-memory volumes** (`emptyDir.medium: Memory`) — not on disk

### 8.4 Container Image Security

- [ ] 🔴 **ECR image scanning** is enabled — scans on every `docker push`
- [ ] 🔴 CI/CD pipeline **blocks deployment** of images with CRITICAL or HIGH CVEs (threshold configurable)
- [ ] 🟠 **Container images are signed** (cosign / AWS Signer) — signature verified on admission
- [ ] 🟠 **SBOM (Software Bill of Materials)** is generated at build time and stored in ECR
- [ ] 🟡 Base images are **minimal and pinned** — use distroless or Alpine, never `latest` tag

### 8.5 Service Communication

- [ ] 🟠 **mTLS between all microservices** — Istio / AWS App Mesh service mesh deployed
- [ ] 🟠 **Service-to-service authorization policies** — explicit allowlist which service can call which endpoint
- [ ] 🟡 **Outbound traffic from pods** is restricted by Network Policy to VPC Endpoints only

---

## Section 9 — Secrets Management
> **HIPAA:** §164.312(a)(1) Access Control | §164.312(a)(2)(iv) Encryption

### 9.1 Secret Storage

- [ ] 🔴 **No secrets in source code, Dockerfiles, or environment variable plaintext** — use SSM or Vault
- [ ] 🔴 All SSM parameters for PHI-related services use **`SecureString` type with CMK**
- [ ] 🔴 **SSM path structure is namespaced** (`/{env}/{service}/section/key`) — prevents cross-service access
- [ ] 🟠 **HashiCorp Vault KV v2** is used for application secrets — provides versioning and soft delete
- [ ] 🟠 **Vault K8s auth** backend is configured — pods authenticate via Service Account JWT
- [ ] 🟡 Vault secrets are mounted via **Vault Agent Sidecar** or **External Secrets Operator** — not init containers with plaintext output

### 9.2 Secret Access Control

- [ ] 🔴 **IAM resource policy on SSM namespace** — only specific IRSA roles can `GetParameter`
- [ ] 🔴 **Vault policies are least-privilege** — `read`-only on specific paths, no wildcard `secret/data/*`
- [ ] 🔴 Each microservice has its **own Vault role and policy** — no shared access
- [ ] 🟠 **SSM parameter access is logged** via CloudTrail data events

### 9.3 Secret Rotation

- [ ] 🔴 **RDS master password rotation** — automated, every 90 days (AWS Secrets Manager or Vault dynamic secrets)
- [ ] 🟠 **All external API keys** are rotated every 180 days
- [ ] 🟠 **Rotation schedule is documented** for every secret category
- [ ] 🟡 **Vault dynamic secrets** for RDS — short-lived credentials auto-revoked after TTL

### 9.4 Secret Auditing

- [ ] 🔴 **Vault audit device is enabled** — every read, write, delete to Vault is logged
- [ ] 🟠 Vault audit logs are **shipped to HIPAA 7-year retention pipeline**
- [ ] 🟠 **Alert on unauthorized Vault access** — CloudWatch Metric Filter or Vault alert rule
- [ ] 🟡 Vault audit log **cleanup requires documented approval** — pre-deletion audit trail

---

## Section 10 — Database Security (RDS)
> **HIPAA:** §164.312(a)(1) | §164.312(b) | §164.312(e)(2)(ii)

### 10.1 Access Control

- [ ] 🔴 **IAM database authentication** enabled (`iam_database_authentication_enabled = true`)
- [ ] 🔴 **No static database passwords** for application connections — use IAM auth tokens
- [ ] 🔴 `publicly_accessible = false` — no direct internet access to RDS
- [ ] 🔴 **Dedicated DB user per microservice** — no shared `admin` user for application traffic
- [ ] 🟠 DB users have **minimum required grants** — no `SUPERUSER` or `CREATEDB` for app users

### 10.2 Encryption & Transit

- [ ] 🔴 `storage_encrypted = true` with **CMK**
- [ ] 🔴 `rds.force_ssl = 1` in parameter group — **rejects all non-TLS connections**
- [ ] 🔴 `performance_insights_kms_key_id` set to CMK
- [ ] 🟠 DB **connection strings use `sslmode=require`** or stronger in application config

### 10.3 Audit Logging

- [ ] 🔴 **CloudWatch Logs exports enabled** — `postgresql` and `upgrade` log types minimum
- [ ] 🔴 **`log_connections = 1`** — every new connection is logged
- [ ] 🔴 **`log_disconnections = 1`** — every disconnection is logged
- [ ] 🟠 **`pgaudit` extension enabled** — `pgaudit.log = ddl,write,role` — DDL and DML audit per user
- [ ] 🟠 **`log_min_duration_statement = 1000`** — slow queries (>1s) are logged for audit and performance review
- [ ] 🟡 **`log_error_verbosity = default`** — sufficient detail without exposing PHI in error messages

### 10.4 High Availability & Backup

- [ ] 🔴 `multi_az = true` — automatic failover, zero-data-loss HA
- [ ] 🔴 `backup_retention_period = 35` for production (maximum automated backup window)
- [ ] 🔴 `skip_final_snapshot = false` — snapshot taken on instance deletion
- [ ] 🟠 **AWS Backup Plan** — long-term snapshot retention in encrypted Backup Vault
- [ ] 🟠 **Restore test is scheduled** — verify PITR works within RTO target
- [ ] 🟠 `deletion_protection = true` — prevents accidental instance deletion
- [ ] 🟡 `auto_minor_version_upgrade = false` — manual upgrade control, tested before applying

### 10.5 Monitoring

- [ ] 🔴 **CloudWatch Alarms with SNS actions** — never leave alarms without notification targets
- [ ] 🔴 Alarms configured for: CPU > 80%, Freeable Memory < 1GB, Free Storage < 10GB
- [ ] 🟠 Alarms configured for: High Connection Count, High Read/Write Latency
- [ ] 🟠 **Enhanced Monitoring** enabled (`monitoring_interval` ≤ 60s)

---

## Section 11 — Application Layer (Microservices)
> **HIPAA:** §164.312(b) Audit Controls | §164.308(a)(6) Security Incidents

### 11.1 PHI Handling in Code

- [ ] 🔴 **No PHI in application logs** — no patient name, DOB, diagnosis, contact info, account number in log output
- [ ] 🔴 **No PHI in error messages** returned to clients — return error code only, never stack traces with data
- [ ] 🔴 **No PHI in URL query parameters** — use POST body or request headers for PHI identifiers
- [ ] 🔴 **No PHI in SQS message bodies in plaintext** — encrypt PHI fields before enqueuing
- [ ] 🟠 **PHI fields are masked** in log output (e.g., `patientId: ****-****-xxxx`)
- [ ] 🟡 **Field-level encryption** for PHI stored in DB or S3 (application-layer, in addition to storage encryption)

### 11.2 Audit Logging (Application Level)

- [ ] 🔴 **Every access to PHI is logged** — who, when, what resource, what action, what outcome
- [ ] 🔴 Audit log entries contain: `timestamp`, `service`, `user_id` (not name), `action`, `resource_id`, `outcome`
- [ ] 🔴 Audit logs are **separate from application logs** — different log group, different retention
- [ ] 🟠 Audit logs are **immutable** — shipped to S3 with Object Lock
- [ ] 🟡 Audit logs include `request_id` for end-to-end traceability

### 11.3 API Security

- [ ] 🔴 All API endpoints require **authentication** — no anonymous access to PHI endpoints
- [ ] 🔴 **Authorization is enforced at every endpoint** — not just at gateway level
- [ ] 🔴 **Rate limiting** is applied — prevent PHI enumeration attacks
- [ ] 🟠 **CORS policy** is restrictive — only allowed origins can make requests
- [ ] 🟠 **Input validation** on all PHI fields — reject unexpected formats, lengths, characters
- [ ] 🟡 Sensitive endpoints require **re-authentication** (e.g., exporting PHI report)

### 11.4 Health Checks & Observability

- [ ] 🔴 **Health endpoints do not expose configuration, secrets, or PHI** — return status code only
- [ ] 🟠 Spring Boot Actuator: **disable or protect** `/actuator/env`, `/actuator/beans`, `/actuator/heapdump`
- [ ] 🟠 **Metrics do not contain PHI label values** (e.g., no patient_id in Prometheus labels)
- [ ] 🟡 **Distributed tracing** (OpenTelemetry / AWS X-Ray) — trace IDs must not leak PHI

---

## Section 12 — CI/CD & Supply Chain Security
> **HIPAA:** §164.308(a)(1) Risk Analysis | §164.308(a)(5) Security Training

### 12.1 Pipeline Security

- [ ] 🔴 **CI/CD pipelines use IRSA** — no static AWS credentials in pipeline environment variables
- [ ] 🔴 **Secrets are pulled from SSM/Vault at runtime** — never stored in CI/CD platform
- [ ] 🔴 **Container image vulnerability scan** blocks deployment on CRITICAL CVEs
- [ ] 🟠 **SAST (Static Application Security Testing)** runs on every pull request
- [ ] 🟠 **Dependency vulnerability scanning** (e.g., `dependabot`, `snyk`, `trivy fs`) on every build
- [ ] 🟡 **DAST (Dynamic Application Security Testing)** runs against staging environment

### 12.2 Infrastructure as Code

- [ ] 🔴 **IaC security scanning** (`tfsec`, `checkov`, `terrascan`) runs on every Terraform PR
- [ ] 🔴 IaC scanning **blocks merge** if HIPAA-critical controls are missing (encryption, public access)
- [ ] 🟠 **Terraform state is encrypted** in S3 with KMS CMK and DynamoDB locking
- [ ] 🟠 **Terraform state S3 bucket** has versioning and deny-delete policy
- [ ] 🟡 Terraform workspace separation: **dev / staging / prod in separate AWS accounts** (not just workspaces)

### 12.3 Change Management

- [ ] 🔴 All infrastructure changes require **peer review** (pull request)
- [ ] 🔴 Production changes require **approval from designated security reviewer**
- [ ] 🟠 **Breaking glass procedure** is documented for emergency changes
- [ ] 🟡 All changes are **linked to a ticket** — traceability from code change to business justification

---

## Section 13 — Administrative Safeguards
> **HIPAA:** §164.308 Administrative Safeguards

### 13.1 Policies & Procedures

- [ ] 🔴 **Business Associate Agreement (BAA)** is signed with AWS
- [ ] 🔴 **Information Security Policy** documents PHI handling rules — reviewed annually
- [ ] 🔴 **Acceptable Use Policy** is acknowledged by all personnel with AWS access
- [ ] 🟠 **Data Classification Policy** — defines what constitutes PHI and how it must be treated
- [ ] 🟠 **Incident Response Plan** — documented, tested, includes HIPAA Breach Notification steps
- [ ] 🟡 All policies are **version-controlled** and available to all relevant staff

### 13.2 Risk Management

- [ ] 🔴 **Annual risk assessment** is conducted and documented (§164.308(a)(1)(ii)(A))
- [ ] 🔴 Identified risks have **documented mitigation plans** with owners and deadlines
- [ ] 🟠 **Penetration testing** is conducted annually — results are remediated and tracked
- [ ] 🟡 **Threat modeling** (STRIDE or PASTA) is performed for every new PHI feature

### 13.3 Training & Workforce

- [ ] 🔴 All staff with access to PHI systems complete **annual HIPAA Security Training**
- [ ] 🔴 **Onboarding security training** for new engineers before granting AWS access
- [ ] 🟠 **PHI handling procedures** are part of developer onboarding checklist
- [ ] 🟡 **Phishing simulation** is conducted annually

### 13.4 Access Reviews

- [ ] 🔴 **Quarterly access review** — verify all IAM roles and user accounts are still needed
- [ ] 🔴 **Immediate deprovisioning** when employee leaves — IAM users, VPN certificates, Vault tokens
- [ ] 🟠 **Privileged access review** (Admin/Operator roles) — monthly review
- [ ] 🟡 Access review results are **documented and retained** for 7 years

---

## Section 14 — Physical Safeguards
> **HIPAA:** §164.310 Physical Safeguards

- [ ] 🔴 **AWS Business Associate Agreement (BAA) is signed** — AWS covers physical safeguards for managed services (EC2, RDS, S3, EKS)
- [ ] 🔴 **Only BAA-covered AWS services** are used to process PHI — verify on the AWS HIPAA Eligible Services page
- [ ] 🟠 **On-premise developer workstations** with access to PHI use full-disk encryption (FileVault / BitLocker)
- [ ] 🟠 **VPN is required** for any access to PHI systems from outside the corporate network
- [ ] 🟡 **Mobile device management (MDM)** policy covers any device with AWS console access

---

## Quick Reference — HIPAA §164 → Checklist Section Mapping

| HIPAA Reference | Description | Checklist Sections |
|---|---|---|
| §164.308(a)(1) | Risk Analysis & Risk Management | 6, 12, 13 |
| §164.308(a)(3) | Workforce Authorization | 1, 9, 13 |
| §164.308(a)(5) | Security Awareness Training | 12, 13 |
| §164.308(a)(6) | Security Incident Procedures | 5, 11 |
| §164.308(a)(7) | Contingency Plan (Backup & DR) | 7 |
| §164.308(a)(8) | Evaluation (periodic) | 6 |
| §164.310 | Physical Safeguards | 14 |
| §164.312(a)(1) | Access Control | 1, 8, 9, 10, 11 |
| §164.312(a)(2)(iv) | Encryption at Rest | 2 |
| §164.312(b) | Audit Controls | 5, 10, 11 |
| §164.312(c)(1) | Integrity | 2, 7, 8 |
| §164.312(d) | Authentication | 1, 3, 9 |
| §164.312(e)(1) | Transmission Security | 3, 4, 8 |
| §164.312(e)(2)(ii) | Encryption in Transit | 3, 10 |

---

## Minimum Viable HIPAA — "Must have before first PHI in production"

The following items are the absolute minimum before any PHI is processed. All others must be addressed within 30-90 days.

```
ENCRYPTION
[ ] CMK encryption enabled on: RDS, S3, EKS secrets, SQS, CloudWatch Logs
[ ] rds.force_ssl = 1
[ ] S3 bucket policy: deny non-TLS requests
[ ] ALB: TLS 1.2+ with HTTP→HTTPS redirect

ACCESS CONTROL
[ ] IRSA for all EKS workloads (no static credentials)
[ ] MFA required for all human AWS users
[ ] No public RDS, no public S3
[ ] RDS IAM authentication enabled
[ ] Client VPN for remote access (no bastion over internet)

AUDIT LOGGING
[ ] CloudTrail: multi-region, log file validation, KMS, S3 with deny-delete
[ ] VPC Flow Logs: enabled, KMS-encrypted
[ ] EKS: all 5 control plane log types enabled
[ ] RDS: CloudWatch Logs exports (postgresql, upgrade)
[ ] WAF: always-on logging to Firehose → S3
[ ] SNS actions on ALL CloudWatch alarms

THREAT DETECTION
[ ] GuardDuty: enabled (S3 + EKS runtime protection)

BACKUP & DR
[ ] RDS: Multi-AZ, backup_retention_period = 35, skip_final_snapshot = false
[ ] S3: versioning enabled, 7-year lifecycle rules

NETWORK
[ ] All PHI workloads in private subnets
[ ] VPC Endpoints: S3, STS, KMS, CloudWatch Logs
[ ] WAF on all ALBs

ADMINISTRATIVE
[ ] AWS BAA signed
[ ] HIPAA Security Policy documented
[ ] Incident Response Plan documented
```

---

## Revision History

| Version | Date | Author | Changes |
|---|---|---|---|
| 1.0 | 2024-06-01 | [Your Name] | Initial creation of the HIPAA DevOps Checklist |

---

*This checklist should be reviewed and updated after each:*
- *Annual risk assessment*
- *Major architecture change*
- *New AWS service added to the PHI data path*
- *HIPAA regulation update*
- *Penetration test or security incident*
