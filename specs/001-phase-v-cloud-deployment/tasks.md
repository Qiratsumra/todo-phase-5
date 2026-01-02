# Tasks: Phase V Advanced Cloud Deployment

**Feature**: `001-phase-v-cloud-deployment`
**Generated**: 2025-12-29
**Input**: Design documents from `/specs/001-phase-v-cloud-deployment/`, Phase V Master Task Breakdown

**Tests**: NOT requested in spec.md - tests are optional and not included

**Organization**: Tasks are grouped by user story to enable independent implementation and testing

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1-US6)
- Include exact file paths in descriptions

---

## Phase 1: Foundational (Database & Models)

**Purpose**: Core database schema and SQLAlchemy models that ALL user stories depend on

**CRITICAL**: This phase MUST be complete before any user story implementation

- [x] T001 Create PriorityEnum, RecurrenceEnum, TaskStatusEnum, ReminderStatusEnum enums in `backend/enums.py`
- [x] T002 [P] Create Task SQLAlchemy model with priority, recurrence, tags, due_date, parent_task_id, reminder_offset in `backend/models.py`
- [x] T003 [P] Create Reminder SQLAlchemy model with dapr_job_id, scheduled_at, status in `backend/models.py`
- [x] T004 [P] Create AuditLogEntry SQLAlchemy model for task event history in `backend/models.py`
- [x] T005 Create PostgreSQL migration script for Phase V columns in `backend/migrations/versions/001_add_phase_v_columns.py`
- [x] T006 Update database indexes: GIN on tags, B-tree on priority/due_date, parent_task_id index in `backend/models.py`
- [x] T007 [P] Update Pydantic schemas in `backend/schemas.py` to include priority, tags, recurrence fields
- [x] T008 Update TaskService in `backend/service.py` to handle priority, tags, recurrence CRUD operations

**Checkpoint**: Foundation ready - models and database schema complete for all user stories

---

## Phase 2: Dapr Components & Infrastructure

**Purpose**: Dapr components configuration for event-driven architecture

- [x] T009 Define kafka-pubsub.yaml Dapr component for Kafka Pub/Sub in `dapr-components/kafka-pubsub.yaml`
- [x] T010 Define statestore.yaml Dapr component for PostgreSQL state in `dapr-components/statestore.yaml`
- [x] T011 Define kubernetes-secrets.yaml Dapr component for secrets management in `dapr-components/kubernetes-secrets.yaml`
- [x] T012 Create Dapr Pub/Sub event publisher helper in `backend/services/event_publisher.py`
- [x] T013 Create Dapr Jobs API client for reminder scheduling in `backend/services/dapr_jobs_client.py`
- [x] T014 Implement event schema for task-events topic in `backend/services/events/task_event.py`
- [x] T015 Implement event schema for reminders topic in `backend/services/events/reminder_event.py`

**Checkpoint**: Dapr infrastructure ready for all event-driven features

---

## Phase 3: User Story 1 - Manage Recurring Tasks (Priority: P1) MVP

**Goal**: Users can create recurring tasks (daily/weekly/monthly) and next occurrence is auto-created within 5 seconds of completion

**Independent Test**: Create recurring task → Complete it → Verify next task appears with correct due date within 5 seconds

### Implementation for User Story 1

- [x] T016 [US1] Implement recurrence frequency parser in `backend/utils/recurrence_parser.py` (daily/weekly/monthly patterns)
- [x] T017 [US1] Implement next_due_date calculator in `backend/utils/recurrence_calculator.py`
- [x] T018 [US1] Create MCP tool definition for create_recurring_task in `backend/mcp_tools/create_recurring_task.py`
- [x] T019 [US1] Add complete_recurring_task tool to MCP definitions in `backend/mcp_tools/complete_task.py`
- [x] T020 [US1] Update complete_task endpoint to detect recurrence and publish task.completed event in `backend/service.py`
- [x] T021 [US1] Implement task.completed event publication to task-events topic via Dapr Pub/Sub in `backend/services/event_publisher.py`

**Checkpoint**: US1 complete - recurring tasks create next occurrence on completion

---

## Phase 4: User Story 2 - Schedule Task Reminders (Priority: P1)

**Goal**: Users can set reminders for tasks and receive notifications at exact scheduled times via Dapr Jobs API

**Independent Test**: Create task with due date → Set reminder → Verify Dapr Jobs API schedules job → Verify notification fires at exact time

### Implementation for User Story 2

