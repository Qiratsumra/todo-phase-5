# Feature Specification: Phase V Advanced Cloud Deployment

**Feature Branch**: `001-phase-v-cloud-deployment`
**Created**: 2025-12-29
**Status**: Draft
**Input**: User description: "PHASE V: Advanced Cloud Deployment - Dapr-integrated microservices with recurring tasks, reminders, priorities, tags, search/filter/sort, deployed to Minikube and cloud (AKS/GKE/OKE)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Manage Recurring Tasks (Priority: P1)

A user wants to create tasks that automatically repeat on a schedule (daily, weekly, monthly) without manual recreation. When they complete a recurring task, the system automatically creates the next occurrence with the correct due date, maintaining continuity for habitual activities like "Weekly team standup" or "Monthly budget review."

**Why this priority**: Recurring tasks are a core advanced feature requirement for Phase V. They demonstrate event-driven architecture capabilities and provide significant user value by reducing repetitive task creation overhead.

**Independent Test**: Can be fully tested by creating a recurring task, completing it, and verifying the next occurrence appears within 5 seconds with the correct due date. Delivers immediate value as a standalone feature.

**Acceptance Scenarios**:

1. **Given** a user creates a task "Weekly report" with weekly recurrence and due date 2025-12-31, **When** they complete the task on 2025-12-31, **Then** a new task "Weekly report" is created with due date 2026-01-07 within 5 seconds
2. **Given** a recurring task is marked complete, **When** the system creates the next occurrence, **Then** the original task remains in history with completed status (not deleted)
3. **Given** a recurring task has been completed multiple times, **When** viewing task history, **Then** parent-child relationships are visible in the audit log
4. **Given** a user creates a daily recurring task, **When** they complete it, **Then** the next occurrence has a due date exactly 1 day later
5. **Given** a user creates a monthly recurring task due on the 15th, **When** they complete it in January, **Then** the next occurrence is due February 15th

---

### User Story 2 - Schedule Task Reminders (Priority: P1)

A user creating a task with a due date wants to be reminded before the deadline to ensure timely completion. When setting up a reminder (e.g., "1 day before," "1 hour before"), they receive a notification at the exact scheduled time without the system constantly polling. Users can also cancel reminders without deleting the task itself.

**Why this priority**: Due dates and reminders are mandatory advanced features for Phase V. They showcase Dapr Jobs API integration for exact-time scheduling and provide critical value for time-sensitive task management.

**Independent Test**: Can be fully tested by creating a task with a due date, setting a reminder, and verifying the notification fires at the exact scheduled time. Delivers standalone value for deadline management.

**Acceptance Scenarios**:

1. **Given** a user creates a task due 2025-12-31 10:00 AM, **When** they set a reminder for "1 day before," **Then** a notification is sent exactly at 2025-12-30 10:00 AM
2. **Given** a reminder notification fails to send, **When** the system detects the failure, **Then** it retries up to 3 times with exponential backoff
3. **Given** a task has a scheduled reminder, **When** the user cancels the reminder, **Then** the task remains but no notification is sent
4. **Given** a reminder fires, **When** the user receives the notification, **Then** it includes the task title and due date
5. **Given** multiple tasks have reminders at the same time, **When** the scheduled time arrives, **Then** all reminders fire independently and concurrently

---

### User Story 3 - Prioritize and Tag Tasks (Priority: P2)

