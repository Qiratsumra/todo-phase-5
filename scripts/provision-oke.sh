#!/bin/bash
# ========================================================================
# Oracle Kubernetes Engine (OKE) Provisioning Script
# ========================================================================
# This script provisions an OKE cluster with required addons for TaskFlow.
#
# Prerequisites:
# - Oracle Cloud CLI (oci) installed and configured
# - kubectl installed
# - helm installed
# - Active OCI subscription
#
# Usage: ./scripts/provision-oke.sh
# ========================================================================

set -e

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-taskflow-oke}"
COMPARTMENT_ID="${COMPARTMENT_ID:-$(oci os compartment get --name root --query 'data.id' --raw-output)}"
NODE_POOL_SIZE="${NODE_POOL_SIZE:-3}"
NODE_SHAPE="${NODE_SHAPE:-VM.Standard3.Flex}"
NODE_CPU="${NODE_CPU:-2}"
NODE_MEMORY="${NODE_MEMORY:-32}"
VCN_CIDR="${VCN_CIDR:-10.0.0.0/16}"
POD_CIDR="${POD_CIDR:-10.244.0.0/16}"
SERVICE_CIDR="${SERVICE_CIDR:-10.96.0.0/16}"

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

    if ! command -v oci &> /dev/null; then
        log_error "Oracle Cloud CLI (oci) not found"
        echo "Install from: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm"
        exit 1
    fi

    # Verify OCI is configured
    if ! oci iam compartment get --compartment-id "$COMPARTMENT_ID" &>/dev/null; then
        log_error "OCI not configured or compartment not accessible"
        echo "Run: oci setup config"
        exit 1
    fi

    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found"
        exit 1
    fi

    log_info "All prerequisites satisfied"
}

create_vcn() {
    log_info "Creating Virtual Cloud Network..."

    # Check if VCN already exists
    local vcn_id
    vcn_id=$(oci network vcn list \
        --compartment-id "$COMPARTMENT_ID" \
        --display-name "${CLUSTER_NAME}-vcn" \
        --query 'data[0].id' \
        --raw-output 2>/dev/null || echo "")

    if [ -n "$vcn_id" ]; then
        log_warn "VCN already exists: $vcn_id"
        echo "$vcn_id"
        return
    fi

    # Create VCN
    local vcn_response
    vcn_response=$(oci network vcn create \
        --compartment-id "$COMPARTMENT_ID" \
        --display-name "${CLUSTER_NAME}-vcn" \
        --cidr-block "$VCN_CIDR" \
        --dns-label "${CLUSTER_NAME}vcn")

    VCN_ID=$(echo "$vcn_response" | jq -r '.data.id')
    log_info "VCN created: $VCN_ID"

    # Create Internet Gateway
    log_info "Creating Internet Gateway..."
    oci network internet-gateway create \
        --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$VCN_ID" \
        --display-name "${CLUSTER_NAME}-igw" \
        --is-enabled true

    # Create NAT Gateway
    log_info "Creating NAT Gateway..."
    oci network nat-gateway create \
        --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$VCN_ID" \
        --display-name "${CLUSTER_NAME}-nat"

    # Create Service Gateway
    log_info "Creating Service Gateway..."
    oci network service-gateway create \
        --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$VCN_ID" \
        --display-name "${CLUSTER_NAME}-sgw" \
        --services 'all' 2>/dev/null || true

    echo "$VCN_ID"
}

create_subnets() {
    local vcn_id=$1

    log_info "Creating subnets..."

    # Public subnet for load balancers
    oci network subnet create \
        --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$vcn_id" \
        --display-name "${CLUSTER_NAME}-public" \
        --cidr-block "10.0.1.0/24" \
        --dns-label "${CLUSTER_NAME}pub" \
        --prohibit-public-ip-on-vlan false

    # Private subnet for nodes
    oci network subnet create \
        --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$vcn_id" \
        --display-name "${CLUSTER_NAME}-private" \
        --cidr-block "10.0.2.0/24" \
        --dns-label "${CLUSTER_NAME}pri"

    log_info "Subnets created"
}

