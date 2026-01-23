# Lambda Log Transformer Module

Universal AWS Lambda function for Kinesis Firehose log transformation. Supports multiple log sources with automatic detection and Pattern A metadata enrichment.

## Features

- **Multi-Source Support**: WAF, VPC Flow Logs, RDS, EKS Events, EKS Pod Logs, CloudWatch Metrics
- **Auto-Detection**: Extracts source from `deliveryStreamArn` (e.g., `waf-firehose-stream` → `waf`)
- **Pattern A Compliance**: Injects `customer`, `project`, `environment` metadata from common_tags
- **Container Deployment**: Uses AWS Lambda container images (Python 3.13)
- **HIPAA Ready**: 7-year CloudWatch Logs retention, optional KMS encryption
- **Performance Optimized**: 180s timeout, 1024MB memory, unreserved concurrency (default)
- **Parquet Support**: Flattens CloudWatch Metrics for Athena (10x faster queries, 5x compression)

## Usage

```hcl
module "lambda_log_transformer" {
  source = "../../compute/lambda-log-transformer"

  # Pattern A variables
  common_prefix = "forge"
  common_tags = {
    customer    = "acme"
    project     = "forge"
    environment = "production"
    managed_by  = "terraform"
  }
  environment = "production"

  # Lambda configuration
  image_uri   = "123456789012.dkr.ecr.us-east-1.amazonaws.com/lambda-log-transformer:latest"
  timeout     = 180
  memory_size = 1024

  # Optional: Reserved concurrency (null = unreserved)
  reserved_concurrent_executions = null

  # Feature flags
  enable_metrics_parquet = true
  log_level              = "INFO"

  # CloudWatch Logs (HIPAA 7-year retention)
  log_retention_days    = 2557 # 7 years
  cloudwatch_kms_key_arn = module.kms.key_arn # Optional
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| common_prefix | Common prefix for resources (Pattern A) | `string` | - | yes |
| common_tags | Common tags (must include: customer, project, environment, managed_by) | `map(string)` | - | yes |
| environment | Environment name (dev, staging, production) | `string` | - | yes |
| image_uri | ECR image URI with tag | `string` | - | yes |
| timeout | Timeout in seconds (60-180) | `number` | `180` | no |
| memory_size | Memory in MB (128-10240) | `number` | `1024` | no |
| reserved_concurrent_executions | Reserved concurrency (null = unreserved) | `number` | `null` | no |
| enable_metrics_parquet | Enable Parquet for metrics | `bool` | `true` | no |
| log_level | Log level (DEBUG, INFO, WARNING, ERROR) | `string` | `"INFO"` | no |
| log_retention_days | CloudWatch Logs retention (HIPAA = 2557) | `number` | `2557` | no |
| cloudwatch_kms_key_arn | KMS key for CloudWatch Logs (null = AWS managed) | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| function_name | Lambda function name |
| function_arn | Lambda function ARN |
| invoke_arn | Lambda invoke ARN (use in Firehose) |
| role_arn | Execution role ARN |
| log_group_name | CloudWatch Log Group name |

## Supported Sources

| Source | Stream Name Pattern | Output Prefix |
|--------|---------------------|---------------|
| AWS WAF | `waf-firehose-stream` | `logs/cloudwatch/waf/` |
| VPC Flow Logs | `vpc-firehose-stream` | `logs/cloudwatch/vpc/` |
| RDS Logs | `rds-firehose-stream` | `logs/cloudwatch/rds/` |
| EKS Events | `eks-events-firehose-stream` | `logs/kubernetes/events/` |
| EKS Pod Logs | `eks-pods-firehose-stream` | `logs/kubernetes/pods/` |
| CloudWatch Metrics | `metrics-firehose-stream` | `metrics/cloudwatch/` |

## Output Schema

```json
{
  "@timestamp": "2026-01-17T10:30:45Z",
  "aws_component": "waf",
  "environment": "production",
  "customer": "acme",
  "project": "forge",
  "log_level": "INFO",
  "message": "Extracted log message",
  "raw_log": {...},
  "metadata": {
    "record_id": "49640912608...",
    "ingestion_time": "2026-01-17T10:30:45Z",
    "source_log_group": "/aws/waf/webacl"
  }
}
```

## IAM Permissions

The Lambda execution role includes:

- **AWSLambdaBasicExecutionRole** (managed policy)
- **CloudWatch Logs**: CreateLogGroup, CreateLogStream, PutLogEvents
- **KMS** (if encrypted): Decrypt, GenerateDataKey

## Performance

**Expected Load** (~30 Kubernetes pods):
- Pod logs: ~10 logs/s/pod = 300 logs/s
- CloudWatch Logs (WAF/VPC/RDS): ~15 logs/s
- Metrics: ~250 metrics/min = ~4/s
- **Total**: ~320 records/s → **~5 concurrent executions**

**Peak Handling** (5x spike):
- 1600 rec/s → ~25 concurrent executions
- Well below AWS default limit (1000)
- **Recommendation**: Unreserved concurrency sufficient

## Cost Estimate

**Lambda Costs** (320 rec/s, 24/7):
- Requests: 27.6M/month × $0.20/1M = **$5.52**
- Duration: 27.6M × 500ms × 1024MB = 14.1M GB-s × $0.0000166667 = **$235**
- **Total Lambda**: **~$240/month**

**Savings vs. CloudWatch Direct**:
- CloudWatch Logs Insights: $0.005/GB scanned
- 10 GB logs/day × 30 days × $0.005 = **$1.50/day** = **$45/month** (per query)
- Athena after transformation: $5/TB scanned = **$0.05/month** (90% cheaper)

## Dependencies

- AWS Lambda container image in ECR
- Kinesis Firehose delivery streams
- S3 bucket for transformed logs
- (Optional) KMS key for CloudWatch Logs encryption

## Example Firehose Integration

```hcl
resource "aws_kinesis_firehose_delivery_stream" "waf_logs" {
  name        = "waf-firehose-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.logs.arn
    prefix     = "logs/cloudwatch/waf/"
    
    processing_configuration {
      enabled = true
      
      processors {
        type = "Lambda"
        
        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = module.lambda_log_transformer.invoke_arn
        }
      }
    }
  }
}
```

## Troubleshooting

**High Lambda duration (>5s per record)**:
- Check CloudWatch Logs for recursive parsing loops
- Verify log size (max 6MB Firehose record)
- Increase memory (more vCPU) if CPU-bound

**ProcessingFailed records in S3**:
- Check `/aws/lambda/${function_name}` logs for errors
- Common: Invalid JSON, oversized records, timeout
- Failed records preserved in `processing-failed/` prefix

**Cost higher than expected**:
- Verify Parquet enabled for metrics (`enable_metrics_parquet = true`)
- Check actual records/s vs. estimate (CloudWatch Metrics: `Invocations`)
- Consider reserved concurrency if baseline predictable

## License

Proprietary - Forge Platform
