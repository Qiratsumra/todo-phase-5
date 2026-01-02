#!/bin/bash
# ========================================================================
# Docker Build Script for Local Development
# ========================================================================
# This script builds Docker images for all TaskFlow services.
#
# Usage: ./scripts/build-images-local.sh
# Requires: Docker, access to project root
# ========================================================================

set -e

# Configuration
REGISTRY="${REGISTRY:-localhost:5000}"
BACKEND_IMAGE="taskflow-backend"
FRONTEND_IMAGE="taskflow-frontend"
RECURRING_IMAGE="taskflow-recurring-service"
NOTIFICATION_IMAGE="taskflow-notification-service"
TAG="${TAG:-latest}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    if ! docker info &> /dev/null; then
        log_error "Docker is not running"
        exit 1
    fi
    log_info "Docker is ready"
}

build_backend() {
    log_info "Building backend image..."
    cd backend

    if [ -f Dockerfile ]; then
        docker build -t "${REGISTRY}/${BACKEND_IMAGE}:${TAG}" .
        log_info "Backend image built: ${BACKEND_IMAGE}:${TAG}"
    else
        log_warn "No Dockerfile found in backend directory"
    fi

    cd ..
}

build_frontend() {
    log_info "Building frontend image..."
    cd frontend

    if [ -f Dockerfile ]; then
        docker build -t "${REGISTRY}/${FRONTEND_IMAGE}:${TAG}" .
        log_info "Frontend image built: ${FRONTEND_IMAGE}:${TAG}"
    else
        log_warn "No Dockerfile found in frontend directory"
    fi

    cd ..
}

build_recurring_service() {
    log_info "Building recurring task service image..."

    if [ -d "services/recurring-task-service" ]; then
        cd services/recurring-task-service

        if [ -f Dockerfile ]; then
            docker build -t "${REGISTRY}/${RECURRING_IMAGE}:${TAG}" .
            log_info "Recurring service image built: ${RECURRING_IMAGE}:${TAG}"
        else
            log_warn "No Dockerfile found in recurring-task-service"
        fi

        cd ../..
    else
        log_warn "Recurring task service directory not found"
    fi
}

build_notification_service() {
    log_info "Building notification service image..."

    if [ -d "services/notification-service" ]; then
        cd services/notification-service

        if [ -f Dockerfile ]; then
            docker build -t "${REGISTRY}/${NOTIFICATION_IMAGE}:${TAG}" .
            log_info "Notification service image built: ${NOTIFICATION_IMAGE}:${TAG}"
        else
            log_warn "No Dockerfile found in notification-service"
        fi

        cd ../..
    else
        log_warn "Notification service directory not found"
    fi
}

push_images() {
    log_info "Pushing images to registry..."

    docker push "${REGISTRY}/${BACKEND_IMAGE}:${TAG}" || log_warn "Failed to push backend image"
    docker push "${REGISTRY}/${FRONTEND_IMAGE}:${TAG}" || log_warn "Failed to push frontend image"

    if docker image inspect "${REGISTRY}/${RECURRING_IMAGE}:${TAG}" &> /dev/null; then
        docker push "${REGISTRY}/${RECURRING_IMAGE}:${TAG}" || log_warn "Failed to push recurring image"
    fi

    if docker image inspect "${REGISTRY}/${NOTIFICATION_IMAGE}:${TAG}" &> /dev/null; then
        docker push "${REGISTRY}/${NOTIFICATION_IMAGE}:${TAG}" || log_warn "Failed to push notification image"
    fi

    log_info "Images pushed"
}

list_images() {
    echo ""
    echo "=== Built Images ==="
    docker images | grep -E "^${REGISTRY}|taskflow" || echo "No taskflow images found"
}

main() {
    echo "=============================================================="
    echo "TaskFlow Docker Build Script"
    echo "=============================================================="

    check_docker

    echo ""
    echo "Building images with tag: ${TAG}"
    echo "Registry: ${REGISTRY}"
    echo ""

    build_backend
    build_frontend
    build_recurring_service
    build_notification_service

    echo ""
    read -p "Push images to registry? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        push_images
    fi

    list_images

    echo ""
    log_info "Build complete!"
}

main "$@"
