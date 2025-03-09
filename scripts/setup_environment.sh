#!/usr/bin/env bash
# setup_environment.sh - Automates the setup of environment files for uServer-Web
#
# This script copies environment templates and helps configure them for local development.
# It also adds necessary entries to the hosts file if requested.

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

# Default values
MONITOR_HOST="monitor.userver.lan"
WHOAMI_HOST="whoami.userver.lan"
UPDATE_HOSTS=false

# Function to display usage information
usage() {
    echo -e "${BLUE}Usage:${NC} $0 [options]"
    echo
    echo "Options:"
    echo "  -m, --monitor-host HOST   Set the monitor virtual host (default: $MONITOR_HOST)"
    echo "  -w, --whoami-host HOST    Set the whoami virtual host (default: $WHOAMI_HOST)"
    echo "  -u, --update-hosts        Update /etc/hosts file with the virtual hosts"
    echo "  -h, --help                Display this help message"
    echo
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--monitor-host)
            MONITOR_HOST="$2"
            shift 2
            ;;
        -w|--whoami-host)
            WHOAMI_HOST="$2"
            shift 2
            ;;
        -u|--update-hosts)
            UPDATE_HOSTS=true
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

echo -e "${BLUE}=== uServer-Web Environment Setup ===${NC}"
echo

# Copy environment templates
echo -e "${YELLOW}Copying environment templates...${NC}"

# Function to copy and configure environment files
setup_env_file() {
    local template_path="$1"
    local env_path="$2"
    local service_name="$3"
    local host_value="$4"

    if [ -f "$env_path" ]; then
        echo -e "${YELLOW}$env_path already exists. Skipping...${NC}"
    else
        cp "$template_path" "$env_path"
        echo -e "${GREEN}Created $env_path${NC}"

        # If host value is provided, update the VIRTUAL_HOST in the env file
        if [ -n "$host_value" ]; then
            sed -i "s/VIRTUAL_HOST=/VIRTUAL_HOST=$host_value/g" "$env_path"
            sed -i "s/LETSENCRYPT_HOST=/LETSENCRYPT_HOST=$host_value/g" "$env_path"
            echo -e "${GREEN}Set $service_name virtual host to $host_value${NC}"
        fi
    fi
}

# Setup each environment file
setup_env_file "$PROJECT_ROOT/letsencrypt/.env.template" "$PROJECT_ROOT/letsencrypt/.env" "letsencrypt" ""
setup_env_file "$PROJECT_ROOT/monitor/.env.template" "$PROJECT_ROOT/monitor/.env" "monitor" "$MONITOR_HOST"
setup_env_file "$PROJECT_ROOT/nginx-proxy/.env.template" "$PROJECT_ROOT/nginx-proxy/.env" "nginx-proxy" ""
setup_env_file "$PROJECT_ROOT/whoami/.env.template" "$PROJECT_ROOT/whoami/.env" "whoami" "$WHOAMI_HOST"

echo

# Update hosts file if requested
if [ "$UPDATE_HOSTS" = true ]; then
    echo -e "${YELLOW}Updating /etc/hosts file...${NC}"

    # Check if running as root
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}Error: Updating hosts file requires root privileges.${NC}"
        echo -e "Please run the following commands manually:"
        echo -e "${BLUE}sudo echo \"127.0.0.1 $MONITOR_HOST\" | sudo tee -a /etc/hosts${NC}"
        echo -e "${BLUE}sudo echo \"127.0.0.1 $WHOAMI_HOST\" | sudo tee -a /etc/hosts${NC}"
    else
        # Check if entries already exist
        if grep -q "$MONITOR_HOST" /etc/hosts; then
            echo -e "${YELLOW}$MONITOR_HOST already in /etc/hosts. Skipping...${NC}"
        else
            echo "127.0.0.1 $MONITOR_HOST" | tee -a /etc/hosts > /dev/null
            echo -e "${GREEN}Added $MONITOR_HOST to /etc/hosts${NC}"
        fi

        if grep -q "$WHOAMI_HOST" /etc/hosts; then
            echo -e "${YELLOW}$WHOAMI_HOST already in /etc/hosts. Skipping...${NC}"
        else
            echo "127.0.0.1 $WHOAMI_HOST" | tee -a /etc/hosts > /dev/null
            echo -e "${GREEN}Added $WHOAMI_HOST to /etc/hosts${NC}"
        fi
    fi
    echo
fi

echo -e "${GREEN}Environment setup complete!${NC}"
echo -e "You can now run ${BLUE}docker-compose up --build${NC} to start the services."
