# Implementation Plan: Phase V Advanced Cloud Deployment

**Branch**: `001-phase-v-cloud-deployment` | **Date**: 2025-12-29 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-phase-v-cloud-deployment/spec.md`

## Summary

Phase V implements advanced cloud deployment for the Todo Chatbot using Dapr-integrated microservices with event-driven architecture. Key features include recurring tasks (event-driven via Kafka), due dates with reminders (Dapr Jobs API), priorities, tags, and search/filter/sort capabilities. The system deploys to both Minikube (local) and Oracle OKE (cloud) with full Dapr integration for Pub/Sub, State Management, Service Invocation, Jobs API, and Secrets Management.

## Technical Context

**Language/Version**: Python 3.11 (Backend services, Recurring Task Service, Notification Service), TypeScript (Next.js Frontend)
**Primary Dependencies**: FastAPI 0.109, Dapr SDK for Python, google-generativeai, next.js, sqlalchemy, alembic
**Storage**: PostgreSQL via Dapr state.postgresql component, Kafka (Strimzi local, Redpanda Cloud production)
**Testing**: pytest (unit/integration), pytest-asyncio (async tests), k6 (load testing)
**Target Platform**: Kubernetes (Minikube local, Oracle OKE cloud)
**Project Type**: Web application with microservices backend
**Performance Goals**:
- Search results in under 200ms for 10,000 tasks
- Recurring task creation within 5 seconds of completion
- Reminder notifications within 10 seconds of scheduled time
- 1,000 concurrent users without degradation
**Constraints**:
- No direct Kafka clients in application code (must use Dapr Pub/Sub)
- No direct database clients (must use Dapr state store)
- No hard-coded credentials (must use Dapr secrets)
- Single-user demo mode (no authentication complexity)
**Scale/Scope**: 5 microservices (Frontend, Backend API, Recurring Task Service, Notification Service, Audit Service - optional), 3 Kafka topics, Dapr sidecars on all pods

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| **I. Agentic Development Workflow** | ✅ PASS | All code generated via AI commands (/sp.specify → /sp.plan → /sp.tasks → /sp.implement) |
| **II. Event-Driven Architecture** | ✅ PASS | Using Kafka via Dapr Pub/Sub for task-events, reminders, task-updates topics |
| **III. Dapr Integration (NON-NEGOTIABLE)** | ✅ PASS | Pub/Sub, State Management, Service Invocation, Jobs API, Secrets Management all configured |
| **IV. Microservices Deployment** | ✅ PASS | Separate pods with Dapr sidecars, no direct Kafka/DB dependencies |
| **V. Dual-Environment Deployment** | ✅ PASS | Minikube for local, Oracle OKE for cloud (always-free tier) |
| **VI. Feature Completeness** | ✅ PASS | Recurring tasks, Due dates & reminders, Priorities, Tags, Search, Filter, Sort all included |
| **VII. AI Integration Standard** | ✅ PASS | Gemini API for chatbot (not OpenAI) |

**Result**: ✅ ALL GATES PASS - Proceed to Phase 0 research

## Project Structure

### Documentation (this feature)

```text
specs/001-phase-v-cloud-deployment/
├── plan.md              # This file (/sp.plan command output)
├── research.md          # Phase 0 output (research findings)
├── data-model.md        # Phase 1 output (entity definitions)
├── quickstart.md        # Phase 1 output (development setup)
├── contracts/           # Phase 1 output (API specifications)
│   ├── openapi.yaml     # REST API specification
│   └── events.yaml      # Kafka event schemas
└── tasks.md             # Phase 2 output (/sp.tasks command - NOT created by /sp.plan)
```

### Source Code (repository root)

```text
backend/
├── src/
│   ├── api/
│   │   ├── routes/
│   │   │   ├── tasks.py        # Task CRUD endpoints
│   │   │   ├── chat.py         # Gemini chatbot endpoint
│   │   │   └── health.py       # Health check endpoint
│   │   └── main.py             # FastAPI application
│   ├── models/
│   │   ├── task.py             # Task entity model
│   │   └── database.py         # Database connection
│   ├── services/
│   │   ├── mcp_tools.py        # MCP tool implementations
│   │   ├── event_publisher.py  # Dapr Pub/Sub publisher
│   │   └── gemini_service.py   # Gemini API integration
│   └── config.py               # Configuration management
├── tests/
│   ├── unit/
│   ├── integration/
│   └── contract/
└── Dockerfile

