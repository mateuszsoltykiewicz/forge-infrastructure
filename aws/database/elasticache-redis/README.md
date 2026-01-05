# ElastiCache Redis Terraform Module

This module creates an AWS ElastiCache Redis cluster with Multi-AZ replication, encryption, and SSM Parameter Store integration for connection management.

## Features

- **Multi-AZ High Availability**: Automatic failover across 2-6 availability zones
- **Security**: 
  - Encryption at rest using AWS KMS
  - Encryption in transit (TLS)
  - Redis AUTH token authentication
- **Backup & Recovery**: Automated snapshots with configurable retention (0-35 days)
- **Parameter Groups**: Custom Redis configuration with apply methods (immediate vs pending-reboot)
- **SSM Integration**: Automatic storage of connection details in AWS Systems Manager Parameter Store
- **CloudWatch Logs**: Optional log delivery for slow-log and engine-log
- **Customer-Aware**: Supports shared and dedicated customer architectures

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ElastiCache Redis Cluster                 │
│  ┌────────────────┐              ┌────────────────┐         │
│  │   Primary      │─────────────▶│    Replica     │         │
│  │   AZ: us-e-1a  │  Replication │   AZ: us-e-1b  │         │
│  └────────────────┘              └────────────────┘         │
│         │                                 │                  │
│         └─────────────┬───────────────────┘                  │
│                       │                                      │
│              ┌────────▼────────┐                             │
│              │ Subnet Group    │                             │
│              │ (Private subnets)│                            │
│              └─────────────────┘                             │
└─────────────────────────────────────────────────────────────┘
                        │
                        │ TLS + AUTH token
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              SSM Parameter Store                             │
│  /production/cache/forge-production-redis/                   │
│  ├── primary-endpoint   (String)                             │
│  ├── reader-endpoint    (String)                             │
│  ├── port               (String)                             │
│  └── auth-token         (SecureString - KMS encrypted)       │
└─────────────────────────────────────────────────────────────┘
```

## Usage Examples

### Example 1: Shared Multi-Tenant Redis Cluster (Production)

```hcl
module "shared_redis" {
  source = "../../modules/cache/elasticache-redis"

  # Customer Context (Shared Architecture)
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # ElastiCache Configuration
  engine_version     = "7.1"
  node_type          = "cache.r7g.large"
  num_cache_clusters = 3  # Primary + 2 replicas

  # Network Configuration
  vpc_id             = "vpc-0123456789abcdef0"
  subnet_ids         = [
    "subnet-0123456789abcdef0",  # us-east-1a
    "subnet-0123456789abcdef1",  # us-east-1b
    "subnet-0123456789abcdef2"   # us-east-1c
  ]
  security_group_ids = ["sg-0123456789abcdef0"]
  preferred_azs      = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # High Availability
  multi_az_enabled            = true
  automatic_failover_enabled  = true

  # Security
  at_rest_encryption_enabled  = true
  transit_encryption_enabled  = true
  auth_token_enabled          = true
  kms_key_id                  = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  # Backups
  snapshot_retention_limit = 7
  snapshot_window          = "03:00-05:00"
  final_snapshot_identifier = "forge-production-redis-final-snapshot"

  # Maintenance
  maintenance_window         = "sun:05:00-sun:07:00"
  auto_minor_version_upgrade = true
  apply_immediately          = false

  # Parameter Group
  create_parameter_group = true
  parameter_group_family = "redis7"
  parameters = [
    {
      name  = "maxmemory-policy"
      value = "allkeys-lru"
    },
    {
      name  = "timeout"
      value = "300"
    }
  ]

  # Monitoring
  notification_topic_arn = "arn:aws:sns:us-east-1:123456789012:forge-production-alerts"
  log_delivery_configuration = [
    {
      destination      = "forge-production-redis-slow-log"
      destination_type = "cloudwatch-logs"
      log_format       = "json"
      log_type         = "slow-log"
    },
    {
      destination      = "forge-production-redis-engine-log"
      destination_type = "cloudwatch-logs"
      log_format       = "json"
      log_type         = "engine-log"
    }
  ]

  tags = {
    Project     = "Forge"
    CostCenter  = "Platform"
    Compliance  = "SOC2"
  }
}
```

### Example 2: Dedicated Customer Redis Cluster (Development)

```hcl
module "customer_redis" {
  source = "../../modules/cache/elasticache-redis"

  # Customer Context (Dedicated Architecture)
  customer_id       = "cust-123e4567-e89b-12d3-a456-426614174000"
  customer_name     = "acme-corp"
  architecture_type = "dedicated"
  plan_tier         = "enterprise"

