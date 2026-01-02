#!/bin/bash
# ========================================================================
# Dapr Initialization Script for Local Development
# ========================================================================
# This script initializes Dapr in a Kubernetes cluster for local development.
# It installs Dapr with appropriate settings for Minikube.
#
# Usage: ./setup-dapr-local.sh
# Requires: kubectl, helm, dapr CLI
# ========================================================================

set -e

# Configuration
DAPR_NAMESPACE="${DAPR_NAMESPACE:-dapr-system}"
DAPR_VERSION="${DAPR_VERSION:-1.12.0}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    local missing=()

    if ! command -v kubectl &> /dev/null; then
        missing+=("kubectl")
    fi

    if ! command -v dapr &> /dev/null; then
        log_warn "Dapr CLI not found. Installing..."
        install_dapr_cli
    fi

    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing[*]}"
        exit 1
    fi

    # Check cluster connectivity
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi

    log_info "All prerequisites satisfied"
}

install_dapr_cli() {
    log_info "Installing Dapr CLI..."

    # Detect OS
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    if [ "$ARCH" = "x86_64" ]; then
        ARCH="amd64"
    fi

    # Download Dapr CLI
    curl -sL https://github.com/dapr/cli/releases/download/v${DAPR_VERSION}/dapr-${OS}-${ARCH}.tar.gz | tar xz

    # Move to PATH
    sudo mv dapr /usr/local/bin/ || mv dapr /usr/local/bin/

    log_info "Dapr CLI installed"
}

create_namespace() {
    log_info "Creating Dapr namespace: $DAPR_NAMESPACE"
    kubectl create namespace "$DAPR_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
}

initialize_dapr() {
    log_info "Initializing Dapr in cluster..."

    # Initialize Dapr with Helm chart
    dapr init -k \
        --namespace "$DAPR_NAMESPACE" \
        --runtime-version "$DAPR_VERSION" \
        --wait \
        --timeout 300

    log_info "Dapr initialized successfully"
}

deploy_components() {
    log_info "Deploying Dapr components..."

    local components_dir="dapr-components"

    if [ -d "$components_dir" ]; then
        for component in "$components_dir"/*.yaml; do
            if [ -f "$component" ]; then
                log_info "Deploying: $component"
                kubectl apply -f "$component" -n "$DAPR_NAMESPACE"
            fi
        done
    else
        log_warn "Components directory not found: $components_dir"
    fi

    log_info "Dapr components deployed"
}

verify_installation() {
    log_info "Verifying Dapr installation..."

    echo ""
    echo "=== Dapr Control Plane ==="
    kubectl get pods -n "$DAPR_NAMESPACE"

    echo ""
    echo "=== Dapr Components ==="
    kubectl get components -n "$DAPR_NAMESPACE" 2>/dev/null || echo "No custom components"

    echo ""
    echo "=== Dapr Configurations ==="
    kubectl get configurations -n "$DAPR_NAMESPACE" 2>/dev/null || echo "No custom configurations"

    echo ""
    echo "=== Dapr Subscriptions ==="
    kubectl get subscriptions -n "$DAPR_NAMESPACE" 2>/dev/null || echo "No subscriptions"
}

print_status() {
    echo ""
    echo "=============================================================="
    echo -e "${GREEN}Dapr initialization complete!${NC}"
    echo "=============================================================="
    echo ""
    echo "Useful commands:"
    echo "- View Dapr dashboard: dapr dashboard -k"
    echo "- List components: kubectl get components -n $DAPR_NAMESPACE"
    echo "- View logs: kubectl logs -n $DAPR_NAMESPACE -l app=dapr-control-plane"
    echo ""
    echo "Dapr sidecar annotation format:"
    echo '  annotations:'
    echo '    dapr.io/enabled: "true"'
    echo '    dapr.io/app-id: "{{ .Values.name }}"'
    echo '    dapr.io/app-port: "{{ .Values.containerPort }}"'
    echo '    dapr.io/config: "dapr-config"'
}

# Main execution
main() {
    echo "=============================================================="
    echo "Dapr Initialization Script"
    echo "=============================================================="
    echo ""

    check_prerequisites
    create_namespace
    initialize_dapr
    deploy_components
    verify_installation
    print_status
}

# Run main
main "$@"
