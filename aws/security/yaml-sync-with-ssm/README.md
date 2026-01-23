# YAML-SSM Sync - Terraform Module

Terraform wrapper for synchronizing YAML configuration files with AWS SSM Parameter Store.

## Purpose

Automates bidirectional synchronization between local YAML files and AWS SSM Parameter Store as part of Terraform deployment workflow.

## Features

- ✅ **Upload Mode**: YAML file → SSM Parameter Store
- ✅ **Download Mode**: SSM Parameter Store → YAML file
- ✅ **Change Detection**: Only syncs when content changes
- ✅ **Schema Validation**: Validates YAML before upload
- ✅ **Force Sync**: Override smart sync behavior
- ✅ **Docker-based**: No local Python dependencies

## Usage

### Upload YAML to SSM (Pre-Apply)

Use this to upload configuration **before** running other modules that depend on SSM config.

```hcl
module "yaml_ssm_sync_upload" {
  source = "./security/yaml-sync-with-ssm"
  
  common_prefix = local.common_prefix
  common_tags   = local.common_tags
  
  sync_mode         = "upload"
  yaml_file_path    = "${path.root}/config/chains.yaml"
  ssm_parameter_name = "/forge/security-group-chains"
  aws_region        = var.aws_region
  
  validate_before_upload = true
  force_sync            = false
}
```

### Download from SSM to YAML (Post-Apply)

Use this to download updated configuration **after** manual SSM changes.

```hcl
module "yaml_ssm_sync_download" {
  source = "./security/yaml-sync-with-ssm"
  
  common_prefix = local.common_prefix
  common_tags   = local.common_tags
  
  sync_mode          = "download"
  yaml_file_path     = "${path.root}/config/chains.yaml"
  ssm_parameter_name = "/forge/security-group-chains"
  aws_region         = var.aws_region
}
```

### Disable Sync

```hcl
module "yaml_ssm_sync" {
  source = "./security/yaml-sync-with-ssm"
  
  common_prefix = local.common_prefix
  common_tags   = local.common_tags
  
  sync_mode          = "none"  # Skip sync
  yaml_file_path     = "${path.root}/config/chains.yaml"
  ssm_parameter_name = "/forge/security-group-chains"
  aws_region         = var.aws_region
}
```

## Workflow Examples

### Workflow 1: Upload Config Before Infrastructure

```hcl
# Step 1: Upload chains config to SSM
module "yaml_ssm_sync" {
  source = "./security/yaml-sync-with-ssm"
  
  sync_mode          = "upload"
  yaml_file_path     = "${path.root}/config/chains.yaml"
  ssm_parameter_name = "/forge/security-group-chains"
  aws_region         = var.aws_region
  validate_before_upload = true
}

# Step 2: Create security groups
module "eks" {
  source = "./compute/eks"
  # ...
  
  depends_on = [module.yaml_ssm_sync]
}

# Step 3: Run chainer (reads from SSM)
module "security_group_chainer" {
  source = "./security/security-group-chainer"
  
  chains_config_ssm_parameter = "/forge/security-group-chains"
  # ...
  
  depends_on = [module.eks, module.yaml_ssm_sync]
}
```

### Workflow 2: Download After Manual SSM Update

```bash
# Someone updated SSM parameter manually via AWS Console
# Download to local file for version control

terraform apply -target=module.yaml_ssm_sync_download
git add config/chains.yaml
git commit -m "Updated chains config from SSM"
```

## Sync Modes

### `upload`
- Direction: Local YAML → SSM
- Use case: Before infrastructure deployment
- Validates YAML schema before upload
- Skips if SSM already has identical content (unless `force_sync = true`)

### `download`
- Direction: SSM → Local YAML
- Use case: After manual SSM updates
- Overwrites local file
- Skips if local file already has identical content (unless `force_sync = true`)

### `none`
- Direction: None
- Use case: Disable sync temporarily
- No Docker execution

## Change Detection

Sync triggers when:
- **YAML file content changes** (SHA256 hash)
- **SSM parameter name changes**
- **Docker image version changes**
- **Sync mode changes**
- **force_sync = true** (forces every apply)

## Prerequisites