  # Environment
  environment = "development"
  region      = "us-west-2"

  # ElastiCache Configuration (Smaller for dev)
  engine_version     = "7.1"
  node_type          = "cache.t4g.medium"
  num_cache_clusters = 2  # Primary + 1 replica

  # Network Configuration
  vpc_id             = "vpc-abcdef0123456789"
  subnet_ids         = [
    "subnet-abcdef0123456789",  # us-west-2a
    "subnet-abcdef0123456790"   # us-west-2b
  ]
  security_group_ids = ["sg-abcdef0123456789"]

  # High Availability (Minimal for dev)
  multi_az_enabled            = true
  automatic_failover_enabled  = true

  # Security
  at_rest_encryption_enabled  = true
  transit_encryption_enabled  = true
  auth_token_enabled          = true

  # Backups (None for dev environment)
  snapshot_retention_limit = 0

  # Maintenance
  auto_minor_version_upgrade = true
  apply_immediately          = true  # Dev can handle immediate changes

  tags = {
    Project     = "AcmeCorp"
    Environment = "Development"
  }
}
```

### Example 3: High-Performance Redis Cluster

```hcl
module "high_performance_redis" {
  source = "../../modules/cache/elasticache-redis"

  # Customer Context
  customer_id       = "00000000-0000-0000-0000-000000000000"
  customer_name     = "forge"
  architecture_type = "shared"
  plan_tier         = "platform"

  # Environment
  environment = "production"
  region      = "us-east-1"

  # High-Performance Configuration
  engine_version     = "7.1"
  node_type          = "cache.r7g.xlarge"  # 26.32 GiB memory
  num_cache_clusters = 6                    # Maximum replicas

  # Network Configuration
  vpc_id             = "vpc-0123456789abcdef0"
  subnet_ids         = [
    "subnet-0123456789abcdef0",  # us-east-1a
    "subnet-0123456789abcdef1",  # us-east-1b
    "subnet-0123456789abcdef2",  # us-east-1c
    "subnet-0123456789abcdef3",  # us-east-1d
    "subnet-0123456789abcdef4",  # us-east-1e
    "subnet-0123456789abcdef5"   # us-east-1f
  ]
  security_group_ids = ["sg-0123456789abcdef0"]
  preferred_azs      = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]

  # High Availability
  multi_az_enabled            = true
  automatic_failover_enabled  = true

  # Security
  at_rest_encryption_enabled  = true
  transit_encryption_enabled  = true
  auth_token_enabled          = true
  kms_key_id                  = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  # Backups
  snapshot_retention_limit = 14  # 2 weeks
  snapshot_window          = "03:00-05:00"

  # Custom Parameters for High Performance
  create_parameter_group = true
  parameter_group_family = "redis7"
  parameters = [
    {
      name  = "maxmemory-policy"
      value = "allkeys-lru"
    },
    {
      name  = "timeout"
      value = "600"
    },
    {
      name  = "tcp-keepalive"
      value = "300"
    },
    {
      name  = "lazyfree-lazy-eviction"
      value = "yes"
    }
  ]

  tags = {
    Performance = "High"
    SLA         = "99.99"
  }
}
```

## SSM Parameter Store Integration

The module automatically creates SSM parameters for secure connection management:

### Parameter Structure

```
/production/cache/forge-production-redis/
├── primary-endpoint   (String)         - Write endpoint address
├── reader-endpoint    (String)         - Read endpoint address (Multi-AZ only)
├── port               (String)         - Redis port (default: 6379)
└── auth-token         (SecureString)   - Redis AUTH password (KMS encrypted)
```

### Application Integration Example (Python)

```python
import boto3
import redis

# Initialize AWS clients
ssm = boto3.client('ssm', region_name='us-east-1')

# Retrieve connection details from SSM
def get_ssm_parameter(name, with_decryption=False):
    response = ssm.get_parameter(
        Name=name,
        WithDecryption=with_decryption
    )
    return response['Parameter']['Value']

# Connection parameters
primary_endpoint = get_ssm_parameter('/production/cache/forge-production-redis/primary-endpoint')
port = int(get_ssm_parameter('/production/cache/forge-production-redis/port'))
auth_token = get_ssm_parameter('/production/cache/forge-production-redis/auth-token', with_decryption=True)

# Connect to Redis
redis_client = redis.Redis(
    host=primary_endpoint,
    port=port,
    password=auth_token,
    ssl=True,
    ssl_cert_reqs='required',
    decode_responses=True
)

