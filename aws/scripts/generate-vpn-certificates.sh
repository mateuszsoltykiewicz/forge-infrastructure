#!/bin/bash
# ==============================================================================
# AWS Client VPN - Certificate Generation Script
# ==============================================================================
# This script generates server and client certificates for AWS Client VPN
# using Easy-RSA and imports them to AWS Certificate Manager (ACM).
#
# Prerequisites:
# - AWS CLI configured with appropriate credentials
# - easy-rsa installed (brew install easy-rsa on macOS)
# - OpenSSL installed
#
# Usage:
#   ./generate-vpn-certificates.sh [OPTIONS]
#
# Options:
#   --region REGION       AWS region (default: us-east-1)
#   --workspace NAME      Workspace name (default: forge-platform)
#   --customer NAME       Customer name (optional)
#   --project NAME        Project name (optional)
#   --output-dir DIR      Output directory for certificates (default: ./vpn-certs)
#   --help                Show this help message
#
# Example:
#   ./generate-vpn-certificates.sh --region us-east-1 --workspace forge-platform
# ==============================================================================

set -e  # Exit on error
set -u  # Exit on undefined variable

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

AWS_REGION="${AWS_REGION:-us-east-1}"
WORKSPACE="forge-platform"
CUSTOMER_NAME=""
PROJECT_NAME=""
OUTPUT_DIR="./vpn-certs"
VPN_NAME=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --region REGION       AWS region (default: us-east-1)
    --workspace NAME      Workspace name (default: forge-platform)
    --customer NAME       Customer name (optional)
    --project NAME        Project name (optional)
    --output-dir DIR      Output directory for certificates (default: ./vpn-certs)
    --help                Show this help message

Example:
    $0 --region us-east-1 --workspace forge-platform
    $0 --region us-east-1 --customer acme --project webapp
EOF
}

# ------------------------------------------------------------------------------
# Parse Arguments
# ------------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case $1 in
        --region)
            AWS_REGION="$2"
            shift 2
            ;;
        --workspace)
            WORKSPACE="$2"
            shift 2
            ;;
        --customer)
            CUSTOMER_NAME="$2"
            shift 2
            ;;
        --project)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --help)
            print_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# ------------------------------------------------------------------------------
# Determine VPN Name (Multi-tenant naming convention)
# ------------------------------------------------------------------------------

if [[ -n "$PROJECT_NAME" ]]; then
    VPN_NAME="forge-${CUSTOMER_NAME}-${PROJECT_NAME}-vpn"
elif [[ -n "$CUSTOMER_NAME" ]]; then
    VPN_NAME="forge-${CUSTOMER_NAME}-vpn"
else
    VPN_NAME="forge-shared-vpn"
fi

print_info "VPN Name: $VPN_NAME"
print_info "AWS Region: $AWS_REGION"
print_info "Output Directory: $OUTPUT_DIR"

# ------------------------------------------------------------------------------
# Check Prerequisites
# ------------------------------------------------------------------------------

print_info "Checking prerequisites..."

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI not found. Please install it first."
    exit 1
fi

# Check easy-rsa
if ! command -v easyrsa &> /dev/null; then
    print_error "easy-rsa not found. Please install it first:"
    print_error "  macOS: brew install easy-rsa"
    print_error "  Ubuntu: apt-get install easy-rsa"
    exit 1
fi

# Check OpenSSL
if ! command -v openssl &> /dev/null; then
    print_error "OpenSSL not found. Please install it first."
    exit 1
fi

print_info "All prerequisites satisfied."

# ------------------------------------------------------------------------------
# Create Output Directory
# ------------------------------------------------------------------------------

mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

print_info "Working directory: $(pwd)"

# ------------------------------------------------------------------------------
# Initialize PKI (Public Key Infrastructure)
# ------------------------------------------------------------------------------

print_info "Initializing PKI..."

# Clone easy-rsa if not already present
if [[ ! -d "easy-rsa" ]]; then
    git clone https://github.com/OpenVPN/easy-rsa.git
fi

cd easy-rsa/easyrsa3

# Initialize PKI
./easyrsa init-pki

# ------------------------------------------------------------------------------
# Build Certificate Authority (CA)
# ------------------------------------------------------------------------------

print_info "Building Certificate Authority..."

# Build CA (non-interactive)
./easyrsa --batch --req-cn="${VPN_NAME}-ca" build-ca nopass

print_info "Certificate Authority created."

# ------------------------------------------------------------------------------
# Generate Server Certificate
# ------------------------------------------------------------------------------

print_info "Generating server certificate..."

./easyrsa --batch --req-cn="${VPN_NAME}-server" build-server-full server nopass

print_info "Server certificate created."

# ------------------------------------------------------------------------------
# Generate Client Certificate
# ------------------------------------------------------------------------------

print_info "Generating client certificate..."

./easyrsa --batch --req-cn="${VPN_NAME}-client1" build-client-full client1.domain.tld nopass

print_info "Client certificate created."

# ------------------------------------------------------------------------------
# Copy Certificates to Output Directory
# ------------------------------------------------------------------------------

print_info "Copying certificates..."

