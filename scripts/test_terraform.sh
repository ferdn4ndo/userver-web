#!/usr/bin/env bash
# test_terraform.sh - Integration tests for Terraform deployment
#
# This script tests the Terraform deployment of uServer-Web using Terraform's
# built-in testing capabilities and localstack for AWS service emulation.

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
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"

# Function to display usage information
usage() {
    echo -e "${BLUE}Terraform Integration Tests${NC}"
    echo
    echo -e "${BLUE}Usage:${NC} $0 [options]"
    echo
    echo "Options:"
    echo "  -c, --cleanup          Clean up the test environment after running tests"
    echo "  -k, --keep             Keep the test environment even if tests fail"
    echo "  -s, --skip-setup       Skip the setup phase (use existing localstack)"
    echo "  -h, --help             Display this help message"
    echo
    exit 1
}

# Default values
CLEANUP=true
KEEP_ON_FAILURE=false
SKIP_SETUP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--cleanup)
            CLEANUP=true
            shift
            ;;
        -k|--keep)
            KEEP_ON_FAILURE=true
            shift
            ;;
        -s|--skip-setup)
            SKIP_SETUP=true
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

echo -e "${BLUE}=== Terraform Integration Tests ===${NC}"
echo

# Check if required tools are installed
check_requirements() {
    echo -e "${YELLOW}Checking requirements...${NC}"

    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}Error:${NC} terraform is not installed. Please install it from https://www.terraform.io/downloads.html"
        exit 1
    fi

    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error:${NC} docker is not installed. Please install it from https://docs.docker.com/get-docker/"
        exit 1
    fi

    # Check if docker-compose is installed
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}Error:${NC} docker-compose is not installed. Please install it from https://docs.docker.com/compose/install/"
        exit 1
    fi

    # Check if aws-cli is installed
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}Error:${NC} aws-cli is not installed. Please install it from https://aws.amazon.com/cli/"
        exit 1
    fi

    echo -e "${GREEN}All requirements satisfied.${NC}"
    echo
}

# Start localstack
start_localstack() {
    echo -e "${YELLOW}Starting localstack...${NC}"

    # Create a docker-compose file for localstack
    cat <<EOF > /tmp/localstack-docker-compose.yml
version: '3.8'

services:
  localstack:
    container_name: userver-web-localstack
    image: localstack/localstack:latest
    ports:
      - "4566:4566"
    environment:
      - SERVICES=ec2,route53,iam,s3,cloudwatch
      - DEBUG=1
      - DATA_DIR=/tmp/localstack/data
    volumes:
      - /tmp/localstack:/tmp/localstack
      - /var/run/docker.sock:/var/run/docker.sock
EOF

    # Start localstack
    docker-compose -f /tmp/localstack-docker-compose.yml up -d

    # Wait for localstack to be ready
    echo -e "${YELLOW}Waiting for localstack to be ready...${NC}"
    until docker logs userver-web-localstack 2>&1 | grep -q "Ready."; do
        echo -n "."
        sleep 1
    done
    echo

    # Configure AWS CLI to use localstack
    aws configure set aws_access_key_id test
    aws configure set aws_secret_access_key test
    aws configure set region us-east-1
    aws configure set output json

    echo -e "${GREEN}Localstack started successfully.${NC}"
    echo
}

