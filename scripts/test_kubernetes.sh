#!/usr/bin/env bash
# test_kubernetes.sh - Integration tests for Kubernetes deployment
#
# This script tests the Kubernetes deployment of uServer-Web using kind (Kubernetes in Docker)
# to create a local Kubernetes cluster and Helm to deploy the chart.

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
    echo -e "${BLUE}Kubernetes Integration Tests${NC}"
    echo
    echo -e "${BLUE}Usage:${NC} $0 [options]"
    echo
    echo "Options:"
    echo "  -c, --cleanup          Clean up the test environment after running tests"
    echo "  -k, --keep             Keep the test environment even if tests fail"
    echo "  -s, --skip-setup       Skip the setup phase (use existing cluster)"
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

echo -e "${BLUE}=== Kubernetes Integration Tests ===${NC}"
echo

# Check if required tools are installed
check_requirements() {
    echo -e "${YELLOW}Checking requirements...${NC}"

    # Check if kind is installed
    if ! command -v kind &> /dev/null; then
        echo -e "${RED}Error:${NC} kind is not installed. Please install it from https://kind.sigs.k8s.io/"
        exit 1
    fi

    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}Error:${NC} kubectl is not installed. Please install it from https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi

    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        echo -e "${RED}Error:${NC} helm is not installed. Please install it from https://helm.sh/docs/intro/install/"
        exit 1
    fi

    echo -e "${GREEN}All requirements satisfied.${NC}"
    echo
}

# Create a kind cluster
create_cluster() {
    echo -e "${YELLOW}Creating kind cluster...${NC}"

    # Create a kind configuration file
    cat <<EOF > /tmp/kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
EOF

    # Create the cluster
    kind create cluster --name userver-web-test --config=/tmp/kind-config.yaml

    # Wait for the cluster to be ready
    echo -e "${YELLOW}Waiting for the cluster to be ready...${NC}"
    kubectl wait --for=condition=Ready nodes --all --timeout=300s

    echo -e "${GREEN}Kind cluster created successfully.${NC}"
    echo
}

# Install NGINX Ingress Controller
install_ingress_controller() {
    echo -e "${YELLOW}Installing NGINX Ingress Controller...${NC}"

    # Install NGINX Ingress Controller
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

    # Wait for the ingress controller to be ready
    echo -e "${YELLOW}Waiting for the ingress controller to be ready...${NC}"
    kubectl wait --namespace ingress-nginx \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=300s

    echo -e "${GREEN}NGINX Ingress Controller installed successfully.${NC}"
    echo
}

# Install cert-manager
install_cert_manager() {
    echo -e "${YELLOW}Installing cert-manager...${NC}"

    # Add the Jetstack Helm repository
    helm repo add jetstack https://charts.jetstack.io
    helm repo update

    # Install cert-manager
    helm install \
      cert-manager jetstack/cert-manager \
      --namespace cert-manager \
      --create-namespace \
      --version v1.13.1 \
      --set installCRDs=true

    # Wait for cert-manager to be ready
    echo -e "${YELLOW}Waiting for cert-manager to be ready...${NC}"
    kubectl wait --namespace cert-manager \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/instance=cert-manager \
      --timeout=300s

    # Create a self-signed ClusterIssuer
    cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
EOF

    echo -e "${GREEN}cert-manager installed successfully.${NC}"
    echo
}

# Install the uServer-Web Helm chart
install_userver_web() {
    echo -e "${YELLOW}Installing uServer-Web Helm chart...${NC}"

    # Create a values file for testing
    cat <<EOF > /tmp/userver-web-values.yaml
global:
  domain:
    base: "test.local"
    monitor: "monitor"
    whoami: "whoami"
  tls:
    enabled: true
    certManager:
      enabled: true
      issuer: "selfsigned-issuer"

ingress:
  enabled: true
  className: "nginx"
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: "selfsigned-issuer"

nginxProxy:
  service:
    type: ClusterIP
EOF

    # Install the Helm chart
    helm install userver-web "${PROJECT_ROOT}/helm/userver-web" -f /tmp/userver-web-values.yaml

    # Wait for all pods to be ready
    echo -e "${YELLOW}Waiting for all pods to be ready...${NC}"
    kubectl wait --for=condition=ready pod --selector=app.kubernetes.io/instance=userver-web --timeout=300s

    echo -e "${GREEN}uServer-Web Helm chart installed successfully.${NC}"
    echo
}

