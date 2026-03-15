#!/usr/bin/env bash
# ==============================================================================
# VPN Certificate Generator Script
# ==============================================================================
# This script generates VPN certificates using Easy-RSA and imports them to ACM.
# It auto-detects the platform (macOS/Ubuntu/Amazon Linux) and installs Easy-RSA
# if not present.
#
# Environment Variables (Required):
#   COMMON_NAME       - Certificate common name (FQDN)
#   ORG_NAME          - Organization name for CA
#   CERT_VALIDITY_DAYS - Certificate validity in days
#   AWS_REGION        - AWS region for ACM import
#   OUTPUT_JSON       - Path to output JSON file
#
# Output:
#   JSON file with certificate ARNs, PEM data, and expiration date
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Color Output
# ------------------------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ------------------------------------------------------------------------------
# Validate Environment Variables
# ------------------------------------------------------------------------------

print_info "Validating environment variables..."

if [[ -z "${COMMON_NAME:-}" ]]; then
    print_error "COMMON_NAME environment variable is required"
    exit 1
fi

if [[ -z "${ORG_NAME:-}" ]]; then
    print_error "ORG_NAME environment variable is required"
    exit 1
fi

if [[ -z "${CERT_VALIDITY_DAYS:-}" ]]; then
    print_error "CERT_VALIDITY_DAYS environment variable is required"
    exit 1
fi

if [[ -z "${AWS_REGION:-}" ]]; then
    print_error "AWS_REGION environment variable is required"
    exit 1
fi

if [[ -z "${OUTPUT_JSON:-}" ]]; then
    print_error "OUTPUT_JSON environment variable is required"
    exit 1
fi

print_success "All environment variables validated"

# ------------------------------------------------------------------------------
# Platform Detection
# ------------------------------------------------------------------------------

print_info "Detecting platform..."

OS_TYPE=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
    print_info "Detected: macOS"
elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    if [[ "$ID" == "ubuntu" ]] || [[ "$ID_LIKE" == *"debian"* ]]; then
        OS_TYPE="ubuntu"
        print_info "Detected: Ubuntu/Debian"
    elif [[ "$ID" == "amzn" ]]; then
        OS_TYPE="amazon-linux"
        print_info "Detected: Amazon Linux"
    else
        OS_TYPE="linux"
        print_info "Detected: Generic Linux"
    fi
else
    print_error "Unsupported operating system"
    exit 1
fi

# ------------------------------------------------------------------------------
# Install Easy-RSA if Not Present
# ------------------------------------------------------------------------------

print_info "Checking for Easy-RSA installation..."

if command -v easyrsa &> /dev/null; then
    print_success "Easy-RSA is already installed"
    EASYRSA_CMD="easyrsa"
else
    print_warn "Easy-RSA not found. Installing..."
    
    case "$OS_TYPE" in
        macos)
            if ! command -v brew &> /dev/null; then
                print_error "Homebrew is required but not installed. Please install Homebrew first:"
                print_error "https://brew.sh"
                exit 1
            fi
            print_info "Installing Easy-RSA via Homebrew..."
            brew install easy-rsa
            EASYRSA_CMD="easyrsa"
            ;;
            
        ubuntu)
            print_info "Installing Easy-RSA via apt..."
            sudo apt-get update -qq
            sudo apt-get install -y easy-rsa
            EASYRSA_CMD="/usr/share/easy-rsa/easyrsa"
            ;;
            
        amazon-linux)
            print_info "Installing Easy-RSA via yum..."
            sudo yum install -y easy-rsa
            EASYRSA_CMD="/usr/share/easy-rsa/3/easyrsa"
            ;;
            
        linux)
            print_warn "Generic Linux detected. Attempting apt-get installation..."
            if command -v apt-get &> /dev/null; then
                sudo apt-get update -qq
                sudo apt-get install -y easy-rsa
                EASYRSA_CMD="/usr/share/easy-rsa/easyrsa"
            elif command -v yum &> /dev/null; then
                sudo yum install -y easy-rsa
                EASYRSA_CMD="/usr/share/easy-rsa/3/easyrsa"
            else
                print_error "Could not find package manager (apt-get or yum)"
                exit 1
            fi
            ;;
    esac
    
    print_success "Easy-RSA installed successfully"
fi

# Verify installation
if ! command -v "$EASYRSA_CMD" &> /dev/null && ! [[ -x "$EASYRSA_CMD" ]]; then
    print_error "Easy-RSA installation failed or not in PATH"
    exit 1
fi

# ------------------------------------------------------------------------------
# Check AWS CLI
# ------------------------------------------------------------------------------

print_info "Checking for AWS CLI..."

if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is required but not installed"
    print_error "Install: https://aws.amazon.com/cli/"
    exit 1
fi

print_success "AWS CLI found"

# ------------------------------------------------------------------------------
# Setup Working Directory
# ------------------------------------------------------------------------------

print_info "Setting up working directory..."

WORK_DIR="$(mktemp -d -t vpn-certs-XXXXXX)"
trap 'rm -rf "$WORK_DIR"' EXIT

cd "$WORK_DIR"
print_info "Working directory: $WORK_DIR"

# ------------------------------------------------------------------------------
# Initialize Easy-RSA PKI
# ------------------------------------------------------------------------------

print_info "Initializing Easy-RSA PKI..."

$EASYRSA_CMD init-pki