A user managing multiple tasks wants to organize them by priority (low/medium/high) and apply tags (e.g., #work, #personal, #urgent) for better categorization. They can update priorities and tags via natural language commands like "Set task 5 to high priority" or "Tag task 3 with #work and #urgent," enabling flexible task organization.

**Why this priority**: Priorities and tags are mandatory intermediate features for Phase V. They enable better task organization and support the search/filter/sort capabilities, providing structured data for advanced queries.

**Independent Test**: Can be fully tested by creating tasks, setting priorities, adding tags, and verifying changes persist. Delivers value as a standalone organizational system.

**Acceptance Scenarios**:

1. **Given** a user creates a task, **When** they say "Set task 5 to high priority," **Then** the task priority is updated to high
2. **Given** a task exists, **When** the user says "Tag task 3 with #work and #urgent," **Then** both tags are applied to the task
3. **Given** a task has tags, **When** the user adds another tag, **Then** all tags are preserved (additive, not replacement)
4. **Given** multiple tasks exist, **When** the user requests "Show all high priority tasks," **Then** only tasks with high priority are displayed
5. **Given** tasks have various priorities and tags, **When** the user views their task list, **Then** priority and tags are clearly visible for each task

---

### User Story 4 - Search, Filter, and Sort Tasks (Priority: P2)

A user with many tasks wants to quickly find specific items using natural language queries like "Show high priority work tasks due this week" or "Find tasks tagged #personal." The system understands complex multi-criteria queries and returns results in under 200ms, with the ability to sort by due date, priority, or creation date.

**Why this priority**: Search, filter, and sort are mandatory intermediate features for Phase V. They leverage Gemini's natural language understanding and provide essential usability for users with large task lists.

**Independent Test**: Can be fully tested by creating tasks with various attributes, running search queries, and verifying results match filters within performance limits. Delivers standalone value for task discovery.

**Acceptance Scenarios**:

1. **Given** tasks exist with various tags, **When** the user queries "Find tasks tagged #personal due this week," **Then** results include only tasks with #personal tag and due dates within 7 days, returned in under 200ms
2. **Given** tasks have different priorities, **When** the user says "Show all high priority tasks," **Then** only high-priority tasks are displayed
3. **Given** filtered results are displayed, **When** the user says "Sort by due date," **Then** tasks are reordered with earliest due dates first
4. **Given** a user queries "Show work tasks," **When** multiple filters apply (priority AND tags AND dates), **Then** all conditions are combined with AND logic
5. **Given** a complex natural language query, **When** Gemini interprets the intent, **Then** the correct MCP tool functions are called to retrieve matching tasks

---

### User Story 5 - Deploy to Local Kubernetes (Minikube) (Priority: P1)

A developer wants to run the entire todo chatbot system locally on Minikube to test all microservices, Dapr components, and Kafka event flows before deploying to production. They can verify that events flow through Kafka topics, services communicate via Dapr, and all features (recurring tasks, reminders, search) work end-to-end in a local environment that mirrors production architecture.

**Why this priority**: Local deployment is mandatory for Phase V Part B. It validates the entire architecture in a controlled environment and is a prerequisite for cloud deployment, enabling rapid development and testing.

**Independent Test**: Can be fully tested by running setup scripts, deploying all services to Minikube, and executing the testing checklist (create task, complete recurring task, schedule reminder, verify Kafka events). Delivers standalone value for development workflow.

**Acceptance Scenarios**:

1. **Given** Minikube is started with 4 CPUs and 8GB RAM, **When** Kafka (Strimzi) and Dapr are initialized, **Then** all required components are running and healthy
2. **Given** all services are deployed, **When** a user creates a task via the frontend, **Then** the event appears in the "task-events" Kafka topic within 1 second
3. **Given** a recurring task is completed, **When** the event is consumed by the Recurring Task Service, **Then** the next occurrence is created within 5 seconds
4. **Given** a reminder is scheduled, **When** the scheduled time arrives, **Then** the Dapr Jobs API triggers the callback and the notification service processes it
5. **Given** a pod crashes or is killed, **When** Kubernetes detects the failure, **Then** the pod is automatically restarted within 30 seconds

---

### User Story 6 - Deploy to Cloud Kubernetes (AKS/GKE/OKE) (Priority: P1)

A team wants to deploy the todo chatbot to production cloud infrastructure with high availability, auto-scaling, monitoring, and CI/CD automation. The deployment uses managed Kubernetes (Azure AKS, Google GKE, or Oracle OKE), Redpanda Cloud for Kafka, Neon PostgreSQL for state, and includes HTTPS, health checks, zero-downtime updates, and comprehensive observability.

**Why this priority**: Cloud deployment is mandatory for Phase V Part C. It demonstrates production-readiness and real-world scalability, showcasing the full stack from development to live deployment.

**Independent Test**: Can be fully tested by running the CI/CD pipeline, verifying all services deploy successfully, testing the public HTTPS endpoints, and confirming monitoring dashboards show healthy metrics. Delivers production-grade infrastructure.

**Acceptance Scenarios**:

1. **Given** a commit is pushed to the main branch, **When** the GitHub Actions workflow runs, **Then** tests pass, Docker images build, services deploy to the cluster, and smoke tests succeed
2. **Given** the application is deployed to the cloud, **When** users access the frontend URL (https://taskflow.your-domain.com), **Then** they can create tasks, set reminders, and search via the Gemini chatbot over HTTPS
3. **Given** CPU usage exceeds 70%, **When** the Horizontal Pod Autoscaler (HPA) detects high load, **Then** additional pods are automatically created within 2 minutes
4. **Given** a new version is deployed, **When** the rolling update strategy executes, **Then** zero downtime occurs and users experience no service interruption
5. **Given** an error occurs in any service, **When** Prometheus detects the issue, **Then** an alert is sent to the team via Slack webhook within 1 minute

---

### Edge Cases

- What happens when a user tries to create a recurring task with an invalid recurrence pattern (e.g., "every 0 days")?
- How does the system handle a reminder scheduled for a past date/time?
- What happens when Kafka is temporarily unavailable and events cannot be published?
- How does the system behave when a user completes the same recurring task multiple times rapidly (within the 5-second auto-creation window)?
- What happens when the Dapr Jobs API fails to schedule a reminder job?
- How does the system handle duplicate tags being added to the same task?
- What happens when a search query returns more than 10,000 results?
- How does the system respond when the Gemini API rate limit is exceeded?
- What happens when a notification service fails all 3 retry attempts?
- How does the system handle tasks with due dates more than 10 years in the future?
- What happens during a cloud deployment if database migrations fail mid-deployment?
- How does the system behave when a Kubernetes node fails and multiple pods need rescheduling?

## Requirements *(mandatory)*

### Functional Requirements

#### Core Task Management
- **FR-001**: System MUST allow users to create tasks with recurrence patterns (daily, weekly, monthly)
- **FR-002**: System MUST automatically create the next occurrence of a recurring task within 5 seconds of the current task being completed
- **FR-003**: System MUST preserve completed recurring tasks in history with completed status (not delete them)
- **FR-004**: System MUST record parent-child relationships for recurring tasks in the audit log
- **FR-005**: System MUST allow users to create tasks with due dates
- **FR-006**: System MUST allow users to set reminders relative to due dates (e.g., "1 day before," "1 hour before," custom time)
- **FR-007**: System MUST fire reminders at exact scheduled times using Dapr Jobs API (no polling)
- **FR-008**: System MUST allow users to cancel reminders without deleting the associated task
- **FR-009**: System MUST include task title and due date in all reminder notifications

#### Priority and Tag Management
- **FR-010**: System MUST support three priority levels: low, medium, high
- **FR-011**: System MUST allow users to set and update task priorities via natural language commands
- **FR-012**: System MUST allow users to add multiple tags to tasks (stored as PostgreSQL text arrays)
- **FR-013**: System MUST support tag addition via natural language commands (e.g., "Tag task 3 with #work and #urgent")
- **FR-014**: System MUST preserve existing tags when adding new tags (additive behavior)

#### Search, Filter, and Sort
- **FR-015**: System MUST return search results in under 200ms for queries on up to 10,000 tasks
- **FR-016**: System MUST support combined filters using AND logic (priority AND tags AND due dates)
- **FR-017**: System MUST support natural language search queries via Gemini understanding
- **FR-018**: System MUST support sorting by due date, priority, and creation date
- **FR-019**: System MUST call appropriate MCP tool functions (update_task_priority, add_tags, search_tasks) based on user commands

#### Event-Driven Architecture
- **FR-020**: System MUST publish "task.completed" events to the "task-events" Kafka topic when tasks are completed
- **FR-021**: System MUST publish reminder events to the "reminders" Kafka topic when Dapr Jobs API triggers callbacks
- **FR-022**: System MUST publish task update events to the "task-updates" Kafka topic for real-time sync
- **FR-023**: Recurring Task Service MUST consume events from "task-events" topic and create next occurrences
- **FR-024**: Notification Service MUST consume events from "reminders" topic and send notifications
- **FR-025**: Audit Service MUST consume events from all topics and log task operations

#### Dapr Integration
- **FR-026**: System MUST use Dapr Pub/Sub (pubsub.kafka) for all inter-service messaging
- **FR-027**: System MUST use Dapr State Management (state.postgresql) for conversation history persistence
- **FR-028**: System MUST use Dapr Service Invocation for frontend-backend communication
- **FR-029**: System MUST use Dapr Jobs API for scheduling reminders at exact times
- **FR-030**: System MUST use Dapr Secrets Management (secretstores.kubernetes) for API keys and credentials
- **FR-031**: All services MUST run with Dapr sidecars (no direct Kafka or database client dependencies in application code)

#### Notification Handling
- **FR-032**: System MUST retry failed notifications up to 3 times with exponential backoff
- **FR-033**: System MUST support email and/or push notification delivery mechanisms
- **FR-034**: System MUST log all notification attempts (success and failure) in the audit log

#### Deployment - Local (Minikube)
- **FR-035**: System MUST deploy successfully to Minikube with 4 CPUs and 8GB RAM
- **FR-036**: System MUST include Kafka installation via Strimzi in the Minikube cluster
- **FR-037**: System MUST initialize Dapr in Kubernetes mode (dapr init -k)
- **FR-038**: System MUST deploy five services: Frontend (Next.js), Backend API (FastAPI + MCP), Notification Service, Recurring Task Service, Audit Service
- **FR-039**: System MUST deploy Dapr components: kafka-pubsub, statestore, kubernetes-secrets

#### Deployment - Cloud (AKS/GKE/OKE)
- **FR-040**: System MUST deploy to Azure AKS, Google GKE, or Oracle OKE with 3+ worker nodes
- **FR-041**: System MUST use Redpanda Cloud or self-hosted Redpanda/Strimzi for Kafka in production
- **FR-042**: System MUST use Neon PostgreSQL or equivalent serverless PostgreSQL for state store
- **FR-043**: System MUST store all Kafka credentials and database connection strings in Kubernetes secrets
- **FR-044**: System MUST implement CI/CD pipeline via GitHub Actions with triggers on main branch push and manual workflow_dispatch
- **FR-045**: System MUST execute zero-downtime rolling updates for new deployments
- **FR-046**: System MUST enable HTTPS with cert-manager and Let's Encrypt
- **FR-047**: System MUST implement health check endpoints (/health) for all services
- **FR-048**: System MUST configure Horizontal Pod Autoscaler (HPA) based on CPU/memory thresholds
- **FR-049**: System MUST deploy monitoring with Prometheus and Grafana (or cloud-native equivalent)
- **FR-050**: System MUST deploy log aggregation with Loki or cloud-native logging
- **FR-051**: System MUST deploy distributed tracing with Jaeger or cloud-native equivalent
- **FR-052**: System MUST send error alerts to team via Slack webhook

#### Gemini API Integration
- **FR-053**: System MUST use gemini-2.0-flash-exp or gemini-pro model for chatbot inference
- **FR-054**: System MUST store Gemini API key in Kubernetes secrets via Dapr secretstore
- **FR-055**: System MUST support natural language task creation via Gemini
- **FR-056**: System MUST maintain conversational context using Dapr state management
- **FR-057**: System MUST pass MCP tool functions to Gemini for tool calling (create/update/delete/search tasks)
- **FR-058**: System MUST handle Gemini API rate limits by queuing requests and retrying with exponential backoff
- **FR-059**: System MUST fallback to cached responses on Gemini API timeout
- **FR-060**: System MUST alert operations team immediately if Gemini API key is invalid

#### Database Schema
- **FR-061**: Tasks table MUST include columns: id, title, description, due_date, recurrence, priority, tags, created_at, updated_at, completed_at, parent_task_id
- **FR-062**: System MUST create index on (priority, due_date) for efficient priority-based queries
- **FR-063**: System MUST create GIN index on tags column for efficient tag-based searches
- **FR-064**: System MUST use PostgreSQL enum type for priority (low, medium, high)
- **FR-065**: System MUST use PostgreSQL text array type for tags

### Key Entities

- **Task**: Represents a user's to-do item with attributes including title, description, due date, recurrence pattern (daily/weekly/monthly/none), priority (low/medium/high), tags (array of strings), status (pending/completed), creation timestamp, update timestamp, completion timestamp, and parent task ID (for recurring task lineage)

- **Reminder**: Represents a scheduled notification linked to a task, with attributes including task ID, user ID, scheduled time (ISO 8601), notification type (email/push), retry count, status (pending/sent/failed), and Dapr job ID

- **Event**: Represents a domain event published to Kafka topics, with attributes including event type (completed/updated/reminder_triggered), task ID, task data payload, user ID, timestamp, and correlation ID for tracing

- **User**: Represents a system user (authentication mechanism assumed standard but not specified in requirements), with attributes including user ID, conversation state (for Gemini context), and notification preferences

- **Audit Log Entry**: Represents a historical record of task operations, with attributes including event ID, event type, task ID, parent task ID (for recurring task relationships), user ID, timestamp, and event payload

## Success Criteria *(mandatory)*

### Measurable Outcomes

#### Feature Performance
- **SC-001**: Users can create recurring tasks and see the next occurrence appear within 5 seconds of completing the current task
- **SC-002**: Users receive reminder notifications at the exact scheduled time with less than 10 seconds of variance
- **SC-003**: Users can search tasks and receive results in under 200ms for task lists up to 10,000 items
- **SC-004**: Users can set priorities and tags via natural language commands with 95% accuracy in intent recognition

#### System Performance
- **SC-005**: System handles 1,000 concurrent users creating and completing tasks without degradation
- **SC-006**: System processes 10,000 Kafka events per minute across all topics without backlog
- **SC-007**: System maintains 99.9% uptime in cloud deployment over a 30-day period
- **SC-008**: System auto-scales from 3 to 10 pods within 2 minutes when CPU usage exceeds 70%

#### Deployment Success
- **SC-009**: Developers can deploy the full system to Minikube locally in under 15 minutes following documentation
- **SC-010**: CI/CD pipeline completes end-to-end (test, build, deploy, smoke test) in under 10 minutes
- **SC-011**: System achieves zero-downtime deployment with rolling updates showing no user-facing errors
- **SC-012**: All health check endpoints return 200 OK status within 1 second

#### Reliability and Resilience
- **SC-013**: Failed notifications retry successfully within 3 attempts at least 98% of the time
- **SC-014**: When a pod crashes, Kubernetes restarts it and the service recovers within 30 seconds
- **SC-015**: When Kafka is temporarily unavailable, services queue messages and resume publishing within 1 minute of Kafka recovery
- **SC-016**: Database connection pooling maintains stable performance with 500 concurrent connections

#### User Experience
- **SC-017**: 90% of users successfully complete their first recurring task setup and verification on first attempt
- **SC-018**: 95% of natural language search queries return relevant results matching user intent
- **SC-019**: Users can navigate from task creation to reminder notification in under 3 minutes during testing
- **SC-020**: Monitoring dashboards show clear metrics for task creation rate, event processing latency, and service health

#### Observability
- **SC-021**: All services emit structured logs that can be queried in Loki or cloud logging within 30 seconds of event occurrence
- **SC-022**: Distributed traces show end-to-end request flows from frontend to backend to Kafka in Jaeger
- **SC-023**: Prometheus metrics show at least 15 key indicators (request rate, error rate, latency, queue depth, etc.)
- **SC-024**: Error alerts reach the team via Slack within 1 minute of detection

#### Documentation and Deliverables
- **SC-025**: GitHub repository contains complete code for all phases (I-V) with clear directory structure
- **SC-026**: README.md provides step-by-step deployment instructions that a new developer can follow successfully
- **SC-027**: Demo video (under 90 seconds) successfully demonstrates recurring task creation, reminder notification, natural language search, Kubernetes dashboard, and Kafka event flow
- **SC-028**: CLAUDE.md documents all Claude Code workflow iterations and prompts used during development

## Clarified Decisions

The following architectural decisions were clarified during `/sp.clarify` to resolve ambiguities:

### Core Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Notification Delivery** | WebSocket real-time updates | Simplest for hackathon demo, no external provider setup, real-time delivery in browser |
| **Cloud Platform** | Oracle OKE (Always Free) | No time pressure on credits, sufficient resources (4 OCPU, 24GB RAM), always-free tier |
| **Kafka Provider** | Redpanda Cloud (Serverless - Free) | Free tier with no ops overhead, Kafka-compatible, easy setup |
| **Multi-Tenancy** | Single-user demo mode | Simplified architecture for hackathon, no authentication complexity |
| **Recurring Task Logic** | Next due = Original due + N periods (from completion) | More predictable for users; if weekly task due Monday completed Thursday, next is following Monday |

### Technical Implementation Decisions

| Decision | Choice | Details |
|----------|--------|---------|
| **Gemini Rate Limits** | Queue with backoff, max 50 concurrent conversations | When rate limit hit: queue request, retry with exponential backoff, fallback to cached responses |
| **State Management** | Dapr state: Conversation history; PostgreSQL: Tasks/users | Dapr state for ephemeral conversation context, PostgreSQL for persistent data |
| **Disaster Recovery** | RPO: 1 hour, RTO: 15 minutes | Hourly database snapshots, Kubernetes auto-restart for pod failures |
| **Alert Thresholds** | Error rate >5%, p95 latency >1s, Kafka lag >1000 messages, pod restarts >3/hour | Fires Slack alert within 1 minute of threshold breach |

### Notifications Architecture

WebSocket real-time updates were selected for notification delivery because:
- **Frontend**: Next.js app establishes WebSocket connection to Backend API
- **Delivery**: When Dapr Jobs API triggers reminder callback, backend publishes to "reminders" topic, Notification Service pushes to frontend via WebSocket
- **User Experience**: Real-time notification badge updates without page refresh
- **Demo Value**: Visible real-time behavior showcases event-driven architecture
- **Simplicity**: No external email/push provider integration needed

### Recurring Task Business Logic

When a user completes a recurring task late (after its due date), the next occurrence is scheduled based on the COMPLETION date, not the original due date:

**Example**: Weekly task due Monday 9 AM, user completes it Thursday 6 PM
- Next task due: Following Monday 9 AM (7 days from completion)
- This ensures users always have 1 week to complete each occurrence from when they actually finished the previous one

**Edge Case**: If user completes task BEFORE due date, next task is scheduled 1 week from COMPLETION (not from due date), maintaining consistent behavior.

## Assumptions

- **Cloud Platform**: Oracle OKE is the primary target for cloud deployment (always-free tier: 4 OCPU, 24GB RAM)
- **Kafka Provider**: Redpanda Cloud (Serverless Free tier) is used for Kafka in production
- **Database Provider**: Neon PostgreSQL (Serverless) or equivalent for state persistence
- **Notification Delivery**: WebSocket real-time updates from Backend API to Next.js frontend (no email/push providers needed)
- **Multi-Tenancy**: Single-user demo mode with no authentication complexity
- **Authentication**: Not required for single-user demo; session-based or OAuth2 would be added for multi-user production
- **Gemini API Access**: Valid Gemini API key available with rate limit handling (max 50 concurrent conversations, queue with backoff)
- **State Management**: Dapr state for ephemeral conversation history; PostgreSQL for persistent task/user data
- **Disaster Recovery**: RPO: 1 hour (hourly DB snapshots); RTO: 15 minutes (K8s auto-restart)
- **Kubernetes Knowledge**: Team has basic Kubernetes and Dapr knowledge for deployment and troubleshooting
- **MCP Tools**: MCP tool framework for Gemini integration is available or will be implemented as part of the backend
- **Phase IV Helm Charts**: Existing Helm charts from Phase IV can be extended with Dapr annotations for Phase V
- **Monitoring Stack**: Prometheus, Grafana, Loki, and Jaeger deployed or available as managed services
- **CI/CD Platform**: GitHub repository with Actions enabled for CI/CD pipeline execution
- **Domain Name**: Custom domain name (e.g., taskflow.your-domain.com) available for HTTPS configuration
- **Resource Limits**: Minikube runs on a machine with at least 4 CPUs and 8GB RAM; cloud cluster has sufficient quota

## Out of Scope

- User authentication system (single-user demo mode, no auth required)
- Mobile native applications (iOS/Android apps) - frontend is web-based (Next.js)
- Real-time collaborative editing (multiple users editing the same task simultaneously)
- Task assignment to other users or team management features
- File attachments or rich media in tasks
- Advanced recurrence patterns (e.g., "every 2nd Tuesday of the month")
- Time tracking or task duration estimation
- Integration with external calendar systems (Google Calendar, Outlook, etc.)
- Offline mode or progressive web app (PWA) capabilities
- Multi-language or internationalization (i18n) support
- Advanced analytics or reporting dashboards
- Automated disaster recovery (hourly snapshots for RPO: 1hr, manual restore process)
- Custom notification templates or user-configurable notification content
- Task dependencies or workflows (tasks that depend on other tasks)
- Subtasks or hierarchical task structures beyond recurring parent-child relationships
- Email or push notification providers (WebSocket used for demo simplicity)

