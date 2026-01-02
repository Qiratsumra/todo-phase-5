#!/bin/bash
# ========================================================================
# Local Deployment Script for TaskFlow
# ========================================================================
# This script deploys the TaskFlow application to Minikube.
#
# Usage: ./scripts/deploy-local.sh
# Requires: kubectl, kustomize, images built
# ========================================================================

set -e

# Configuration
NAMESPACE="${NAMESPACE:-todo-app}"
OVERLAY_DIR="k8s/overlays/local"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found"
        exit 1
    fi

    if ! command -v kustomize &> /dev/null && ! kubectl kustomize --help &> /dev/null 2>&1; then
        log_error "kustomize not found"
        exit 1
    fi

    # Check cluster
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi

    log_info "Prerequisites satisfied"
}

create_namespace() {
    log_info "Creating namespace: $NAMESPACE"
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

    # Label namespace for Dapr
    kubectl label namespace "$NAMESPACE" dapr.io/enabled=true --overwrite || true
}

deploy_postgres() {
    log_info "Deploying PostgreSQL..."
    kubectl apply -f helm-charts/postgres-deployment.yaml -n "$NAMESPACE"

    # Wait for PostgreSQL to be ready
    log_info "Waiting for PostgreSQL to be ready..."
    kubectl wait --for=condition=ready pod -l app=postgres -n "$NAMESPACE" --timeout=120s
    log_info "PostgreSQL is ready"
}

deploy_redis() {
    log_info "Deploying Redis..."
    kubectl create deployment redis --image=redis:7-alpine -n "$NAMESPACE"
    kubectl expose deployment redis --port=6379 --name=redis-master -n "$NAMESPACE"

    kubectl wait --for=condition=ready pod -l app=redis -n "$NAMESPACE" --timeout=60s
    log_info "Redis is ready"
}

deploy_dapr_components() {
    log_info "Deploying Dapr components..."
    for component in dapr-components/*.yaml; do
        if [ -f "$component" ]; then
            log_info "Applying $component"
            kubectl apply -f "$component" -n "$NAMESPACE"
        fi
    done
    log_info "Dapr components deployed"
}

deploy_application() {
    log_info "Deploying application using kustomize..."

    if [ -d "$OVERLAY_DIR" ]; then
        kubectl apply -k "$OVERLAY_DIR" -n "$NAMESPACE"
    else
        log_error "Overlay directory not found: $OVERLAY_DIR"
        exit 1
    fi

    log_info "Application deployed"
}

wait_for_deployments() {
    log_info "Waiting for deployments to be ready..."

    local deployments=("taskflow-backend" "taskflow-frontend")

    for deploy in "${deployments[@]}"; do
        log_info "Waiting for $deploy..."
        kubectl rollout status deployment "$deploy" -n "$NAMESPACE" --timeout=300s || {
            log_warn "Deployment $deploy not ready, checking status..."
            kubectl get deployment "$deploy" -n "$NAMESPACE"
            kubectl get pods -n "$NAMESPACE" -l app="$deploy"
        }
    done

    log_info "All deployments are ready"
}

verify_deployment() {
    log_info "Verifying deployment..."

    echo ""
    echo "=== Pods ==="
    kubectl get pods -n "$NAMESPACE"

    echo ""
    echo "=== Services ==="
    kubectl get svc -n "$NAMESPACE"

    echo ""
    echo "=== Dapr Components ==="
    kubectl get components -n "$NAMESPACE" 2>/dev/null || echo "No Dapr components"

    echo ""
    echo "=== Ingress ==="
    kubectl get ingress -n "$NAMESPACE" 2>/dev/null || echo "No ingress"
}

print_access_info() {
    echo ""
    echo "=============================================================="
    echo -e "${GREEN}Deployment Complete!${NC}"
    echo "=============================================================="
    echo ""
    echo "Access points:"
    echo ""
    echo "Backend API:"
    echo "  kubectl port-forward -n $NAMESPACE svc/taskflow-backend 8000:80"
    echo "  Then open: http://localhost:8000"
    echo ""
    echo "Frontend:"
    echo "  kubectl port-forward -n $NAMESPACE svc/taskflow-frontend 3000:80"
    echo "  Then open: http://localhost:3000"
    echo ""
    echo "Dapr Dashboard:"
    echo "  dapr dashboard -k"
    echo ""
    echo "Useful commands:"
    echo "  View logs: kubectl logs -n $NAMESPACE -l app=taskflow-backend -f"
    echo "  Restart: kubectl rollout restart deployment/taskflow-backend -n $NAMESPACE"
    echo ""
}

main() {
    echo "=============================================================="
    echo "TaskFlow Local Deployment Script"
    echo "=============================================================="

    check_prerequisites
    create_namespace
    deploy_postgres
    deploy_redis
    deploy_dapr_components
    deploy_application
    wait_for_deployments
    verify_deployment
    print_access_info
}

main "$@"
