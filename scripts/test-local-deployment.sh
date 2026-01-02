#!/bin/bash
# ========================================================================
# Local Deployment Testing Script
# ========================================================================
# This script tests the TaskFlow deployment by verifying:
# - Task creation flow
# - Recurring task completion flow
# - Reminder scheduling flow
# - Kafka event flows
#
# Usage: ./scripts/test-local-deployment.sh
# Requires: kubectl, curl, jq
# ========================================================================

set -e

# Configuration
NAMESPACE="${NAMESPACE:-todo-app}"
BACKEND_URL="http://localhost:8000"
API_PREFIX="${API_PREFIX:-/api}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; ((TESTS_PASSED++)); }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; ((TESTS_FAILED++)); }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v curl &> /dev/null; then
        log_fail "curl not found"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        log_warn "jq not found - some output will be raw JSON"
    fi

    log_info "Prerequisites satisfied"
}

setup_port_forward() {
    log_info "Setting up port forward to backend..."
    kubectl port-forward -n "$NAMESPACE" svc/taskflow-backend 8000:80 &>/dev/null &
    PF_PID=$!
    sleep 3

    if ! kill -0 $PF_PID 2>/dev/null; then
        log_fail "Failed to start port forward"
        exit 1
    fi

    log_info "Port forward started (PID: $PF_PID)"
}

cleanup_port_forward() {
    if [ -n "$PF_PID" ]; then
        log_info "Cleaning up port forward..."
        kill $PF_PID 2>/dev/null || true
    fi
}

test_health_endpoint() {
    log_info "Testing health endpoint..."

    local response
    response=$(curl -s "$BACKEND_URL/health" || echo "")

    if echo "$response" | grep -q "ok"; then
        log_pass "Health endpoint responds"
    else
        log_fail "Health endpoint failed: $response"
    fi
}