# Test connection
redis_client.ping()
print("Connected to Redis successfully!")
```

### Application Integration Example (Node.js)

```javascript
const AWS = require('aws-sdk');
const redis = require('redis');

const ssm = new AWS.SSM({ region: 'us-east-1' });

async function getSSMParameter(name, withDecryption = false) {
  const params = {
    Name: name,
    WithDecryption: withDecryption
  };
  const data = await ssm.getParameter(params).promise();
  return data.Parameter.Value;
}

async function connectToRedis() {
  // Retrieve connection details
  const primaryEndpoint = await getSSMParameter('/production/cache/forge-production-redis/primary-endpoint');
  const port = parseInt(await getSSMParameter('/production/cache/forge-production-redis/port'));
  const authToken = await getSSMParameter('/production/cache/forge-production-redis/auth-token', true);

  // Create Redis client
  const client = redis.createClient({
    host: primaryEndpoint,
    port: port,
    password: authToken,
    tls: {
      rejectUnauthorized: true
    }
  });

  client.on('connect', () => {
    console.log('Connected to Redis successfully!');
  });

  return client;
}

connectToRedis();
```

## Multi-AZ High Availability

When `multi_az_enabled = true` and `automatic_failover_enabled = true`:

1. **Primary Node**: Handles all write operations
2. **Replica Nodes**: Synchronous replication from primary (configurable 1-5 replicas)
3. **Automatic Failover**: If primary fails, a replica is promoted automatically (typically < 60 seconds)
4. **Read Scaling**: Use reader endpoint to distribute read traffic across replicas

### Failover Behavior

```
┌───────────────────────────────────────────────────────────────┐
│  Normal Operations                                             │
│  ┌────────────┐     Replication     ┌────────────┐            │
│  │  Primary   │────────────────────▶│  Replica   │            │
│  │  (Writes)  │                     │  (Reads)   │            │
│  └────────────┘                     └────────────┘            │
└───────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────┐
│  Primary Failure Detected                                      │
│  ┌────────────┐                     ┌────────────┐            │
│  │  Primary   │                     │  Replica   │            │
│  │   (DOWN)   │         Promote     │  (Standby) │            │
│  └────────────┘       ◀─────────    └────────────┘            │
│                                                                │
│  Duration: ~30-60 seconds                                      │
└───────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────┐
│  After Failover                                                │
│  ┌────────────┐                     ┌────────────┐            │
│  │ New Primary│                     │ New Replica│            │
│  │  (Writes)  │────────────────────▶│  (Reads)   │            │
│  └────────────┘                     └────────────┘            │
│                                                                │
│  Old primary rejoins as replica when healthy                  │
└───────────────────────────────────────────────────────────────┘
```

## Security

### Encryption at Rest

- **KMS Integration**: All data encrypted using AWS KMS (customer-managed or AWS-managed keys)
- **Snapshot Encryption**: Backups are automatically encrypted with the same KMS key

### Encryption in Transit

- **TLS 1.2+**: All client connections require TLS
- **Redis CLI**: Use `--tls` flag when connecting

```bash
redis-cli -h forge-production-redis.abc123.0001.use1.cache.amazonaws.com \
  -p 6379 \
  --tls \
  -a $(aws ssm get-parameter --name /production/cache/forge-production-redis/auth-token --with-decryption --query Parameter.Value --output text)
```

### Authentication

- **Redis AUTH**: Randomly generated 32-character token
- **SSM SecureString**: Token stored encrypted in SSM Parameter Store
- **Rotation**: Auth token can be rotated by changing lifecycle ignore_changes

## Backup & Recovery

### Automated Snapshots

- **Retention**: 0-35 days (0 = disabled)
- **Window**: Configurable snapshot window (e.g., "03:00-05:00")
- **Final Snapshot**: Optional snapshot created before deletion

### Manual Recovery

```bash
# List available snapshots
aws elasticache describe-snapshots \
  --replication-group-id forge-production-redis

# Restore from snapshot (requires new replication group)
aws elasticache create-replication-group \
  --replication-group-id forge-production-redis-restored \
  --replication-group-description "Restored from snapshot" \
  --snapshot-name forge-production-redis-snapshot-2024-01-15 \
  --cache-subnet-group-name forge-production-redis-subnet-group
