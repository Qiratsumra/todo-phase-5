#!/bin/bash

# Docker Run Script for Todo Application
# Starts all services using docker-compose

set -e

echo "======================================"
echo "Starting Todo Application with Docker"
echo "======================================"
echo ""

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "Error: docker-compose is not installed"
    exit 1
fi

# Use docker compose or docker-compose based on what's available
COMPOSE_CMD="docker compose"
if ! docker compose version &> /dev/null; then
    COMPOSE_CMD="docker-compose"
fi

# Parse command line arguments
PROFILE=""
BUILD_FLAG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --with-services)
            PROFILE="--profile with-services"
            echo "Starting with microservices (notification & recurring task)"
            ;;
        --build)
            BUILD_FLAG="--build"
            echo "Building images before starting"
            ;;
        --help)
            echo "Usage: ./docker-run.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --with-services    Start with notification and recurring task services"
            echo "  --build            Build images before starting"
            echo "  --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./docker-run.sh                    # Start core services only"
            echo "  ./docker-run.sh --with-services    # Start all services including microservices"
            echo "  ./docker-run.sh --build            # Build and start core services"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
    shift
done

# Start services
echo ""
echo "Starting services..."
$COMPOSE_CMD up -d $BUILD_FLAG $PROFILE

echo ""
echo "======================================"
echo "Services started successfully!"
echo "======================================"
echo ""
echo "Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAMES|todo-"

echo ""
echo "Access the application:"
echo "  - Frontend:  http://localhost:3000"
echo "  - Backend:   http://localhost:8000"
echo "  - API Docs:  http://localhost:8000/docs"
echo "  - Database:  localhost:5432"

if [[ $PROFILE == *"with-services"* ]]; then
    echo "  - Notification Service: http://localhost:8002"
    echo "  - Recurring Task Service: http://localhost:8001"
fi

echo ""
echo "To view logs: $COMPOSE_CMD logs -f"
echo "To stop: $COMPOSE_CMD down"