# Configure Easy-RSA
cat > pki/vars <<EOF
set_var EASYRSA_REQ_COUNTRY    "US"
set_var EASYRSA_REQ_PROVINCE   "California"
set_var EASYRSA_REQ_CITY       "San Francisco"
set_var EASYRSA_REQ_ORG        "$ORG_NAME"
set_var EASYRSA_REQ_EMAIL      "admin@example.com"
set_var EASYRSA_REQ_OU         "VPN"
set_var EASYRSA_KEY_SIZE       2048
set_var EASYRSA_ALGO           rsa
set_var EASYRSA_CA_EXPIRE      3650
set_var EASYRSA_CERT_EXPIRE    $CERT_VALIDITY_DAYS
set_var EASYRSA_CERT_RENEW     30
EOF

print_success "PKI initialized"

# ------------------------------------------------------------------------------
# Build CA
# ------------------------------------------------------------------------------

print_info "Building Certificate Authority..."

$EASYRSA_CMD --batch build-ca nopass

print_success "CA certificate created"

# ------------------------------------------------------------------------------
# Generate Server Certificate
# ------------------------------------------------------------------------------

print_info "Generating server certificate for: $COMMON_NAME..."

$EASYRSA_CMD --batch --req-cn="$COMMON_NAME" build-server-full "$COMMON_NAME" nopass

print_success "Server certificate created"

# ------------------------------------------------------------------------------
# Extract Certificate Files
# ------------------------------------------------------------------------------

print_info "Extracting certificate files..."

CA_CERT="pki/ca.crt"
CA_KEY="pki/private/ca.key"
SERVER_CERT="pki/issued/${COMMON_NAME}.crt"
SERVER_KEY="pki/private/${COMMON_NAME}.key"

# Verify files exist
for file in "$CA_CERT" "$CA_KEY" "$SERVER_CERT" "$SERVER_KEY"; do
    if [[ ! -f "$file" ]]; then
        print_error "Certificate file not found: $file"
        exit 1
    fi
done

print_success "All certificate files generated"

# ------------------------------------------------------------------------------
# Import Certificates to ACM
# ------------------------------------------------------------------------------

print_info "Importing server certificate to ACM..."

SERVER_ARN=$(aws acm import-certificate \
    --certificate fileb://"$SERVER_CERT" \
    --private-key fileb://"$SERVER_KEY" \
    --certificate-chain fileb://"$CA_CERT" \
    --region "$AWS_REGION" \
    --query 'CertificateArn' \
    --output text)

if [[ -z "$SERVER_ARN" ]]; then
    print_error "Failed to import server certificate to ACM"
    exit 1
fi

print_success "Server certificate imported: $SERVER_ARN"

print_info "Importing client CA certificate to ACM..."

CLIENT_CA_ARN=$(aws acm import-certificate \
    --certificate fileb://"$CA_CERT" \
    --private-key fileb://"$CA_KEY" \
    --region "$AWS_REGION" \
    --query 'CertificateArn' \
    --output text)

if [[ -z "$CLIENT_CA_ARN" ]]; then
    print_error "Failed to import client CA certificate to ACM"
    exit 1
fi

print_success "Client CA certificate imported: $CLIENT_CA_ARN"

# ------------------------------------------------------------------------------
# Calculate Expiration Date
# ------------------------------------------------------------------------------

print_info "Calculating expiration date..."

# Current date + validity days
if [[ "$OS_TYPE" == "macos" ]]; then
    # macOS date command
    EXPIRATION_DATE=$(date -u -v+${CERT_VALIDITY_DAYS}d +"%Y-%m-%dT%H:%M:%SZ")
else
    # GNU date command
    EXPIRATION_DATE=$(date -u -d "+${CERT_VALIDITY_DAYS} days" +"%Y-%m-%dT%H:%M:%SZ")
fi

print_info "Certificate expires: $EXPIRATION_DATE"

# ------------------------------------------------------------------------------
# Encode Certificates as Base64
# ------------------------------------------------------------------------------

print_info "Encoding certificates to base64..."

SERVER_CERT_B64=$(base64 < "$SERVER_CERT" | tr -d '\n')
SERVER_KEY_B64=$(base64 < "$SERVER_KEY" | tr -d '\n')
CA_CERT_B64=$(base64 < "$CA_CERT" | tr -d '\n')
CA_KEY_B64=$(base64 < "$CA_KEY" | tr -d '\n')

print_success "Certificates encoded"

# ------------------------------------------------------------------------------
# Generate Output JSON
# ------------------------------------------------------------------------------

print_info "Generating output JSON..."

# Create output directory if it doesn't exist
OUTPUT_DIR=$(dirname "$OUTPUT_JSON")
mkdir -p "$OUTPUT_DIR"

cat > "$OUTPUT_JSON" <<EOF
{
  "server_arn": "$SERVER_ARN",
  "client_ca_arn": "$CLIENT_CA_ARN",
  "expiration_date": "$EXPIRATION_DATE",
  "server_cert_pem": "$SERVER_CERT_B64",
  "server_key_pem": "$SERVER_KEY_B64",
  "client_ca_cert_pem": "$CA_CERT_B64",
  "client_ca_key_pem": "$CA_KEY_B64"
}
EOF

print_success "Output JSON written to: $OUTPUT_JSON"

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------

echo ""
print_success "=========================================="
print_success "VPN Certificate Generation Complete"
print_success "=========================================="
echo ""
print_info "Server Certificate ARN: $SERVER_ARN"
print_info "Client CA ARN: $CLIENT_CA_ARN"
print_info "Expiration Date: $EXPIRATION_DATE"
print_info "Output File: $OUTPUT_JSON"
echo ""
print_warn "Note: Certificate files will be automatically cleaned up on exit"
echo ""
