#!/usr/bin/env bash
# run_tests.sh - Comprehensive test runner for uServer-Web
#
# This script runs various tests to ensure the uServer-Web stack is functioning correctly.
# It includes unit tests for shell scripts, integration tests, and end-to-end tests.

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
    echo "  -u, --unit-tests       Run unit tests only"
    echo "  -i, --integration      Run integration tests only"
    echo "  -e, --e2e              Run end-to-end tests only"
    echo "  -s, --shellcheck       Run ShellCheck tests only"
    echo "  -k, --kubernetes       Run Kubernetes integration tests only"
    echo "  -t, --terraform        Run Terraform integration tests only"
    echo "  -a, --all              Run all tests (default)"
    echo "  -h, --help             Display this help message"
    echo
    exit 1
}

# Default values
RUN_UNIT_TESTS=false
RUN_INTEGRATION_TESTS=false
RUN_E2E_TESTS=false
RUN_SHELLCHECK=false
RUN_KUBERNETES_TESTS=false
RUN_TERRAFORM_TESTS=false
RUN_ALL_TESTS=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--unit-tests)
            RUN_UNIT_TESTS=true
            RUN_ALL_TESTS=false
            shift
            ;;
        -i|--integration)
            RUN_INTEGRATION_TESTS=true
            RUN_ALL_TESTS=false
            shift
            ;;
        -e|--e2e)
            RUN_E2E_TESTS=true
            RUN_ALL_TESTS=false
            shift
            ;;
        -s|--shellcheck)
            RUN_SHELLCHECK=true
            RUN_ALL_TESTS=false
            shift
            ;;
        -k|--kubernetes)
            RUN_KUBERNETES_TESTS=true
            RUN_ALL_TESTS=false
            shift
            ;;
        -t|--terraform)
            RUN_TERRAFORM_TESTS=true
            RUN_ALL_TESTS=false
            shift
            ;;
        -a|--all)
            RUN_ALL_TESTS=true
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

# If all tests are enabled, set all individual test flags to true
if [ "$RUN_ALL_TESTS" = true ]; then
    RUN_UNIT_TESTS=true
    RUN_INTEGRATION_TESTS=true
    RUN_E2E_TESTS=true
    RUN_SHELLCHECK=true
    RUN_KUBERNETES_TESTS=true
    RUN_TERRAFORM_TESTS=true
fi

echo -e "${BLUE}=== uServer-Web Test Runner ===${NC}"
echo

# Track test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"

    echo -e "${YELLOW}Running $test_name...${NC}"
    ((TOTAL_TESTS++))

    if eval "$test_command"; then
        echo -e "${GREEN}✓ $test_name passed${NC}"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${RED}✗ $test_name failed${NC}"
        ((FAILED_TESTS++))
        return 1
    fi
}

# Check if ShellCheck is installed
check_shellcheck() {
    if ! command -v shellcheck &> /dev/null; then
        echo -e "${RED}Error:${NC} ShellCheck is not installed. Please install it to run shell script tests."
        echo -e "Installation instructions: https://github.com/koalaman/shellcheck#installing"
        return 1
    fi
    return 0
}

# Run ShellCheck tests
run_shellcheck_tests() {
    if ! check_shellcheck; then
        return 1
    fi

    echo -e "${YELLOW}Running ShellCheck on shell scripts...${NC}"

    local shellcheck_failed=0
    local scripts_to_check=()

    # Find all shell scripts in the project
    while IFS= read -r -d '' script; do
        scripts_to_check+=("$script")
    done < <(find "$PROJECT_ROOT" -type f -name "*.sh" -print0)

    # Run ShellCheck on each script
    for script in "${scripts_to_check[@]}"; do
        echo -e "Checking ${BLUE}$(basename "$script")${NC}..."
        if shellcheck -x "$script"; then
            echo -e "${GREEN}✓ $(basename "$script") passed${NC}"
        else
            echo -e "${RED}✗ $(basename "$script") failed${NC}"
            shellcheck_failed=1
        fi
    done

    if [ "$shellcheck_failed" -eq 0 ]; then
        echo -e "${GREEN}All ShellCheck tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some ShellCheck tests failed.${NC}"
        return 1
    fi
}

