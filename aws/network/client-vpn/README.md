# AWS Client VPN Module

This module creates an AWS Client VPN Endpoint for secure remote access to VPC resources, including private EKS clusters, RDS databases, and ElastiCache.

## Features

- **Multi-tenant naming**: Supports workspace, customer, and project-specific deployments
- **Flexible authentication**: Mutual TLS (certificates), Active Directory, or SAML-based federation
- **Multi-AZ high availability**: Network associations across multiple availability zones
- **Split tunneling**: Only VPC traffic routes through VPN (saves bandwidth)
- **CloudWatch Logs integration**: Connection audit trail and troubleshooting
- **Security groups**: Automatic security group creation for VPN access control
- **Self-service portal**: Optional client configuration portal

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     VPN Clients                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ Developer   │  │ DevOps      │  │ Support     │          │
│  │ Laptop      │  │ Laptop      │  │ Laptop      │          │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘          │
│         │                 │                 │                 │
│         └─────────────────┴─────────────────┘                 │
│                           │                                   │
│                  VPN Client CIDR: 172.16.0.0/22               │
└───────────────────────────┼───────────────────────────────────┘
                            │
                            │ Mutual TLS / Active Directory
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│              AWS Client VPN Endpoint                          │
│  ┌────────────────────────────────────────────────────┐      │
│  │  Authentication: Certificate / AD / SAML           │      │
│  │  Transport: UDP:1194 or TCP:443                    │      │
│  │  Logging: CloudWatch Logs                          │      │
│  └────────────────────────────────────────────────────┘      │
└───────────────────────────┼───────────────────────────────────┘
                            │
                ┌───────────┼───────────┐
                │           │           │
                ▼           ▼           ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │ Subnet A │ │ Subnet B │ │ Subnet C │
        │ us-east  │ │ us-east  │ │ us-east  │
        │   -1a    │ │   -1b    │ │   -1c    │
        └──────────┘ └──────────┘ └──────────┘
                            │
            VPC CIDR: 10.0.0.0/16
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ EKS Cluster │    │ RDS Database│    │ ElastiCache │
│ (Private)   │    │ (Private)   │    │ (Private)   │
└─────────────┘    └─────────────┘    └─────────────┘
```

## Usage

### Basic Configuration (Mutual TLS)

```hcl
module "client_vpn" {
  source = "./network/client-vpn"

  # Multi-tenant configuration
  workspace     = "forge-platform"
  environment   = "shared"
  customer_name = "acme"
  project_name  = "webapp"

  # VPN Configuration
  client_cidr_block = "172.16.0.0/22"
  split_tunnel      = true
  transport_protocol = "udp"

  # Authentication (Mutual TLS)
  authentication_type           = "certificate-authentication"
  server_certificate_arn        = "arn:aws:acm:us-east-1:123456789012:certificate/abcd1234"
  client_root_certificate_arn   = "arn:aws:acm:us-east-1:123456789012:certificate/efgh5678"

  # Network Configuration
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  vpc_cidr_block = "10.0.0.0/16"

  # Authorization
  authorize_all_groups = true

  # Logging
  enable_connection_logs = true
  cloudwatch_log_retention_days = 30

  tags = {
    Terraform   = "true"
    Environment = "production"
  }
}
```

### Active Directory Authentication

```hcl
module "client_vpn" {
  source = "./network/client-vpn"

  # ... (same as above)

  # Active Directory Authentication
  authentication_type = "directory-service-authentication"
  active_directory_id = "d-1234567890"

  # Authorization with AD Groups
  authorize_all_groups = false
  access_group_id      = "S-1-5-21-123456789-123456789-123456789-1234"  # AD group SID
}
```

### SAML-based Federation

```hcl
module "client_vpn" {
  source = "./network/client-vpn"

  # ... (same as above)

  # SAML Authentication
  authentication_type         = "federated-authentication"
  saml_provider_arn           = "arn:aws:iam::123456789012:saml-provider/MyProvider"
  enable_self_service_portal  = true
  self_service_saml_provider_arn = "arn:aws:iam::123456789012:saml-provider/MyProvider-SelfService"
}
```

## Prerequisites

### 1. Generate VPN Certificates (Mutual TLS)

Use the provided script to generate server and client certificates:

```bash
cd scripts
./generate-vpn-certificates.sh --region us-east-1 --workspace forge-platform

