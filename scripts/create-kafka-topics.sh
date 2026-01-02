#!/bin/bash

# Script to create Kafka topics for Todo Application
# This script creates all required topics with appropriate configurations

set -e

echo "======================================"
echo "Creating Kafka Topics for Todo App"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Kafka broker address
KAFKA_BROKER="localhost:9093"
CONTAINER_NAME="todo-kafka"

# Wait for Kafka to be ready
echo -e "${BLUE}Waiting for Kafka to be ready...${NC}"
MAX_TRIES=30
TRIES=0

while [ $TRIES -lt $MAX_TRIES ]; do
    if docker exec $CONTAINER_NAME kafka-broker-api-versions --bootstrap-server localhost:9092 &> /dev/null; then
        echo -e "${GREEN}✓ Kafka is ready${NC}"
        break
    fi
    TRIES=$((TRIES+1))
    echo "Waiting for Kafka... ($TRIES/$MAX_TRIES)"
    sleep 2
done

if [ $TRIES -eq $MAX_TRIES ]; then
    echo -e "${YELLOW}⚠ Timeout waiting for Kafka${NC}"
    exit 1
fi

echo ""

# Function to create a topic
create_topic() {
    local topic_name=$1
    local partitions=$2
    local retention_ms=$3
    local description=$4

    echo -e "${BLUE}Creating topic: $topic_name${NC}"
    echo "  Description: $description"
    echo "  Partitions: $partitions"
    echo "  Retention: $retention_ms ms"

    docker exec $CONTAINER_NAME kafka-topics \
        --create \
        --if-not-exists \
        --bootstrap-server localhost:9092 \
        --topic $topic_name \
        --partitions $partitions \
        --replication-factor 1 \
        --config retention.ms=$retention_ms \
        --config cleanup.policy=delete \
        --config min.insync.replicas=1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Topic $topic_name created successfully${NC}"
    else
        echo -e "${YELLOW}⚠ Topic $topic_name might already exist${NC}"
    fi
    echo ""
}

# Create topics
echo "Creating application topics..."
echo ""

# Task Events Topic
create_topic "task-events" 3 604800000 "Task lifecycle events (created, updated, completed, deleted)"

# Reminders Topic
create_topic "reminders" 3 259200000 "Reminder scheduling and delivery events"

# Task Updates Topic
create_topic "task-updates" 3 86400000 "Real-time task update notifications"

# Audit Events Topic
create_topic "audit-events" 3 2592000000 "Audit trail for all operations"

echo "======================================"
echo -e "${GREEN}All topics created successfully!${NC}"
echo "======================================"
echo ""

# List all topics
echo "Current Kafka topics:"
docker exec $CONTAINER_NAME kafka-topics \
    --list \
    --bootstrap-server localhost:9092

echo ""
echo "To describe a topic, run:"
echo "  docker exec $CONTAINER_NAME kafka-topics --describe --topic <topic-name> --bootstrap-server localhost:9092"
