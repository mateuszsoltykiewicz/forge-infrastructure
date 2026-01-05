# RDS PostgreSQL Module

Terraform module for deploying Amazon RDS PostgreSQL databases in the Forge platform. Optimized for PostgreSQL 16+ with Multi-AZ, automated backups, encryption, and enhanced monitoring.

## Overview

This module creates a production-ready RDS PostgreSQL instance with:
- **PostgreSQL 16+** with automatic minor version upgrades
- **Multi-AZ deployment** for high availability
- **Automated backups** with point-in-time recovery
- **Encryption at rest** using AWS KMS
- **Enhanced monitoring** with CloudWatch and Performance Insights
- **Secrets Manager integration** for password management
- **Customer-aware naming** for multi-tenant deployments

Designed specifically for Forge's configuration database requirements.

## Usage

### Basic Example (Shared Infrastructure)

```hcl
module "forge_db" {
  source = "../../modules/database/rds-postgresql"

  # Customer context (shared)
  customer_id       = ""
  customer_name     = ""
  architecture_type = "shared"
  plan_tier         = ""

  # Environment
  environment = "production"
  aws_region  = "us-east-1"

  # Instance configuration
  engine_version = "16.4"
  instance_class = "db.r8g.xlarge"

  # Storage (500GB with autoscaling to 1TB)
  allocated_storage     = 500
  max_allocated_storage = 1000
  storage_type          = "gp3"
  storage_throughput    = 125

  # Database configuration
  database_name   = "forge"
  master_username = "forgeadmin"
  # master_password = ""  # Auto-generated and stored in Secrets Manager

  # Network configuration
  vpc_id             = "vpc-0123456789abcdef0"
  subnet_ids         = ["subnet-abc123", "subnet-def456", "subnet-ghi789"]
  security_group_ids = ["sg-0123456789abcdef0"]

  # High availability
  multi_az = true

  # Backups (7 days retention)
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Security
  storage_encrypted         = true
  deletion_protection       = true
  iam_database_authentication_enabled = true

  # Monitoring
  monitoring_interval                   = 60
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]

  tags = {
    Project     = "Forge Platform"
    CostCenter  = "Platform Engineering"
  }
}
```

**Generated identifier**: `forge-production-db`

### Customer-Dedicated Example

```hcl
module "customer_db" {
  source = "../../modules/database/rds-postgresql"

  # Customer context (dedicated)
  customer_id       = "cust-sanofi-001"
  customer_name     = "sanofi"
  architecture_type = "dedicated_regional"
  plan_tier         = "advanced"

  # Environment
  environment = "production"
  aws_region  = "us-east-1"

  # Instance configuration (larger for customer workload)
  engine_version = "16.4"
  instance_class = "db.r8g.2xlarge"

  # Storage (1TB with autoscaling to 2TB)
  allocated_storage     = 1000
  max_allocated_storage = 2000
  storage_type          = "gp3"
  storage_throughput    = 500  # Higher throughput

  # Database configuration
  database_name   = "sanofi_db"
  master_username = "sanofi_admin"

  # Network configuration
  vpc_id             = "vpc-customer123"
  subnet_ids         = ["subnet-cust-a", "subnet-cust-b", "subnet-cust-c"]
  security_group_ids = ["sg-customer123"]

  # High availability
  multi_az = true

  # Backups (30 days retention for compliance)
  backup_retention_period = 30
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"
  skip_final_snapshot     = false

  # Security
  storage_encrypted         = true
  kms_key_id               = "arn:aws:kms:us-east-1:123456789012:key/abc-def-ghi"
  deletion_protection       = true
  iam_database_authentication_enabled = true

  # Monitoring (longer retention)
  monitoring_interval                   = 30
  performance_insights_enabled          = true
  performance_insights_retention_period = 731  # 2 years
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]

  # Custom parameters
  parameters = [
    {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements"
    },
    {
      name  = "max_connections"
      value = "500"
    },
    {
      name  = "work_mem"
      value = "16384"  # 16MB
    }
  ]

  tags = {
    Customer    = "Sanofi"
    CostCenter  = "Customer-Sanofi"
    Compliance  = "HIPAA"
  }
}
```

