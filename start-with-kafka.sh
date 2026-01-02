#!/bin/bash

# Start Todo Application with Kafka and Dapr
# This script orchestrates the complete event-driven setup

set -e

echo "=========================================="
echo "Starting Todo App with Kafka & Dapr"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Use docker compose or docker-compose
COMPOSE_CMD="docker compose"
if ! docker compose version &> /dev/null; then
    COMPOSE_CMD="docker-compose"
fi

# Check if Dapr is installed
echo -e "${BLUE}Checking prerequisites...${NC}"
if ! command -v dapr &> /dev/null; then
    echo -e "${YELLOW}⚠ Dapr CLI not found${NC}"
    echo "Installing Dapr CLI..."
    wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O - | /bin/bash
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Failed to install Dapr CLI${NC}"
        echo "Please install manually: https://docs.dapr.io/getting-started/install-dapr-cli/"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Dapr CLI installed${NC}"
echo ""

# Step 1: Start core services + Kafka
echo -e "${BLUE}[1/5] Starting core services and Kafka...${NC}"
$COMPOSE_CMD --profile kafka up -d postgres zookeeper kafka

echo "Waiting for services to be healthy..."
sleep 10

# Check if Kafka is running
if ! docker ps | grep -q todo-kafka; then
    echo -e "${RED}✗ Kafka failed to start${NC}"
    $COMPOSE_CMD logs kafka
    exit 1
fi

echo -e "${GREEN}✓ Kafka is running${NC}"
echo ""

# Step 2: Create Kafka topics
echo -e "${BLUE}[2/5] Creating Kafka topics...${NC}"
./scripts/create-kafka-topics.sh
echo ""

# Step 3: Start application services
echo -e "${BLUE}[3/5] Starting application services...${NC}"
$COMPOSE_CMD up -d backend frontend
sleep 5
echo -e "${GREEN}✓ Application services started${NC}"
echo ""

# Step 4: Start microservices
echo -e "${BLUE}[4/5] Starting microservices...${NC}"
$COMPOSE_CMD --profile with-services up -d notification-service recurring-task-service
sleep 5
echo -e "${GREEN}✓ Microservices started${NC}"
echo ""

# Step 5: Start Dapr sidecars
echo -e "${BLUE}[5/5] Starting Dapr sidecars...${NC}"
$COMPOSE_CMD -f docker-compose.yml -f docker-compose.dapr.yml up -d

echo "Waiting for Dapr sidecars to initialize..."
sleep 10
echo -e "${GREEN}✓ Dapr sidecars started${NC}"
echo ""

echo "=========================================="
echo -e "${GREEN}Todo App is ready with Kafka & Dapr!${NC}"
echo "=========================================="
echo ""

echo "Access points:"
echo "  - Frontend:             http://localhost:3000"
echo "  - Backend API:          http://localhost:8000"
echo "  - API Docs:             http://localhost:8000/docs"
echo "  - Kafka UI:             http://localhost:8080"
echo "  - Notification Service: http://localhost:8002"
echo "  - Recurring Service:    http://localhost:8001"
echo ""

echo "Dapr endpoints:"
echo "  - Backend Dapr:         http://localhost:3500"
echo "  - Recurring Dapr:       http://localhost:3501"
echo "  - Notification Dapr:    http://localhost:3502"
echo ""

echo "Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAMES|todo-|dapr-"

echo ""
echo "To view logs:"
echo "  All services:    $COMPOSE_CMD logs -f"
echo "  Kafka:           $COMPOSE_CMD logs -f kafka"
echo "  Backend:         $COMPOSE_CMD logs -f backend"
echo "  Dapr sidecars:   $COMPOSE_CMD -f docker-compose.dapr.yml logs -f"
echo ""
echo "To stop everything:"
echo "  ./stop-all.sh"
