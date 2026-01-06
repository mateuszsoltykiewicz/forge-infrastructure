# RDS PostgreSQL Module - Production-Grade Database

This module creates a production-ready Amazon RDS PostgreSQL instance with Graviton3 processors, automated backups, Multi-AZ deployment, encryption, and comprehensive monitoring.

## Features

- ✅ **Graviton3 Instances** - ARM64 architecture for 35% better price/performance
- ✅ **PostgreSQL 16.x** - Latest major version with improved performance
- ✅ **Multi-AZ Deployment** - Automatic failover for high availability
- ✅ **Automated Backups** - Daily snapshots with configurable retention
- ✅ **KMS Encryption** - Data encrypted at rest and in transit
- ✅ **Enhanced Monitoring** - 60-second granularity CloudWatch metrics
- ✅ **Performance Insights** - Query-level performance analysis
- ✅ **Parameter Groups** - Optimized PostgreSQL configuration
- ✅ **Security Groups** - Automatic network isolation
- ✅ **CloudWatch Dashboards** - Pre-built monitoring dashboards
- ✅ **Multi-Tenant** - Supports shared, customer-specific, and project-specific databases

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    RDS PostgreSQL Instance                      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Primary Instance (AZ-A)                    │   │
│  │  - PostgreSQL 16.4                                      │   │
│  │  - Graviton3 (db.r8g.xlarge)                           │   │
│  │  - gp3 Storage (100GB-64TB, encrypted)                 │   │
│  │  - Automated Backups (7-35 days)                       │   │
│  └──────────────────┬──────────────────────────────────────┘   │
│                     │                                           │
│                     │ Synchronous Replication                   │
│                     ↓                                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │            Standby Instance (AZ-B) [Multi-AZ]           │   │
│  │  - Automatic Failover (~60-120 seconds)                │   │
│  │  - Same configuration as primary                       │   │
│  │  - Not readable (standby only)                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │               Read Replicas (Optional)                  │   │
│  │  - Asynchronous replication from primary               │   │
│  │  - Read-only workloads                                  │   │
│  │  - Can be in different region                          │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Example - Shared Database

```hcl
module "rds" {
  source = "./database/rds-postgresql"

  workspace   = "production"
  environment = "production"
  aws_region  = "us-west-2"
  
  engine_version = "16.4"
  instance_class = "db.r8g.xlarge"
  
  allocated_storage = 100
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"
  
  common_tags = {
    Project = "MyApp"
  }
}
```

### Customer-Specific Database

```hcl
module "rds_customer" {
  source = "./database/rds-postgresql"

  workspace     = "production"
  environment   = "production"
  customer_name = "acme-corp"
  aws_region    = "us-west-2"
  
  engine_version = "16.4"
  instance_class = "db.r8g.2xlarge"  # Larger for customer
  
  allocated_storage     = 500
  max_allocated_storage = 2000  # Auto-scaling
  
  multi_az = true  # High availability
  
  backup_retention_period = 30  # Extended retention
  
  common_tags = {
    Customer = "Acme Corp"
  }
}
```

### Project-Specific Database

```hcl
module "rds_project" {
  source = "./database/rds-postgresql"

  workspace     = "production"
  environment   = "production"
  customer_name = "acme-corp"
  project_name  = "analytics"
  aws_region    = "us-west-2"
  
  engine_version = "16.4"
  instance_class = "db.r8g.4xlarge"  # High-performance
  
  allocated_storage = 1000
  iops              = 10000  # Provisioned IOPS
  storage_type      = "io2"
  
  common_tags = {
    Customer = "Acme Corp"
    Project  = "Analytics Platform"
  }
}
```

## Graviton3 Instance Sizing Guide

### Available Instance Classes

| Instance Class | vCPUs | RAM | Network | Use Case | Monthly Cost* |
|---------------|-------|-----|---------|----------|---------------|
| `db.t4g.micro` | 2 | 1 GB | Low | Development | ~$12 |
| `db.t4g.small` | 2 | 2 GB | Low | Small apps | ~$25 |
| `db.t4g.medium` | 2 | 4 GB | Moderate | Testing | ~$50 |
| `db.t4g.large` | 2 | 8 GB | Moderate | Staging | ~$100 |
| `db.r8g.large` | 2 | 16 GB | High | Small prod | ~$200 |
| `db.r8g.xlarge` | 4 | 32 GB | High | **Default prod** | ~$400 |
| `db.r8g.2xlarge` | 8 | 64 GB | 10 Gbps | Medium prod | ~$800 |
| `db.r8g.4xlarge` | 16 | 128 GB | 10 Gbps | Large prod | ~$1,600 |
| `db.r8g.8xlarge` | 32 | 256 GB | 12 Gbps | Very large | ~$3,200 |
| `db.r8g.12xlarge` | 48 | 384 GB | 20 Gbps | Enterprise | ~$4,800 |
| `db.r8g.16xlarge` | 64 | 512 GB | 25 Gbps | Maximum | ~$6,400 |

