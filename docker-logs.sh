#!/bin/bash

# Docker Logs Script for Todo Application
# View logs from running containers

set -e

# Use docker compose or docker-compose based on what's available
COMPOSE_CMD="docker compose"
if ! docker compose version &> /dev/null; then
    COMPOSE_CMD="docker-compose"
fi

# Parse command line arguments
SERVICE=""
FOLLOW_FLAG="-f"

while [[ $# -gt 0 ]]; do
    case $1 in
        backend|frontend|postgres|notification-service|recurring-task-service)
            SERVICE="$1"
            ;;
        --no-follow)
            FOLLOW_FLAG=""
            ;;
        --help)
            echo "Usage: ./docker-logs.sh [SERVICE] [OPTIONS]"
            echo ""
            echo "Services:"
            echo "  backend                   Backend API service"
            echo "  frontend                  Frontend Next.js service"
            echo "  postgres                  PostgreSQL database"
            echo "  notification-service      Notification microservice"
            echo "  recurring-task-service    Recurring task microservice"
            echo ""
            echo "Options:"
            echo "  --no-follow    Don't follow log output"
            echo "  --help         Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./docker-logs.sh                  # View all service logs (following)"
            echo "  ./docker-logs.sh backend          # View backend logs only"
            echo "  ./docker-logs.sh --no-follow      # Show logs without following"
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

# View logs
if [[ -n $SERVICE ]]; then
    echo "Viewing logs for: $SERVICE"
    echo "Press Ctrl+C to exit"
    echo ""
    $COMPOSE_CMD logs $FOLLOW_FLAG $SERVICE
else
    echo "Viewing logs for all services"
    echo "Press Ctrl+C to exit"
    echo ""
    $COMPOSE_CMD logs $FOLLOW_FLAG
fi
