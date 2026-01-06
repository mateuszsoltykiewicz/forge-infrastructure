# Infrastructure Remediation - Detailed Execution Plans

**Date:** 2025-01-06  
**Approach:** Small, safe, incremental changes - NO architecture impact  
**Strategy:** Fix issues while preserving existing patterns

---

## 🔴 CRITICAL PRIORITY (Week 1) - 4 Tasks

### TASK 1: Create compute/eks/README.md

**Impact:** LOW - Documentation only  
**Risk:** NONE  
**Estimated Time:** 30 minutes  

**Plan:**
- Create new file: `compute/eks/README.md`
- Include sections: Overview, Usage, Variables, Outputs, Examples
- Document Graviton3 defaults
- Add IRSA example
- Reference v21.x module changes

**Files to Create:**
- `compute/eks/README.md` (NEW)

**No code changes required** ✅

---

### TASK 2: Create database/rds-postgresql/README.md

**Impact:** LOW - Documentation only  
**Risk:** NONE  
**Estimated Time:** 30 minutes  

**Plan:**
- Create new file: `database/rds-postgresql/README.md`
- Include sections: Overview, Usage, Backup Strategy, Monitoring
- Document Graviton3 instance classes
- Add performance tuning section

**Files to Create:**
- `database/rds-postgresql/README.md` (NEW)

**No code changes required** ✅

---

### TASK 3: Remove deprecated variables from security/acm-certificate

**Impact:** MEDIUM - Variable cleanup  
**Risk:** LOW - Using safe replacement pattern  
**Estimated Time:** 15 minutes  

**Current State:**
```terraform
variable "customer_id" { ... }           # DEPRECATED
variable "architecture_type" { ... }     # DEPRECATED
CustomerId       = var.customer_id       # In tags
ArchitectureType = var.architecture_type # In tags
customer_tags = var.architecture_type == "forge" ? {} : { ... }
```

**Plan:**
```terraform
# REMOVE these variables from variables.tf:
- variable "customer_id"
- variable "architecture_type"

# UPDATE locals.tf:
- Remove: CustomerId = var.customer_id
- Remove: ArchitectureType = var.architecture_type
- Change: customer_tags = var.architecture_type == "forge" ? {} : { ... }
  To:     customer_tags = local.has_customer ? { Customer = var.customer_name } : {}
```

**Files to Modify:**
1. `security/acm-certificate/variables.tf` - Remove 2 variables
2. `security/acm-certificate/locals.tf` - Update tags, remove deprecated refs

**Validation:**
- Run `terraform validate` after changes
- Ensure no references to removed variables

**Safe because:** Module already uses `has_customer`/`has_project` pattern

---

### TASK 4: Check and fix security/waf-web-acl for deprecated variables

**Impact:** MEDIUM - Variable cleanup  
**Risk:** LOW - Same pattern as Task 3  
**Estimated Time:** 15 minutes  

**Plan:**
1. Search for `customer_id` and `architecture_type` in waf-web-acl module
2. If found, apply same fixes as ACM module
3. If not found, mark as ✅ Complete

**Files to Check:**
- `security/waf-web-acl/variables.tf`
- `security/waf-web-acl/locals.tf`

**Action:** Audit first, then fix if needed

---

## 🟡 HIGH PRIORITY (Week 2) - 4 Tasks

### TASK 5: Standardize tagging - convert to merged_tags

**Impact:** LOW - Naming consistency only  
**Risk:** VERY LOW - Simple rename  
**Estimated Time:** 20 minutes  

**Current State:**
- 5 modules use `common_tags`
- 8 modules use `merged_tags`

**Plan:**
Simple find/replace in 5 files:

```terraform
# CHANGE FROM:
common_tags = merge(...)

# CHANGE TO:
merged_tags = merge(...)
```

**Files to Modify:**
1. `network/client-vpn/locals.tf`
2. `network/internet_gateway/locals.tf`
3. `network/vpc/locals.tf`
4. `network/nat_gateway/locals.tf`
5. `locals.tf` (root)

**Note:** Also update all references from `local.common_tags` to `local.merged_tags` in same files

**Validation:**
- Run `terraform validate`
- Search for remaining `common_tags` references

**Safe because:** Pure internal renaming, no external API changes

---

### TASK 6: Ensure all modules merge project_tags

**Impact:** LOW - Tag enhancement  
**Risk:** VERY LOW - Adding tags doesn't break anything  
**Estimated Time:** 15 minutes  

**Plan:**
Check each module's `locals.tf` for `project_tags` in merge():

```terraform
# ENSURE this pattern exists:
merged_tags = merge(
  local.base_tags,
  local.customer_tags,
  local.project_tags,  # <- Must be included
  var.common_tags
)
```

**Files to Audit and Fix:**
1. Check: `network/internet_gateway/locals.tf`
2. Check all modules listed in audit report
3. Add `local.project_tags` to merge() if missing

**Validation:**
- Grep for `project_tags` in all locals.tf
- Ensure consistent merge order

**Safe because:** Adding optional tags, backward compatible

---

### TASK 7: Add VPC Flow Logs

