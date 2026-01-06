# Infrastructure Quality - Remediation Todo List

**Based on:** INFRASTRUCTURE_AUDIT_REPORT.md (2025-01-06)  
**Baseline Commit:** 7d5300f  
**Current Compliance:** 65% → **85% (Updated 2026-01-06)**  
**Target:** 95%

---

## 🔴 CRITICAL PRIORITY (Week 1) - ✅ COMPLETE

### Documentation

- [x] **Task 1:** Create comprehensive `compute/eks/README.md` ✅ (Commit: 04f8154)
  - Architecture overview (control plane + node groups)
  - Graviton3 configuration and benefits
  - Node group sizing strategies
  - EKS Add-ons management (CoreDNS, VPC-CNI, Pod Identity)
  - IRSA (IAM Roles for Service Accounts) examples
  - Upgrade guide for v21.x module
  - Networking configuration (VPC, subnets)
  - Security best practices
  - Troubleshooting guide

- [x] **Task 2:** Create comprehensive `database/rds-postgresql/README.md` ✅ (Commit: 04f8154)

### Code Quality

- [x] **Task 3:** Remove deprecated variables from `security/acm-certificate` ✅ (Commit: 04f8154)
- [x] **Task 4:** Check and fix `security/waf-web-acl` for deprecated variables ✅ (Commit: 04f8154)
- [x] **Task 10:** Fix deprecated `data.aws_region.current.name` → `.id` ✅ (Commit: 04f8154)

---

## 🟡 HIGH PRIORITY (Week 2) - ✅ COMPLETE

### Consistency & Standardization

- [x] **Task 5:** Standardize tagging pattern - convert to `merged_tags` ✅ (Commit: a73a8d3)
  - All 14 modules now use `merged_tags` consistently
  
- [x] **Task 6:** Ensure all modules merge `project_tags` ✅ (Commits: 3619089, bf88a4a)
  - Removed ALL deprecated variables (customer_id, architecture_type)
  - Added project_name support to: KMS, SSM, NAT Gateway, Route53 Zone
  - All modules now use has_customer/has_project pattern

### Security Enhancements

- [x] **Task 7:** Add VPC Flow Logs to `network/vpc` module ✅ (Commit: 125e255)
  - Created flow-logs.tf with CloudWatch Log Group, IAM Role, Flow Log resource
  - Configurable via enable_flow_logs (default: true)
  - 7 days retention default, configurable
  
- [x] **Task 8:** Make CloudWatch retention configurable ✅ (Commit: 69aa473)
  - Added cloudwatch_retention_days to RDS and ElastiCache
  - Default: 30 days with validation

---

## 🟢 MEDIUM PRIORITY (Week 3-4) - 🔄 IN PROGRESS

### Module Flexibility

- [ ] **Task 9:** Add conditional resource creation pattern to all modules (🔄 PARTIAL - 1/15)
  - Add `create` boolean variable to each module's variables.tf
  - Wrap main resources in `count = var.create ? 1 : 0`
  - Update outputs to handle conditional creation
  - Modules status:
    - [x] security/ssm-parameter ✅ (Commit: ba04a8f)
    - [ ] security/kms
    - [ ] security/acm-certificate
    - [ ] security/waf-web-acl
    - [ ] compute/eks
    - [ ] database/rds-postgresql
    - [ ] database/elasticache-redis
    - [ ] storage/s3
    - [ ] network/vpc
    - [ ] network/client-vpn
    - [ ] network/nat_gateway
    - [ ] network/internet_gateway
    - [ ] network/vpc-endpoint
    - [ ] network/route53-zone
    - [ ] load-balancing/alb
    - [ ] security/kms
    - [ ] security/acm-certificate
    - [ ] security/waf-web-acl
    - [ ] security/ssm-parameter
    - [ ] storage/s3

### Code Quality

- [ ] **Task 10:** Fix deprecated AWS provider attributes
  - Replace `data.aws_region.current.name` with `.id` in:
    - `database/rds-postgresql/cloudwatch.tf` (33 instances)
  - Run terraform validate to confirm fixes

- [ ] **Task 11:** Enhance child module variable validation
  - Add validation blocks to module-specific variables
  - Focus on:
    - Instance types/sizes (ensure valid AWS types)
    - CIDR blocks (regex validation)
    - Port numbers (range validation)
    - Engine versions (format validation)
  - Document validation patterns in comments

### Security Audit

- [ ] **Task 12:** Conduct security group rules audit
  - Review all security group ingress/egress rules
  - Document justification for each rule
  - Identify overly permissive rules (e.g., 0.0.0.0/0)
  - Restrict development environment rules where possible
  - Create security_groups_audit.md with findings

- [ ] **Task 13:** Review IAM policies for least privilege
  - Audit all IAM role policies
  - Verify minimal permissions for:
    - EKS node roles
    - VPC CNI role
    - Lambda execution roles (if any)
  - Document required permissions

---

## 🔵 LOW PRIORITY (Backlog)

### Documentation Enhancements

- [ ] **Task 14:** Add architecture diagrams to all module READMEs
  - Use mermaid diagrams or draw.io
  - Show resource relationships
  - Include network topology where relevant