**Generated identifier**: `sanofi-us-east-1-db`

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `customer_id` | Customer identifier (empty for shared) | `string` | `""` | no |
| `customer_name` | Customer name for naming (empty for shared) | `string` | `""` | no |
| `architecture_type` | shared, dedicated_local, or dedicated_regional | `string` | `"shared"` | no |
| `plan_tier` | Customer plan tier for cost allocation | `string` | `""` | no |
| `environment` | Environment (production, staging, development) | `string` | n/a | yes |
| `aws_region` | AWS region | `string` | n/a | yes |
| `identifier_override` | Override DB identifier (auto-generated if empty) | `string` | `""` | no |
| `engine_version` | PostgreSQL version | `string` | `"16.4"` | no |
| `instance_class` | Instance type | `string` | `"db.r8g.xlarge"` | no |
| `allocated_storage` | Storage in GB | `number` | `500` | no |
| `max_allocated_storage` | Max storage for autoscaling | `number` | `1000` | no |
| `storage_type` | gp3, gp2, io1, or io2 | `string` | `"gp3"` | no |
| `iops` | Provisioned IOPS | `number` | `0` | no |
| `storage_throughput` | gp3 throughput in MB/s (125-1000) | `number` | `125` | no |
| `database_name` | Initial database name | `string` | `"forge"` | no |
| `master_username` | Master username | `string` | `"forgeadmin"` | no |
| `master_password` | Master password (auto-generated if empty) | `string` | `""` | no |
| `port` | Database port | `number` | `5432` | no |
| `vpc_id` | VPC ID | `string` | n/a | yes |
| `subnet_ids` | Subnet IDs (min 2 AZs) | `list(string)` | n/a | yes |
| `security_group_ids` | Security group IDs | `list(string)` | `[]` | no |
| `publicly_accessible` | Make publicly accessible | `bool` | `false` | no |
| `multi_az` | Enable Multi-AZ | `bool` | `true` | no |
| `availability_zone` | Preferred AZ (ignored if multi_az=true) | `string` | `""` | no |
| `backup_retention_period` | Backup retention days (0-35) | `number` | `7` | no |
| `backup_window` | Backup window (UTC) | `string` | `"03:00-04:00"` | no |
| `maintenance_window` | Maintenance window (UTC) | `string` | `"sun:04:00-sun:05:00"` | no |
| `skip_final_snapshot` | Skip final snapshot on deletion | `bool` | `false` | no |
| `final_snapshot_identifier_prefix` | Final snapshot prefix | `string` | `"final-snapshot"` | no |
| `copy_tags_to_snapshot` | Copy tags to snapshots | `bool` | `true` | no |
| `storage_encrypted` | Enable encryption | `bool` | `true` | no |
| `kms_key_id` | KMS key ID (uses default if empty) | `string` | `""` | no |
| `iam_database_authentication_enabled` | Enable IAM auth | `bool` | `true` | no |
| `deletion_protection` | Enable deletion protection | `bool` | `true` | no |
| `enabled_cloudwatch_logs_exports` | CloudWatch log types | `list(string)` | `["postgresql", "upgrade"]` | no |
| `monitoring_interval` | Enhanced monitoring interval (0-60) | `number` | `60` | no |
| `performance_insights_enabled` | Enable Performance Insights | `bool` | `true` | no |
| `performance_insights_retention_period` | PI retention days | `number` | `7` | no |
| `parameter_group_family` | Parameter group family | `string` | `"postgres16"` | no |
| `parameters` | Database parameters | `list(object)` | See [defaults](#default-parameters) | no |
| `tags` | Additional tags | `map(string)` | `{}` | no |

### Default Parameters

```hcl
[
  {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  },
  {
    name  = "log_statement"
    value = "ddl"
  },
  {
    name  = "log_min_duration_statement"
    value = "1000"  # Log queries > 1 second
  }
]
```

## Outputs

| Name | Description |
|------|-------------|
| `db_instance_id` | RDS instance identifier |
| `db_instance_arn` | RDS instance ARN |
| `db_instance_endpoint` | Connection endpoint (address:port) |
| `db_instance_address` | Hostname |
| `db_instance_port` | Port number |
| `db_name` | Database name |
| `master_username` | Master username (sensitive) |
| `master_password_secret_arn` | Secrets Manager ARN |
| `master_password_secret_name` | Secrets Manager name |
| `connection_string` | PostgreSQL connection string (sensitive) |
| `psql_command` | psql connection command |

## Features

### Password Management

Passwords are automatically generated and stored in AWS Secrets Manager:

```bash
# Retrieve password
aws secretsmanager get-secret-value \
  --secret-id forge-production-db-master-password \
  --query SecretString --output text | jq -r .password

# Get full connection info
aws secretsmanager get-secret-value \
  --secret-id forge-production-db-master-password \
  --query SecretString --output text | jq .
```

### Multi-AZ High Availability

Automatic failover to standby instance in different AZ:
- **RTO**: ~1-2 minutes
- **RPO**: 0 (synchronous replication)

### Storage Autoscaling

Automatically scales storage up to `max_allocated_storage`:
```hcl
allocated_storage     = 500  # Initial
max_allocated_storage = 1000 # Auto-scales to 1TB
```

### Performance Insights

Query performance analysis with 7-731 days retention:
```bash
# View top queries in console
https://console.aws.amazon.com/rds/home?region=us-east-1#performance-insights:
```

### Enhanced Monitoring

OS-level metrics with 1-60 second granularity via CloudWatch.

## Best Practices

### Production Configuration

```hcl
instance_class = "db.r8g.xlarge"  # Memory-optimized, Graviton3
multi_az       = true             # High availability
deletion_protection = true        # Prevent accidental deletion
backup_retention_period = 30      # 30 days retention
storage_encrypted = true          # Encryption at rest
iam_database_authentication_enabled = true
performance_insights_enabled = true
```

### Development/Staging Configuration

```hcl
instance_class = "db.t4g.large"   # Cost-optimized, Graviton2
multi_az       = false            # Single AZ
deletion_protection = false       # Allow easy cleanup
backup_retention_period = 7       # 7 days retention
```

## Troubleshooting

### Connection Issues

```bash
# Test connectivity
telnet forge-production-db.abc123.us-east-1.rds.amazonaws.com 5432

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxx

# Connect using psql
psql -h forge-production-db.abc123.us-east-1.rds.amazonaws.com \
     -p 5432 -U forgeadmin -d forge
```

### Performance Issues

```bash
# Check Performance Insights
aws pi get-resource-metrics \
  --service-type RDS \
  --identifier db-ABCDEFGHIJK \
  --metric-queries file://metrics.json

# View slow query log
aws logs tail /aws/rds/instance/forge-production-db/postgresql \
  --follow --filter-pattern "duration"
```

## License

Internal use only - Forge Platform

---

**Module Version**: 1.0.0  
**Terraform Version**: >= 1.5.0  
**AWS Provider Version**: >= 6.9.0
