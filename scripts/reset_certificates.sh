#!/usr/bin/env bash
# reset_certificates.sh - Safely removes SSL certificates and nginx configuration
#
# This script provides a safe way to remove SSL certificates and nginx configuration
# for a fresh start. It includes confirmation prompts and error handling.

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
    echo "  -y, --yes       Skip confirmation prompts"
    echo "  -h, --help      Display this help message"
    echo
    exit 1
}

# Default values
SKIP_CONFIRMATION=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
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

echo -e "${BLUE}=== uServer-Web Certificate Reset ===${NC}"
echo

# Confirmation prompt if not skipped
if [ "$SKIP_CONFIRMATION" = false ]; then
    echo -e "${RED}WARNING:${NC} THIS PROCESS WILL DELETE THE EXISTING CERTIFICATES FOR EVERY HOST!"
    echo -e "${RED}WARNING:${NC} THIS IS IRREVERSIBLE!"
    echo
    echo -e "Are you sure you want to continue? (LAST CHANCE!)"
    read -p "Type 'Y' to continue or any other key to abort: " -n 1 -r
    echo    # Move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborting.${NC}"
        exit 0
    fi
fi

echo -e "${YELLOW}Removing SSL certificates...${NC}"

# Check if certificates directory exists
if [ ! -d "$PROJECT_ROOT/certs" ]; then
    echo -e "${RED}Error:${NC} Certificates directory not found at $PROJECT_ROOT/certs"
    exit 1
fi

# Remove certificates with error handling
CERT_COUNT=0
for cert in "$PROJECT_ROOT"/certs/*.{crt,key,pem}; do
    if [ -f "$cert" ]; then
        rm -f "$cert"
        ((CERT_COUNT++))
    fi
done

if [ $CERT_COUNT -eq 0 ]; then
    echo -e "${YELLOW}No certificates found to remove.${NC}"
else
    echo -e "${GREEN}Successfully removed $CERT_COUNT certificate files.${NC}"
fi

echo -e "${YELLOW}Removing nginx configuration...${NC}"

# Check if nginx configuration exists
NGINX_CONF="$PROJECT_ROOT/nginx-proxy/conf/default.conf"
if [ -f "$NGINX_CONF" ]; then
    rm -f "$NGINX_CONF"
    echo -e "${GREEN}Successfully removed nginx default configuration.${NC}"
else
    echo -e "${YELLOW}No nginx default configuration found to remove.${NC}"
fi

echo -e "${GREEN}Reset complete!${NC}"
echo -e "You can now restart the services with ${BLUE}docker-compose down && docker-compose up --build${NC}"