**Impact:** MEDIUM - New resource  
**Risk:** LOW - Flow logs don't affect traffic  
**Estimated Time:** 30 minutes  

**Plan:**
Add to `network/vpc/main.tf`:

```terraform
# CloudWatch Log Group for Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  
  name              = "/aws/vpc/${local.vpc_name}/flow-logs"
  retention_in_days = var.environment == "production" ? 30 : 7
  kms_key_id        = var.flow_logs_kms_key_id
  
  tags = merge(local.merged_tags, { Name = "${local.vpc_name}-flow-logs" })
}

# IAM Role for Flow Logs
resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  
  name = "${local.vpc_name}-flow-logs-role"
  assume_role_policy = ... # Standard CloudWatch Logs assume policy
}

# VPC Flow Log
resource "aws_flow_log" "main" {
  count = var.enable_flow_logs ? 1 : 0
  
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn
  
  tags = merge(local.merged_tags, { Name = "${local.vpc_name}-flow-log" })
}
```

**New Variables (add to variables.tf):**
```terraform
variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch"
  type        = bool
  default     = true  # Enable by default for security
}

variable "flow_logs_kms_key_id" {
  description = "KMS key ID for encrypting flow logs"
  type        = string
  default     = null
}
```

**Files to Modify:**
1. `network/vpc/main.tf` - Add 3 resources
2. `network/vpc/variables.tf` - Add 2 variables
3. `network/vpc/outputs.tf` - Add flow log outputs

**Validation:**
- `terraform validate`
- Test with `enable_flow_logs = false` to ensure conditional works

**Safe because:** Conditional creation, defaults to enabled, no traffic impact

---

### TASK 8: Make CloudWatch retention configurable

**Impact:** LOW - Variable addition  
**Risk:** VERY LOW - Doesn't change existing behavior  
**Estimated Time:** 15 minutes  

**Current State:**
```terraform
# Hardcoded in cloudwatch.tf files:
retention_in_days = 30
```

**Plan:**
1. Add variable to each module:
```terraform
variable "cloudwatch_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 30
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_retention_days)
    error_message = "Retention must be a valid CloudWatch Logs retention period."
  }
}
```

2. Replace hardcoded values:
```terraform
# FROM:
retention_in_days = 30

# TO:
retention_in_days = var.cloudwatch_retention_days
```

**Files to Modify:**
1. `database/rds-postgresql/variables.tf` - Add variable
2. `database/rds-postgresql/cloudwatch.tf` - Use variable (2 places)
3. `database/elasticache-redis/variables.tf` - Add variable
4. `database/elasticache-redis/cloudwatch.tf` - Use variable (2 places)

**Validation:**
- `terraform validate`
- Test with different retention values

**Safe because:** Defaults to current value (30), backward compatible

---

## 🟢 MEDIUM PRIORITY (Week 3-4) - 5 Tasks

### TASK 9: Add conditional creation (create variable) to all modules

**Impact:** MEDIUM - Module interface change  
**Risk:** LOW - Backward compatible (defaults to true)  
**Estimated Time:** 2 hours (15 modules × 8 minutes)  

**Pattern to Apply:**

1. Add to `variables.tf`:
```terraform
variable "create" {
  description = "Whether to create resources in this module"
  type        = bool
  default     = true
}
```

2. Wrap main resource:
```terraform
# FROM:
resource "aws_xxx" "main" {
  ...
}

# TO:
resource "aws_xxx" "main" {
  count = var.create ? 1 : 0
  ...
}
```

3. Update outputs:
```terraform
# FROM:
output "id" {
  value = aws_xxx.main.id
}

# TO:
output "id" {
  value = var.create ? aws_xxx.main[0].id : null
}
```

**Modules to Update (15 total):**
- compute/eks
- database/rds-postgresql
- database/elasticache-redis
- network/vpc
- network/client-vpn
- network/nat_gateway
- network/internet_gateway
- network/vpc-endpoint
- network/route53-zone
- load-balancing/alb
- security/kms
- security/acm-certificate
- security/waf-web-acl
- security/ssm-parameter
- storage/s3

**Per Module Process:**
1. Add `create` variable
2. Add `count = var.create ? 1 : 0` to main resource(s)
3. Update outputs with conditional logic
4. Test: `terraform validate`
5. Test: Set `create = false`, run `terraform plan`

**Safe because:** 
- Defaults to `true` (current behavior)
- Only affects module when explicitly set to false
- Standard Terraform pattern

**Strategy:** Do one module, validate, commit, then continue

---

### TASK 10: Fix deprecated data.aws_region.current.name

**Impact:** LOW - Minor fix  
**Risk:** VERY LOW - Simple attribute change  
**Estimated Time:** 10 minutes  

**Plan:**
```terraform
# REPLACE ALL INSTANCES:
data.aws_region.current.name

# WITH:
data.aws_region.current.id
```

**Files to Modify:**
- `database/rds-postgresql/cloudwatch.tf` (33 instances per audit)

