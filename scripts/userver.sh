#!/usr/bin/env bash
# userver.sh - Main entry point for uServer-Web management
#
# This script provides a unified interface for managing the uServer-Web stack,
# including setup, certificate management, testing, and service control.

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
    echo -e "${BLUE}uServer-Web Management Tool${NC}"
    echo
    echo -e "${BLUE}Usage:${NC} $0 [command] [options]"
    echo
    echo "Commands:"
    echo "  setup                Set up environment files"
    echo "  certs                Manage SSL certificates"
    echo "  test                 Run tests"
    echo "  start                Start services"
    echo "  stop                 Stop services"
    echo "  restart              Restart services"
    echo "  status               Show service status"
    echo "  upgrade              Upgrade the stack to the latest version"
    echo "  help                 Show this help message"
    echo
    echo "Run '$0 [command] --help' for more information on a command."
    echo
    exit 1
}

# Function to display setup command help
setup_usage() {
    echo -e "${BLUE}uServer-Web Setup${NC}"
    echo
    echo -e "${BLUE}Usage:${NC} $0 setup [options]"
    echo
    echo "Options:"
    echo "  -m, --monitor-host HOST   Set the monitor virtual host (default: monitor.userver.lan)"
    echo "  -w, --whoami-host HOST    Set the whoami virtual host (default: whoami.userver.lan)"
    echo "  -u, --update-hosts        Update /etc/hosts file with the virtual hosts"
    echo "  -h, --help                Display this help message"
    echo
    exit 1
}

# Function to display certificates command help
certs_usage() {
    echo -e "${BLUE}uServer-Web Certificate Management${NC}"
    echo
    echo -e "${BLUE}Usage:${NC} $0 certs [action] [options]"
    echo
    echo "Actions:"
    echo "  generate             Generate new certificates"
    echo "  reset                Remove existing certificates"
    echo
    echo "Options for 'generate':"
    echo "  -d, --domain DOMAIN   Generate certificate for specific domain(s)"
    echo "                        Can be specified multiple times for multiple domains"
    echo "  -y, --yes             Skip confirmation prompts"
    echo "  -h, --help            Display this help message"
    echo
    echo "Options for 'reset':"
    echo "  -y, --yes             Skip confirmation prompts"
    echo "  -h, --help            Display this help message"
    echo
    exit 1
}

# Function to display test command help
test_usage() {
    echo -e "${BLUE}uServer-Web Testing${NC}"
    echo
    echo -e "${BLUE}Usage:${NC} $0 test [options]"
    echo
    echo "Options:"
    echo "  -u, --unit-tests       Run unit tests only"
    echo "  -i, --integration      Run integration tests only"
    echo "  -e, --e2e              Run end-to-end tests only"
    echo "  -s, --shellcheck       Run ShellCheck tests only"
    echo "  -a, --all              Run all tests (default)"
    echo "  -h, --help             Display this help message"
    echo
    exit 1
}

# Function to display service control command help
service_usage() {
    echo -e "${BLUE}uServer-Web Service Control${NC}"
    echo
    echo -e "${BLUE}Usage:${NC} $0 (start|stop|restart|status) [options]"
    echo
    echo "Options:"
    echo "  -d, --detach           Run containers in the background (for start/restart)"
    echo "  -b, --build            Build images before starting containers (for start/restart)"
    echo "  -h, --help             Display this help message"
    echo
    exit 1
}

# Function to display upgrade command help
upgrade_usage() {
    echo -e "${BLUE}uServer-Web Upgrade${NC}"
    echo
    echo -e "${BLUE}Usage:${NC} $0 upgrade [options]"
    echo
    echo "Options:"
    echo "  -b, --backup          Create a backup before upgrading"
    echo "  -p, --pull-only       Only pull the latest images without restarting"
    echo "  -f, --force           Force upgrade without confirmation"
    echo "  -h, --help            Display this help message"
    echo
    exit 1
}

# Check if a command was provided
if [ $# -eq 0 ]; then
    usage
fi

# Parse command
COMMAND="$1"
shift

# Process commands
case "$COMMAND" in
    setup)
        # Display help if requested
        if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
            setup_usage
        fi

        # Execute setup script with all arguments
        "$SCRIPT_DIR/setup_environment.sh" "$@"
        ;;

    certs)
        # Check if an action was provided
        if [ $# -eq 0 ]; then
            certs_usage
        fi

        # Parse action
        CERTS_ACTION="$1"
        shift

        case "$CERTS_ACTION" in
            generate)
                # Display help if requested
                if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
                    certs_usage
                fi

                # Execute generate certificates script with all arguments
                "$SCRIPT_DIR/generate_certificates.sh" "$@"
                ;;

            reset)
                # Display help if requested
                if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
                    certs_usage
                fi

                # Execute reset certificates script with all arguments
                "$SCRIPT_DIR/reset_certificates.sh" "$@"
                ;;

            *)
                echo -e "${RED}Error:${NC} Unknown certificates action: $CERTS_ACTION"
                certs_usage
                ;;
        esac
        ;;

    test)
        # Display help if requested
        if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
            test_usage
        fi

        # Execute test script with all arguments
        "$SCRIPT_DIR/run_tests.sh" "$@"
        ;;

    start|stop|restart|status)
        # Service control options
        DETACH=""
        BUILD=""

        # Parse options
        while [[ $# -gt 0 ]]; do
            case $1 in
                -d|--detach)
                    DETACH="--detach"
                    shift
                    ;;
                -b|--build)
                    BUILD="--build"
                    shift
                    ;;
                -h|--help)
                    service_usage
                    ;;
                *)
                    echo -e "${RED}Error:${NC} Unknown option $1"
                    service_usage
                    ;;
            esac
        done

        # Execute docker-compose command based on the requested action
        cd "$PROJECT_ROOT"

        case "$COMMAND" in
            start)
                echo -e "${BLUE}Starting uServer-Web services...${NC}"
                docker-compose up $BUILD $DETACH
                ;;

            stop)
                echo -e "${BLUE}Stopping uServer-Web services...${NC}"
                docker-compose down
                ;;

            restart)
                echo -e "${BLUE}Restarting uServer-Web services...${NC}"
                docker-compose down
                docker-compose up $BUILD $DETACH
                ;;

            status)
                echo -e "${BLUE}uServer-Web services status:${NC}"
                docker-compose ps
                ;;
        esac
        ;;

    upgrade)
        # Display help if requested
        if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
            upgrade_usage
        fi

        # Execute upgrade script with all arguments
        "$SCRIPT_DIR/upgrade.sh" "$@"
        ;;

    help)
        usage
        ;;

    *)
        echo -e "${RED}Error:${NC} Unknown command: $COMMAND"
        usage
        ;;
esac