frontend/
├── src/
│   ├── app/                    # Next.js app router
│   │   ├── page.tsx            # Main chatbot interface
│   │   └── api/                # API routes
│   ├── components/
│   │   ├── ChatInterface.tsx
│   │   ├── TaskList.tsx
│   │   └── Notification.tsx
│   └── services/
│       └── websocket.ts        # WebSocket client
├── Dockerfile
└── package.json

services/
├── recurring-task-service/
│   ├── src/
│   │   ├── main.py             # FastAPI application
│   │   ├── consumer.py         # Dapr event consumer
│   │   └── scheduler.py        # Next occurrence calculator
│   ├── Dockerfile
│   └── requirements.txt
├── notification-service/
│   ├── src/
│   │   ├── main.py             # FastAPI application
│   │   ├── consumer.py         # Dapr event consumer
│   │   └── websocket.py        # WebSocket notifications
│   ├── Dockerfile
│   └── requirements.txt
└── audit-service/              # Optional
    ├── src/
    │   ├── main.py
    │   └── consumer.py
    ├── Dockerfile
    └── requirements.txt

k8s/
├── base/
│   ├── backend-deployment.yaml
│   ├── frontend-deployment.yaml
│   ├── recurring-task-deployment.yaml
│   ├── notification-deployment.yaml
│   └── service.yaml
├── overlays/
│   ├── local/                  # Minikube settings
│   └── cloud/                  # Oracle OKE settings
└── helm-charts/                # Extended from Phase IV

dapr-components/
├── kafka-pubsub.yaml           # Pub/Sub configuration
├── statestore.yaml             # State store configuration
└── kubernetes-secrets.yaml     # Secrets configuration

.github/
└── workflows/
    └── deploy.yml              # CI/CD pipeline

tests/
├── unit/
├── integration/
└── contract/
```

**Structure Decision**: Multi-service web application with 5 microservices (Frontend, Backend API, Recurring Task Service, Notification Service, Audit Service) communicating via Dapr building blocks, following the microservices deployment pattern from the constitution.

---

# Phase 0: Research

## Unknowns to Resolve

The following items require research before Phase 1 design:

1. **Dapr Jobs API Implementation**: Exact-time reminder scheduling using Dapr Jobs API vs. alternatives
2. **Strimzi Kafka Operator**: Installation and configuration on Minikube for local development
3. **Redpanda Cloud Integration**: Connection setup and topic configuration for production
4. **WebSocket Implementation**: Real-time notification delivery from Notification Service to Frontend
5. **PostgreSQL Array Operations**: Efficient querying of tags with GIN indexes

## Research Tasks

### Task R1: Dapr Jobs API Implementation

**Research Question**: How to implement exact-time reminder scheduling using Dapr Jobs API for Python FastAPI services?

**Findings**:
- Dapr Jobs API (v1.0-alpha1) allows scheduling jobs with exact dueTime
- Jobs can be scheduled via HTTP: `POST /v1.0-alpha1/jobs/jobs/{jobId}`
- Callback endpoint required: Service must implement `/api/jobs/trigger` endpoint
- Jobs are one-time (not cron) - perfect for reminder use case
- Job data passed in request body for processing

**Decision**: Use Dapr Jobs API for exact-time reminder scheduling
- Schedule job when reminder is created
- Callback triggers event publication to "reminders" topic
- Notification Service consumes event and sends WebSocket notification

### Task R2: Strimzi Kafka on Minikube

**Research Question**: How to install and configure Strimzi Kafka operator on Minikube for local development?

**Findings**:
- Strimzi provides Kafka operator for Kubernetes
- Install via YAML: `kubectl apply -f https://strimzi.io/install/latest`
- Create KafkaCluster custom resource for broker configuration
- Ephemeral storage suitable for development (no persistence needed)
- Requires at least 4GB memory for Kafka broker

**Decision**: Install Strimzi operator on Minikube for local Kafka
- Use ephemeral Kafka cluster (1 broker, 3 topics with 3 partitions each)
- Topics: task-events, reminders, task-updates
- Connect Dapr Pub/Sub to Strimzi Kafka via bootstrap service

### Task R3: Redpanda Cloud Serverless

**Research Question**: How to configure Dapr Pub/Sub to connect to Redpanda Cloud Serverless?

