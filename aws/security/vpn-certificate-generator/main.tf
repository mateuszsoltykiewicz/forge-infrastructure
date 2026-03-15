# ==============================================================================
# VPN Certificate Generator Module - Main Resources
# ==============================================================================

# ------------------------------------------------------------------------------
# KMS Key for Certificate Encryption
# ------------------------------------------------------------------------------

resource "aws_kms_key" "vpn_certificates" {
  count = var.kms_key_arn == null ? 1 : 0

  description              = local.kms_key_description
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region             = false

  # Automatic key rotation enabled (best practice)
  enable_key_rotation     = var.enable_kms_key_rotation
  rotation_period_in_days = var.enable_kms_key_rotation ? 90 : null

  deletion_window_in_days = var.kms_deletion_window_in_days
  is_enabled              = true

  # Key policy allowing SSM and root account access
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow SSM to use the key"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = [
              "ssm.${data.aws_region.current.id}.amazonaws.com"
            ]
          }
        }
      }
    ]
  })

  tags = merge(
    local.merged_tags,
    {
      Name = local.kms_key_alias
    }
  )
}

resource "aws_kms_alias" "vpn_certificates" {
  count = var.kms_key_arn == null ? 1 : 0

  name          = "alias/${local.kms_key_alias}"
  target_key_id = aws_kms_key.vpn_certificates[0].key_id
}

# Use either provided KMS key or newly created one
locals {
  kms_key_id = var.kms_key_arn != null ? var.kms_key_arn : aws_kms_key.vpn_certificates[0].arn
}

# ------------------------------------------------------------------------------
# Certificate Generation (Conditional)
# ------------------------------------------------------------------------------

# Generate certificates only if they don't exist in SSM
resource "null_resource" "generate_certificates" {
  count = local.should_generate_certs ? 1 : 0

  # Trigger regeneration if certificate configuration changes
  triggers = {
    common_name   = local.cert_common_name
    org_name      = local.cert_org_name
    validity_days = var.cert_validity_days
    aws_region    = data.aws_region.current.id
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/generate.sh"

    environment = {
      COMMON_NAME       = local.cert_common_name
      ORG_NAME          = local.cert_org_name
      CERT_VALIDITY_DAYS = var.cert_validity_days
      AWS_REGION        = data.aws_region.current.id
      OUTPUT_JSON       = "${path.module}/.terraform/vpn-certs.json"
    }
  }

  # Ensure KMS key exists before generating certificates
  depends_on = [
    aws_kms_key.vpn_certificates,
    aws_kms_alias.vpn_certificates
  ]
}

# Read generated certificate data
data "local_file" "cert_data" {
  count = local.should_generate_certs ? 1 : 0

  filename = "${path.module}/.terraform/vpn-certs.json"

  depends_on = [null_resource.generate_certificates]
}

locals {
  # Parse JSON output from certificate generation script
  cert_output = local.should_generate_certs ? jsondecode(data.local_file.cert_data[0].content) : null

  # Certificate values (from generation or from existing SSM parameters)
  server_arn         = local.should_generate_certs ? local.cert_output.server_arn : try(data.aws_ssm_parameter.existing_server_arn[0].value, null)
  client_ca_arn      = local.should_generate_certs ? local.cert_output.client_ca_arn : null
  server_cert_pem    = local.should_generate_certs ? local.cert_output.server_cert_pem : null
  server_key_pem     = local.should_generate_certs ? local.cert_output.server_key_pem : null
  client_ca_cert_pem = local.should_generate_certs ? local.cert_output.client_ca_cert_pem : null
  client_ca_key_pem  = local.should_generate_certs ? local.cert_output.client_ca_key_pem : null
  expiration_date    = local.should_generate_certs ? local.cert_output.expiration_date : null
}

# ------------------------------------------------------------------------------
# SSM Parameters (Primary Region)
# ------------------------------------------------------------------------------

# Server Certificate ARN
resource "aws_ssm_parameter" "server_arn" {
  count = local.should_generate_certs ? 1 : 0

  name        = local.ssm_paths.server_arn
  description = "ACM ARN for VPN server certificate"
  type        = "SecureString"
  value       = local.server_arn
  key_id      = local.kms_key_id

  tags = merge(
    local.merged_tags,
    {
      Name    = "${local.ssm_paths.server_arn}"
      Purpose = "vpn-certificates"
    }
  )

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [value]
  }
}

# Client CA ARN
resource "aws_ssm_parameter" "client_ca_arn" {
  count = local.should_generate_certs ? 1 : 0

  name        = local.ssm_paths.client_ca_arn
  description = "ACM ARN for VPN client root CA certificate"
  type        = "SecureString"
  value       = local.client_ca_arn
  key_id      = local.kms_key_id

  tags = merge(
    local.merged_tags,
    {
      Name    = "${local.ssm_paths.client_ca_arn}"
      Purpose = "vpn-certificates"
    }
  )

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [value]
  }
}

