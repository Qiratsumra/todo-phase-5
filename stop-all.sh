#!/bin/bash

# Stop all Todo Application services including Kafka and Dapr

set -e

echo "=========================================="
echo "Stopping Todo Application"
echo "=========================================="
echo ""

# Use docker compose or docker-compose
COMPOSE_CMD="docker compose"
if ! docker compose version &> /dev/null; then
    COMPOSE_CMD="docker-compose"
fi

# Parse arguments
REMOVE_VOLUMES=""
if [[ "$1" == "--volumes" || "$1" == "-v" ]]; then
    REMOVE_VOLUMES="-v"
    echo "⚠️  Will remove all volumes (data will be deleted)"
    echo ""
fi

# Stop Dapr sidecars
echo "[1/2] Stopping Dapr sidecars..."
$COMPOSE_CMD -f docker-compose.dapr.yml down --remove-orphans 2>/dev/null || true

# Stop all application services
echo "[2/2] Stopping all services..."
$COMPOSE_CMD --profile kafka --profile with-services down $REMOVE_VOLUMES --remove-orphans

echo ""
echo "=========================================="
echo "All services stopped successfully!"
echo "=========================================="

if [[ -n $REMOVE_VOLUMES ]]; then
    echo ""
    echo "⚠️  All data has been removed (database, Kafka messages)"
fi
