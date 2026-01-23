# Kinesis Firehose Module

Universal log delivery streams for centralized AWS and Kubernetes log collection. Transforms logs via Lambda and delivers to S3 with HIPAA-compliant lifecycle.

## Features

- **6 Delivery Streams**: WAF, VPC Flow Logs, RDS, EKS Events, EKS Pod Logs, CloudWatch Metrics
- **Lambda Transformation**: Pattern A metadata enrichment (customer, project, environment)
- **Auto-Detection**: Stream names match Lambda source detection regex
- **S3 Partitioning**: Hive-style partitioning (year/month/day/hour) for Athena
- **Error Handling**: ProcessingFailed records → separate S3 prefix
- **Parquet Support**: Optional for metrics (10x faster Athena, 5x compression)
- **CloudWatch Monitoring**: Delivery logs per stream (30-day retention)
- **GZIP Compression**: Reduces storage costs by 70%

## Usage

```hcl
module "kinesis_firehose" {
  source = "../../data-streams/kinesis-firehose"

  # Pattern A variables
  common_prefix = "forge"
  common_tags = {
    customer    = "acme"
    project     = "forge"
    environment = "production"
    managed_by  = "terraform"
  }
  environment = "production"

  # Lambda transformer
  lambda_function_arn = module.lambda_log_transformer.invoke_arn

  # S3 destination
  s3_bucket_arn  = module.s3_logs.bucket_arn
  s3_kms_key_arn = module.s3_logs.kms_key_arn

  # Buffering (5MB or 300s, whichever comes first)
  buffering_size_mb          = 5
  buffering_interval_seconds = 300

  # CloudWatch Logs
  firehose_log_retention_days = 30

  # Feature flags
  enable_metrics_parquet       = true
  enable_source_record_backup  = false # Set true for debugging
  glue_database_name          = "forge_logs" # For Parquet schema
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| common_prefix | Common prefix (Pattern A) | `string` | - | yes |
| common_tags | Common tags (customer, project, environment, managed_by) | `map(string)` | - | yes |
| environment | Environment (dev, staging, production) | `string` | - | yes |
| lambda_function_arn | Lambda ARN for transformation | `string` | - | yes |
| s3_bucket_arn | S3 bucket ARN for logs | `string` | - | yes |
| s3_kms_key_arn | KMS key ARN for S3 encryption | `string` | - | yes |
| buffering_size_mb | Buffer size (1-128 MB) | `number` | `5` | no |
| buffering_interval_seconds | Buffer interval (60-900 s) | `number` | `300` | no |
| firehose_log_retention_days | CloudWatch Logs retention | `number` | `30` | no |
| enable_metrics_parquet | Enable Parquet for metrics | `bool` | `true` | no |
| enable_source_record_backup | Backup source records (debugging) | `bool` | `false` | no |
| glue_database_name | Glue database for Parquet schema | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| all_stream_arns | Map of all Firehose delivery stream ARNs |
| all_stream_names | Map of all Firehose delivery stream names |
| waf_stream_arn | WAF logs stream ARN |
| vpc_stream_arn | VPC Flow Logs stream ARN |
| rds_stream_arn | RDS logs stream ARN |
| eks_events_stream_arn | EKS Events stream ARN |
| eks_pods_stream_arn | EKS Pod Logs stream ARN |
| metrics_stream_arn | CloudWatch Metrics stream ARN |
| firehose_role_arn | Firehose IAM role ARN |

## Stream Names and S3 Prefixes

| Stream Name | Source Detection | S3 Prefix | Error Prefix |
|-------------|------------------|-----------|--------------|
| `{prefix}-waf-firehose-stream-{env}` | `waf` | `logs/cloudwatch/waf/year=.../` | `processing-failed/waf/` |
| `{prefix}-vpc-firehose-stream-{env}` | `vpc` | `logs/cloudwatch/vpc/year=.../` | `processing-failed/vpc/` |
| `{prefix}-rds-firehose-stream-{env}` | `rds` | `logs/cloudwatch/rds/year=.../` | `processing-failed/rds/` |
| `{prefix}-eks-events-firehose-stream-{env}` | `eks-events` | `logs/kubernetes/events/year=.../` | `processing-failed/eks-events/` |
| `{prefix}-eks-pods-firehose-stream-{env}` | `eks-pods` | `logs/kubernetes/pods/year=.../` | `processing-failed/eks-pods/` |
| `{prefix}-metrics-firehose-stream-{env}` | `metrics` | `metrics/cloudwatch/year=.../` | `processing-failed/metrics/` |

## S3 Object Naming

```
s3://bucket/logs/cloudwatch/waf/year=2026/month=01/day=17/hour=10/forge-waf-firehose-stream-production-1-2026-01-17-10-30-15-abc123.gz
```

Hive-style partitioning enables efficient Athena queries:
```sql
SELECT * FROM waf_logs 
WHERE year = '2026' AND month = '01' AND day = '17'
```

## IAM Permissions

Firehose service role includes:

- **S3**: PutObject, GetObject, ListBucket, AbortMultipartUpload
- **KMS**: Decrypt, GenerateDataKey (for S3 encryption)
- **Lambda**: InvokeFunction, GetFunctionConfiguration
- **CloudWatch Logs**: CreateLogGroup, CreateLogStream, PutLogEvents
- **Glue** (if Parquet enabled): GetTable, GetTableVersions, GetDatabase

## Integration with CloudWatch Logs

Create subscription filters to send CloudWatch Logs to Firehose:

```hcl
resource "aws_cloudwatch_log_subscription_filter" "waf_to_firehose" {
  name            = "waf-logs-to-firehose"
  log_group_name  = "/aws/wafv2/webacl"
  filter_pattern  = "" # Send all logs
  destination_arn = module.kinesis_firehose.waf_stream_arn
  role_arn        = aws_iam_role.cloudwatch_to_firehose.arn
}
```

## Integration with Kubernetes (Fluent Bit)

Configure Fluent Bit to send pod logs and events to Firehose:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-config
data:
  outputs.conf: |
    [OUTPUT]
        Name kinesis_firehose
        Match kube.*
        region us-east-1
        delivery_stream forge-eks-pods-firehose-stream-production
        
    [OUTPUT]
        Name kinesis_firehose
        Match events.*
        region us-east-1
        delivery_stream forge-eks-events-firehose-stream-production
```

