#!/bin/bash
# ========================================================================
# Minikube Setup Script for TaskFlow Todo Application
# ========================================================================
# This script sets up Minikube with required addons:
# - Kubernetes ingress controller
# - MetalLB load balancer
# - Strimzi Kafka operator
# - Dapr runtime
# - PostgreSQL storage
#
# Usage: ./setup-minikube.sh
# Requires: minikube, kubectl, helm, docker
# ========================================================================

set -e

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-taskflow}"
KUBERNETES_VERSION="${KUBERNETES_VERSION:-v1.28.0}"
MEMORY="${MEMORY:-8192}"
CPUS="${CPUS:-4}"
DISK_SIZE="${DISK_SIZE:-50g}"
INGRESS_NAMESPACE="ingress-nginx"
METALLB_NAMESPACE="metallb-system"
STRIMZI_NAMESPACE="strimzi"
DAPR_NAMESPACE="dapr-system"
POSTGRES_NAMESPACE="postgres"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

    if ! command -v minikube &> /dev/null; then
        missing+=("minikube")
    fi

    if ! command -v kubectl &> /dev/null; then
        missing+=("kubectl")
    fi

    if ! command -v helm &> /dev/null; then
        missing+=("helm")
    fi

    if ! command -v docker &> /dev/null; then
        missing+=("docker")
    fi

    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing[*]}"
        echo "Please install the missing tools and try again."
        exit 1
    fi

    # Check docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi

    log_info "All prerequisites satisfied"
}

stop_existing_cluster() {
    log_info "Stopping existing Minikube cluster (if any)..."
    minikube stop -p "$CLUSTER_NAME" 2>/dev/null || true
    minikube delete -p "$CLUSTER_NAME" 2>/dev/null || true
}

start_cluster() {
    log_info "Starting Minikube cluster '$CLUSTER_NAME'..."
    minikube start \
        -p "$CLUSTER_NAME" \
        --kubernetes-version="$KUBERNETES_VERSION" \
        --memory="$MEMORY" \
        --cpus="$CPUS" \
        --disk-size="$DISK_SIZE" \
        --driver=docker

    log_info "Enabling Minikube Docker daemon..."
    eval $(minikube -p "$CLUSTER_NAME" docker-env)
}

enable_addons() {
    log_info "Enabling Kubernetes addons..."

    # Enable ingress controller
    log_info "Enabling ingress-nginx controller..."
    minikube addons enable ingress -p "$CLUSTER_NAME"

    # Enable MetalLB
    log_info "Enabling MetalLB..."
    minikube addons enable metallb -p "$CLUSTER_NAME"

    # Configure MetalLB IP address pool
    log_info "Configuring MetalLB IP address pool..."
    minikube addons configure metallb -p "$CLUSTER_NAME" \
        --metalLB-address-pool-range=192.168.49.100-192.168.49.120
}

install_strimzi() {
    log_info "Installing Strimzi Kafka operator..."

    # Create namespace
    kubectl create namespace "$STRIMZI_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

    # Add Strimzi Helm repo
    helm repo add strimzi https://strimzi.io/charts || true
    helm repo update

    # Install Strimzi operator
    helm install strimzi-kafka strimzi/strimzi-kafka-operator \
        --namespace "$STRIMZI_NAMESPACE" \
        --version 0.39.0 \
        --set watchNamespaces="" \
        --wait \
        --timeout 10m

    log_info "Strimzi Kafka operator installed"
}

create_kafka_cluster() {
    log_info "Creating Kafka cluster..."

    kubectl apply -f k8s/strimzi/kafka-cluster.yaml -n "$STRIMZI_NAMESPACE"

    # Wait for Kafka to be ready
    log_info "Waiting for Kafka cluster to be ready..."
    kubectl wait kafka/my-cluster --for=condition=Ready --timeout=300s -n "$STRIMZI_NAMESPACE" || true

    log_info "Kafka cluster created"
}