```

## Monitoring

### CloudWatch Metrics (Automatic)

Key metrics to monitor:

- `CPUUtilization`: Should stay < 90%
- `DatabaseMemoryUsagePercentage`: Should stay < 90%
- `NetworkBytesIn/Out`: Monitor for traffic patterns
- `Evictions`: Should be 0 (if not, increase memory)
- `CurrConnections`: Monitor connection pool usage
- `ReplicationLag`: Should be < 1 second

### CloudWatch Logs (Optional)

Enable log delivery for troubleshooting:

```hcl
log_delivery_configuration = [
  {
    destination      = "forge-production-redis-slow-log"
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }
]
```

### SNS Notifications

Configure SNS topic for critical events:

- Primary failover events
- Node replacement events
- Snapshot completion/failures

## Performance Tuning

### Parameter Recommendations

#### General Purpose (Balanced)
```hcl
parameters = [
  { name = "maxmemory-policy", value = "allkeys-lru" },
  { name = "timeout", value = "300" },
  { name = "tcp-keepalive", value = "300" }
]
```

#### Cache-Heavy (High Read Volume)
```hcl
parameters = [
  { name = "maxmemory-policy", value = "allkeys-lru" },
  { name = "timeout", value = "0" },
  { name = "lazyfree-lazy-eviction", value = "yes" },
  { name = "lazyfree-lazy-expire", value = "yes" }
]
```

#### Session Store
```hcl
parameters = [
  { name = "maxmemory-policy", value = "volatile-lru" },
  { name = "timeout", value = "600" },
  { name = "notify-keyspace-events", value = "Ex" }
]
```

### Node Type Selection

| Node Type | vCPUs | Memory | Network | Use Case |
|-----------|-------|--------|---------|----------|
| cache.t4g.medium | 2 | 3.09 GiB | Up to 5 Gbps | Development/Testing |
| cache.r7g.large | 2 | 13.07 GiB | Up to 12.5 Gbps | Small production |
| cache.r7g.xlarge | 4 | 26.32 GiB | Up to 12.5 Gbps | Medium production |
| cache.r7g.2xlarge | 8 | 52.88 GiB | Up to 15 Gbps | Large production |
| cache.r7g.4xlarge | 16 | 106.07 GiB | Up to 15 Gbps | High-performance |

## Troubleshooting

### Connection Timeouts

**Symptom**: Applications can't connect to Redis

**Solutions**:
1. Check security group rules allow inbound on port 6379
2. Verify subnet routing allows access from application subnets
3. Confirm TLS is enabled in client connection
4. Verify auth token from SSM is correct

```bash
# Test connectivity from EC2/EKS
nc -zv <primary-endpoint> 6379