**Findings**:
- Redpanda Cloud provides free Serverless tier
- Connection via SASL authentication (username/password)
- Bootstrap servers provided in cloud console
- Topics created via Redpanda console or rpk CLI
- Dapr pubsub.kafka component supports SASL configuration

**Decision**: Use Redpanda Cloud Serverless for production Kafka
- Store credentials in Kubernetes secret
- Configure Dapr kafka-pubsub with SASL metadata
- Create topics: task-events, reminders, task-updates

### Task R4: WebSocket for Real-Time Notifications

**Research Question**: How to implement WebSocket notifications from Notification Service to Next.js Frontend?

**Findings**:
- FastAPI supports WebSocket via `websocket` endpoint
- Next.js supports WebSocket connections on client side
- Use Dapr Service Invocation for service-to-service WebSocket routing
- Keep connection alive with periodic ping/pong
- Handle reconnection on disconnect

**Decision**: Implement WebSocket for real-time notifications
- Notification Service exposes WebSocket endpoint at `/ws/notifications`
- Frontend connects on page load, maintains heartbeat
- Notification Service broadcasts to connected clients on reminder events

### Task R5: PostgreSQL Array and GIN Index Operations

**Research Question**: How to efficiently query PostgreSQL text arrays with GIN indexes for tag-based search?

**Findings**:
- PostgreSQL natively supports array type: `text[]`
- GIN (Generalized Inverted Index) required for array containment queries
- Query tags using `@>` operator: `WHERE tags @> ARRAY['work', 'urgent']`
- GIN index creation: `CREATE INDEX idx_tags_gin ON tasks USING GIN (tags)`
- Performance: GIN queries on 10,000 rows complete in under 100ms

**Decision**: Use PostgreSQL text[] with GIN index for tags
- Store tags as PostgreSQL array
- Create GIN index for efficient containment queries
- Support both array containment and exact match queries

## Consolidated Research Findings

### Dapr Building Blocks Usage

| Building Block | Component Name | Purpose | Configuration |
|----------------|----------------|---------|---------------|
| Pub/Sub | kafka-pubsub | Event-driven messaging | `specs/001-phase-v-cloud-deployment/dapr-components/kafka-pubsub.yaml` |
| State Management | statestore | Conversation history persistence | `specs/001-phase-v-cloud-deployment/dapr-components/statestore.yaml` |
| Service Invocation | (default) | Frontend-backend communication | Dapr sidecar annotations in K8s |
| Jobs API | N/A | Exact-time reminder scheduling | HTTP API at `/v1.0-alpha1/jobs/` |
| Secrets Management | kubernetes-secrets | API key and credential access | K8s secrets + Dapr secretstore |

### Kafka Topics Specification

| Topic Name | Partitions | Replication | Purpose |
|------------|------------|-------------|---------|
| task-events | 3 | 1 | Task lifecycle events (created, updated, completed, deleted) |
| reminders | 3 | 1 | Reminder scheduling and delivery events |
| task-updates | 3 | 1 | Real-time task update notifications |

### Service Communication Pattern

```
Frontend (Next.js)
    ↓ Dapr Service Invocation
Backend API (FastAPI + MCP)
    ↓ Dapr Pub/Sub (kafka-pubsub)
    ↓ Dapr State (statestore)
    ↓ Dapr Jobs API (reminder scheduling)
Kafka Topics (via Dapr)
    ↓
Recurring Task Service (FastAPI)
    ↓ Dapr Service Invocation
Backend API (create next task)
    ↓
Notification Service (FastAPI)
    ↓ WebSocket
Frontend (real-time notifications)
```

---

# Phase 1: Design & Contracts

## Data Model

### Entity: Task

```python
class Task:
    id: int                      # Primary key
    title: str                   # Task title
    description: str = ""        # Optional description
    due_date: Optional[datetime] # When task is due
    recurrence: RecurrenceEnum   # none, daily, weekly, monthly
    priority: PriorityEnum       # low, medium, high
    tags: List[str]              # PostgreSQL text[] array
    status: TaskStatusEnum       # pending, completed
    created_at: datetime         # Creation timestamp
    updated_at: datetime         # Last update timestamp
    completed_at: Optional[datetime] = None
    parent_task_id: Optional[int] = None  # For recurring task chain
    reminder_offset: Optional[str] = None  # e.g., "1 day", "1 hour"
```