*Approximate costs for us-west-2, Multi-AZ. Actual costs vary by region.

### Sizing Recommendations

**Development:**
```hcl
instance_class        = "db.t4g.medium"
allocated_storage     = 20
multi_az              = false
backup_retention_period = 1
```

**Staging:**
```hcl
instance_class        = "db.r8g.large"
allocated_storage     = 100
multi_az              = true
backup_retention_period = 7
```

**Production (Small - <1000 users):**
```hcl
instance_class        = "db.r8g.xlarge"
allocated_storage     = 100
max_allocated_storage = 500
multi_az              = true
backup_retention_period = 30
```

**Production (Medium - 1000-10000 users):**
```hcl
instance_class        = "db.r8g.2xlarge"
allocated_storage     = 500
max_allocated_storage = 2000
multi_az              = true
backup_retention_period = 30
performance_insights_enabled = true
```

**Production (Large - >10000 users):**
```hcl
instance_class        = "db.r8g.4xlarge"
allocated_storage     = 1000
max_allocated_storage = 5000
storage_type          = "io2"
iops                  = 10000
multi_az              = true
backup_retention_period = 35
performance_insights_enabled = true
```

## Backup and Restore Procedures

### Automated Backups

Backups run automatically during the backup window:

```hcl
backup_window           = "03:00-04:00"  # Daily at 3 AM (UTC)
backup_retention_period = 30             # Keep for 30 days
```

**Features:**
- Point-in-time recovery (PITR) to any second within retention period
- Transaction log backups every 5 minutes
- Stored in S3 (encrypted)
- No performance impact during backup

### Manual Snapshots

```bash
# Create manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier forge-prod-acme-postgres \
  --db-snapshot-identifier forge-prod-acme-manual-20250106

# List snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier forge-prod-acme-postgres

# Copy snapshot to another region
aws rds copy-db-snapshot \
  --source-db-snapshot-identifier arn:aws:rds:us-west-2:... \
  --target-db-snapshot-identifier forge-prod-dr-backup \
  --region us-east-1
```

### Restore from Backup

#### Option 1: Point-in-Time Restore

```bash
# Restore to specific time
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier forge-prod-acme-postgres \
  --target-db-instance-identifier forge-prod-acme-postgres-restored \
  --restore-time 2025-01-06T10:30:00Z
```

#### Option 2: Restore from Snapshot

```bash
# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier forge-prod-acme-postgres-restored \
  --db-snapshot-identifier forge-prod-acme-manual-20250106
```

#### Option 3: Blue/Green Deployment

See "Blue/Green Deployment Strategy" section below.

### Backup Best Practices

1. **Test Restores Monthly** - Verify backups are working
2. **Cross-Region Copies** - For disaster recovery
3. **Manual Snapshots** - Before major changes
4. **Retention Policy** - Balance cost vs compliance needs
5. **Monitor Backup Status** - CloudWatch alarms for failed backups

## Performance Tuning Recommendations

### PostgreSQL Parameters

Custom parameter group included with optimizations:

```hcl
parameters = [
  {
    name  = "shared_buffers"
    value = "{DBInstanceClassMemory/4}"  # 25% of RAM
  },
  {
    name  = "effective_cache_size"
    value = "{DBInstanceClassMemory*3/4}"  # 75% of RAM
  },
  {
    name  = "maintenance_work_mem"
    value = "2097152"  # 2GB for maintenance
  },
  {
    name  = "checkpoint_completion_target"
    value = "0.9"  # Spread checkpoints
  },
  {
    name  = "wal_buffers"
    value = "16384"  # 16MB for WAL
  },
  {
    name  = "default_statistics_target"
    value = "100"  # Better query plans
  },
  {
    name  = "random_page_cost"
    value = "1.1"  # SSD optimization
  },
  {
    name  = "effective_io_concurrency"
    value = "200"  # SSD concurrent I/O
  },
  {
    name  = "work_mem"
    value = "10485"  # 10MB per operation
  },
  {
    name  = "max_connections"
    value = "200"  # Adjust based on app
  }
]
```