# For customer-specific deployment
./generate-vpn-certificates.sh --region us-east-1 --customer acme --project webapp
```

This script will:
- Generate CA, server, and client certificates using Easy-RSA
- Import certificates to AWS Certificate Manager (ACM)
- Update `terraform.tfvars` with certificate ARNs
- Create client configuration template

### 2. Enable VPN in Terraform

Edit `terraform.tfvars`:

```hcl
enable_vpn = true
vpn_server_certificate_arn       = "arn:aws:acm:us-east-1:123456789012:certificate/abcd1234"
vpn_client_root_certificate_arn  = "arn:aws:acm:us-east-1:123456789012:certificate/efgh5678"
```

### 3. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### 4. Configure VPN Client

After deployment, get the VPN endpoint DNS name from Terraform outputs:

```bash
terraform output vpn_endpoint_dns_name
```

Update the client configuration file:

```bash
cd vpn-certs
sed -i "s/<CLIENT_VPN_ENDPOINT_DNS_NAME>/$VPN_DNS_NAME/" client-config-template.ovpn
mv client-config-template.ovpn client-config.ovpn
```

Distribute `client-config.ovpn` to VPN users.

### 5. Install OpenVPN Client

**macOS**:
```bash
brew install --cask tunnelblick
```

**Windows**: Download from https://openvpn.net/client/

**Linux (Ubuntu)**:
```bash
sudo apt-get install openvpn
```

### 6. Connect to VPN

Import `client-config.ovpn` into your OpenVPN client and connect.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| workspace | Workspace identifier | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| customer_name | Customer name (optional) | `string` | `null` | no |
| project_name | Project name (optional) | `string` | `null` | no |
| client_cidr_block | CIDR block for VPN clients | `string` | n/a | yes |
| dns_servers | DNS servers for VPN clients | `list(string)` | `[]` | no |
| split_tunnel | Enable split tunneling | `bool` | `true` | no |
| transport_protocol | Transport protocol (udp/tcp) | `string` | `"udp"` | no |
| vpn_port | VPN port (auto-selected if null) | `number` | `null` | no |
| session_timeout_hours | Session timeout (8-24 hours) | `number` | `24` | no |
| authentication_type | Authentication type | `string` | `"certificate-authentication"` | no |
| server_certificate_arn | Server certificate ARN | `string` | n/a | yes |
| client_root_certificate_arn | Client root certificate ARN | `string` | `null` | no |
| active_directory_id | Active Directory ID | `string` | `null` | no |
| saml_provider_arn | SAML provider ARN | `string` | `null` | no |
| vpc_id | VPC ID | `string` | n/a | yes |
| subnet_ids | Subnet IDs for VPN endpoint | `list(string)` | n/a | yes |
| vpc_cidr_block | VPC CIDR block | `string` | n/a | yes |
| authorize_all_groups | Authorize all users | `bool` | `true` | no |
| access_group_id | AD group SID for authorization | `string` | `null` | no |
| enable_connection_logs | Enable CloudWatch Logs | `bool` | `true` | no |
| cloudwatch_log_retention_days | Log retention period | `number` | `30` | no |
| create_security_group | Create security group | `bool` | `true` | no |
| enable_self_service_portal | Enable self-service portal | `bool` | `false` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpn_endpoint_id | VPN endpoint ID |
| vpn_endpoint_arn | VPN endpoint ARN |
| vpn_endpoint_dns_name | VPN endpoint DNS name (for client configuration) |
| network_association_ids | List of network association IDs |
| security_group_id | VPN access security group ID |
| cloudwatch_log_group_name | CloudWatch log group name |
| summary | Summary of all VPN configuration |

## Cost Estimation

| Component | Cost | Notes |
|-----------|------|-------|
| VPN Endpoint | $0.05/hour = **$36/month** | Per endpoint (always running) |
| VPN Connection | $0.05/hour = **$36/month** | Per active connection |
| CloudWatch Logs | ~$0.50/GB | Connection logs (~1GB/month/user) |
| Data Transfer | $0.09/GB | Outbound data transfer |

**Total Monthly Cost**:
- 1 user: **$73/month** (endpoint + 1 connection)
- 5 users: **$216/month** (endpoint + 5 connections)
- 10 users: **$396/month** (endpoint + 10 connections)

## Security Best Practices

1. **Use Mutual TLS for development, AD/SAML for production**: Certificate-based auth is easier to set up but harder to manage at scale.

2. **Enable CloudWatch Logs**: Track all VPN connections for audit and troubleshooting.

3. **Use split tunneling**: Only route VPC traffic through VPN to reduce bandwidth and improve performance.

4. **Rotate certificates regularly**: Rotate server and client certificates every 90-365 days.

5. **Revoke certificates for terminated users**: Use Easy-RSA to revoke certificates and regenerate CRL.

6. **Restrict security group rules**: Only allow access to required resources (e.g., EKS API, RDS, Redis).

7. **Use Active Directory groups**: For production, use AD groups to control access (set `authorize_all_groups = false`).

8. **Enable VPC Endpoints**: When using private EKS, enable VPC Endpoints for AWS services (EC2, ECR, S3, etc.).

9. **Set appropriate session timeout**: 8-24 hours (default: 24h). Shorter timeouts improve security but require more frequent reconnections.

10. **Monitor connection attempts**: Set up CloudWatch Alarms for failed connection attempts to detect potential attacks.

## Troubleshooting

### Connection Refused

**Problem**: VPN client cannot connect to endpoint.

**Solution**:
1. Check VPN endpoint status: `aws ec2 describe-client-vpn-endpoints`
2. Verify certificate ARNs in Terraform configuration
3. Check CloudWatch Logs for connection attempts
4. Verify client configuration file has correct VPN endpoint DNS name

### Authentication Failed

**Problem**: VPN client connects but authentication fails.

**Solution**:
1. Verify certificate validity: `openssl x509 -in server.crt -text -noout`
2. Check certificate CN matches expected value
3. For AD: Verify Active Directory ID and user credentials
4. For SAML: Verify SAML provider ARN and IdP configuration

### Cannot Access VPC Resources

**Problem**: VPN connected but cannot access EKS, RDS, etc.

**Solution**:
1. Check authorization rules: `aws ec2 describe-client-vpn-authorization-rules`
2. Verify security group rules allow traffic from VPN security group
3. Check VPC route tables have routes to VPN subnets
4. Verify split tunneling configuration (should include VPC CIDR)
5. Test connectivity: `ping <private-ip>` or `telnet <private-ip> <port>`

### High Costs

**Problem**: VPN costs higher than expected.

**Solution**:
1. Check number of active connections: `aws ec2 describe-client-vpn-connections`
2. Disconnect idle VPN users
3. Reduce session timeout to force disconnection after inactivity
4. Enable split tunneling to reduce data transfer costs
5. Archive old CloudWatch Logs to S3 (cheaper storage)

## Advanced Configuration

### Custom Authorization Rules

```hcl
authorization_rules = [
  {
    target_network_cidr = "10.1.0.0/16"  # Peered VPC
    access_group_id     = "S-1-5-21-123456789-123456789-123456789-1234"
    description         = "Access to peered VPC for DevOps team"
  },
  {
    target_network_cidr = "192.168.0.0/16"  # On-premises network
    access_group_id     = null
    description         = "Access to on-premises network for all users"
  }
]
```

### Client Connect Handler (Lambda-based authorization)

```hcl
client_connect_options = {
  enabled             = true
  lambda_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:vpn-auth-handler"
}
```

### KMS Encryption for CloudWatch Logs

```hcl
enable_connection_logs = true
cloudwatch_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
```

## Migration from Public EKS to Private EKS

1. **Phase 1 - Deploy VPN (current state)**:
   - Deploy VPN endpoint with certificates
   - Test VPN connectivity
   - Verify access to EKS API via VPN
   - Keep `eks_endpoint_public_access = true`

2. **Phase 2 - Enable VPC Endpoints**:
   - Set `enable_vpc_endpoints = true`
   - Deploy VPC Endpoints for EC2, ECR, S3, CloudWatch, etc.
   - Test VPC Endpoints connectivity

3. **Phase 3 - Disable Public EKS Access**:
   - Set `eks_endpoint_public_access = false`
   - Set `eks_endpoint_private_access = true`
   - Update `kubeconfig` to use VPN connection
   - Test `kubectl` access via VPN

4. **Phase 4 - Update CI/CD**:
   - Configure CI/CD runners to connect via VPN
   - Update deployment scripts
   - Test automated deployments

## Additional Client Certificates

To generate additional client certificates for new users:

```bash
cd vpn-certs/easy-rsa/easyrsa3
./easyrsa build-client-full client2.domain.tld nopass