# Test with redis-cli
redis-cli -h <primary-endpoint> -p 6379 --tls PING
```

### High Memory Usage

**Symptom**: DatabaseMemoryUsagePercentage > 90%

**Solutions**:
1. Scale up to larger node type (cache.r7g.xlarge → cache.r7g.2xlarge)
2. Review maxmemory-policy (consider allkeys-lru for eviction)
3. Add more replicas for read scaling
4. Implement application-level caching strategies

### Slow Performance

**Symptom**: Increased latency, slow queries

**Solutions**:
1. Enable slow-log in CloudWatch Logs
2. Review CPU utilization (should be < 90%)
3. Check for network saturation
4. Consider larger node type or more replicas
5. Review application query patterns

### Failover Issues

**Symptom**: Cluster not failing over automatically

**Solutions**:
1. Verify `automatic_failover_enabled = true`
2. Ensure `multi_az_enabled = true`
3. Confirm `num_cache_clusters >= 2`
4. Check CloudWatch Events for failover notifications

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| customer_id | UUID of the customer (00000000-0000-0000-0000-000000000000 for shared) | string | n/a | yes |
| customer_name | Name of the customer (used in resource naming) | string | n/a | yes |
| architecture_type | Architecture type: shared, dedicated_single_tenant, dedicated_vpc | string | n/a | yes |
| plan_tier | Customer plan tier: basic, pro, enterprise, platform | string | n/a | yes |
| environment | Environment name (e.g., production, development) | string | n/a | yes |
| region | AWS region for resource deployment | string | n/a | yes |
| engine_version | Redis engine version (e.g., 7.1) | string | "7.1" | no |
| node_type | ElastiCache node type (e.g., cache.r7g.large) | string | "cache.r7g.large" | no |
| num_cache_clusters | Number of cache clusters (primary + replicas), 2-6 for Multi-AZ | number | 2 | no |
| port | Redis port number | number | 6379 | no |
| vpc_id | VPC ID where ElastiCache will be deployed | string | n/a | yes |
| subnet_ids | List of subnet IDs for ElastiCache (must span 2+ AZs) | list(string) | n/a | yes |
| security_group_ids | List of security group IDs to attach | list(string) | n/a | yes |
| preferred_azs | List of preferred availability zones | list(string) | [] | no |
| multi_az_enabled | Enable Multi-AZ deployment | bool | true | no |
| automatic_failover_enabled | Enable automatic failover (requires Multi-AZ) | bool | true | no |
| at_rest_encryption_enabled | Enable encryption at rest | bool | true | no |
| transit_encryption_enabled | Enable encryption in transit (TLS) | bool | true | no |
| auth_token_enabled | Enable Redis AUTH token authentication | bool | true | no |
| kms_key_id | KMS key ID for encryption (optional, uses AWS-managed if not provided) | string | null | no |
| snapshot_retention_limit | Number of days to retain snapshots (0-35, 0 = disabled) | number | 7 | no |
| snapshot_window | Daily time range for snapshots (HH:MM-HH:MM) | string | "03:00-05:00" | no |
| final_snapshot_identifier | Name of final snapshot before deletion (optional) | string | null | no |
| maintenance_window | Weekly time range for maintenance (ddd:hh24:mi-ddd:hh24:mi) | string | "sun:05:00-sun:07:00" | no |
| auto_minor_version_upgrade | Enable automatic minor version upgrades | bool | true | no |
| apply_immediately | Apply changes immediately vs next maintenance window | bool | false | no |
| create_parameter_group | Create custom parameter group | bool | false | no |
| parameter_group_family | Redis parameter group family (e.g., redis7) | string | "redis7" | no |
| parameter_group_description | Description for custom parameter group | string | "Custom parameter group for ElastiCache Redis" | no |
| parameters | List of Redis parameters to configure | list(object) | [] | no |
| notification_topic_arn | SNS topic ARN for ElastiCache notifications | string | null | no |
| log_delivery_configuration | CloudWatch Logs delivery configuration | list(object) | [] | no |
| tags | Additional tags for resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| replication_group_id | The ID of the ElastiCache replication group |
| replication_group_arn | The ARN of the ElastiCache replication group |
| replication_group_primary_endpoint_address | The address of the primary endpoint |
| replication_group_reader_endpoint_address | The address of the reader endpoint (Multi-AZ only) |
| replication_group_member_clusters | The member clusters of the replication group |
| port | The Redis port |
| engine_version | The running version of the Redis engine |
| subnet_group_name | The name of the cache subnet group |
| security_group_ids | The security group IDs attached to the cluster |
| ssm_parameter_primary_endpoint | SSM parameter name for Redis primary endpoint |
| ssm_parameter_reader_endpoint | SSM parameter name for Redis reader endpoint |
| ssm_parameter_port | SSM parameter name for Redis port |
| ssm_parameter_auth_token | SSM parameter name for Redis AUTH token |
| parameter_group_id | The name of the parameter group |
| parameter_group_arn | The ARN of the parameter group |
| redis_cli_command | Command to connect using redis-cli |

## Migration from Cluster-Based Source

This module simplifies the cloud-platform-features ElastiCache module:

| Feature | Source Module | Forge Module |
|---------|---------------|--------------|
| Cluster Mode | ✅ Supported | ❌ Removed (P1) |
| Global Replication | ✅ Supported | ❌ Removed (P1) |
| User Groups (RBAC) | ✅ Supported | ❌ Removed (P1) |
| Standard Replication | ✅ Supported | ✅ Supported |
| Multi-AZ | ✅ Supported | ✅ Supported |
| Encryption | ✅ Supported | ✅ Supported |
| Auth Token | ✅ Supported | ✅ Supported |
| SSM Integration | ✅ Supported | ✅ Supported |

**Rationale**: Forge MVP focuses on standard replication groups with Multi-AZ. Cluster mode and global replication add complexity and are deferred to P1.

## Cost Optimization

### Development Environments

```hcl
node_type                  = "cache.t4g.medium"
num_cache_clusters         = 2
snapshot_retention_limit   = 0
```

### Production Environments

```hcl
node_type                  = "cache.r7g.large"
num_cache_clusters         = 3  # 1 primary + 2 replicas
snapshot_retention_limit   = 7
```

### High Availability Production

```hcl
node_type                  = "cache.r7g.xlarge"
num_cache_clusters         = 6  # Maximum replicas
snapshot_retention_limit   = 14
```

## References

- [AWS ElastiCache for Redis Documentation](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/)
- [Redis Documentation](https://redis.io/documentation)
- [Terraform AWS ElastiCache Resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_replication_group)
- [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)

## License

This module is proprietary to Moai Engineering Forge platform.