### Storage Optimization

**gp3 (General Purpose - Default):**
- Best for most workloads
- 3,000 IOPS baseline (free)
- 125 MiB/s baseline throughput
- Cost-effective

**io2 (Provisioned IOPS):**
```hcl
storage_type = "io2"
iops         = 10000
```
- For high-performance workloads
- Up to 256,000 IOPS
- 4,000 MiB/s throughput
- Higher cost

### Connection Pooling

Use RDS Proxy for connection pooling:

```hcl
# Separate resource (not in this module)
resource "aws_db_proxy" "main" {
  name                   = "forge-prod-postgres-proxy"
  engine_family          = "POSTGRESQL"
  auth {
    secret_arn = aws_secretsmanager_secret.db_password.arn
  }
  role_arn               = aws_iam_role.proxy.arn
  vpc_subnet_ids         = var.private_subnet_ids
  require_tls            = true
}
```

### Query Optimization

Enable Performance Insights:

```hcl
performance_insights_enabled    = true
performance_insights_retention  = 7  # days
```

**Analyze slow queries:**
```sql
-- Enable pg_stat_statements
CREATE EXTENSION pg_stat_statements;

-- Find slow queries
SELECT 
  query,
  calls,
  total_exec_time,
  mean_exec_time,
  max_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

## Parameter Group Customization

### Creating Custom Parameter Group

```hcl
parameters = [
  # Memory settings
  {
    name  = "shared_buffers"
    value = "8388608"  # 8GB
  },
  
  # Connection settings
  {
    name  = "max_connections"
    value = "500"
  },
  
  # Logging
  {
    name  = "log_min_duration_statement"
    value = "1000"  # Log queries >1s
  },
  {
    name  = "log_connections"
    value = "1"
  },
  
  # Performance
  {
    name  = "random_page_cost"
    value = "1.1"  # For SSD
  },
  
  # Replication (if using read replicas)
  {
    name  = "max_wal_senders"
    value = "10"
  }
]
```

### Applying Parameter Changes

- **Static parameters** - Require reboot
- **Dynamic parameters** - Apply immediately

```bash
# Check pending changes
aws rds describe-db-instances \
  --db-instance-identifier forge-prod-postgres \
  --query 'DBInstances[0].PendingModifiedValues'

# Reboot if needed
aws rds reboot-db-instance \
  --db-instance-identifier forge-prod-postgres
```

## Blue/Green Deployment Strategy

For zero-downtime major upgrades:

### Step 1: Create Blue/Green Deployment

```bash
aws rds create-blue-green-deployment \
  --blue-green-deployment-name forge-prod-upgrade \
  --source-arn arn:aws:rds:us-west-2:ACCOUNT:db:forge-prod-postgres \
  --target-engine-version 16.4 \
  --target-db-parameter-group-name postgres16-optimized
```

### Step 2: Test Green Environment

```bash
# Get green endpoint
aws rds describe-blue-green-deployments \
  --blue-green-deployment-identifier bgd-xxx

# Run tests against green environment
psql -h green-endpoint -U postgres -d mydb
```

### Step 3: Switchover

```bash
# Promote green to production
aws rds switchover-blue-green-deployment \
  --blue-green-deployment-identifier bgd-xxx \
  --switchover-timeout 300
```

**Switchover process:**
1. Green becomes new primary (60-120 seconds downtime)
2. Blue becomes standby
3. Old blue can be deleted after verification

## Monitoring and Alerting

### CloudWatch Dashboards

Pre-built dashboard includes:
- CPU utilization
- Database connections
- Read/Write IOPS
- Freeable memory
- Storage usage
- Replication lag

### Recommended CloudWatch Alarms

```hcl
# High CPU
resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "RDS CPU > 80%"
}

# Low freeable memory
resource "aws_cloudwatch_metric_alarm" "memory" {
  alarm_name          = "rds-low-memory"
  comparison_operator = "LessThanThreshold"
  metric_name         = "FreeableMemory"
  threshold           = "1000000000"  # 1GB
}

# High connections
resource "aws_cloudwatch_metric_alarm" "connections" {
  alarm_name          = "rds-high-connections"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "DatabaseConnections"
  threshold           = "180"  # 90% of max_connections=200
}