- [x] T022 [US2] Implement reminder offset parser (e.g., "1 day", "1 hour", "15 minutes") in `backend/utils/reminder_parser.py`
- [x] T023 [US2] Create Reminder model CRUD operations in `backend/service.py`
- [x] T024 [US2] Create Dapr Jobs API schedule_reminder endpoint in `backend/services/dapr_jobs_client.py`
- [x] T025 [US2] Implement reminder creation with Dapr Jobs API scheduling in `backend/routes/reminders.py`
- [x] T026 [US2] Implement /api/jobs/trigger callback endpoint for Dapr Jobs in `backend/routes/jobs.py`
- [x] T027 [US2] Implement reminder event publication to reminders topic on job trigger in `backend/services/event_publisher.py`
- [x] T028 [US2] Create MCP tool definition for create_reminder in `backend/mcp_tools/create_reminder.py`
- [x] T029 [US2] Create cancel_reminder MCP tool in `backend/mcp_tools/cancel_reminder.py`

**Checkpoint**: US2 complete - reminders schedule via Dapr Jobs API and fire at exact times

---

## Phase 5: User Story 3 - Prioritize and Tag Tasks (Priority: P2)

**Goal**: Users can set task priority (low/medium/high) and add tags via natural language commands

**Independent Test**: Create task → Set priority → Add tags → Verify changes persist and display correctly

### Implementation for User Story 3