# Server Certificate PEM
resource "aws_ssm_parameter" "server_cert_pem" {
  count = local.should_generate_certs ? 1 : 0

  name        = local.ssm_paths.server_cert_pem
  description = "VPN server certificate (PEM format)"
  type        = "SecureString"
  value       = local.server_cert_pem
  key_id      = local.kms_key_id

  tags = merge(
    local.merged_tags,
    {
      Name    = "${local.ssm_paths.server_cert_pem}"
      Purpose = "vpn-certificates"
    }
  )

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [value]
  }
}

# Server Private Key PEM
resource "aws_ssm_parameter" "server_key_pem" {
  count = local.should_generate_certs ? 1 : 0

  name        = local.ssm_paths.server_key_pem
  description = "VPN server private key (PEM format)"
  type        = "SecureString"
  value       = local.server_key_pem
  key_id      = local.kms_key_id

  tags = merge(
    local.merged_tags,
    {
      Name    = "${local.ssm_paths.server_key_pem}"
      Purpose = "vpn-certificates"
    }
  )

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [value]
  }
}

# Client CA Certificate PEM
resource "aws_ssm_parameter" "client_ca_cert_pem" {
  count = local.should_generate_certs ? 1 : 0

  name        = local.ssm_paths.client_ca_cert_pem
  description = "VPN client CA certificate (PEM format)"
  type        = "SecureString"
  value       = local.client_ca_cert_pem
  key_id      = local.kms_key_id

  tags = merge(
    local.merged_tags,
    {
      Name    = "${local.ssm_paths.client_ca_cert_pem}"
      Purpose = "vpn-certificates"
    }
  )

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [value]
  }
}

# Client CA Private Key PEM
resource "aws_ssm_parameter" "client_ca_key_pem" {
  count = local.should_generate_certs ? 1 : 0

  name        = local.ssm_paths.client_ca_key_pem
  description = "VPN client CA private key (PEM format)"
  type        = "SecureString"
  value       = local.client_ca_key_pem
  key_id      = local.kms_key_id

  tags = merge(
    local.merged_tags,
    {
      Name    = "${local.ssm_paths.client_ca_key_pem}"
      Purpose = "vpn-certificates"
    }
  )

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [value]
  }
}

# Certificate Expiration Date (ISO 8601)
resource "aws_ssm_parameter" "expiration_date" {
  count = local.should_generate_certs ? 1 : 0

  name        = local.ssm_paths.expiration_date
  description = "VPN certificate expiration date (ISO 8601 format)"
  type        = "String" # Not encrypted - just metadata
  value       = local.expiration_date

  tags = merge(
    local.merged_tags,
    {
      Name    = "${local.ssm_paths.expiration_date}"
      Purpose = "vpn-certificates"
    }
  )

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [value]
  }
}

# ------------------------------------------------------------------------------
# Cross-Region Backup (DR Region) - CA Private Key Only
# ------------------------------------------------------------------------------

# Backup CA private key to DR region (single point of failure protection)
resource "aws_ssm_parameter" "client_ca_key_backup" {
  count = local.should_generate_certs && var.enable_dr_backup ? 1 : 0

  provider = aws.dr_region

  name        = local.ssm_backup_path
  description = "VPN client CA private key backup (PEM format) - DR region"
  type        = "SecureString"
  value       = local.client_ca_key_pem
  key_id      = local.kms_key_id # Cross-region KMS key replication

  tags = merge(
    local.merged_tags,
    {
      Name    = "${local.ssm_backup_path}"
      Purpose = "vpn-certificates"
      Backup  = "true"
    }
  )

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [value]
  }
}

# ------------------------------------------------------------------------------
# IAM Policy for Certificate Rotation Job
# ------------------------------------------------------------------------------

resource "aws_iam_policy" "rotation_access" {
  count = var.create_rotation_policy ? 1 : 0

  name        = local.iam_policy_name
  path        = local.path_prefix
  description = local.iam_policy_description

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMParameterAccess"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:PutParameter",
          "ssm:DescribeParameters"
        ]
        Resource = "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_base_path}/*"
        Condition = {
          StringEquals = {
            "ssm:ResourceTag/Purpose" = "vpn-certificates"
          }
        }
      },
      {
        Sid    = "ACMCertificateImport"
        Effect = "Allow"
        Action = [
          "acm:ImportCertificate",
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:GetCertificate"
        ]
        Resource = "*"
      },
      {
        Sid    = "KMSDecryption"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = local.kms_key_id
        Condition = {
          StringEquals = {
            "kms:ViaService" = [
              "ssm.${data.aws_region.current.id}.amazonaws.com"
            ]
          }
        }
      }
    ]
  })

  tags = local.merged_tags
}