1. **Docker installed** on machine running Terraform
2. **AWS credentials** configured
3. **YAML file exists** (for upload mode)
4. **SSM parameter exists** (for download mode)

## Example YAML File

`config/chains.yaml`:
```yaml
version: "1.0"
timeout_seconds: 1800
polling_interval_seconds: 10
circuit_breaker_threshold: 5

chains:
  - name: alb-to-eks
    master_tier: ALB
    slave_tier: EKSNodes
    ports: [80, 443]
    protocol: tcp
    bidirectional: true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| common_prefix | Common prefix for resource naming | string | - | yes |
| common_tags | Common tags | map(string) | - | yes |
| sync_mode | Sync mode (upload/download/none) | string | "upload" | no |
| yaml_file_path | Path to local YAML file | string | - | yes |
| ssm_parameter_name | SSM parameter path | string | - | yes |
| docker_image | Docker image | string | "ghcr.io/forge/yaml-ssm-sync:latest" | no |
| aws_region | AWS region | string | - | yes |
| validate_before_upload | Validate YAML schema | bool | true | no |
| force_sync | Force sync even if identical | bool | false | no |
| parameter_description | SSM parameter description | string | "Synchronized from Terraform" | no |
| trigger_on_yaml_change | Trigger on YAML content change | bool | true | no |

## Outputs

| Name | Description |
|------|-------------|
| sync_executed | Whether sync was executed |
| sync_mode | Sync mode used |
| yaml_file_path | Path to local YAML file |
| ssm_parameter_name | SSM parameter path |
| yaml_file_hash | SHA256 hash of YAML content |
| docker_command | Docker command executed |
| module_tags | Tags applied by module |

## Integration with Main Terraform

Add to `forge-infrastructure/aws/main.tf`:

```hcl
# Upload chains config to SSM before creating infrastructure
module "yaml_ssm_sync_chains" {
  source = "./security/yaml-sync-with-ssm"
  
  common_prefix = local.common_prefix
  common_tags   = local.common_tags
  
  sync_mode              = "upload"
  yaml_file_path         = "${path.root}/config/chains.yaml"
  ssm_parameter_name     = "/forge/security-group-chains"
  aws_region             = var.aws_region
  validate_before_upload = true
  force_sync             = false
}

# Create infrastructure (depends on config being uploaded)
module "eks" {
  source = "./compute/eks"
  # ...
  depends_on = [module.yaml_ssm_sync_chains]
}

# Run chainer (reads config from SSM)
module "security_group_chainer" {
  source = "./security/security-group-chainer"
  
  chains_config_ssm_parameter = "/forge/security-group-chains"
  # ...
  depends_on = [module.eks, module.yaml_ssm_sync_chains]
}
```

## Testing

```bash
# 1. Create test config
cat > config/chains.yaml <<EOF
version: "1.0"
timeout_seconds: 1800
chains:
  - name: test-chain
    master_tier: TestTier1
    slave_tier: TestTier2
    ports: [8080]
EOF

# 2. Upload to SSM
terraform apply -target=module.yaml_ssm_sync_chains

# 3. Verify in AWS
aws ssm get-parameter --name /forge/security-group-chains --query 'Parameter.Value' --output text

# 4. Test download
rm config/chains.yaml
terraform apply -target=module.yaml_ssm_sync_download
cat config/chains.yaml
```

## Troubleshooting

### YAML validation fails
```
Error: YAML validation failed: Invalid port: 70000
```
**Solution**: Fix YAML syntax/schema and re-apply

### SSM parameter not found (download mode)
```
Error: SSM parameter not found: /forge/security-group-chains
```
**Solution**: Run upload first or create parameter manually

### Sync not triggered
- Check `trigger_on_yaml_change = true`
- Verify YAML file exists: `ls -la config/chains.yaml`
- Try `force_sync = true`

### Docker command fails
- Verify Docker installed: `docker --version`
- Check AWS credentials: `aws sts get-caller-identity`
- Check Docker image exists: `docker pull ghcr.io/forge/yaml-ssm-sync:latest`

## Related Modules

- `security/security-group-chainer` - Consumes SSM config
- `forge-helpers/yaml-sync-with-ssm` - Python implementation
- `forge-helpers/security-group-chainer` - Chain automation

## License

MIT
