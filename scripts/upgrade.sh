#!/usr/bin/env bash
# upgrade.sh - Upgrade the uServer-Web stack to the latest version
#
# This script helps with upgrading the uServer-Web stack by pulling the latest
# images, backing up the current configuration, and restarting the services.

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
    echo -e "${BLUE}uServer-Web Upgrade Tool${NC}"
    echo
    echo -e "${BLUE}Usage:${NC} $0 [options]"
    echo
    echo "Options:"
    echo "  -b, --backup          Create a backup before upgrading"
    echo "  -p, --pull-only       Only pull the latest images without restarting"
    echo "  -f, --force           Force upgrade without confirmation"
    echo "  -h, --help            Display this help message"
    echo
    exit 1
}

# Default values
CREATE_BACKUP=false
PULL_ONLY=false
FORCE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--backup)
            CREATE_BACKUP=true
            shift
            ;;
        -p|--pull-only)
            PULL_ONLY=true
            shift
            ;;
        -f|--force)
            FORCE=true
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

echo -e "${BLUE}=== uServer-Web Upgrade ===${NC}"
echo

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}Error:${NC} Docker Compose is not installed. Please install it and try again."
    exit 1
fi

# Confirmation prompt if not forced
if [ "$FORCE" = false ]; then
    echo -e "${YELLOW}This will upgrade the uServer-Web stack to the latest version.${NC}"
    echo -e "${YELLOW}It is recommended to create a backup before upgrading.${NC}"
    echo
    read -p "Continue with the upgrade? (y/n): " -n 1 -r
    echo    # Move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Upgrade aborted.${NC}"
        exit 0
    fi
fi

# Create backup if requested
if [ "$CREATE_BACKUP" = true ]; then
    echo -e "${YELLOW}Creating backup...${NC}"

    # Create backup directory
    BACKUP_DIR="$PROJECT_ROOT/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    # Backup environment files
    echo -e "Backing up environment files..."
    mkdir -p "$BACKUP_DIR/env"
    [ -f "$PROJECT_ROOT/letsencrypt/.env" ] && cp "$PROJECT_ROOT/letsencrypt/.env" "$BACKUP_DIR/env/letsencrypt.env"
    [ -f "$PROJECT_ROOT/monitor/.env" ] && cp "$PROJECT_ROOT/monitor/.env" "$BACKUP_DIR/env/monitor.env"
    [ -f "$PROJECT_ROOT/nginx-proxy/.env" ] && cp "$PROJECT_ROOT/nginx-proxy/.env" "$BACKUP_DIR/env/nginx-proxy.env"
    [ -f "$PROJECT_ROOT/whoami/.env" ] && cp "$PROJECT_ROOT/whoami/.env" "$BACKUP_DIR/env/whoami.env"

    # Backup certificates
    echo -e "Backing up certificates..."
    if [ -d "$PROJECT_ROOT/certs" ] && [ "$(ls -A "$PROJECT_ROOT/certs")" ]; then
        mkdir -p "$BACKUP_DIR/certs"
        cp -r "$PROJECT_ROOT/certs"/* "$BACKUP_DIR/certs/"
    fi

    # Backup docker-compose override file if it exists
    if [ -f "$PROJECT_ROOT/docker-compose.override.yml" ]; then
        echo -e "Backing up docker-compose.override.yml..."
        cp "$PROJECT_ROOT/docker-compose.override.yml" "$BACKUP_DIR/"
    fi

    echo -e "${GREEN}Backup created at $BACKUP_DIR${NC}"
    echo
fi

# Pull latest images
echo -e "${YELLOW}Pulling latest images...${NC}"
cd "$PROJECT_ROOT"
docker-compose pull

echo -e "${GREEN}Images updated successfully!${NC}"

# Restart services if not pull-only
if [ "$PULL_ONLY" = false ]; then
    echo -e "${YELLOW}Restarting services...${NC}"
    cd "$PROJECT_ROOT"
    docker-compose down
    docker-compose up -d
    echo -e "${GREEN}Services restarted successfully!${NC}"
else
    echo -e "${YELLOW}Images have been pulled, but services were not restarted.${NC}"
    echo -e "To restart the services, run: ${BLUE}./scripts/userver.sh restart${NC}"
fi

echo
echo -e "${GREEN}Upgrade completed successfully!${NC}"
