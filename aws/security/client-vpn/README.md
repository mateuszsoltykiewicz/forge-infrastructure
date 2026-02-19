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

## End-User VPN Setup Guide

This section explains how to use AWS Client VPN from an end-user perspective after the infrastructure administrator has provisioned the VPN endpoint.

### Prerequisites for End Users

You will need to receive from your administrator:
1. **VPN configuration file** (`.ovpn` file) - contains connection settings and your certificates
2. **OpenVPN client** installation instructions for your operating system

### Step 1: Install AWS VPN Client or OpenVPN Client

Choose one of the following options:

**Option A: AWS VPN Client (Recommended)**

- **macOS**: Download from [AWS VPN Client Downloads](https://aws.amazon.com/vpn/client-vpn-download/)
- **Windows**: Download from [AWS VPN Client Downloads](https://aws.amazon.com/vpn/client-vpn-download/)
- **Linux**: Use OpenVPN instead (Option B)

**Option B: OpenVPN Client (Alternative)**

- **macOS**: 
  ```bash
  brew install --cask tunnelblick
  ```
  Or download from [Tunnelblick](https://tunnelblick.net/)

- **Windows**: Download from [OpenVPN Downloads](https://openvpn.net/client/)

- **Linux (Ubuntu/Debian)**:
  ```bash
  sudo apt-get update
  sudo apt-get install openvpn
  ```

- **Linux (RHEL/CentOS)**:
  ```bash
  sudo yum install openvpn
  ```

### Step 2: Understanding Your VPN Configuration File

The `.ovpn` file you received contains:

```ovpn
client
dev tun
proto udp
remote cvpn-endpoint-xxxxx.prod.clientvpn.us-east-1.amazonaws.com 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
verb 3

<ca>
-----BEGIN CERTIFICATE-----
[Your Certificate Authority certificate]
-----END CERTIFICATE-----
</ca>

<cert>
-----BEGIN CERTIFICATE-----
[Your client certificate]
-----END CERTIFICATE-----
</cert>

<key>
-----BEGIN PRIVATE KEY-----
[Your private key - KEEP THIS SECRET!]
-----END PRIVATE KEY-----
</key>
```

**Important Security Notes**:
- Keep this file **secure** - it contains your private authentication key
- **Never share** your `.ovpn` file with anyone
- Store it in an encrypted location when not in use
- If compromised, immediately notify your administrator to revoke the certificate

### Step 3: Import Configuration

**AWS VPN Client**:
1. Open AWS VPN Client
2. Click **File** → **Manage Profiles**
3. Click **Add Profile**
4. Browse to your `.ovpn` file
5. Enter a display name (e.g., "Forge Production VPN")
6. Click **Add Profile**

**Tunnelblick (macOS)**:
1. Double-click the `.ovpn` file
2. Tunnelblick will ask to install the configuration
3. Choose "Only Me" or "All Users"
4. Enter your macOS password when prompted

**OpenVPN GUI (Windows)**:
1. Right-click OpenVPN GUI in system tray
2. Right-click on the connection name
3. Select **Import file**
4. Browse to your `.ovpn` file

**OpenVPN CLI (Linux)**:
```bash
# Copy the configuration file to OpenVPN directory
sudo cp your-vpn-config.ovpn /etc/openvpn/client/

# Or place it in your home directory
mkdir -p ~/.openvpn
cp your-vpn-config.ovpn ~/.openvpn/
```

### Step 4: Connect to VPN

**AWS VPN Client**:
1. Open AWS VPN Client
2. Select your profile from the dropdown
3. Click **Connect**
4. Wait for status to change to "Connected" (green checkmark)

**Tunnelblick (macOS)**:
1. Click Tunnelblick icon in menu bar
2. Select your VPN connection
3. Click **Connect**
4. Connection status shows in menu bar

**OpenVPN GUI (Windows)**:
1. Right-click OpenVPN GUI in system tray
2. Select your connection
3. Click **Connect**
4. Icon turns green when connected

**OpenVPN CLI (Linux)**:
```bash
# Connect using OpenVPN
sudo openvpn --config ~/.openvpn/your-vpn-config.ovpn

# Or if using systemd (place config in /etc/openvpn/client/)
sudo systemctl start openvpn-client@your-vpn-config

# Check connection status
systemctl status openvpn-client@your-vpn-config
```

### Step 5: Verify Connection

Once connected, verify you can access private resources:

**Test VPN Connection**:
```bash
# Check your IP assigned by VPN (should be from 172.16.0.0/22)
ifconfig | grep "172.16"  # macOS/Linux
ipconfig | findstr "172.16"  # Windows

# Test connectivity to private resources
ping 10.0.1.10  # Example: Private EKS node IP
```

**Test Private EKS Access**:
```bash
# Update kubeconfig to use private endpoint
aws eks update-kubeconfig --name forge-production-customer-project-eks --region us-east-1

# Test kubectl access (requires VPN connection)
kubectl get nodes
kubectl get pods -A
```

**Test Private RDS Access**:
```bash
# Test PostgreSQL connection (requires psql client)
psql -h forge-production-customer-project-rds.xxxxx.us-east-1.rds.amazonaws.com \
     -U forge_admin \
     -d forge_db
```

**Test Private Redis Access**:
```bash
# Test Redis connection (requires redis-cli)
redis-cli -h forge-production-customer-project-redis.xxxxx.cache.amazonaws.com \
          -p 6379 \
          PING
```

### Step 6: Understanding Split Tunnel vs Full Tunnel

**Split Tunnel** (Default - Recommended):
- Only traffic to private AWS resources (10.0.0.0/16) goes through VPN
- Regular internet traffic uses your normal connection
- **Advantages**: Faster internet browsing, lower VPN bandwidth costs
- **Use case**: Accessing private EKS/RDS while working normally

**Full Tunnel** (If enabled by administrator):
- All traffic routes through VPN
- Internet traffic goes through AWS VPN endpoint
- **Advantages**: All traffic encrypted and logged
- **Use case**: High security environments, compliance requirements

To check which mode you're using, look at your routing table:

```bash
# macOS/Linux
netstat -rn | grep utun  # Split tunnel shows only specific routes

# Windows
route print | findstr "172.16"  # Split tunnel shows limited routes
```

### Step 7: Disconnect from VPN

**AWS VPN Client / Tunnelblick / OpenVPN GUI**:
- Click **Disconnect** button in the application

**OpenVPN CLI (Linux)**:
```bash
# Stop the VPN connection
sudo systemctl stop openvpn-client@your-vpn-config

# Or if running in foreground, press Ctrl+C
```

### Common Issues and Solutions

#### Issue: "Connection Timeout"

**Cause**: VPN endpoint unreachable or incorrect DNS name

**Solution**:
1. Check your internet connection
2. Verify the VPN endpoint DNS name in your `.ovpn` file
3. Try using TCP protocol instead of UDP (ask administrator)
4. Check if corporate firewall blocks UDP port 1194 or TCP port 443

#### Issue: "Authentication Failed"

**Cause**: Certificate expired or revoked

**Solution**:
1. Contact your administrator to verify your certificate is valid
2. Request a new `.ovpn` file with fresh certificates
3. Check certificate expiration:
   ```bash
   openssl x509 -in <(sed -n '/<cert>/,/<\/cert>/p' your-vpn-config.ovpn | sed '1d;$d') -noout -dates
   ```

#### Issue: "Connected but Cannot Access Resources"

**Cause**: Routing or security group configuration

**Solution**:
1. Verify you're connected to the correct VPN profile
2. Check your IP is in the VPN range (172.16.x.x)
3. Test basic connectivity: `ping 10.0.1.1` (VPC gateway)
4. Contact administrator to verify authorization rules and security groups
5. Check if split tunneling is routing traffic correctly

#### Issue: "Slow VPN Performance"

**Cause**: Bandwidth limitations or routing inefficiency

**Solution**:
1. Verify split tunneling is enabled (don't route all traffic through VPN)
2. Try switching between UDP and TCP protocols
3. Close unnecessary applications using bandwidth
4. Check if your local network has bandwidth restrictions

#### Issue: "VPN Disconnects Frequently"

**Cause**: Session timeout or network instability

**Solution**:
1. Check session timeout setting (default: 24 hours)
2. Verify your internet connection stability
3. Ask administrator to increase session timeout
4. Enable "persist-tun" in OpenVPN settings (usually enabled by default)

### Best Practices for End Users

1. **Connect only when needed**: VPN connections are billed per hour
2. **Disconnect when done**: Remember to disconnect after finishing work
3. **Keep certificate secure**: Store `.ovpn` file in encrypted folder
4. **Don't share credentials**: Each user should have their own certificate
5. **Report issues promptly**: Contact administrator if connection fails
6. **Update client software**: Keep OpenVPN/AWS VPN Client updated
7. **Use split tunnel**: Don't route personal browsing through VPN
8. **Test connectivity**: After connecting, verify access to required resources

### Getting Help

If you encounter issues:

1. **Check connection logs**:
   - AWS VPN Client: View → Connection Log
   - Tunnelblick: Click Details → View Log
   - OpenVPN CLI: Check `/var/log/syslog` or systemd logs

2. **Gather diagnostic information**:
   ```bash
   # Your VPN-assigned IP
   ifconfig | grep "172.16"
   
   # VPN routing table
   netstat -rn | grep utun
   
   # Test connectivity to VPC gateway
   ping 10.0.0.1
   ```

3. **Contact your administrator** with:
   - Error message from VPN client
   - Time when issue occurred
   - Steps you took before the error
   - Diagnostic information from above

### Certificate Management

**Certificate Expiration**:
- Certificates typically expire after 1-3 years
- You'll receive a notification before expiration
- Request new `.ovpn` file from administrator before expiry

**Certificate Revocation**:
- If you lose your laptop or `.ovpn` file is compromised
- Immediately notify administrator to revoke your certificate
- You'll receive a new `.ovpn` file with fresh credentials

### Multi-Device Setup

If you need VPN access on multiple devices:

1. **Request separate certificates** from administrator for each device
   - laptop-username.ovpn
   - desktop-username.ovpn
   - tablet-username.ovpn

2. **Never copy the same `.ovpn` file** to multiple devices
   - Each device should have unique credentials
   - Easier to revoke single device if compromised

3. **Label configurations clearly** in VPN client
   - "Forge Production VPN - MacBook"
   - "Forge Production VPN - Desktop"

## Additional Client Certificates

### For Administrators: Generating Additional Client Certificates

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