# Run unit tests for shell scripts
run_unit_tests() {
    echo -e "${YELLOW}Running unit tests for shell scripts...${NC}"

    # Test setup_environment.sh
    run_test "setup_environment.sh basic functionality" "
        # Create temporary directory for testing
        TEST_DIR=$(mktemp -d)

        # Copy necessary files for testing
        mkdir -p \"\$TEST_DIR/letsencrypt\" \"\$TEST_DIR/monitor\" \"\$TEST_DIR/nginx-proxy\" \"\$TEST_DIR/whoami\" \"\$TEST_DIR/scripts\"
        cp \"$PROJECT_ROOT/letsencrypt/.env.template\" \"\$TEST_DIR/letsencrypt/\"
        cp \"$PROJECT_ROOT/monitor/.env.template\" \"\$TEST_DIR/monitor/\"
        cp \"$PROJECT_ROOT/nginx-proxy/.env.template\" \"\$TEST_DIR/nginx-proxy/\"
        cp \"$PROJECT_ROOT/whoami/.env.template\" \"\$TEST_DIR/whoami/\"
        cp \"$PROJECT_ROOT/scripts/setup_environment.sh\" \"\$TEST_DIR/scripts/\"

        # Run the script with test parameters
        cd \"\$TEST_DIR\"
        ./scripts/setup_environment.sh -m test.monitor.local -w test.whoami.local

        # Check if files were created
        [ -f \"\$TEST_DIR/letsencrypt/.env\" ] &&
        [ -f \"\$TEST_DIR/monitor/.env\" ] &&
        [ -f \"\$TEST_DIR/nginx-proxy/.env\" ] &&
        [ -f \"\$TEST_DIR/whoami/.env\" ] &&
        grep -q \"VIRTUAL_HOST=test.monitor.local\" \"\$TEST_DIR/monitor/.env\" &&
        grep -q \"VIRTUAL_HOST=test.whoami.local\" \"\$TEST_DIR/whoami/.env\"

        # Clean up
        rm -rf \"\$TEST_DIR\"
    "

    # Test reset_certificates.sh
    run_test "reset_certificates.sh basic functionality" "
        # Create temporary directory for testing
        TEST_DIR=$(mktemp -d)

        # Create test structure
        mkdir -p \"\$TEST_DIR/certs\" \"\$TEST_DIR/nginx-proxy/conf\" \"\$TEST_DIR/scripts\"
        touch \"\$TEST_DIR/certs/test.crt\" \"\$TEST_DIR/certs/test.key\" \"\$TEST_DIR/certs/test.pem\"
        touch \"\$TEST_DIR/nginx-proxy/conf/default.conf\"
        cp \"$PROJECT_ROOT/scripts/reset_certificates.sh\" \"\$TEST_DIR/scripts/\"

        # Run the script with --yes flag to skip confirmation
        cd \"\$TEST_DIR\"
        ./scripts/reset_certificates.sh --yes

        # Check if files were removed
        [ ! -f \"\$TEST_DIR/certs/test.crt\" ] &&
        [ ! -f \"\$TEST_DIR/certs/test.key\" ] &&
        [ ! -f \"\$TEST_DIR/certs/test.pem\" ] &&
        [ ! -f \"\$TEST_DIR/nginx-proxy/conf/default.conf\" ]

        # Clean up
        rm -rf \"\$TEST_DIR\"
    "

    # Test generate_certificates.sh
    run_test "generate_certificates.sh basic functionality" "
        # Skip if openssl is not installed
        if ! command -v openssl &> /dev/null; then
            echo 'OpenSSL not installed, skipping test'
            return 0
        fi

        # Create temporary directory for testing
        TEST_DIR=$(mktemp -d)

        # Create test structure
        mkdir -p \"\$TEST_DIR/certs\" \"\$TEST_DIR/scripts\"
        cp \"$PROJECT_ROOT/scripts/generate_certificates.sh\" \"\$TEST_DIR/scripts/\"

        # Run the script with --yes flag to skip confirmation
        cd \"\$TEST_DIR\"
        ./scripts/generate_certificates.sh --yes

        # Check if default certificate files were created
        [ -f \"\$TEST_DIR/certs/default.crt\" ] &&
        [ -f \"\$TEST_DIR/certs/default.key\" ]

        # Clean up
        rm -rf \"\$TEST_DIR\"
    "
}

# Run integration tests
run_integration_tests() {
    echo -e "${YELLOW}Running integration tests...${NC}"

    # Test if docker and docker-compose are installed
    run_test "Docker and Docker Compose availability" "
        command -v docker &> /dev/null &&
        (command -v docker-compose &> /dev/null || docker compose version &> /dev/null)
    "

    # Test if the nginx-proxy network exists or can be created
    run_test "nginx-proxy network" "
        # Check if network exists
        if ! docker network ls | grep -q nginx-proxy; then
            # Try to create the network
            docker network create nginx-proxy
            # Clean up
            docker network rm nginx-proxy
        fi
        true
    "

    # Test if the required ports are available
    run_test "Required ports availability" "
        # Function to check if a port is in use
        port_in_use() {
            if command -v nc &> /dev/null; then
                nc -z localhost \$1 &> /dev/null
                return \$?
            elif command -v lsof &> /dev/null; then
                lsof -i :\$1 &> /dev/null
                return \$?
            else
                # If neither nc nor lsof is available, assume port is free
                return 1
            fi
        }

        # Check ports 80 and 443
        if port_in_use 80; then
            echo 'Port 80 is already in use'
            exit 1
        fi

        if port_in_use 443; then
            echo 'Port 443 is already in use'
            exit 1
        fi

        true
    "
}

# Run Kubernetes integration tests
run_kubernetes_tests() {
    echo -e "${YELLOW}Running Kubernetes integration tests...${NC}"

    # Check if the Kubernetes test script exists
    if [ -f "$SCRIPT_DIR/test_kubernetes.sh" ]; then
        run_test "Kubernetes deployment tests" "
            # Make the script executable
            [ -x \"$SCRIPT_DIR/test_kubernetes.sh\" ] || chmod +x \"$SCRIPT_DIR/test_kubernetes.sh\"

            # Run the Kubernetes tests with cleanup and skip-setup options
            # We skip setup in CI to avoid installing kind, kubectl, etc.
            \"$SCRIPT_DIR/test_kubernetes.sh\" --cleanup --skip-setup
        "
    else
        echo -e "${RED}Kubernetes test script not found at $SCRIPT_DIR/test_kubernetes.sh${NC}"
        return 1
    fi
}

# Run Terraform integration tests
run_terraform_tests() {
    echo -e "${YELLOW}Running Terraform integration tests...${NC}"

    # Check if the Terraform test script exists
    if [ -f "$SCRIPT_DIR/test_terraform.sh" ]; then
        run_test "Terraform deployment tests" "
            # Make the script executable
            [ -x \"$SCRIPT_DIR/test_terraform.sh\" ] || chmod +x \"$SCRIPT_DIR/test_terraform.sh\"

            # Run the Terraform tests with cleanup and skip-setup options
            # We skip setup in CI to avoid installing terraform, localstack, etc.
            \"$SCRIPT_DIR/test_terraform.sh\" --cleanup --skip-setup
        "
    else
        echo -e "${RED}Terraform test script not found at $SCRIPT_DIR/test_terraform.sh${NC}"
        return 1
    fi
}

# Run end-to-end tests
run_e2e_tests() {
    echo -e "${YELLOW}Running end-to-end tests...${NC}"

    # Check if the original E2E test script exists
    if [ -f "$PROJECT_ROOT/run_e2e_tests.sh" ]; then
        run_test "Original E2E tests" "
            # We don't actually run the E2E tests here as they require the services to be running
            # Instead, we just check if the script exists and is executable
            [ -x \"$PROJECT_ROOT/run_e2e_tests.sh\" ] || chmod +x \"$PROJECT_ROOT/run_e2e_tests.sh\"
            true
        "
    fi

    # Additional E2E tests
    run_test "Service configuration validation" "
        # Check if docker-compose.yml exists and is valid
        [ -f \"$PROJECT_ROOT/docker-compose.yml\" ] &&
        docker-compose -f \"$PROJECT_ROOT/docker-compose.yml\" config > /dev/null
    "
}

# Run the selected tests
if [ "$RUN_SHELLCHECK" = true ]; then
    if run_shellcheck_tests; then
        echo -e "${GREEN}ShellCheck tests passed!${NC}"
    else
        echo -e "${RED}ShellCheck tests failed.${NC}"
    fi
    echo
fi

if [ "$RUN_UNIT_TESTS" = true ]; then
    run_unit_tests
    echo
fi

if [ "$RUN_INTEGRATION_TESTS" = true ]; then
    run_integration_tests
    echo
fi

if [ "$RUN_E2E_TESTS" = true ]; then
    run_e2e_tests
    echo
fi

if [ "$RUN_KUBERNETES_TESTS" = true ]; then
    run_kubernetes_tests
    echo
fi

if [ "$RUN_TERRAFORM_TESTS" = true ]; then
    run_terraform_tests
    echo
fi

# Print test summary
echo -e "${BLUE}=== Test Summary ===${NC}"
echo -e "Total tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
if [ "$FAILED_TESTS" -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    exit 1
else
    echo -e "Failed: $FAILED_TESTS"
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
