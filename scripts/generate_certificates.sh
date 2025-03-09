#!/usr/bin/env bash
# generate_certificates.sh - Generates self-signed SSL certificates for local development
#
# This script generates self-signed SSL certificates for local development environments.
# It supports generating certificates for specific domains or a default certificate.

set -e
set -o pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Function to display usage information
usage() {
    echo -e "${BLUE}Usage:${NC} $0 [options]"
    echo
    echo "Options:"
    echo "  -d, --domain DOMAIN   Generate certificate for specific domain(s)"
    echo "                        Can be specified multiple times for multiple domains"
    echo "  -y, --yes             Skip confirmation prompts"
    echo "  -h, --help            Display this help message"
    echo
    echo "Examples:"
    echo "  $0                    Generate default certificate for localhost"
    echo "  $0 -d example.com     Generate certificate for example.com"
    echo "  $0 -d example.com -d api.example.com"
    echo "                        Generate certificate with multiple domains"
    echo
    exit 1
}

# Default values
SKIP_CONFIRMATION=false
DOMAINS=()

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain)
            DOMAINS+=("$2")
            shift 2
            ;;
        -y|--yes)
            SKIP_CONFIRMATION=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Error:${NC} Unknown option $1"
            usage
            ;;
    esac
done

echo -e "${BLUE}=== uServer-Web Certificate Generator ===${NC}"
echo

# Check if OpenSSL is installed
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}Error:${NC} OpenSSL is not installed. Please install it and try again."
    exit 1
fi

# Ensure certificates directory exists
CERTS_DIR="$PROJECT_ROOT/certs"
mkdir -p "$CERTS_DIR"

# Confirmation prompt if not skipped
if [ "$SKIP_CONFIRMATION" = false ]; then
    echo -e "${YELLOW}This script will generate self-signed SSL certificates for local development.${NC}"
    echo -e "${YELLOW}These certificates are NOT suitable for production use.${NC}"
    echo
    read -p "Continue? (y/n): " -n 1 -r
    echo    # Move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborting.${NC}"
        exit 0
    fi
fi

# Generate certificates
if [ ${#DOMAINS[@]} -eq 0 ]; then
    # Generate default certificate for localhost
    echo -e "${YELLOW}Generating default certificate for localhost...${NC}"

    openssl req -x509 -out "$CERTS_DIR/default.crt" -keyout "$CERTS_DIR/default.key" \
        -newkey rsa:2048 -nodes -sha256 \
        -subj '/CN=localhost' -extensions EXT -config <( \
        printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")

    echo -e "${GREEN}Successfully generated default certificate:${NC}"
    echo -e "  - ${BLUE}$CERTS_DIR/default.crt${NC}"
    echo -e "  - ${BLUE}$CERTS_DIR/default.key${NC}"
else
    # Generate certificate for specified domains
    DOMAIN_PRIMARY="${DOMAINS[0]}"
    DOMAIN_FILE_NAME=$(echo "$DOMAIN_PRIMARY" | sed 's/[^a-zA-Z0-9]/_/g')

    echo -e "${YELLOW}Generating certificate for ${#DOMAINS[@]} domain(s):${NC}"
    for domain in "${DOMAINS[@]}"; do
        echo -e "  - ${BLUE}$domain${NC}"
    done

    # Create SAN configuration
    SAN="DNS:${DOMAINS[0]}"
    for ((i=1; i<${#DOMAINS[@]}; i++)); do
        SAN="$SAN,DNS:${DOMAINS[$i]}"
    done

    openssl req -x509 -out "$CERTS_DIR/$DOMAIN_FILE_NAME.crt" -keyout "$CERTS_DIR/$DOMAIN_FILE_NAME.key" \
        -newkey rsa:2048 -nodes -sha256 \
        -subj "/CN=$DOMAIN_PRIMARY" -extensions EXT -config <( \
        printf "[dn]\nCN=$DOMAIN_PRIMARY\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=$SAN\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")

    echo -e "${GREEN}Successfully generated certificate for $DOMAIN_PRIMARY:${NC}"
    echo -e "  - ${BLUE}$CERTS_DIR/$DOMAIN_FILE_NAME.crt${NC}"
    echo -e "  - ${BLUE}$CERTS_DIR/$DOMAIN_FILE_NAME.key${NC}"
fi

echo
echo -e "${GREEN}Certificate generation complete!${NC}"
echo -e "You may need to restart your services with ${BLUE}docker-compose down && docker-compose up --build${NC}"