test_create_task() {
    log_info "Testing task creation..."

    local task_data='{"title": "Test task from automation", "description": "Created by test script", "priority": "medium"}'
    local response
    response=$(curl -s -X POST "$BACKEND_URL$API_PREFIX/tasks/" \
        -H "Content-Type: application/json" \
        -d "$task_data")

    if echo "$response" | grep -q '"success":true'; then
        log_pass "Task creation works"
        TASK_ID=$(echo "$response" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
        echo "  Created task ID: $TASK_ID"
        echo "$TASK_ID"
    else
        log_fail "Task creation failed: $response"
        echo ""
    fi
}

test_list_tasks() {
    log_info "Testing task listing..."

    local response
    response=$(curl -s "$BACKEND_URL$API_PREFIX/tasks/")

    if echo "$response" | grep -q "tasks"; then
        log_pass "Task listing works"
        local count=$(echo "$response" | grep -o '"total_count":[0-9]*' | head -1 | cut -d: -f2)
        echo "  Total tasks: $count"
    else
        log_fail "Task listing failed: $response"
    fi
}

test_create_recurring_task() {
    log_info "Testing recurring task creation..."

    local task_data='{"title": "Weekly meeting", "description": "Recurring task test", "recurrence": "weekly"}'
    local response
    response=$(curl -s -X POST "$BACKEND_URL$API_PREFIX/tasks/" \
        -H "Content-Type: application/json" \
        -d "$task_data")

    if echo "$response" | grep -q '"success":true'; then
        log_pass "Recurring task creation works"
        RECURRING_TASK_ID=$(echo "$response" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
        echo "  Created recurring task ID: $RECURRING_TASK_ID"
        echo "$RECURRING_TASK_ID"
    else
        log_fail "Recurring task creation failed: $response"
        echo ""
    fi
}

test_complete_task() {
    local task_id=$1

    if [ -z "$task_id" ]; then
        log_warn "No task ID provided for completion test"
        return
    fi

    log_info "Testing task completion (ID: $task_id)..."

    local response
    response=$(curl -s -X POST "$BACKEND_URL$API_PREFIX/tasks/$task_id/complete")

    if echo "$response" | grep -q '"success":true'; then
        log_pass "Task completion works"

        # Check if next occurrence was created
        if echo "$response" | grep -q '"next_occurrence"'; then
            log_pass "Next occurrence created for recurring task"
        fi
    else
        log_fail "Task completion failed: $response"
    fi
}

test_create_reminder() {
    log_info "Testing reminder creation..."

    local from_date=$(date -d "+1 day" +%Y-%m-%d 2>/dev/null || date -v+1d +%Y-%m-%d)
    local task_data='{"title": "Task with reminder", "description": "Task to test reminders", "due_date": "'"$from_date"T10:00:00Z\"}", "priority": "high"}'

    # First create a task
    local task_response
    task_response=$(curl -s -X POST "$BACKEND_URL$API_PREFIX/tasks/" \
        -H "Content-Type: application/json" \
        -d "$task_data")

    local task_id
    task_id=$(echo "$task_response" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)

    if [ -z "$task_id" ]; then
        log_fail "Could not create task for reminder test"
        return
    fi

    log_info "Created task $task_id for reminder test"

    # Now create a reminder
    local reminder_data='{"task_id": '$task_id', "offset_minutes": 60}'
    local response
    response=$(curl -s -X POST "$BACKEND_URL$API_PREFIX/reminders/" \
        -H "Content-Type: application/json" \
        -d "$reminder_data")

    if echo "$response" | grep -q '"success":true'; then
        log_pass "Reminder creation works"
        local reminder_id=$(echo "$response" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
        echo "  Created reminder ID: $reminder_id"

        # Cancel the reminder
        curl -s -X DELETE "$BACKEND_URL$API_PREFIX/reminders/$reminder_id" > /dev/null
        log_info "Cleaned up test reminder"
    else
        log_fail "Reminder creation failed: $response"
    fi
}

test_search_tasks() {
    log_info "Testing task search..."

    local search_data='{"query": "test", "filters": {"status": "pending"}}'
    local response
    response=$(curl -s -X POST "$BACKEND_URL$API_PREFIX/tasks/search" \
        -H "Content-Type: application/json" \
        -d "$search_data")

    if echo "$response" | grep -q '"results"'; then
        log_pass "Task search works"
    else
        log_fail "Task search failed: $response"
    fi
}

test_priority_update() {
    log_info "Testing priority update..."

    local task_id=$1

    if [ -z "$task_id" ]; then
        log_warn "No task ID provided for priority update test"
        return
    fi

    local priority_data='{"priority": "high"}'
    local response
    response=$(curl -s -X PUT "$BACKEND_URL$API_PREFIX/tasks/$task_id/priority" \
        -H "Content-Type: application/json" \
        -d "$priority_data")

    if echo "$response" | grep -q '"success":true'; then
        log_pass "Priority update works"
    else
        log_fail "Priority update failed: $response"
    fi
}

test_tags() {
    log_info "Testing tag operations..."

    local task_id=$1

    if [ -z "$task_id" ]; then
        log_warn "No task ID provided for tag test"
        return
    fi

    local tags_data='{"tags": ["#test", "#automation"]}'
    local response
    response=$(curl -s -X POST "$BACKEND_URL$API_PREFIX/tasks/$task_id/tags" \
        -H "Content-Type: application/json" \
        -d "$tags_data")

    if echo "$response" | grep -q '"success":true'; then
        log_pass "Add tags works"
    else
        log_fail "Add tags failed: $response"
    fi
}

verify_kafka_events() {
    log_info "Checking Kafka topics..."

    if kubectl get kafkatopics -n strimzi &>/dev/null; then
        local topics
        topics=$(kubectl get kafkatopics -n strimzi -o name 2>/dev/null | wc -l)

        if [ "$topics" -gt 0 ]; then
            log_pass "Kafka topics exist ($topics topics)"
            kubectl get kafkatopics -n strimzi 2>/dev/null
        else
            log_warn "No Kafka topics found"
        fi
    else
        log_warn "Kafka topics not available (Strimzi may not be ready)"
    fi
}

verify_dapr_components() {
    log_info "Checking Dapr components..."

    if kubectl get components -n "$NAMESPACE" &>/dev/null; then
        local components
        components=$(kubectl get components -n "$NAMESPACE" -o name 2>/dev/null | wc -l)

        if [ "$components" -gt 0 ]; then
            log_pass "Dapr components exist ($components components)"
            kubectl get components -n "$NAMESPACE" 2>/dev/null
        else
            log_warn "No Dapr components found"
        fi
    else
        log_warn "Dapr not available"
    fi
}

print_summary() {
    echo ""
    echo "=============================================================="
    echo "Test Summary"
    echo "=============================================================="
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed. Check output above.${NC}"
        return 1
    fi
}

main() {
    echo "=============================================================="
    echo "TaskFlow Local Deployment Testing Script"
    echo "=============================================================="
    echo ""

    check_prerequisites
    setup_port_forward

    trap cleanup_port_forward EXIT

    echo ""
    echo "=== Core API Tests ==="

    test_health_endpoint
    test_list_tasks

    echo ""
    echo "=== Task CRUD Tests ==="

    TASK_ID=$(test_create_task)
    test_priority_update "$TASK_ID"
    test_tags "$TASK_ID"

    echo ""
    echo "=== Recurring Task Tests ==="

    RECURRING_TASK_ID=$(test_create_recurring_task)
    test_complete_task "$RECURRING_TASK_ID"

    echo ""
    echo "=== Reminder Tests ==="

    test_create_reminder

    echo ""
    echo "=== Search Tests ==="

    test_search_tasks

    echo ""
    echo "=== Infrastructure Verification ==="

    verify_kafka_events
    verify_dapr_components

    print_summary
}

main "$@"
