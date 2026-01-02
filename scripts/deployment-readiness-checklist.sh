#!/bin/bash
# ========================================================================
# Deployment Readiness Checklist for TaskFlow
# ========================================================================
# This script verifies that all required infrastructure components
# are in place before deployment.
#
# Usage: ./scripts/deployment-readiness-checklist.sh
# ========================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Checklist items
CHECKS_PASSED=0
CHECKS_FAILED=0

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; ((CHECKS_PASSED++)); }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; ((CHECKS_FAILED++)); }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_header() { echo ""; echo "========================================"; echo -e "${YELLOW}$1${NC}"; echo "========================================"; }

# Check 1: Prerequisites
check_prerequisites() {
    log_header "1. Prerequisites"

    if command -v kubectl &> /dev/null; then
        log_pass "kubectl is installed"
    else
        log_fail "kubectl is NOT installed"
    fi

    if command -v helm &> /dev/null; then
        log_pass "helm is installed"
    else
        log_fail "helm is NOT installed"
    fi

    if command -v minikube &> /dev/null; then
        log_pass "minikube is installed"
    else
        log_fail "minikube is NOT installed"
    fi

    if command -v dapr &> /dev/null; then
        log_pass "dapr CLI is installed"
    else
        log_fail "dapr CLI is NOT installed"
    fi

    if command -v docker &> /dev/null; then
        log_pass "docker is installed"
    else
        log_fail "docker is NOT installed"
    fi

    if docker info &> /dev/null; then
        log_pass "docker daemon is running"
    else
        log_fail "docker daemon is NOT running"
    fi
}

# Check 2: Kubernetes Configuration Files
check_k8s_files() {
    log_header "2. Kubernetes Configuration Files"

    local required_files=(
        "k8s/strimzi/operator.yaml"
        "k8s/strimzi/kafka-cluster.yaml"
        "k8s/kafka-topics.yaml"
        "k8s/base/backend-deployment.yaml"
        "k8s/overlays/local/kustomization.yaml"
        "k8s/overlays/cloud/kustomization.yaml"
    )

    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            log_pass "$file exists"
        else
            log_fail "$file NOT found"
        fi
    done
}

# Check 3: Dapr Component Files
check_dapr_components() {
    log_header "3. Dapr Component Files"

    local required_files=(
        "dapr-components/kafka-pubsub.yaml"
        "dapr-components/statestore.yaml"
        "dapr-components/kubernetes-secrets.yaml"
    )

    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            log_pass "$file exists"
        else
            log_fail "$file NOT found"
        fi
    done
}

# Check 4: Helm Charts
check_helm_charts() {
    log_header "4. Helm Charts"

    local charts=(
        "helm-charts/todo-backend/Chart.yaml"
        "helm-charts/todo-backend/values.yaml"
        "helm-charts/todo-backend/templates/deployment.yaml"
        "helm-charts/todo-backend/templates/service.yaml"
        "helm-charts/todo-backend/templates/hpa.yaml"
        "helm-charts/todo-recurring-service/Chart.yaml"
        "helm-charts/todo-recurring-service/values.yaml"
        "helm-charts/todo-recurring-service/templates/deployment.yaml"
        "helm-charts/todo-recurring-service/templates/service.yaml"
        "helm-charts/todo-recurring-service/templates/hpa.yaml"
        "helm-charts/todo-notification-service/Chart.yaml"
        "helm-charts/todo-notification-service/values.yaml"
        "helm-charts/todo-notification-service/templates/deployment.yaml"
        "helm-charts/todo-notification-service/templates/service.yaml"
        "helm-charts/todo-notification-service/templates/hpa.yaml"
        "helm-charts/dapr-components/Chart.yaml"
        "helm-charts/dapr-components/values.yaml"
        "helm-charts/dapr-components/templates/kafka-pubsub.yaml"
        "helm-charts/dapr-components/templates/statestore.yaml"
        "helm-charts/dapr-components/templates/kubernetes-secrets.yaml"
    )

    for chart in "${charts[@]}"; do
        if [ -f "$chart" ]; then
            log_pass "$chart exists"
        else
            log_fail "$chart NOT found"
        fi
    done
}

# Check 5: Deployment Scripts
check_deployment_scripts() {
    log_header "5. Deployment Scripts"

    local scripts=(
        "scripts/setup-minikube.sh"
        "scripts/setup-dapr-local.sh"
        "scripts/build-images-local.sh"
        "scripts/deploy-local.sh"
        "scripts/test-local-deployment.sh"
        "scripts/provision-oke.sh"
    )

    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            log_pass "$script exists"
        else
            log_fail "$script NOT found"
        fi
    done

    # Check if scripts are executable
    for script in "scripts/"*.sh; do
        if [ -x "$script" ]; then
            log_pass "$(basename $script) is executable"
        else
            log_warn "$(basename $script) is NOT executable - run: chmod +x $script"
        fi
    done
}