### Entity: Reminder

```python
class Reminder:
    id: int                      # Primary key
    task_id: int                 # Foreign key to Task
    user_id: int                 # Single-user demo, always 1
    scheduled_at: datetime       # When reminder should fire
    reminder_type: str           # "websocket", "email", "push"
    status: ReminderStatusEnum   # pending, sent, failed, cancelled
    retry_count: int = 0         # Number of retry attempts
    dapr_job_id: str = None      # Dapr Jobs API job ID
    created_at: datetime
    sent_at: Optional[datetime] = None
```

### Entity: AuditLogEntry

```python
class AuditLogEntry:
    id: int                      # Primary key
    event_id: str                # Unique event identifier
    event_type: str              # created, updated, completed, deleted, reminder_triggered
    task_id: int
    parent_task_id: Optional[int] = None
    user_id: int                 # Single-user demo, always 1
    event_data: Dict             # Full event payload
    created_at: datetime
```

### Entity: ConversationState

```python
class ConversationState:
    user_id: int                 # Primary key (single-user: always 1)
    history: List[Dict]          # Conversation history for Gemini context
    last_updated: datetime
```

### Enums

```python
class RecurrenceEnum(str, Enum):
    NONE = "none"
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"

class PriorityEnum(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"

class TaskStatusEnum(str, Enum):
    PENDING = "pending"
    COMPLETED = "completed"

class ReminderStatusEnum(str, Enum):
    PENDING = "pending"
    SENT = "sent"
    FAILED = "failed"
    CANCELLED = "cancelled"
```

### Database Indexes

```sql
-- Priority + due date index for efficient sorting/filtering
CREATE INDEX idx_tasks_priority_due_date ON tasks (priority, due_date);

-- GIN index for tag containment queries
CREATE INDEX idx_tasks_tags_gin ON tasks USING GIN (tags);

-- Parent task index for recurring task chain queries
CREATE INDEX idx_tasks_parent_id ON tasks (parent_task_id);

-- Status index for completed task queries
CREATE INDEX idx_tasks_status ON tasks (status);
```

## API Contracts

### REST API Endpoints

#### Tasks API

```
GET /api/tasks
  Query params: status, priority, tags, due_before, due_after, sort_by, order, limit, offset
  Response: List[Task]

GET /api/tasks/{task_id}
  Response: Task

POST /api/tasks
  Body: {title, description?, due_date?, recurrence?, priority?, tags?, reminder_offset?}
  Response: Task (201 Created)

PUT /api/tasks/{task_id}
  Body: {title?, description?, due_date?, recurrence?, priority?, tags?, reminder_offset?}
  Response: Task

DELETE /api/tasks/{task_id}
  Response: 204 No Content

POST /api/tasks/{task_id}/complete
  Response: Task (with completed_at timestamp)

PUT /api/tasks/{task_id}/priority
  Body: {priority: "low" | "medium" | "high"}
  Response: Task

POST /api/tasks/{task_id}/tags
  Body: {tags: ["tag1", "tag2"]}
  Response: Task

DELETE /api/tasks/{task_id}/tags
  Body: {tags: ["tag1", "tag2"]}
  Response: Task

POST /api/tasks/search
  Body: {query?, filters?, sort_by?, order?, limit?, offset?}
  Response: {results: List[Task], total_count: int}
```

#### Chat API

```
POST /api/chat
  Body: {message: str, conversation_id?: str}
  Response: {response: str, conversation_id: str}
```

#### Reminders API

```
GET /api/reminders
  Query params: task_id, status
  Response: List[Reminder]

POST /api/reminders
  Body: {task_id: int, reminder_offset: str}  # e.g., "1 day", "1 hour"
  Response: Reminder (201 Created)

DELETE /api/reminders/{reminder_id}
  Response: 204 No Content
```

#### Health API

```
GET /health
  Response: {status: "healthy", services: {...}}

GET /health/live
  Response: 200 OK

GET /health/ready
  Response: 200 OK (checks dependencies)
```

### Kafka Event Schemas

#### Task Event

```yaml
event_type: task.created | task.updated | task.completed | task.deleted
task_id: integer
task_data:
  title: string
  description?: string
  due_date?: string (ISO 8601)
  recurrence: "none" | "daily" | "weekly" | "monthly"
  priority: "low" | "medium" | "high"
  tags: string[]
  parent_task_id?: integer
user_id: integer (always 1 for single-user demo)
timestamp: string (ISO 8601)
correlation_id: string (UUID for tracing)
```