# Copy certificates
cp pki/issued/client2.domain.tld.crt ../../
cp pki/private/client2.domain.tld.key ../../

# Generate client configuration
cd ../../
cat > client2-config.ovpn << EOF
client
dev tun
proto udp
remote <VPN_ENDPOINT_DNS_NAME> 1194
... (same as client1)

<ca>
$(cat ca.crt)
</ca>

<cert>
$(cat client2.domain.tld.crt)
</cert>

<key>
$(cat client2.domain.tld.key)
</key>
EOF
```

## Certificate Revocation

To revoke a client certificate:

```bash
cd vpn-certs/easy-rsa/easyrsa3
./easyrsa revoke client1.domain.tld
./easyrsa gen-crl

# Upload CRL to S3
aws s3 cp pki/crl.pem s3://your-bucket/vpn-crl.pem
```

## Monitoring Queries (CloudWatch Insights)

**Connection Summary**:
```sql
fields @timestamp, `connection-id`, `common-name`, event
| filter event = "connection-established"
| stats count() by `common-name`
```

**Failed Connections**:
```sql
fields @timestamp, `connection-id`, `common-name`, event
| filter event = "connection-attempt" and status != "success"
| sort @timestamp desc
```

**Bandwidth Usage**:
```sql
fields @timestamp, `common-name`, `bytes-sent`, `bytes-received`
| stats sum(`bytes-sent`) as TotalSent, sum(`bytes-received`) as TotalReceived by `common-name`
```

## References

- [AWS Client VPN Documentation](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/what-is.html)
- [AWS Client VPN Pricing](https://aws.amazon.com/vpn/pricing/)
- [Easy-RSA Documentation](https://easy-rsa.readthedocs.io/)
- [OpenVPN Client Downloads](https://openvpn.net/client/)