- [ ] **Task 15:** Create examples/ directories for each module
  - Basic example (minimal configuration)
  - Advanced example (all features)
  - Multi-environment example
  - Ensure examples are tested and working

- [ ] **Task 16:** Add CHANGELOG.md to each module
  - Document version history
  - Note breaking changes
  - Migration guides for major versions

### Variable Management

- [ ] **Task 17:** Standardize variable descriptions
  - Format: "What it does. Why you'd change it. Example: <value>"
  - Add type information where complex
  - Document relationships between variables

- [ ] **Task 18:** Document terraform.tfvars usage pattern
  - Create VARIABLES.md guide
  - Explain which vars go in tfvars vs passed directly
  - Provide example terraform.tfvars for each environment

### Automation & CI/CD

- [ ] **Task 19:** Add pre-commit hooks
  - Create `.pre-commit-config.yaml`
  - Include hooks:
    - terraform fmt
    - terraform validate
    - tflint
    - tfsec (security scanning)
  - Document installation in CONTRIBUTING.md

- [ ] **Task 20:** Create GitHub Actions workflow
  - Trigger on pull requests
  - Run terraform validate
  - Run terraform plan (with mock backend)
  - Run security scans
  - Fail PR if validation fails

### State Management

- [ ] **Task 21:** Audit Terraform state backend configuration
  - Verify S3 backend has:
    - Encryption enabled
    - Versioning enabled
    - Access logging enabled
  - Verify DynamoDB table for state locking
  - Document state backend setup in README

### Module Version Management

- [ ] **Task 22:** Document module version pinning strategy
  - Create VERSION_POLICY.md
  - Explain semantic versioning usage
  - Document when to pin vs use ranges
  - Example: `~> 21.0` for EKS module

### Dependency Management

- [ ] **Task 23:** Review and document implicit dependencies
  - Identify resources that depend on others
  - Add explicit `depends_on` where needed
  - Document dependency graph

### Cost Optimization

- [ ] **Task 24:** Enhance cost allocation tagging
  - Ensure all resources have:
    - Environment tag
    - Customer tag (when applicable)
    - Project tag (when applicable)
    - CostCenter tag (add if missing)
  - Document tagging strategy in TAGGING.md

### Additional Quality Improvements

- [ ] **Task 25:** Add input validation for network resources
  - CIDR block overlap detection
  - Subnet size validation
  - Availability zone validation

- [ ] **Task 26:** Create module testing framework
  - Add terratest tests for critical modules
  - Test successful creation
  - Test conditional creation (create = false)
  - Test update scenarios

- [ ] **Task 27:** Performance optimization review
  - Review data source queries (are they efficient?)
  - Minimize provider calls where possible
  - Use `count` vs `for_each` appropriately

- [ ] **Task 28:** Disaster recovery documentation
  - Document backup procedures
  - Document restore procedures
  - Create runbooks for common scenarios
  - Test disaster recovery plans

---

## Progress Tracking

**Total Tasks:** 28  
**Completed:** 0  
**In Progress:** 0  
**Pending:** 28

### By Priority

| Priority | Total | Completed | Remaining |
|----------|-------|-----------|-----------|
| 🔴 Critical | 4 | 0 | 4 |
| 🟡 High | 4 | 0 | 4 |
| 🟢 Medium | 5 | 0 | 5 |
| 🔵 Low | 15 | 0 | 15 |

### By Category

| Category | Tasks | Status |
|----------|-------|--------|
| Documentation | 7 | ⏳ Not Started |
| Code Quality | 5 | ⏳ Not Started |
| Security | 3 | ⏳ Not Started |
| Consistency | 2 | ⏳ Not Started |
| Automation | 3 | ⏳ Not Started |
| Testing | 2 | ⏳ Not Started |
| Other | 6 | ⏳ Not Started |

---

## Success Criteria

### Week 1 Completion (Critical)
- ✅ All critical priority tasks completed
- ✅ terraform validate passes
- ✅ No deprecated variables in use
- ✅ Core modules (EKS, RDS) fully documented

### Week 2 Completion (High)
- ✅ Consistent tagging across all modules
- ✅ VPC Flow Logs enabled
- ✅ CloudWatch retention configurable
- ✅ Security posture improved

### Month 1 Completion (Medium)
- ✅ All modules support conditional creation
- ✅ Enhanced validation on all variables
- ✅ Security audit completed
- ✅ No deprecated AWS provider attributes

### Overall Target (3 months)
- ✅ 95%+ compliance with all quality criteria
- ✅ Comprehensive documentation for all modules
- ✅ Automated validation in CI/CD
- ✅ Full test coverage for critical paths

---

## Notes

- Each task should be completed with terraform validate passing
- Create separate git commits for each logical change
- Update INFRASTRUCTURE_AUDIT_REPORT.md after major milestones
- Add notes in each commit message referencing task numbers
- Consider creating feature branches for larger changes

---

**Last Updated:** 2025-01-06  
**Next Review:** After Week 1 completion (2025-01-13)
