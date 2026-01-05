# Provider Configuration Approach - VPC Module

**Date**: November 23, 2025  
**Module**: network/vpc  
**Decision**: ✅ **NO PROVIDER IN MODULE** (Terraform Best Practice)

---

## Summary

The VPC module **does NOT include provider configuration**. Providers are configured at the **root module level**, following Terraform best practices and HashiCorp recommendations.

---

## Why No Provider in Module?

### 1. Terraform Best Practice ✅

**HashiCorp Recommendation**:
> "Provider configurations belong in the root module of your Terraform configuration. Child modules receive their provider configurations from the root module."

**Source**: [Terraform Module Best Practices](https://developer.hashicorp.com/terraform/language/modules/develop/providers)

### 2. Reusability ✅

**Problem with Provider in Module**:
```hcl
# BAD: Provider in module
provider "aws" {
  region = "us-east-1"  # ❌ Hardcoded region
}
```

**Impact**:
- ❌ Can't use module in different regions
- ❌ Can't use module with different AWS accounts
- ❌ Can't use module with provider aliases

**Solution**:
```hcl
# GOOD: Provider in root module
# Root module
provider "aws" {
  region = var.region  # ✅ Configurable
}

module "vpc" {
  source = "./modules/network/vpc"
  # Provider inherited from root
}
```

### 3. Forge Architecture ✅

**CloudOrchestrator Dynamic Configuration**:

Forge's CloudOrchestrator generates provider configurations dynamically based on customer data from PostgreSQL:

```python
# CloudOrchestrator/terraform_generator.py
def generate_provider_config(customer: Customer) -> str:
    """Generate AWS provider configuration for customer."""
    
    if customer.plan.architecture_type == "shared":
        # Shared infrastructure uses Forge AWS account
        return f'''
        provider "aws" {{
          region = "us-east-1"
          
          default_tags {{
            tags = {{
              ManagedBy = "Forge"
            }}
          }}
        }}
        '''
    
    else:
        # Dedicated infrastructure uses customer AWS account
        role_arn = f"arn:aws:iam::{customer.aws_account_id}:role/ForgeTerraformRole"
        
        return f'''
        provider "aws" {{
          region = "{customer.primary_region}"
          
          assume_role {{
            role_arn     = "{role_arn}"
            session_name = "forge-{customer.name}-{{timestamp()}}"
          }}
          
          default_tags {{
            tags = {{
              ManagedBy    = "Forge"
              CustomerId   = "{customer.id}"
              CustomerName = "{customer.name}"
              PlanTier     = "{customer.plan.name}"
            }}
          }}
        }}
        '''
```

**Benefits**:
- ✅ Different customers use different AWS accounts
- ✅ Different regions per customer
- ✅ Customer-specific IAM roles
- ✅ Database-driven configuration

### 4. Multi-Region Support ✅

**Enterprise customers need multiple regional VPCs**:

```hcl
# Root module for multi-region customer
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}

# US East VPC
module "vpc_us_east" {
  source = "./modules/network/vpc"
  providers = {
    aws = aws.us_east_1  # Use specific provider
  }
  
  vpc_name   = "acme-us-east-1-vpc"
  aws_region = "us-east-1"
  # ...
}

# EU West VPC
module "vpc_eu_west" {
  source = "./modules/network/vpc"
  providers = {
    aws = aws.eu_west_1  # Use different provider
  }
  
  vpc_name   = "acme-eu-west-1-vpc"
  aws_region = "eu-west-1"
  # ...
}
```

**This is IMPOSSIBLE with provider in module!**

### 5. Testing & Development ✅

**Different environments need different auth**:

```hcl
# Development (local credentials)
provider "aws" {
  region  = "us-east-1"
  profile = "dev"  # ~/.aws/credentials
}

# CI/CD (EC2 instance profile)
provider "aws" {
  region = "us-east-1"
  # Automatic credentials from instance metadata
}

# Production (IAM role assumption)
provider "aws" {
  region = "us-east-1"
  
  assume_role {
    role_arn = "arn:aws:iam::123456789012:role/TerraformRole"
  }
}
```

---

## Comparison: Old vs. New Approach

### Old Approach (cloud-platform-features)

**Module includes provider** (`modules/network/vpc/aws_provider.tf`):

```hcl
provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn     = var.role_arn
    session_name = "terraform-vpc-${var.workspace}-${var.owner}"
  }

  default_tags {
    tags = {
      Workspace = var.workspace
      Owner     = var.owner
      ManagedBy = "Terraform"
    }
  }
}
```

**Problems**:
- ❌ Requires `role_arn` variable in every module
- ❌ Can't use module without role assumption
- ❌ Can't use module in multiple regions
- ❌ Hard to test locally
- ❌ Violates Terraform best practices

---

### New Approach (Forge)

**No provider in module** - configured at root level:

**Module** (`modules/network/vpc/main.tf`):
```hcl
# No provider configuration
resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
  # Provider inherited from root
}
```

**Root Module**:
```hcl
provider "aws" {
  region = "us-east-1"
  # Authentication method chosen here
}

module "vpc" {
  source = "./modules/network/vpc"
  # No provider-related variables needed
}
```

**Benefits**:
- ✅ Module is provider-agnostic
- ✅ Works with any authentication method
- ✅ Supports multi-region deployments
- ✅ Easy to test locally
- ✅ Follows Terraform best practices
- ✅ CloudOrchestrator controls provider config

---

## How to Use This Module

### Example 1: Local Development (Shared VPC)

```hcl
# main.tf (root module)
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.9"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "default"  # Use ~/.aws/credentials
  
  default_tags {
    tags = {
      ManagedBy   = "Forge"
      Environment = "development"
    }
  }
}

module "forge_vpc" {
  source = "./modules/network/vpc"
  
  vpc_name          = "forge-dev-vpc"
  cidr_block        = "10.0.0.0/16"
  workspace         = "development"
  environment       = "dev"
  aws_region        = "us-east-1"
  architecture_type = "shared"
}
```

### Example 2: Production (Customer VPC with IAM Role)

```hcl
# main.tf (root module)
provider "aws" {
  region = "us-east-1"
  
  assume_role {
    role_arn     = "arn:aws:iam::123456789012:role/ForgeTerraformRole"
    session_name = "forge-customer-sanofi-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  }
  
  default_tags {
    tags = {
      ManagedBy    = "Forge"
      CustomerId   = "550e8400-e29b-41d4-a716-446655440000"
      CustomerName = "sanofi"
      PlanTier     = "pro"
    }
  }
}

module "customer_vpc" {
  source = "./modules/network/vpc"
  
  vpc_name          = "sanofi-us-east-1-vpc"
  cidr_block        = "10.100.0.0/16"
  workspace         = "production"
  environment       = "prod"
  aws_region        = "us-east-1"
  customer_id       = "550e8400-e29b-41d4-a716-446655440000"
  customer_name     = "sanofi"
  architecture_type = "dedicated_local"
  plan_tier         = "pro"
}
```

### Example 3: Multi-Region (Enterprise Customer)

```hcl
# main.tf (root module)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  
  assume_role {
    role_arn     = "arn:aws:iam::987654321098:role/ForgeTerraformRole"
    session_name = "forge-acme-us-east-1"
  }
}

provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
  
  assume_role {
    role_arn     = "arn:aws:iam::987654321098:role/ForgeTerraformRole"
    session_name = "forge-acme-eu-west-1"
  }
}

# US East VPC
module "vpc_us" {
  source = "./modules/network/vpc"
  providers = {
    aws = aws.us_east_1
  }
  
  vpc_name          = "acme-us-east-1-vpc"
  cidr_block        = "10.200.0.0/16"
  workspace         = "production"
  environment       = "prod"
  aws_region        = "us-east-1"
  customer_id       = "660e8400-e29b-41d4-a716-446655440001"
  customer_name     = "acme"
  architecture_type = "dedicated_regional"
  plan_tier         = "enterprise"
}

# EU West VPC
module "vpc_eu" {
  source = "./modules/network/vpc"
  providers = {
    aws = aws.eu_west_1
  }
  
  vpc_name          = "acme-eu-west-1-vpc"
  cidr_block        = "10.201.0.0/16"
  workspace         = "production"
  environment       = "prod"
  aws_region        = "eu-west-1"
  customer_id       = "660e8400-e29b-41d4-a716-446655440001"
  customer_name     = "acme"
  architecture_type = "dedicated_regional"
  plan_tier         = "enterprise"
}
```

---

## Required IAM Permissions

The IAM role/user needs these permissions for VPC module:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:DescribeVpcs",
        "ec2:ModifyVpcAttribute",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## Testing

### Test Provider Configuration

```bash
# Test provider configuration without creating resources
terraform init
terraform validate
terraform plan
```

### Test Module with Different Providers

```bash
# Test with local credentials
export AWS_PROFILE=dev
terraform plan

# Test with IAM role
export AWS_ROLE_ARN=arn:aws:iam::123456789012:role/Test
terraform plan

# Test in different region
terraform plan -var="aws_region=eu-west-1"
```

---

## Benefits Summary

### For Forge Platform ✅

- ✅ **CloudOrchestrator Control**: Provider config generated from database
- ✅ **Customer Isolation**: Different AWS accounts per customer
- ✅ **Multi-Region Support**: Enterprise customers in multiple regions
- ✅ **Flexible Auth**: Different methods for different environments

### For Module Users ✅

- ✅ **Reusable**: Works in any context with any provider config
- ✅ **Testable**: Easy to test locally with different credentials
- ✅ **Flexible**: Use with or without role assumption
- ✅ **Multi-Region**: Deploy same module in different regions

### For Terraform Best Practices ✅

- ✅ **Follows HashiCorp Guidelines**: Provider in root module only
- ✅ **No Hardcoded Values**: Region, account, auth are configurable
- ✅ **Provider Aliases**: Supports multi-provider scenarios
- ✅ **Version Constraints**: Defined in module's versions.tf

---

## Migration Notes

### Removed from cloud-platform-features

The following file was **removed** during migration:
- ❌ `aws_provider.tf` - Provider configuration
- ❌ `role_arn` variable - Not needed in module

### Added for Forge

The following documentation was **added**:
- ✅ `PROVIDER_CONFIGURATION.md` - Complete provider guide
- ✅ `README.md` provider section - Quick reference
- ✅ `PROVIDER_APPROACH.md` - This document

---

## Related Documentation

- [PROVIDER_CONFIGURATION.md](../../PROVIDER_CONFIGURATION.md) - Complete provider guide with all examples
- [VPC Module README](./README.md) - Module usage documentation
- [Terraform Provider Configuration](https://developer.hashicorp.com/terraform/language/providers/configuration) - Official docs

---

## Conclusion

By **removing provider configuration from the module**, we've made it:
- ✅ More reusable across different contexts
- ✅ Compatible with Forge's database-driven architecture
- ✅ Compliant with Terraform best practices
- ✅ Flexible for multi-region deployments
- ✅ Easier to test and develop

**This approach is essential for Forge's CloudOrchestrator to dynamically manage customer infrastructure.**

---

**Last Updated**: November 23, 2025  
**Author**: MOAI Engineering - Platform Team  
**Decision**: FINAL - No provider in modules
