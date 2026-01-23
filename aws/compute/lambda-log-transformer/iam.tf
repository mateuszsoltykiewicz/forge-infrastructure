# ==============================================================================
# IAM Role and Policies for Lambda Execution
# ==============================================================================

# ------------------------------------------------------------------------------
# Lambda Execution Role
# ------------------------------------------------------------------------------

resource "aws_iam_role" "lambda_execution" {
  name               = "${local.function_name}-execution-role"
  description        = "Execution role for ${local.function_name}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(
    var.common_tags,
    {
      Name        = "${local.function_name}-execution-role"
      Component   = "Lambda IAM Role"
      Environment = var.environment
    }
  )
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# ------------------------------------------------------------------------------
# AWS Managed Policy: AWSLambdaBasicExecutionRole
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ------------------------------------------------------------------------------
# Custom Inline Policy: CloudWatch Logs (if KMS encrypted)
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy" "cloudwatch_logs" {
  count = var.cloudwatch_kms_key_arn != null ? 1 : 0

  name   = "${local.function_name}-cloudwatch-logs"
  role   = aws_iam_role.lambda_execution.name
  policy = data.aws_iam_policy_document.cloudwatch_logs[0].json
}

data "aws_iam_policy_document" "cloudwatch_logs" {
  count = var.cloudwatch_kms_key_arn != null ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.function_name}",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.function_name}:*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    resources = [var.cloudwatch_kms_key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}
