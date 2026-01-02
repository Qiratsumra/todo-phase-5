#!/bin/bash

# Docker Stop Script for Todo Application
# Stops and removes all containers

set -e

echo "======================================"
echo "Stopping Todo Application"
echo "======================================"
echo ""

# Use docker compose or docker-compose based on what's available
COMPOSE_CMD="docker compose"
if ! docker compose version &> /dev/null; then
    COMPOSE_CMD="docker-compose"
fi

# Parse command line arguments
REMOVE_VOLUMES=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --volumes)
            REMOVE_VOLUMES="-v"
            echo "Will remove volumes (database data will be deleted)"
            ;;
        --help)
            echo "Usage: ./docker-stop.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --volumes    Remove volumes (WARNING: deletes database data)"
            echo "  --help       Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./docker-stop.sh           # Stop containers, keep data"
            echo "  ./docker-stop.sh --volumes # Stop containers and remove all data"
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

# Stop services
echo "Stopping all services..."
$COMPOSE_CMD down $REMOVE_VOLUMES --remove-orphans

echo ""
echo "======================================"
echo "All services stopped successfully!"
echo "======================================"

if [[ -n $REMOVE_VOLUMES ]]; then
    echo ""
    echo "⚠️  Database data has been removed"
fi
