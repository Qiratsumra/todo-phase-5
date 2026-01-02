#!/bin/bash

# Docker Build Script for Todo Application
# Builds all Docker images for the application

set -e

echo "======================================"
echo "Building Todo Application Docker Images"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Build backend
echo -e "${BLUE}[1/4] Building Backend Service...${NC}"
cd backend
docker build -t todo-backend:latest .
echo -e "${GREEN}✓ Backend image built successfully${NC}"
echo ""

# Build frontend
echo -e "${BLUE}[2/4] Building Frontend Service...${NC}"
cd ../frontend
docker build -t todo-frontend:latest \
  --build-arg NEXT_PUBLIC_API_URL=http://localhost:8000 .
echo -e "${GREEN}✓ Frontend image built successfully${NC}"
echo ""

# Build notification service
echo -e "${BLUE}[3/4] Building Notification Service...${NC}"
cd ../backend/services/notification
docker build -t todo-notification:latest .
echo -e "${GREEN}✓ Notification service image built successfully${NC}"
echo ""

# Build recurring task service
echo -e "${BLUE}[4/4] Building Recurring Task Service...${NC}"
cd ../recurring_task
docker build -t todo-recurring:latest .
echo -e "${GREEN}✓ Recurring task service image built successfully${NC}"
echo ""

# Return to root directory
cd ../../../../

echo "======================================"
echo -e "${GREEN}All Docker images built successfully!${NC}"
echo "======================================"
echo ""
echo "Built images:"
docker images | grep -E "REPOSITORY|todo-(backend|frontend|notification|recurring)" | grep -E "REPOSITORY|latest"