cp pki/ca.crt ../../
cp pki/issued/server.crt ../../
cp pki/private/server.key ../../
cp pki/issued/client1.domain.tld.crt ../../
cp pki/private/client1.domain.tld.key ../../

cd ../../

print_info "Certificates copied to: $(pwd)"

# ------------------------------------------------------------------------------
# Import Certificates to AWS Certificate Manager (ACM)
# ------------------------------------------------------------------------------

print_info "Importing certificates to AWS Certificate Manager..."

# Import Server Certificate
SERVER_CERT_ARN=$(aws acm import-certificate \
    --certificate fileb://server.crt \
    --private-key fileb://server.key \
    --certificate-chain fileb://ca.crt \
    --region "$AWS_REGION" \
    --tags "Key=Name,Value=${VPN_NAME}-server" \
           "Key=Workspace,Value=${WORKSPACE}" \
           "Key=Component,Value=VPN" \
    --query 'CertificateArn' \
    --output text)

print_info "Server certificate imported: $SERVER_CERT_ARN"

# Import Client Root Certificate
CLIENT_CERT_ARN=$(aws acm import-certificate \
    --certificate fileb://client1.domain.tld.crt \
    --private-key fileb://client1.domain.tld.key \
    --certificate-chain fileb://ca.crt \
    --region "$AWS_REGION" \
    --tags "Key=Name,Value=${VPN_NAME}-client" \
           "Key=Workspace,Value=${WORKSPACE}" \
           "Key=Component,Value=VPN" \
    --query 'CertificateArn' \
    --output text)

print_info "Client certificate imported: $CLIENT_CERT_ARN"

# ------------------------------------------------------------------------------
# Save ARNs to Terraform Variables File
# ------------------------------------------------------------------------------

TFVARS_FILE="../terraform.tfvars"

print_info "Updating Terraform variables file: $TFVARS_FILE"

# Create backup
if [[ -f "$TFVARS_FILE" ]]; then
    cp "$TFVARS_FILE" "${TFVARS_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
fi

# Append or update VPN certificate variables
cat >> "$TFVARS_FILE" << EOF

# ==============================================================================
# AWS Client VPN Configuration
# ==============================================================================
# Auto-generated by scripts/generate-vpn-certificates.sh on $(date)
# ==============================================================================

enable_vpn                       = false  # Set to true to enable VPN
vpn_server_certificate_arn       = "$SERVER_CERT_ARN"
vpn_client_root_certificate_arn  = "$CLIENT_CERT_ARN"
vpn_client_cidr_block            = "172.16.0.0/22"
vpn_split_tunnel                 = true
vpn_transport_protocol           = "udp"
vpn_authorize_all_groups         = true
vpn_enable_connection_logs       = true
vpn_cloudwatch_log_retention_days = 30

EOF

print_info "Terraform variables updated."

# ------------------------------------------------------------------------------
# Generate Client Configuration File
# ------------------------------------------------------------------------------

print_info "Generating client configuration template..."

cat > client-config-template.ovpn << EOF
client
dev tun
proto udp
remote <CLIENT_VPN_ENDPOINT_DNS_NAME> 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
verb 3

<ca>
$(cat ca.crt)
</ca>

<cert>
$(cat client1.domain.tld.crt)
</cert>

<key>
$(cat client1.domain.tld.key)
</key>
EOF

print_info "Client configuration template created: client-config-template.ovpn"

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------

print_info ""
print_info "================================================================="
print_info "Certificate generation completed successfully!"
print_info "================================================================="
print_info ""
print_info "Server Certificate ARN:"
print_info "  $SERVER_CERT_ARN"
print_info ""
print_info "Client Certificate ARN:"
print_info "  $CLIENT_CERT_ARN"
print_info ""
print_info "Terraform variables updated in: $TFVARS_FILE"
print_info ""
print_info "Next steps:"
print_info "  1. Review terraform.tfvars and set enable_vpn = true"
print_info "  2. Run: terraform plan"
print_info "  3. Run: terraform apply"
print_info "  4. Get VPN endpoint DNS name from Terraform outputs"
print_info "  5. Update client-config-template.ovpn with VPN endpoint DNS name"
print_info "  6. Distribute client-config.ovpn to VPN users"
print_info ""
print_info "To create additional client certificates:"
print_info "  cd $OUTPUT_DIR/easy-rsa/easyrsa3"
print_info "  ./easyrsa build-client-full client2.domain.tld nopass"
print_info ""
print_info "================================================================="

# ------------------------------------------------------------------------------
# Security Reminder
# ------------------------------------------------------------------------------

print_warn ""
print_warn "SECURITY REMINDER:"
print_warn "  - Keep private keys secure and never commit to git"
print_warn "  - Add *.key and *.crt to .gitignore"
print_warn "  - Rotate certificates every 90-365 days"
print_warn "  - Revoke certificates for terminated users"
print_warn ""

# Add certificates to .gitignore
if [[ -f "../.gitignore" ]]; then
    if ! grep -q "vpn-certs/" "../.gitignore"; then
        echo -e "\n# VPN Certificates\nvpn-certs/\n*.key\n*.crt\n*.ovpn" >> ../.gitignore
        print_info "Added VPN certificates to .gitignore"
    fi
fi

print_info "Done!"