# Run tests
run_tests() {
    echo -e "${YELLOW}Running tests...${NC}"

    # Test 1: Check if all pods are running
    echo -e "${YELLOW}Test 1: Checking if all pods are running...${NC}"
    if kubectl get pods -l app.kubernetes.io/instance=userver-web | grep -q "Running"; then
        echo -e "${GREEN}Test 1 passed: All pods are running.${NC}"
    else
        echo -e "${RED}Test 1 failed: Not all pods are running.${NC}"
        kubectl get pods -l app.kubernetes.io/instance=userver-web
        return 1
    fi

    # Test 2: Check if the ingress is created
    echo -e "${YELLOW}Test 2: Checking if the ingress is created...${NC}"
    if kubectl get ingress userver-web &> /dev/null; then
        echo -e "${GREEN}Test 2 passed: Ingress is created.${NC}"
    else
        echo -e "${RED}Test 2 failed: Ingress is not created.${NC}"
        kubectl get ingress
        return 1
    fi

    # Test 3: Check if the services are created
    echo -e "${YELLOW}Test 3: Checking if the services are created...${NC}"
    if kubectl get svc -l app.kubernetes.io/instance=userver-web | grep -q "userver-web-nginx-proxy"; then
        echo -e "${GREEN}Test 3 passed: Services are created.${NC}"
    else
        echo -e "${RED}Test 3 failed: Services are not created.${NC}"
        kubectl get svc -l app.kubernetes.io/instance=userver-web
        return 1
    fi

    # Test 4: Check if the persistent volume claims are created
    echo -e "${YELLOW}Test 4: Checking if the persistent volume claims are created...${NC}"
    if kubectl get pvc -l app.kubernetes.io/instance=userver-web | grep -q "userver-web-certs"; then
        echo -e "${GREEN}Test 4 passed: Persistent volume claims are created.${NC}"
    else
        echo -e "${RED}Test 4 failed: Persistent volume claims are not created.${NC}"
        kubectl get pvc -l app.kubernetes.io/instance=userver-web
        return 1
    fi

    # Test 5: Check if the config maps are created
    echo -e "${YELLOW}Test 5: Checking if the config maps are created...${NC}"
    if kubectl get cm -l app.kubernetes.io/instance=userver-web | grep -q "userver-web-nginx-config"; then
        echo -e "${GREEN}Test 5 passed: Config maps are created.${NC}"
    else
        echo -e "${RED}Test 5 failed: Config maps are not created.${NC}"
        kubectl get cm -l app.kubernetes.io/instance=userver-web
        return 1
    fi

    # Test 6: Check if the service account is created
    echo -e "${YELLOW}Test 6: Checking if the service account is created...${NC}"
    if kubectl get sa -l app.kubernetes.io/instance=userver-web | grep -q "userver-web"; then
        echo -e "${GREEN}Test 6 passed: Service account is created.${NC}"
    else
        echo -e "${RED}Test 6 failed: Service account is not created.${NC}"
        kubectl get sa -l app.kubernetes.io/instance=userver-web
        return 1
    fi

    # Test 7: Check if the certificates are created
    echo -e "${YELLOW}Test 7: Checking if the certificates are created...${NC}"
    if kubectl get certificates -l app.kubernetes.io/instance=userver-web &> /dev/null; then
        echo -e "${GREEN}Test 7 passed: Certificates are created.${NC}"
    else
        echo -e "${RED}Test 7 failed: Certificates are not created.${NC}"
        kubectl get certificates
        return 1
    fi

    # Test 8: Check if the endpoints are accessible
    echo -e "${YELLOW}Test 8: Checking if the endpoints are accessible...${NC}"
    # Add entries to /etc/hosts
    echo "127.0.0.1 monitor.test.local whoami.test.local" | sudo tee -a /etc/hosts > /dev/null

    # Wait for the ingress to be ready
    echo -e "${YELLOW}Waiting for the ingress to be ready...${NC}"
    sleep 30

    # Check if the monitor endpoint is accessible
    if curl -k -s -o /dev/null -w "%{http_code}" https://monitor.test.local:8443 | grep -q "200"; then
        echo -e "${GREEN}Test 8 passed: Monitor endpoint is accessible.${NC}"
    else
        echo -e "${RED}Test 8 failed: Monitor endpoint is not accessible.${NC}"
        curl -k -v https://monitor.test.local:8443
        return 1
    fi

    # Check if the whoami endpoint is accessible
    if curl -k -s -o /dev/null -w "%{http_code}" https://whoami.test.local:8443 | grep -q "200"; then
        echo -e "${GREEN}Test 8 passed: Whoami endpoint is accessible.${NC}"
    else
        echo -e "${RED}Test 8 failed: Whoami endpoint is not accessible.${NC}"
        curl -k -v https://whoami.test.local:8443
        return 1
    fi

    # Remove entries from /etc/hosts
    sudo sed -i '/127.0.0.1 monitor.test.local whoami.test.local/d' /etc/hosts

    echo -e "${GREEN}All tests passed!${NC}"
    echo
    return 0
}

# Clean up
cleanup() {
    echo -e "${YELLOW}Cleaning up...${NC}"

    # Delete the Helm release
    helm delete userver-web || true

    # Delete the kind cluster
    kind delete cluster --name userver-web-test

    echo -e "${GREEN}Cleanup completed.${NC}"
    echo
}

# Main function
main() {
    # Check requirements
    check_requirements

    # Set up the test environment
    if [ "$SKIP_SETUP" = false ]; then
        create_cluster
        install_ingress_controller
        install_cert_manager
        install_userver_web
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