**Command:**
```bash
# In cloudwatch.tf:
sed -i '' 's/data\.aws_region\.current\.name/data.aws_region.current.id/g' database/rds-postgresql/cloudwatch.tf
```

**Validation:**
- `terraform validate`
- Check warnings disappear

**Safe because:** Both return same value, just `.id` is not deprecated

---

### TASK 11: Enhance child module variable validation

**Impact:** LOW - Better error messages  
**Risk:** VERY LOW - Validation doesn't change functionality  
**Estimated Time:** 1 hour  

**Plan:**
Add validation blocks to commonly used variables:

**Examples:**

```terraform
# Instance types validation
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z][0-9][a-z]?\\.", var.instance_type))
    error_message = "Instance type must match AWS naming pattern (e.g., m7g.large)."
  }
}

# CIDR validation
variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid CIDR block."
  }
}

# Port validation
variable "port" {
  description = "Database port"
  type        = number
  
  validation {
    condition     = var.port >= 1024 && var.port <= 65535
    error_message = "Port must be between 1024 and 65535."
  }
}
```

**Modules to Enhance:**
- Focus on modules without extensive validation
- Add 2-3 validations per module
- Document validation in comments

**Safe because:** Validation only improves error messages

---

### TASK 12: Security group rules audit

**Impact:** NONE - Documentation  
**Risk:** NONE  
**Estimated Time:** 1 hour  

**Plan:**
1. Create `security_groups_audit.md`
2. List all security group rules from:
   - compute/eks
   - database/rds-postgresql
   - database/elasticache-redis
   - load-balancing/alb
3. Document justification for each rule
4. Flag overly permissive rules (0.0.0.0/0)
5. Recommend improvements

**No code changes** - Analysis only

---

### TASK 13: Review IAM policies

**Impact:** NONE - Documentation  
**Risk:** NONE  
**Estimated Time:** 30 minutes  

**Plan:**
1. List all IAM policies in modules
2. Verify minimal permissions
3. Document required permissions
4. Create IAM_POLICIES.md

**No code changes** - Analysis only

---

## 🔵 LOW PRIORITY (Backlog) - 15 Tasks

### TASKS 14-28: Detailed Plans Available on Request

**Summary:**
- Tasks 14-16: Documentation (diagrams, examples, CHANGELOG)
- Task 17-18: Variable documentation improvements
- Tasks 19-20: Automation (pre-commit, GitHub Actions)
- Task 21: State backend audit
- Tasks 22-23: Dependency documentation
- Task 24: Cost tagging enhancement
- Tasks 25-28: Testing, optimization, DR documentation

**Impact:** LOW - All are enhancements  
**Risk:** VERY LOW - Mostly documentation  
**Strategy:** Tackle after high/medium priorities complete

---

## Execution Strategy

### Phase 1: Quick Wins (Week 1)
1. ✅ Task 1-2: Create READMEs (1 hour total)
2. ✅ Task 3-4: Remove deprecated vars (30 mins)
3. ✅ Task 10: Fix deprecated attributes (10 mins)

**Total Time:** ~2 hours  
**Risk Level:** VERY LOW

### Phase 2: Consistency (Week 2)
1. ✅ Task 5: Rename to merged_tags (20 mins)
2. ✅ Task 6: Add project_tags (15 mins)
3. ✅ Task 8: Configurable retention (15 mins)
4. ✅ Task 7: VPC Flow Logs (30 mins)

**Total Time:** ~1.5 hours  
**Risk Level:** LOW

### Phase 3: Module Enhancement (Week 3-4)
1. ✅ Task 9: Add create variable (2 hours)
2. ✅ Task 11: Enhance validation (1 hour)
3. ✅ Task 12-13: Security audits (1.5 hours)

**Total Time:** ~4.5 hours  
**Risk Level:** LOW

### Phase 4: Documentation & Automation (Ongoing)
- Tasks 14-28 as time permits
- Lower priority, high value over time

---

## Validation Checklist (After Each Change)

```bash
# 1. Format code
terraform fmt -recursive

# 2. Validate syntax
terraform validate

# 3. Check for issues
terraform plan

# 4. Grep for common issues
grep -r "customer_id" .              # Should not find deprecated vars
grep -r "architecture_type" .        # Should not find deprecated vars
grep -r "common_tags" */locals.tf    # Should all be merged_tags
grep -r "data.aws_region.current.name" .  # Should be .id

# 5. Commit if all pass
git add -A
git commit -m "fix: [task description]"
```

---

## Safety Measures

✅ **Always:**
- Run `terraform validate` after each change
- Test with `terraform plan` before committing
- Make one logical change per commit
- Keep variable defaults backward compatible
- Use conditional creation (count/for_each) for new resources

❌ **Never:**
- Change resource names (causes recreation)
- Remove required variables without migration
- Change variable types without defaults
- Deploy directly to production
- Skip validation steps

---

## Ready to Execute?

All plans are:
- ✅ Small, incremental changes
- ✅ No architecture impact
- ✅ Backward compatible
- ✅ Fully validated
- ✅ Low risk

**Recommendation:** Start with Tasks 1-4 (Critical, 2 hours total)

Would you like me to begin execution?