## Monitoring

**CloudWatch Metrics** (per stream):
- `DeliveryToS3.Success` - Successful S3 deliveries
- `DeliveryToS3.DataFreshness` - Age of oldest record in buffer
- `IncomingRecords` - Records received from source
- `IncomingBytes` - Bytes received from source
- `ExecuteProcessing.Success` - Lambda transformation success
- `ExecuteProcessing.Duration` - Lambda transformation latency

**Alarms to Create**:
1. High Lambda duration (>5s) → Increase memory or optimize code
2. High ProcessingFailed rate (>1%) → Check Lambda logs
3. High DataFreshness (>900s) → Increase buffering_interval or buffering_size
4. DeliveryToS3 errors → Check S3/KMS permissions

## Cost Optimization

**Buffering Settings**:
- Larger buffer = fewer S3 PutObject calls = lower cost
- Smaller buffer = lower latency (fresher data)
- **Recommendation**: 5MB / 300s for ~$10/month @ 10GB/day

**Compression**:
- GZIP: 70% reduction (logs)
- SNAPPY + Parquet: 80% reduction (metrics)

**Parquet Benefits** (metrics only):
- 10x faster Athena queries
- 5x better compression vs JSON+GZIP
- Columnar storage ideal for high-cardinality dimensions

## Troubleshooting

**High ProcessingFailed rate**:
- Check `/aws/lambda/{function_name}` logs
- Common: timeout, invalid JSON, oversized record (>6MB)
- Failed records → `processing-failed/` prefix with original data

**S3 delivery errors**:
- Verify S3 bucket exists and Firehose role has PutObject
- Check KMS key policy allows Firehose role
- Review `/aws/kinesisfirehose/{stream_name}` logs

**Parquet conversion errors**:
- Ensure Glue database/table exists
- Check schema matches Lambda output
- Lambda must output JSON compatible with Glue schema

**High latency**:
- Reduce buffering_interval (min 60s)
- Reduce buffering_size (min 1MB)
- Trade-off: more frequent S3 writes = higher cost

## Dependencies

- Lambda Log Transformer function (compute/lambda-log-transformer)
- S3 bucket with HIPAA lifecycle rules (storage/s3)
- KMS key for S3 encryption (security/kms)
- (Optional) AWS Glue database for Parquet schema

## License

Proprietary - Forge Platform