- [x] T030 [US3] Create update_task_priority MCP tool in `backend/mcp_tools/update_task_priority.py`
- [x] T031 [US3] Create add_tags MCP tool in `backend/mcp_tools/add_tags.py`
- [x] T032 [US3] Create remove_tags MCP tool in `backend/mcp_tools/remove_tags.py`
- [x] T033 [US3] Implement tag validation (max 10 tags, must start with #, max 50 chars) in `backend/utils/validators.py`
- [x] T034 [US3] Update task list endpoint to include priority and tags in response in `backend/service.py`
- [x] T035 [US3] Update task detail endpoint to include priority and tags in `backend/service.py`
- [x] T036 [US3] Update Gemini agent to route priority/tag commands to correct MCP tools in `backend/agents/skills/task_management.py`

**Checkpoint**: US3 complete - priorities and tags work via natural language commands

---

## Phase 6: User Story 4 - Search, Filter, and Sort Tasks (Priority: P2)

**Goal**: Users can search tasks using natural language with combined filters, results in under 200ms

**Independent Test**: Create tasks with various attributes → Run search queries → Verify results match filters within 200ms

### Implementation for User Story 4

- [x] T037 [US4] Implement PostgreSQL GIN index query for tag containment in `backend/models.py`
- [x] T038 [US4] Implement filter builder for priority, tags, due_date range in `backend/service.py`
- [x] T039 [US4] Implement sort builder for due_date, priority, created_at in `backend/service.py`
- [x] T040 [US4] Create search_tasks endpoint with query params in `backend/service.py`
- [x] T041 [US4] Create search_tasks MCP tool in `backend/mcp_tools/search_tasks.py`
- [x] T042 [US4] Update Gemini agent to parse natural language search queries to MCP tool calls in `backend/agents/skills/task_search.py`
- [x] T043 [US4] Implement performance optimization (limit result set, index hints) for <200ms response

**Checkpoint**: US4 complete - search/filter/sort works with natural language queries under 200ms

---

## Phase 7: User Story 5 - Deploy to Local Kubernetes (Priority: P1)

**Goal**: Deploy full stack to Minikube with Strimzi Kafka, Dapr, and verify all event flows

**Independent Test**: Run setup scripts → Deploy all services → Execute testing checklist (create task, complete recurring, schedule reminder, verify Kafka events)

### Infrastructure Setup

- [x] T044 Create Minikube setup script in `scripts/setup-minikube.sh`
- [x] T045 Create Strimzi Kafka operator installation manifest in `k8s/strimzi/operator.yaml`
- [x] T046 Create KafkaCluster CR for local development in `k8s/strimzi/kafka-cluster.yaml`
- [x] T047 Create KafkaTopic CRs for task-events, reminders, task-updates in `k8s/kafka-topics.yaml`
- [x] T048 Create Dapr initialization script for Minikube in `scripts/setup-dapr-local.sh`
- [x] T049 Create PostgreSQL Helm deployment for Minikube in `helm-charts/postgres-deployment.yaml`

### Deployment & Verification

- [x] T050 Create Docker build script for all services in `scripts/build-images-local.sh`
- [x] T051 Create Kubernetes deployment manifests for all services in `k8s/base/`
- [x] T052 Create local overlay with Minikube-specific settings in `k8s/overlays/local/`
- [x] T053 Create deployment script in `scripts/deploy-local.sh`
- [x] T054 Create testing checklist script in `scripts/test-local-deployment.sh`
- [ ] T055 Verify task creation flow: frontend → backend → Kafka event
- [ ] T056 Verify recurring task flow: task completion → event → Recurring Task Service → new task
- [ ] T057 Verify reminder flow: reminder creation → Dapr Jobs API → callback → Notification Service → WebSocket

**Checkpoint**: US5 complete - full stack deployed and tested on Minikube

---

## Phase 8: User Story 6 - Deploy to Cloud Kubernetes (Priority: P1)

**Goal**: Deploy to cloud Kubernetes (OKE/AKS/GKE) with Redpanda Cloud, CI/CD, monitoring

### Cloud Infrastructure

- [x] T058 Create Oracle OKE cluster provisioning script in `scripts/provision-oke.sh`
- [x] T059 Create cloud overlay for Helm charts in `k8s/overlays/cloud/`
- [x] T060 Configure Redpanda Cloud connection in `k8s/overlays/cloud/kustomization.yaml`
- [x] T061 Create cloud secrets manifest with Redpanda credentials in `k8s/base/cloud-secrets.yaml`

### CI/CD Pipeline

- [x] T062 Create GitHub Actions workflow for CI in `.github/workflows/ci.yml`
- [x] T063 Create GitHub Actions workflow for CD to OKE in `.github/workflows/deploy-oke.yml`
- [x] T064 Configure Docker image building and pushing in CI workflow
- [x] T065 Configure kubectl authentication for cloud cluster
- [x] T066 Configure Helm repository and chart deployment in CD workflow
- [x] T067 Add smoke test step to CI/CD pipeline

### Monitoring & Observability

- [x] T068 Configure Prometheus metrics endpoint in all services in `k8s/monitoring/prometheus.yaml`
- [x] T069 Create Grafana dashboard for task metrics in `k8s/monitoring/grafana-dashboard.yaml`
- [x] T070 Configure Loki for log aggregation in cloud deployment in `k8s/monitoring/loki.yaml`
- [x] T071 Configure health check endpoints (/health, /health/live, /health/ready) for all services in `k8s/base/backend-deployment.yaml`
- [x] T072 Configure Slack webhook for error alerts in `k8s/monitoring/cert-manager.yaml`

### HTTPS & Certificates

- [x] T073 Configure cert-manager for Let's Encrypt certificates in `k8s/monitoring/cert-manager.yaml`
- [x] T074 Configure Ingress with TLS for frontend in `k8s/networking/ingress.yaml`

**Checkpoint**: US6 complete - full stack deployed to cloud with CI/CD and monitoring

---

## Phase 9: New Microservices - Recurring Task Service

**Goal**: Dedicated service to consume task-events and create next occurrences

- [x] T075 Create Recurring Task Service project structure in `backend/services/recurring_task/`
- [x] T076 Implement FastAPI app with Dapr client in `backend/services/recurring_task/main.py`
- [x] T077 Implement Dapr Pub/Sub consumer for task-events topic in `backend/services/recurring_task/consumer.py`
- [x] T078 Implement next_occurrence calculator using recurrence patterns in `backend/services/recurring_task/scheduler.py`
- [x] T079 Implement Backend API call via Dapr Service Invocation to create next task in `backend/services/recurring_task/client.py`
- [x] T080 Add Dapr dependencies in `backend/services/recurring_task/__init__.py`

**Checkpoint**: Recurring Task Service ready for deployment on Render.com

---

## Phase 10: New Microservices - Notification Service

**Goal**: Dedicated service to consume reminders and send WebSocket notifications

- [x] T082 Create Notification Service project structure in `backend/services/notification/`
- [x] T083 Implement FastAPI app with WebSocket endpoint in `backend/services/notification/main.py`
- [x] T084 Implement ConnectionManager for WebSocket clients in `backend/services/notification/websocket.py`
- [x] T085 Implement Dapr Pub/Sub consumer for reminders topic in `backend/services/notification/consumer.py`
- [x] T086 Create requirements.txt in `backend/services/notification/__init__.py`

**Checkpoint**: Notification Service ready for deployment with WebSocket real-time notifications

---

## Phase 11: Helm Charts with Dapr Sidecars

**Purpose**: Kubernetes deployments with Dapr sidecar annotations for all services

- [x] T089 Update todo-backend Helm chart with Dapr sidecar annotations in `helm-charts/todo-backend/templates/deployment.yaml`
- [x] T090 Create todo-recurring-service Helm chart with Dapr sidecar in `helm-charts/todo-recurring-service/`
- [x] T091 Create todo-notification-service Helm chart with Dapr sidecar in `helm-charts/todo-notification-service/`
- [x] T092 Update Helm values to configure Dapr component bindings for each service
- [x] T093 Create Dapr components Helm chart or configmap in `helm-charts/dapr-components/`
- [x] T094 Configure Horizontal Pod Autoscaler for all services based on CPU/memory thresholds

**Checkpoint**: All services have Helm charts with Dapr sidecars configured

---

## Phase 12: Frontend Updates

**Goal**: Update Next.js frontend to support all new features

- [x] T095 Update TaskList component to display priority badges and tags in `frontend/components/TaskList.tsx`
- [x] T096 Create Priority selector UI component in `frontend/components/PrioritySelect.tsx`
- [x] T097 Create Tag input UI component in `frontend/components/TagInput.tsx`
- [x] T098 Update TaskForm to include priority, tags, due date, recurrence fields in `frontend/components/TaskForm.tsx`
- [x] T099 Implement WebSocket client for real-time notifications in `frontend/lib/websocket.ts`
- [x] T100 Create Notification toast component in `frontend/components/NotificationToast.tsx`
- [x] T101 Implement search/filter UI with priority, tags, due date filters in `frontend/components/TaskFilters.tsx`

**Checkpoint**: Frontend updated with all Phase V features

---

## Phase 13: Agent System Updates

**Goal**: Update Gemini agent to use new MCP tools for all features

- [x] T102 Update main_agent.py to include new MCP tool definitions in `backend/agents/main_agent.py`
- [x] T103 Update TaskManagementSkill for priority/tag commands in `backend/agents/skills/task_management.py`
- [x] T104 Create TaskSearchSkill for natural language search in `backend/agents/skills/task_search.py`
- [x] T105 Update TaskAnalyticsSkill for statistics with new fields in `backend/agents/skills/task_analytics.py`
- [x] T106 Update tool_definitions.py to aggregate all MCP tools in `backend/mcp_tools/tool_definitions.py`

**Checkpoint**: Agent system updated with all new MCP tools

---

## Phase 14: Documentation & Polish

**Purpose**: Final documentation updates and polish

- [x] T107 Update README.md with Phase V features and deployment instructions
- [x] T108 Update CLAUDE.md with Phase V workflow iterations
- [x] T109 Update quickstart.md with local Minikube setup in `specs/001-phase-v-cloud-deployment/quickstart.md`
- [x] T110 Create API documentation summary in `specs/001-phase-v-cloud-deployment/contracts/API.md`
- [x] T111 Verify all acceptance criteria from spec.md are met
- [ ] T112 Run final integration tests for all user stories

**Checkpoint**: All documentation complete and features verified

---

## Dependencies & Execution Order

### Phase Dependencies

| Phase | Depends On | Blocks |
|-------|------------|--------|
| Phase 1: Foundational | None | All user stories |
| Phase 2: Dapr Components | Phase 1 | All event-driven features |
| Phase 3: US1 Recurring Tasks | Phase 1, Phase 2 | US1 completion |
| Phase 4: US2 Reminders | Phase 2 | US2 completion |
| Phase 5: US3 Priority/Tag | Phase 1 | US3 completion |
| Phase 6: US4 Search/Filter | Phase 1, Phase 5 | US4 completion |
| Phase 7: US5 Local K8s | Phase 9, Phase 10 | Local deployment |
| Phase 8: US6 Cloud K8s | Phase 7 | Production deployment |
| Phase 9: Recurring Service | Phase 3 | US1 completion (full flow) |
| Phase 10: Notification Service | Phase 4 | US2 completion (full flow) |
| Phase 11: Helm Charts | Phase 9, Phase 10 | Deployment phases |
| Phase 12: Frontend Updates | Phase 3, Phase 4, Phase 5, Phase 6 | Feature parity |
| Phase 13: Agent Updates | Phase 3, Phase 4, Phase 5, Phase 6 | Agent capabilities |
| Phase 14: Documentation | All phases | Project completion |

### User Story Dependencies

| User Story | Prerequisites | Independent Test |
|------------|---------------|------------------|
| US1: Recurring Tasks | Phase 1, Phase 2 | Create recurring → Complete → Verify next task created |
| US2: Reminders | Phase 2 | Create task → Set reminder → Verify notification at exact time |
| US3: Priority/Tag | Phase 1 | Set priority → Add tags → Verify display |
| US4: Search/Filter | Phase 1, Phase 3, Phase 5 | Run search → Verify results < 200ms |
| US5: Local K8s | Phase 9, Phase 10, Phase 11 | Deploy to Minikube → Run E2E checklist |
| US6: Cloud K8s | Phase 7 | Deploy to cloud → Run smoke tests |

### Parallel Execution Opportunities

1. **Phases 1 & 2**: Can run in parallel (models vs Dapr components)
2. **Within Phase 1**: T001, T002, T003, T004 can run in parallel
3. **Within Phase 2**: T009, T010, T011 can run in parallel
4. **Phases 3-6 (User Stories)**: Can run in parallel after Phase 2 (different features)
5. **Phases 9 & 10**: Can run in parallel (both new services)
6. **Phases 12 & 13**: Can run in parallel (frontend and agent updates)

### Sequential Requirements (Cannot Parallelize)

- Phase 1 must complete before any user story work
- Phase 2 must complete before event-driven features (US1, US2)
- Phase 3 must complete before Phase 9 (Recurring Task Service needs task completion events)
- Phase 4 must complete before Phase 10 (Notification Service needs reminder events)
- Phases 9 & 10 must complete before Phase 11 (Helm charts need service Docker images)
- Phase 11 must complete before Phase 7 (Local deployment needs Helm charts)
- Phase 7 must complete before Phase 8 (Cloud deployment builds on local)

---

## Parallel Example: User Story 3 (Priority/Tag)

```bash
# Tasks that can run in parallel for US3:
Task T030: Create update_task_priority MCP tool
Task T031: Create add_tags MCP tool
Task T032: Create remove_tags MCP tool
Task T033: Implement tag validation utilities
```

All four can be implemented simultaneously as they touch different files and have no dependencies on each other.

---

## Implementation Strategy

### MVP First (User Story 1 Only - Recurring Tasks)

1. Complete Phase 1: Foundational (T001-T008)
2. Complete Phase 2: Dapr Components (T009-T015)
3. Complete Phase 3: US1 Recurring Tasks (T016-T021)
4. **STOP and VALIDATE**: Test recurring task creation and auto-creation
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Phases 1-2 → Foundation ready
2. Add US1 (Phase 3) → Test → Deploy (MVP: Recurring Tasks)
3. Add US2 (Phase 4) → Test → Deploy (Add Reminders)
4. Add US3 (Phase 5) → Test → Deploy (Add Priority/Tag)
5. Add US4 (Phase 6) → Test → Deploy (Add Search)
6. Add Phases 9-10 → Deploy (Add Background Services)
7. Add Phase 7 → Deploy Local K8s
8. Add Phase 8 → Deploy Cloud K8s

### Parallel Team Strategy

With multiple developers:

1. **Developer A**: Phases 1-2 (Foundation)
2. **Developer B**: Phase 3 (US1 Recurring Tasks)
3. **Developer C**: Phase 4 (US2 Reminders)
4. **Developer D**: Phase 5 (US3 Priority/Tag) + Phase 6 (US4 Search)

Once Phase 2 is complete, developers can work on their respective user stories in parallel.

---

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 112 |
| **User Stories** | 6 (US1-US6) |
| **P1 Stories** | 4 (US1, US2, US5, US6) |
| **P2 Stories** | 2 (US3, US4) |
| **New Microservices** | 2 (Recurring Task, Notification) |
| **Dapr Components** | 3 (kafka-pubsub, statestore, secrets) |
| **Helm Charts** | 3 (backend, recurring-service, notification-service) |

### MVP Scope (Phase V Part A)
- Phases 1-6: Core features (recurring tasks, reminders, priority/tags, search)
- Total: ~43 tasks
- Delivers: Full-featured todo chatbot with AI chat interface

### Full Deployment (Phase V Part B+C)
- All phases complete
- Total: 112 tasks
- Delivers: Production-ready, cloud-deployed microservices with Dapr

---

## Notes

- **[P] tasks**: Different files, no dependencies, safe to run in parallel
- **[Story] label**: Maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