# Initialize Terraform
initialize_terraform() {
    echo -e "${YELLOW}Initializing Terraform...${NC}"

    # Create a test directory
    mkdir -p /tmp/userver-web-terraform-test
    cp -r "${TERRAFORM_DIR}"/* /tmp/userver-web-terraform-test/

    # Create a terraform.tfvars file
    cat <<EOF > /tmp/userver-web-terraform-test/terraform.tfvars
aws_region = "us-east-1"
key_name = "userver-web-test-key"
instance_type = "t2.micro"
monitor_domain = "monitor.test.local"
whoami_domain = "whoami.test.local"
ssh_allowed_cidr = "0.0.0.0/0"
EOF

    # Create a backend configuration for testing
    cat <<EOF > /tmp/userver-web-terraform-test/backend.tf
terraform {
  backend "local" {
    path = "/tmp/userver-web-terraform-test/terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
  access_key = "test"
  secret_key = "test"
  skip_credentials_validation = true
  skip_metadata_api_check = true
  skip_requesting_account_id = true

  endpoints {
    ec2 = "http://localhost:4566"
    route53 = "http://localhost:4566"
    iam = "http://localhost:4566"
    s3 = "http://localhost:4566"
    cloudwatch = "http://localhost:4566"
  }
}
EOF

    # Initialize Terraform
    cd /tmp/userver-web-terraform-test
    terraform init

    echo -e "${GREEN}Terraform initialized successfully.${NC}"
    echo
}

# Run Terraform plan
run_terraform_plan() {
    echo -e "${YELLOW}Running Terraform plan...${NC}"

    cd /tmp/userver-web-terraform-test
    terraform plan -out=tfplan

    echo -e "${GREEN}Terraform plan completed successfully.${NC}"
    echo
}

# Run Terraform apply
run_terraform_apply() {
    echo -e "${YELLOW}Running Terraform apply...${NC}"

    cd /tmp/userver-web-terraform-test
    terraform apply -auto-approve tfplan

    echo -e "${GREEN}Terraform apply completed successfully.${NC}"
    echo
}

# Run tests
run_tests() {
    echo -e "${YELLOW}Running tests...${NC}"

    cd /tmp/userver-web-terraform-test

    # Test 1: Check if the EC2 instance is created
    echo -e "${YELLOW}Test 1: Checking if the EC2 instance is created...${NC}"
    if aws --endpoint-url=http://localhost:4566 ec2 describe-instances --filters "Name=tag:Name,Values=userver-web" | grep -q "InstanceId"; then
        echo -e "${GREEN}Test 1 passed: EC2 instance is created.${NC}"
    else
        echo -e "${RED}Test 1 failed: EC2 instance is not created.${NC}"
        aws --endpoint-url=http://localhost:4566 ec2 describe-instances
        return 1
    fi

    # Test 2: Check if the security group is created
    echo -e "${YELLOW}Test 2: Checking if the security group is created...${NC}"
    if aws --endpoint-url=http://localhost:4566 ec2 describe-security-groups --filters "Name=group-name,Values=userver-web-sg" | grep -q "GroupId"; then
        echo -e "${GREEN}Test 2 passed: Security group is created.${NC}"
    else
        echo -e "${RED}Test 2 failed: Security group is not created.${NC}"
        aws --endpoint-url=http://localhost:4566 ec2 describe-security-groups
        return 1
    fi

    # Test 3: Check if the Route53 records are created
    echo -e "${YELLOW}Test 3: Checking if the Route53 records are created...${NC}"
    if aws --endpoint-url=http://localhost:4566 route53 list-hosted-zones | grep -q "userver-web"; then
        echo -e "${GREEN}Test 3 passed: Route53 hosted zone is created.${NC}"
    else
        echo -e "${RED}Test 3 failed: Route53 hosted zone is not created.${NC}"
        aws --endpoint-url=http://localhost:4566 route53 list-hosted-zones
        return 1
    fi

    # Test 4: Check if the Terraform outputs are correct
    echo -e "${YELLOW}Test 4: Checking if the Terraform outputs are correct...${NC}"
    if terraform output -json | grep -q "public_ip"; then
        echo -e "${GREEN}Test 4 passed: Terraform outputs are correct.${NC}"
    else
        echo -e "${RED}Test 4 failed: Terraform outputs are not correct.${NC}"
        terraform output -json
        return 1
    fi

    echo -e "${GREEN}All tests passed!${NC}"
    echo
    return 0
}

# Clean up
cleanup() {
    echo -e "${YELLOW}Cleaning up...${NC}"

    # Destroy Terraform resources
    cd /tmp/userver-web-terraform-test
    terraform destroy -auto-approve || true

    # Stop localstack
    docker-compose -f /tmp/localstack-docker-compose.yml down || true

    # Remove temporary files
    rm -rf /tmp/userver-web-terraform-test
    rm -f /tmp/localstack-docker-compose.yml

    echo -e "${GREEN}Cleanup completed.${NC}"
    echo
}

# Main function
main() {
    # Check requirements
    check_requirements

    # Set up the test environment
    if [ "$SKIP_SETUP" = false ]; then
        start_localstack
        initialize_terraform
        run_terraform_plan
        run_terraform_apply
    fi

    # Run tests
    if run_tests; then
        # Clean up if requested
        if [ "$CLEANUP" = true ]; then
            cleanup
        fi
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        # Clean up if not keeping on failure
        if [ "$KEEP_ON_FAILURE" = false ] && [ "$CLEANUP" = true ]; then
            cleanup
        fi
        echo -e "${RED}Tests failed!${NC}"
        exit 1
    fi
}

# Run the main function
main
