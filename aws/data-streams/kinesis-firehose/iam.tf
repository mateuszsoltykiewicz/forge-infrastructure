# ==============================================================================
# IAM Resources for Kinesis Firehose
# ==============================================================================

# ------------------------------------------------------------------------------
# IAM Role for Firehose Service
# ------------------------------------------------------------------------------

resource "aws_iam_role" "firehose" {
  name               = local.firehose_role_name
  description        = "Service role for Kinesis Firehose delivery streams"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json

  tags = merge(
    var.common_tags,
    {
      Name        = local.firehose_role_name
      Component   = "Kinesis Firehose IAM Role"
      Environment = var.environment
    }
  )
}

data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# ------------------------------------------------------------------------------
# IAM Policy: S3 Write Access
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy" "firehose_s3" {
  name   = "${local.firehose_role_name}-s3-access"
  role   = aws_iam_role.firehose.name
  policy = data.aws_iam_policy_document.firehose_s3.json
}

data "aws_iam_policy_document" "firehose_s3" {
  statement {
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]

    resources = [
      var.s3_bucket_arn,
      "${var.s3_bucket_arn}/*"
    ]
  }

  # KMS access for S3 encryption
  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    resources = [var.s3_kms_key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}

# ------------------------------------------------------------------------------
# IAM Policy: Lambda Invoke Access
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy" "firehose_lambda" {
  name   = "${local.firehose_role_name}-lambda-invoke"
  role   = aws_iam_role.firehose.name
  policy = data.aws_iam_policy_document.firehose_lambda.json
}

data "aws_iam_policy_document" "firehose_lambda" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
      "lambda:GetFunctionConfiguration"
    ]

    resources = [
      var.lambda_function_arn,
      "${var.lambda_function_arn}:*" # Include versions/aliases
    ]
  }
}

# ------------------------------------------------------------------------------
# IAM Policy: CloudWatch Logs Access
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy" "firehose_logs" {
  name   = "${local.firehose_role_name}-cloudwatch-logs"
  role   = aws_iam_role.firehose.name
  policy = data.aws_iam_policy_document.firehose_logs.json
}

data "aws_iam_policy_document" "firehose_logs" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/kinesisfirehose/${var.common_prefix}-*"
    ]
  }
}

# ------------------------------------------------------------------------------
# IAM Policy: Kinesis Data Stream Read Access (for cloudwatch-generic stream)
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy" "firehose_kinesis" {
  name   = "${local.firehose_role_name}-kinesis-read"
  role   = aws_iam_role.firehose.name
  policy = data.aws_iam_policy_document.firehose_kinesis.json
}

data "aws_iam_policy_document" "firehose_kinesis" {
  statement {
    effect = "Allow"

    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards"
    ]

    resources = var.kinesis_cloudwatch_stream_arn != null ? [
      var.kinesis_cloudwatch_stream_arn
    ] : []
  }
}