create_node_pool() {
    log_info "Creating node pool..."

    # Get VCN and subnet IDs
    local subnet_id
    subnet_id=$(oci network subnet list \
        --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$VCN_ID" \
        --display-name "${CLUSTER_NAME}-private" \
        --query 'data[0].id' \
        --raw-output)

    # Create node pool
    oci ce node-pool create \
        --compartment-id "$COMPARTMENT_ID" \
        --cluster-id "$CLUSTER_ID" \
        --name "${CLUSTER_NAME}-nodepool" \
        --kubernetes-version "v1.28.0" \
        --size "$NODE_POOL_SIZE" \
        --subnet-id "$subnet_id" \
        --shape "$NODE_SHAPE" \
        --memory-in-gbs "$NODE_MEMORY" \
        --ocpus "$NODE_CPU" \
        --wait-for-state "ACTIVE"

    log_info "Node pool created"
}

create_cluster() {
    log_info "Creating OKE cluster..."

    # Check if cluster exists
    local existing_id
    existing_id=$(oci ce cluster list \
        --compartment-id "$COMPARTMENT_ID" \
        --name "$CLUSTER_NAME" \
        --query 'data[0].id' \
        --raw-output 2>/dev/null || echo "")

    if [ -n "$existing_id" ]; then
        log_warn "Cluster already exists: $existing_id"
        CLUSTER_ID="$existing_id"
        return
    fi

    # Get VCN ID
    VCN_ID=$(oci network vcn list \
        --compartment-id "$COMPARTMENT_ID" \
        --display-name "${CLUSTER_NAME}-vcn" \
        --query 'data[0].id' \
        --raw-output)

    # Get subnet IDs
    local lb_subnet_id
    lb_subnet_id=$(oci network subnet list \
        --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$VCN_ID" \
        --display-name "${CLUSTER_NAME}-public" \
        --query 'data[0].id' \
        --raw-output)

    local pod_subnet_id
    pod_subnet_id=$(oci network subnet list \
        --compartment-id "$COMPARTMENT_ID" \
        --vcn-id "$VCN_ID" \
        --display-name "${CLUSTER_NAME}-private" \
        --query 'data[0].id' \
        --raw-output)

    # Create cluster
    local cluster_response
    cluster_response=$(oci ce cluster create \
        --compartment-id "$COMPARTMENT_ID" \
        --name "$CLUSTER_NAME" \
        --kubernetes-version "v1.28.0" \
        --vcn-id "$VCN_ID" \
        --pod-cidr-block "$POD_CIDR" \
        --service-lb-subnet-ids "[\"$lb_subnet_id\"]" \
        --endpoint-subnet-id "$pod_subnet_id" \
        --query 'data' \
        --raw-output)

    CLUSTER_ID=$(echo "$cluster_response" | jq -r '.id')
    log_info "Cluster creation initiated: $CLUSTER_ID"

    # Wait for cluster to be active
    log_info "Waiting for cluster to be active..."
    oci ce cluster get --cluster-id "$CLUSTER_ID" \
        --query 'data.lifecycle-state' \
        --raw-output | grep -q "ACTIVE" || \
    oci ce cluster get --cluster-id "$CLUSTER_ID" \
        --wait-for-state "ACTIVE" \
        --query 'data.lifecycle-state' \
        --raw-output

    log_info "Cluster is active"
}

configure_kubectl() {
    log_info "Configuring kubectl..."

    # Get cluster kubeconfig
    oci ce cluster create-kubeconfig \
        --cluster-id "$CLUSTER_ID" \
        --file "$HOME/.kube/config" \
        --region "$(oci region list --query '[0].name' --raw-output)"

    log_info "kubectl configured"
}

install_addons() {
    log_info "Installing cluster addons..."

    # Enable OCI CCM (Cloud Controller Manager)
    log_info "OCI Cloud Controller Manager is enabled by default in OKE"

    # Install Ingress Controller
    log_info "Installing NGINX Ingress Controller..."
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
    helm repo update

    helm install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.service.annotations.service\.beta\.kubernetes\.io/oci-load-balancer-security-list-management-mode="None" \
        --set controller.service.beta.kubernetes.io/oci-load-balancer-subnet1="$(oci network subnet list --compartment-id "$COMPARTMENT_ID" --vcn-id "$VCN_ID" --display-name "${CLUSTER_NAME}-public" --query 'data[0].id' --raw-output)" \
        --wait

    log_info "NGINX Ingress Controller installed"
}

print_summary() {
    echo ""
    echo "=============================================================="
    echo -e "${GREEN}OKE Cluster Provisioning Complete!${NC}"
    echo "=============================================================="
    echo ""
    echo "Cluster Details:"
    echo "  Name: $CLUSTER_NAME"
    echo "  OCID: $CLUSTER_ID"
    echo "  Region: $(oci region list --query '[0].name' --raw-output)"
    echo ""
    echo "Next steps:"
    echo "1. Configure kubectl:"
    echo "   export KUBECONFIG=\$HOME/.kube/config"
    echo ""
    echo "2. Deploy application:"
    echo "   ./scripts/deploy-cloud.sh"
    echo ""
    echo "3. Access the cluster:"
    echo "   kubectl get nodes"
    echo ""
    echo "Useful commands:"
    echo "  View cluster: oci ce cluster get --cluster-id $CLUSTER_ID"
    echo "  Scale nodes: oci ce node-pool update --node-pool-id <nodepool-ocid> --size 5"
    echo "  Delete cluster: oci ce cluster delete --cluster-id $CLUSTER_ID"
}

main() {
    echo "=============================================================="
    echo "TaskFlow OKE Provisioning Script"
    echo "=============================================================="
    echo ""

    check_prerequisites

    create_cluster
    create_node_pool
    configure_kubectl
    install_addons

    print_summary
}

main "$@"
