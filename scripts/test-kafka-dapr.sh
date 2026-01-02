#!/bin/bash

# Test Script for Kafka and Dapr Integration
# Verifies that Kafka topics exist and Dapr can publish/consume messages

set -e

echo "=========================================="
echo "Testing Kafka & Dapr Integration"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

KAFKA_CONTAINER="todo-kafka"
BACKEND_DAPR_PORT="3500"
TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: Check if Kafka is running
echo -e "${BLUE}[Test 1/6] Checking if Kafka is running...${NC}"
if docker ps | grep -q $KAFKA_CONTAINER; then
    echo -e "${GREEN}✓ Kafka container is running${NC}"
    TESTS_PASSED=$((TESTS_PASSED+1))
else
    echo -e "${RED}✗ Kafka container is not running${NC}"
    TESTS_FAILED=$((TESTS_FAILED+1))
fi
echo ""

# Test 2: Check Kafka topics
echo -e "${BLUE}[Test 2/6] Checking Kafka topics...${NC}"
TOPICS=$(docker exec $KAFKA_CONTAINER kafka-topics --list --bootstrap-server localhost:9092 2>/dev/null || echo "")

check_topic() {
    local topic=$1
    if echo "$TOPICS" | grep -q "^$topic$"; then
        echo -e "${GREEN}✓ Topic '$topic' exists${NC}"
        TESTS_PASSED=$((TESTS_PASSED+1))
        return 0
    else
        echo -e "${RED}✗ Topic '$topic' not found${NC}"
        TESTS_FAILED=$((TESTS_FAILED+1))
        return 1
    fi
}

check_topic "task-events"
check_topic "reminders"
check_topic "task-updates"
check_topic "audit-events"
echo ""

# Test 3: Check Dapr sidecars
echo -e "${BLUE}[Test 3/6] Checking Dapr sidecars...${NC}"

check_dapr_sidecar() {
    local name=$1
    local container=$2
    if docker ps | grep -q $container; then
        echo -e "${GREEN}✓ $name sidecar is running${NC}"
        TESTS_PASSED=$((TESTS_PASSED+1))
        return 0
    else
        echo -e "${YELLOW}⚠ $name sidecar is not running${NC}"
        TESTS_FAILED=$((TESTS_FAILED+1))
        return 1
    fi
}

check_dapr_sidecar "Backend" "backend-dapr"
check_dapr_sidecar "Notification" "notification-dapr"
check_dapr_sidecar "Recurring Task" "recurring-dapr"
echo ""

# Test 4: Check Dapr components
echo -e "${BLUE}[Test 4/6] Checking Dapr components...${NC}"
if curl -s http://localhost:$BACKEND_DAPR_PORT/v1.0/metadata > /dev/null 2>&1; then
    METADATA=$(curl -s http://localhost:$BACKEND_DAPR_PORT/v1.0/metadata)

    if echo "$METADATA" | grep -q "kafka-pubsub"; then
        echo -e "${GREEN}✓ Kafka pub/sub component loaded${NC}"
        TESTS_PASSED=$((TESTS_PASSED+1))
    else
        echo -e "${RED}✗ Kafka pub/sub component not loaded${NC}"
        TESTS_FAILED=$((TESTS_FAILED+1))
    fi

    if echo "$METADATA" | grep -q "statestore"; then
        echo -e "${GREEN}✓ State store component loaded${NC}"
        TESTS_PASSED=$((TESTS_PASSED+1))
    else
        echo -e "${RED}✗ State store component not loaded${NC}"
        TESTS_FAILED=$((TESTS_FAILED+1))
    fi
else
    echo -e "${RED}✗ Cannot connect to Dapr sidecar${NC}"
    echo -e "${YELLOW}  Make sure Dapr sidecars are running${NC}"
    TESTS_FAILED=$((TESTS_FAILED+2))
fi
echo ""

# Test 5: Test publishing to Kafka via Dapr
echo -e "${BLUE}[Test 5/6] Testing message publishing via Dapr...${NC}"
TEST_MESSAGE='{"taskId":"test-123","action":"created","timestamp":"2024-01-01T00:00:00Z"}'

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    http://localhost:$BACKEND_DAPR_PORT/v1.0/publish/kafka-pubsub/task-events \
    -H "Content-Type: application/json" \
    -d "$TEST_MESSAGE" 2>/dev/null || echo "000")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [[ "$HTTP_CODE" == "204" || "$HTTP_CODE" == "200" ]]; then
    echo -e "${GREEN}✓ Successfully published message to task-events topic${NC}"
    TESTS_PASSED=$((TESTS_PASSED+1))
else
    echo -e "${RED}✗ Failed to publish message (HTTP $HTTP_CODE)${NC}"
    echo -e "${YELLOW}  Response: $(echo "$RESPONSE" | head -n-1)${NC}"
    TESTS_FAILED=$((TESTS_FAILED+1))
fi
echo ""

# Test 6: Check Kafka UI
echo -e "${BLUE}[Test 6/6] Checking Kafka UI...${NC}"
if curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Kafka UI is accessible at http://localhost:8080${NC}"
    TESTS_PASSED=$((TESTS_PASSED+1))
else
    echo -e "${YELLOW}⚠ Kafka UI is not accessible${NC}"
    echo -e "${YELLOW}  Start with: docker compose --profile kafka up -d kafka-ui${NC}"
    TESTS_FAILED=$((TESTS_FAILED+1))
fi
echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
TOTAL_TESTS=$((TESTS_PASSED+TESTS_FAILED))
echo "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"

if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo ""
    echo "To fix issues:"
    echo "  1. Ensure all services are running: docker ps"
    echo "  2. Check logs: docker compose logs -f"
    echo "  3. Restart services: ./start-with-kafka.sh"
    exit 1
else
    echo -e "${GREEN}Failed: 0${NC}"
    echo ""
    echo -e "${GREEN}All tests passed! Kafka & Dapr integration is working correctly.${NC}"
fi