# Storage space
resource "aws_cloudwatch_metric_alarm" "storage" {
  alarm_name          = "rds-low-storage"
  comparison_operator = "LessThanThreshold"
  metric_name         = "FreeStorageSpace"
  threshold           = "10737418240"  # 10GB
}
```

### Performance Insights Queries

```bash
# Top SQL by execution time
aws pi get-resource-metrics \
  --service-type RDS \
  --identifier db-XXXX \
  --metric-queries 'Id=m1,Metric=db.load.avg' \
  --start-time 2025-01-06T00:00:00Z \
  --end-time 2025-01-06T23:59:59Z
```

## Cost Optimization Tips

1. **Use Graviton3** - 35% better price/performance (default)
2. **Right-size instances** - Monitor CloudWatch metrics
3. **Storage Autoscaling** - Set `max_allocated_storage`
4. **Reserved Instances** - 40% savings for 1-year, 60% for 3-year
5. **Delete old snapshots** - Keep only required retention
6. **Use gp3 storage** - Cheaper than gp2, better performance
7. **Single-AZ for dev/test** - Multi-AZ only for production
8. **Turn off backups for temporary DBs**

### Cost Comparison

| Configuration | Monthly Cost* | Annual Cost* |
|--------------|---------------|--------------|
| db.t4g.medium, 20GB, Single-AZ | $50 | $600 |
| db.r8g.large, 100GB, Multi-AZ | $400 | $4,800 |
| db.r8g.xlarge, 100GB, Multi-AZ | $800 | $9,600 |
| db.r8g.2xlarge, 500GB, Multi-AZ | $1,600 | $19,200 |

*Approximate us-west-2 pricing. Add storage, IOPS, backup costs.

## Security Best Practices

- ✅ **Encryption at rest** - KMS encrypted storage
- ✅ **Encryption in transit** - SSL/TLS required
- ✅ **Network isolation** - Private subnets only
- ✅ **Security groups** - Restrict to application tier
- ✅ **No public access** - `publicly_accessible = false`
- ✅ **IAM authentication** - Option for database users
- ✅ **Secrets Manager** - Auto-rotating passwords
- ✅ **Enhanced monitoring** - 60-second metrics
- ✅ **Deletion protection** - Enabled for production
- ✅ **Audit logging** - CloudWatch Logs integration

## Troubleshooting

### Connection Issues

```bash
# Test connectivity
psql -h <endpoint> -U postgres -d postgres

# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>

# Verify network ACLs
aws ec2 describe-network-acls --network-acl-ids <acl-id>
```

### Performance Issues

```sql
-- Check long-running queries
SELECT pid, age(clock_timestamp(), query_start), usename, query 
FROM pg_stat_activity 
WHERE query != '<IDLE>' AND query NOT ILIKE '%pg_stat_activity%'
ORDER BY query_start DESC;

-- Kill long query
SELECT pg_terminate_backend(pid);

-- Check table bloat
SELECT schemaname, tablename, 
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;

-- Vacuum and analyze
VACUUM ANALYZE;
```

### Storage Full

```bash
# Increase storage (no downtime for gp3/io2)
aws rds modify-db-instance \
  --db-instance-identifier forge-prod-postgres \
  --allocated-storage 200 \
  --apply-immediately
```

## Connection Examples

### Python (psycopg2)

```python
import psycopg2

conn = psycopg2.connect(
    host=module.rds.endpoint,
    port=5432,
    database="mydb",
    user="postgres",
    password="<from-secrets-manager>",
    sslmode="require"
)
```

### Node.js (pg)

```javascript
const { Client } = require('pg');

const client = new Client({
  host: process.env.DB_HOST,
  port: 5432,
  database: 'mydb',
  user: 'postgres',
  password: process.env.DB_PASSWORD,
  ssl: { rejectUnauthorized: false }
});
```

### Go (pgx)

```go
import "github.com/jackc/pgx/v5"

conn, err := pgx.Connect(context.Background(), 
  "postgres://postgres:password@endpoint:5432/mydb?sslmode=require")
```

## Variables

See `variables.tf` for complete list.

## Outputs

| Name | Description |
|------|-------------|
| `db_instance_id` | Database instance identifier |
| `endpoint` | Connection endpoint |
| `port` | Database port |
| `master_username` | Master username |
| `database_name` | Database name |

See `outputs.tf` for complete list.

## References

- [RDS PostgreSQL Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)
- [AWS Graviton Technical Guide](https://github.com/aws/aws-graviton-getting-started)
- [RDS Blue/Green Deployments](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/blue-green-deployments.html)

## License

See parent directory LICENSE file.