create_kafka_topics() {
    log_info "Creating Kafka topics..."

    kubectl apply -f k8s/kafka-topics.yaml -n "$STRIMZI_NAMESPACE"

    # List topics
    log_info "Kafka topics created:"
    kubectl get kafkatopics -n "$STRIMZI_NAMESPACE"
}

install_dapr() {
    log_info "Installing Dapr..."

    # Create namespace
    kubectl create namespace "$DAPR_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

    # Install Dapr CLI if not present
    if ! command -v dapr &> /dev/null; then
        log_info "Installing Dapr CLI..."
        wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O /tmp/install-dapr.sh
        chmod +x /tmp/install-dapr.sh
        /tmp/install-dapr.sh
        rm /tmp/install-dapr.sh
    fi

    # Initialize Dapr in the cluster
    dapr init -k \
        --namespace "$DAPR_NAMESPACE" \
        --wait \
        --timeout 300

    log_info "Dapr installed successfully"
}

deploy_dapr_components() {
    log_info "Deploying Dapr components..."

    # Apply Dapr component configurations
    for component in dapr-components/*.yaml; do
        if [ -f "$component" ]; then
            log_info "Applying $component..."
            kubectl apply -f "$component"
        fi
    done

    log_info "Dapr components deployed"
}

install_postgres() {
    log_info "Installing PostgreSQL via Helm..."

    # Add PostgreSQL Helm repo
    helm repo add bitnami https://charts.bitnami.com/bitnami || true
    helm repo update

    # Install PostgreSQL
    helm install postgres bitnami/postgresql \
        --namespace "$POSTGRES_NAMESPACE" \
        --create-namespace \
        --set auth.username=postgres \
        --set auth.password=postgres \
        --set auth.database=taskflow \
        --set persistence.size=10Gi \
        --set persistence.storageClass=standard \
        --wait \
        --timeout 10m

    log_info "PostgreSQL installed"
}

verify_installation() {
    log_info "Verifying installation..."

    echo ""
    echo "=== Cluster Status ==="
    kubectl cluster-info

    echo ""
    echo "=== Node Status ==="
    kubectl get nodes

    echo ""
    echo "=== Pod Status ==="
    kubectl get pods -A

    echo ""
    echo "=== Kafka Topics ==="
    kubectl get kafkatopics -n "$STRIMZI_NAMESPACE" 2>/dev/null || echo "Kafka topics not available yet"

    echo ""
    echo "=== Dapr Components ==="
    kubectl get components -n "$DAPR_NAMESPACE" 2>/dev/null || echo "Dapr components not available yet"

    echo ""
    echo "=== PostgreSQL ==="
    kubectl get svc -n "$POSTGRES_NAMESPACE" 2>/dev/null || echo "PostgreSQL not available yet"
}

print_next_steps() {
    echo ""
    echo "=============================================================="
    echo -e "${GREEN}Minikube setup complete!${NC}"
    echo "=============================================================="
    echo ""
    echo "Next steps:"
    echo "1. Build Docker images:"
    echo "   ./scripts/build-images-local.sh"
    echo ""
    echo "2. Deploy application:"
    echo "   ./scripts/deploy-local.sh"
    echo ""
    echo "3. Verify deployment:"
    echo "   ./scripts/test-local-deployment.sh"
    echo ""
    echo "Access points:"
    echo "- API: http://localhost:8000 (after port-forward)"
    echo "- Dapr Dashboard: dapr dashboard -k"
    echo "- Kafka: my-cluster-kafka-bootstrap:9092"
    echo "- PostgreSQL: postgres-postgresql.$POSTGRES_NAMESPACE.svc.cluster.local:5432"
    echo ""
}

# Main execution
main() {
    echo "=============================================================="
    echo "TaskFlow Minikube Setup Script"
    echo "=============================================================="
    echo ""

    check_prerequisites
    stop_existing_cluster
    start_cluster
    enable_addons
    install_strimzi
    create_kafka_cluster
    create_kafka_topics
    install_dapr
    deploy_dapr_components
    install_postgres
    verify_installation
    print_next_steps
}

# Run main
main "$@"