# Check 6: Backend Service Files
check_backend_files() {
    log_header "6. Backend Service Files"

    local required_files=(
        "backend/models.py"
        "backend/schemas.py"
        "backend/enums.py"
        "backend/main.py"
        "backend/service.py"
        "backend/routes/chat.py"
        "backend/routes/reminders.py"
        "backend/routes/jobs.py"
        "backend/services/event_publisher.py"
        "backend/services/dapr_jobs_client.py"
        "backend/utils/recurrence_parser.py"
        "backend/utils/recurrence_calculator.py"
        "backend/utils/reminder_parser.py"
        "backend/utils/validators.py"
        "backend/agents/main_agent.py"
        "backend/agents/skills/task_management.py"
        "backend/agents/skills/task_search.py"
        "backend/agents/skills/task_analytics.py"
    )

    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            log_pass "$file exists"
        else
            log_fail "$file NOT found"
        fi
    done
}

# Check 7: MCP Tools
check_mcp_tools() {
    log_header "7. MCP Tools"

    local tools=(
        "backend/mcp_tools/create_recurring_task.py"
        "backend/mcp_tools/complete_task.py"
        "backend/mcp_tools/create_reminder.py"
        "backend/mcp_tools/cancel_reminder.py"
        "backend/mcp_tools/update_task_priority.py"
        "backend/mcp_tools/add_tags.py"
        "backend/mcp_tools/remove_tags.py"
        "backend/mcp_tools/search_tasks.py"
        "backend/mcp_tools/get_task_stats.py"
    )

    for tool in "${tools[@]}"; do
        if [ -f "$tool" ]; then
            log_pass "$(basename $tool) exists"
        else
            log_fail "$(basename $tool) NOT found"
        fi
    done
}

# Check 8: Documentation
check_documentation() {
    log_header "8. Documentation"

    local docs=(
        "README.md"
        "CLAUDE.md"
        "specs/001-phase-v-cloud-deployment/spec.md"
        "specs/001-phase-v-cloud-deployment/plan.md"
        "specs/001-phase-v-cloud-deployment/tasks.md"
        "specs/001-phase-v-cloud-deployment/data-model.md"
        "specs/001-phase-v-cloud-deployment/quickstart.md"
        "specs/001-phase-v-cloud-deployment/acceptance-criteria.md"
    )

    for doc in "${docs[@]}"; do
        if [ -f "$doc" ]; then
            log_pass "$(basename $doc) exists"
        else
            log_fail "$(basename $doc) NOT found"
        fi
    done
}

# Check 9: Required Environment Variables
check_env_vars() {
    log_header "9. Environment Variables"

    if [ -z "$GEMINI_API_KEY" ]; then
        log_warn "GEMINI_API_KEY is not set (required for chatbot)"
    else
        log_pass "GEMINI_API_KEY is set"
    fi

    if [ -z "$DATABASE_URL" ]; then
        log_warn "DATABASE_URL is not set (will use default from config)"
    else
        log_pass "DATABASE_URL is set"
    fi
}

# Check 10: Git Status
check_git_status() {
    log_header "10. Git Status"

    if [ -d ".git" ]; then
        log_pass "Git repository detected"

        echo ""
        echo "Current branch:"
        git branch --show-current 2>/dev/null || log_warn "Not in a git branch"

        echo ""
        echo "Uncommitted changes:"
        local status
        status=$(git status --porcelain 2>/dev/null || echo "")
        if [ -n "$status" ]; then
            echo "$status"
            log_warn "There are uncommitted changes"
        else
            log_pass "Working directory is clean"
        fi
    else
        log_fail "Not in a git repository"
    fi
}

# Print Summary
print_summary() {
    echo ""
    echo "========================================"
    echo "Deployment Readiness Summary"
    echo "========================================"
    echo ""
    echo -e "Checks Passed: ${GREEN}$CHECKS_PASSED${NC}"
    echo -e "Checks Failed: ${RED}$CHECKS_FAILED${NC}"
    echo ""

    if [ $CHECKS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All checks passed! Ready for deployment.${NC}"
        echo ""
        echo "Next steps:"
        echo "1. For local deployment:"
        echo "   ./scripts/setup-minikube.sh"
        echo "   ./scripts/deploy-local.sh"
        echo ""
        echo "2. For cloud deployment:"
        echo "   ./scripts/provision-oke.sh"
        echo ""
        echo "3. After deployment:"
        echo "   ./scripts/test-local-deployment.sh"
        return 0
    else
        echo -e "${RED}Some checks failed. Please address above issues.${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo "========================================"
    echo "TaskFlow Deployment Readiness Checklist"
    echo "========================================"
    echo ""

    check_prerequisites
    check_k8s_files
    check_dapr_components
    check_helm_charts
    check_deployment_scripts
    check_backend_files
    check_mcp_tools
    check_documentation
    check_env_vars
    check_git_status

    print_summary
}

main "$@"