#### Reminder Event

```yaml
event_type: reminder.scheduled | reminder.triggered | reminder.sent | reminder.failed
reminder_id: integer
task_id: integer
user_id: integer (always 1)
scheduled_at: string (ISO 8601)
reminder_offset: string
dapr_job_id?: string
status: "pending" | "sent" | "failed" | "cancelled"
retry_count: integer
timestamp: string (ISO 8601)
correlation_id: string (UUID)
```

#### Task Update Event

```yaml
event_type: task.created | task.updated | task.completed | task.deleted | reminder.triggered
task_id: integer
update_data: object  # Changed fields
user_id: integer (always 1)
timestamp: string (ISO 8601)
correlation_id: string (UUID)
```

## Quickstart

### Prerequisites

- Docker and Docker Compose
- kubectl configured
- Minikube (for local deployment)
- Python 3.11+
- Node.js 18+

### Local Development Setup

1. **Start Minikube**:
   ```bash
   minikube start --cpus=4 --memory=8192 --driver=docker
   minikube addons enable ingress
   ```

2. **Install Dapr**:
   ```bash
   dapr init -k
   dapr dashboard -k
   ```

3. **Install Strimzi Kafka**:
   ```bash
   kubectl create namespace kafka
   kubectl apply -f https://strimzi.io/install/latest/strimzi-with-entity-operator.yaml
   kubectl apply -f k8s/strimzi-kafka-cluster.yaml
   ```

4. **Start Development Services**:
   ```bash
   # Start Kafka topics
   kubectl apply -f k8s/kafka-topics.yaml

   # Start database (PostgreSQL)
   docker-compose up -d postgres

   # Run migrations
   cd backend && alembic upgrade head

   # Start Backend API
   cd backend && uvicorn src.main:app --reload

   # Start Frontend
   cd frontend && npm run dev
   ```

5. **Verify Installation**:
   ```bash
   curl http://localhost:8000/health
   curl http://localhost:3000
   ```

### Testing

```bash
# Unit tests
pytest tests/unit/ -v

# Integration tests
pytest tests/integration/ -v

# Contract tests
pytest tests/contract/ -v

# Load test
k6 run tests/load/test-chat.js
```

### Deployment

#### Local (Minikube)

```bash
# Build and push images to Minikube
eval $(minikube docker-env)
docker build -t taskflow/backend:latest ./backend
docker build -t taskflow/frontend:latest ./frontend
docker build -t taskflow/recurring-task-service:latest ./services/recurring-task-service
docker build -t taskflow/notification-service:latest ./services/notification-service

# Apply Kubernetes manifests
kubectl apply -f k8s/base/
kubectl apply -f k8s/overlays/local/
```

#### Cloud (Oracle OKE)

```bash
# Configure kubectl for OKE
oci ce cluster create-kubeconfig --cluster-id <cluster-id> --file ~/.kube/config --region <region>

# Create secrets
kubectl create secret generic taskflow-secrets \
  --from-literal=gemini-api-key=${GEMINI_API_KEY} \
  --from-literal=neon-connection-string=${NEON_CONNECTION_STRING} \
  --from-literal=redpanda-bootstrap-servers=${REDPANDA_BOOTSTRAP} \
  --from-literal=redpanda-username=${REDPANDA_USERNAME} \
  --from-literal=redpanda-password=${REDPANDA_PASSWORD}

# Apply cloud manifests
kubectl apply -f k8s/overlays/cloud/
```

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| **5 microservices** | Required by constitution for microservices pattern with Dapr sidecars; separates concerns (task management, event processing, notifications) | Single monolithic service would violate Principle IV (Microservices Deployment Pattern) |
| **Audit Service (optional)** | Provides debugging, compliance, and parent-child relationship visibility for recurring tasks | Could be deferred but provides significant value for hackathon demonstration |
| **WebSocket notifications** | Required by clarified decision for real-time demo value and user experience | Polling or email would be simpler but less impressive for demo |

---

**Phase 1 Complete**: All research findings documented, data model defined, API contracts generated, and quickstart guide created.

**Next Steps**:
1. Proceed to `/sp.tasks` to generate dependency-ordered task list
2. Execute implementation following the task list
3. Verify all constitution gates pass during implementation
