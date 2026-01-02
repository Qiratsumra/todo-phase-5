---
id: "0003"
title: "Phase V Cloud Deployment Plan"
stage: "plan"
date: "2025-12-29"
surface: "agent"
model: "claude-opus-4-5-20251101"
feature: "001-phase-v-cloud-deployment"
branch: "001-phase-v-cloud-deployment"
user: "human"
command: "/sp.plan"
labels: ["phase-v","cloud-deployment","architecture","dapr","kafka"]
links:
  spec: "specs/001-phase-v-cloud-deployment/spec.md"
  ticket: "null"
  adr: "null"
  pr: "null"
files:
  - specs/001-phase-v-cloud-deployment/plan.md
  - specs/001-phase-v-cloud-deployment/research.md
  - specs/001-phase-v-cloud-deployment/data-model.md
  - specs/001-phase-v-cloud-deployment/quickstart.md
  - specs/001-phase-v-cloud-deployment/contracts/openapi.yaml
  - specs/001-phase-v-cloud-deployment/contracts/events.yaml
tests: []
---

## Prompt

PHASE V IMPLEMENTATION PLAN

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MILESTONE 1: Advanced Features Implementation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase 1.1: Database Schema Updates
├─ Add priority column (enum: low, medium, high)
├─ Add tags column (text[] with GIN index)
├─ Add recurrence column (enum: none, daily, weekly, monthly)
├─ Add due_date column (timestamp with timezone)
├─ Add reminder_offset column (interval: 1 day, 1 hour, etc.)
└─ Add parent_task_id column (for recurring task chains)

Phase 1.2: MCP Tools Extension
├─ update_task_priority(task_id, priority)
├─ add_tags(task_id, tags[])
├─ remove_tags(task_id, tags[])
├─ search_tasks(query, filters, sort_by, limit, offset)
├─ create_recurring_task(title, recurrence, due_date)
└─ schedule_reminder(task_id, remind_at)

Phase 1.3: Gemini Chatbot Enhancement
├─ Update system prompt with new tool descriptions
├─ Add natural language parsing for:
│   ├─ "high priority" → priority=high
│   ├─ "#work #urgent" → tags=['work', 'urgent']
│   ├─ "every Monday" → recurrence=weekly
│   └─ "remind me 1 day before" → reminder_offset=1 day
├─ Implement conversation state management
└─ Add error handling for Gemini API rate limits

Phase 1.4: Testing
├─ Unit tests for new MCP tools
├─ Integration tests: Gemini → MCP → Database
└─ Load test: 50 concurrent chatbot sessions

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MILESTONE 2: Event-Driven Architecture
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase 2.1: Kafka Setup (Local - Strimzi)
├─ Install Strimzi operator on Minikube
├─ Create Kafka cluster (1 broker, ephemeral storage)
├─ Create topics:
│   ├─ task-events (partitions: 3, replication: 1)
│   ├─ reminders (partitions: 3, replication: 1)
│   └─ task-updates (partitions: 3, replication: 1)
└─ Verify with Kafka console consumer

Phase 2.2: Backend Event Publisher
├─ Add Kafka producer to Backend API
├─ Publish events on:
│   ├─ Task created → task-events (event_type: created)
│   ├─ Task updated → task-events (event_type: updated)
│   ├─ Task completed → task-events (event_type: completed)
│   ├─ Task deleted → task-events (event_type: deleted)
│   └─ Reminder scheduled → reminders (remind_at timestamp)
└─ Include correlation_id in all events (for tracing)

Phase 2.3: Recurring Task Service
├─ Create new microservice (Python FastAPI)
├─ Kafka consumer for "task-events" topic
├─ Logic:
│   ├─ Filter for event_type == "completed"
│   ├─ Check if task has recurrence != "none"
│   ├─ Calculate next due_date based on recurrence type
│   ├─ Create new task via Backend API (HTTP call)
│   └─ Set parent_task_id to maintain chain
└─ Containerize and prepare K8s deployment

Phase 2.4: Notification Service
├─ Create new microservice (Python FastAPI)
├─ Kafka consumer for "reminders" topic
├─ Logic:
│   ├─ Receive reminder event
│   ├─ Fetch task details from database
│   ├─ Send notification (WebSocket/Email/Push)
│   └─ Mark reminder as sent (prevent duplicates)
├─ Implement retry logic (3 attempts with backoff)
└─ Containerize and prepare K8s deployment

Phase 2.5: Audit Service (Optional)
├─ Create microservice for audit logging
├─ Kafka consumer for "task-events" topic
├─ Store all events in separate audit_log table
└─ Useful for debugging and compliance

Phase 2.6: Testing
├─ Integration test: Complete task → new recurring task created
├─ Integration test: Schedule reminder → notification sent
├─ Chaos test: Kill Kafka broker → verify consumer recovery
└─ Load test: 1000 events/second throughput

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MILESTONE 3: Dapr Integration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase 3.1: Dapr Installation
├─ Install Dapr CLI: curl -fsSL https://dapr.io/install.sh | bash
├─ Initialize Dapr on Minikube: dapr init -k
├─ Verify installation: kubectl get pods -n dapr-system
└─ Install Dapr Dashboard: dapr dashboard -k

Phase 3.2: Dapr Components Configuration
├─ Create dapr-components/ folder
├─ kafka-pubsub.yaml (pubsub.kafka)
│   ├─ Connect to Strimzi Kafka cluster
│   └─ Define topics (task-events, reminders, task-updates)
├─ statestore.yaml (state.postgresql)
│   ├─ Connect to Neon PostgreSQL
│   └─ Table name: dapr_state
├─ kubernetes-secrets.yaml (secretstores.kubernetes)
│   └─ Access K8s secrets (Gemini API key, DB credentials)
└─ Apply: kubectl apply -f dapr-components/

Phase 3.3: Refactor Backend to Use Dapr
├─ Remove direct Kafka client (kafka-python)
├─ Publish events via Dapr HTTP API:
│   POST http://localhost:3500/v1.0/publish/kafka-pubsub/task-events
├─ Store conversation state via Dapr:
│   POST http://localhost:3500/v1.0/state/statestore
├─ Retrieve secrets via Dapr:
│   GET http://localhost:3500/v1.0/secrets/kubernetes-secrets/gemini-key
└─ Update Dockerfile and K8s deployment with Dapr annotations

Phase 3.4: Refactor Services to Use Dapr
├─ Recurring Task Service:
│   └─ Subscribe to events via Dapr:
│       POST http://localhost:3500/v1.0/subscribe
├─ Notification Service:
│   └─ Subscribe to events via Dapr
├─ Frontend:
│   └─ Call Backend via Dapr service invocation:
│       POST http://localhost:3500/v1.0/invoke/backend-service/method/api/chat
└─ Update all K8s deployments with Dapr sidecar annotations

Phase 3.5: Dapr Jobs API for Reminders
├─ Remove cron-based polling (if implemented)
├─ Schedule reminders via Dapr Jobs API:
│   POST http://localhost:3500/v1.0-alpha1/jobs/reminder-{task_id}
│   { "dueTime": "2025-12-30T10:00:00Z", "data": {...} }
├─ Implement callback endpoint:
│   @app.post("/api/jobs/trigger")
│   async def handle_job_trigger(request: Request):
│       # Publish to reminders topic
└─ Test: Schedule job → verify callback fires at exact time

Phase 3.6: Testing
├─ Test Dapr Pub/Sub: Publish event → verify consumption
├─ Test Dapr State: Save state → retrieve → verify persistence
├─ Test Dapr Service Invocation: Frontend → Backend call
├─ Test Dapr Jobs: Schedule job → verify callback
└─ Check Dapr Dashboard for metrics and tracing

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MILESTONE 4: Local Deployment (Minikube)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase 4.1: Minikube Setup
├─ Start Minikube: minikube start --cpus=4 --memory=8192
├─ Enable addons: minikube addons enable ingress
├─ Enable Dapr: dapr init -k
└─ Install Strimzi Kafka (from Milestone 2)

Phase 4.2: Kubernetes Manifests
├─ Update Phase IV Helm charts for Phase V services
├─ Add Dapr sidecar annotations to all deployments:
│   dapr.io/enabled: "true"
│   dapr.io/app-id: "backend-service"
│   dapr.io/app-port: "8000"
├─ Create secrets:
│   ├─ gemini-api-key
│   ├─ neon-db-credentials
│   └─ kafka-credentials (if using external Kafka)
├─ Create ingress for frontend and backend
└─ Update ConfigMaps with environment-specific values

Phase 4.3: Deploy All Services
├─ Deploy in order:
│   1. Kafka (Strimzi) - already running
│   2. Dapr components
│   3. Backend API
│   4. Recurring Task Service
│   5. Notification Service
│   6. Frontend
├─ Verify pods: kubectl get pods -n taskflow
├─ Check logs: kubectl logs <pod-name> -c daprd
└─ Test ingress: curl http://$(minikube ip)/api/health

Phase 4.4: End-to-End Testing
├─ Test 1: Create recurring task
│   ├─ Use chatbot: "Create task 'Weekly meeting' every Monday"
│   ├─ Complete task
│   └─ Verify new task created for next Monday
├─ Test 2: Schedule reminder
│   ├─ Use chatbot: "Remind me 1 minute before task due"
│   ├─ Wait 1 minute
│   └─ Verify notification received
├─ Test 3: Search with Gemini
│   ├─ Use chatbot: "Show high priority work tasks due this week"
│   └─ Verify correct results returned
└─ Test 4: Chaos engineering
    ├─ Delete a pod: kubectl delete pod <recurring-task-service-pod>
    ├─ Verify K8s restarts it automatically
    └─ Verify no data loss (Kafka persists events)

Phase 4.5: Documentation
├─ Update README.md with Minikube setup instructions
├─ Create architecture diagram (draw.io or mermaid)
├─ Document all Dapr components
└─ Create troubleshooting guide

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MILESTONE 5: Cloud Deployment (AKS/GKE/OKE)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase 5.1: Cloud Provider Setup
├─ Choose provider (recommendation: Oracle OKE - always free)
├─ Create Kubernetes cluster:
│   Oracle OKE: 4 OCPU, 24GB RAM, 3 nodes
├─ Configure kubectl: oci ce cluster create-kubeconfig ...
├─ Install Dapr: dapr init -k
└─ Verify cluster: kubectl get nodes

Phase 5.2: Kafka Setup (Redpanda Cloud)
├─ Sign up at redpanda.com/cloud
├─ Create Serverless cluster (free tier)
├─ Create topics: task-events, reminders, task-updates
├─ Get bootstrap servers and SASL credentials
├─ Store credentials in K8s secret:
│   kubectl create secret generic kafka-credentials
│     --from-literal=bootstrap-servers='...'
│     --from-literal=username='...'
│     --from-literal='password='...'
└─ Update Dapr kafka-pubsub component with cloud credentials

Phase 5.3: Database Setup (Neon PostgreSQL)
├─ Create Neon project at neon.tech
├─ Create database: taskflow_prod
├─ Run migrations (Alembic or SQL scripts)
├─ Store connection string in K8s secret:
│   kubectl create secret generic neon-db
│     --from-literal=connection-string='postgresql://...'
└─ Update Dapr statestore component with cloud credentials

Phase 5.4: CI/CD Pipeline (GitHub Actions)
├─ Create .github/workflows/deploy.yml
├─ Workflow steps:
│   1. Checkout code
│   2. Run tests (pytest, integration tests)
│   3. Build Docker images (frontend, backend, services)
│   4. Push to container registry (OCIR/ACR/GCR)
│   5. Update K8s manifests with new image tags
│   6. Apply manifests: kubectl apply -f k8s/
│   7. Run smoke tests on deployed services
│   8. Notify team on Slack (optional)
├─ Add secrets to GitHub:
│   ├─ KUBECONFIG (base64 encoded)
│   ├─ DOCKER_USERNAME
│   └─ DOCKER_PASSWORD
└─ Test pipeline: Push to main branch → verify deployment

Phase 5.5: Ingress and TLS Setup
├─ Install NGINX Ingress Controller:
│   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
├─ Install cert-manager for Let's Encrypt:
│   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
├─ Create ClusterIssuer for Let's Encrypt
├─ Update Ingress with TLS config:
│   tls:
│     - hosts: [taskflow.your-domain.com]
│       secretName: taskflow-tls
└─ Verify HTTPS: https://taskflow.your-domain.com

Phase 5.6: Monitoring and Logging
├─ Install Prometheus + Grafana:
│   helm install prometheus prometheus-community/kube-prometheus-stack
├─ Create Grafana dashboards:
│   ├─ Pod CPU/Memory usage
│   ├─ Kafka message throughput
│   ├─ API response times
│   └─ Error rates
├─ Install Loki for log aggregation:
│   helm install loki grafana/loki-stack
├─ Configure alerts:
│   ├─ High error rate (>5%)
│   ├─ Pod restart >3 times/hour
│   └─ Kafka consumer lag >1000 messages
└─ Add Jaeger for distributed tracing (optional)

Phase 5.7: Final Testing
├─ Load test: 1000 concurrent chatbot sessions
├─ Disaster recovery test:
│   ├─ Delete all pods
│   ├─ Verify K8s restarts them
│   └─ Verify no data loss (Kafka + Neon persistence)
├─ Security scan: trivy image scan
└─ Performance test: API response time <500ms (p95)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MILESTONE 6: Documentation and Demo
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase 6.1: Code Documentation
├─ Add docstrings to all functions
├─ Generate API documentation (FastAPI /docs)
├─ Document Dapr component configurations
├─ Create architecture diagrams (draw.io)
└─ Update CLAUDE.md with Claude Code workflow

Phase 6.2: Demo Video (90 seconds)
├─ Script (60 seconds content + 30 seconds buffer):
│   [0-10s] Show chatbot creating recurring task
│   [10-20s] Complete task → show new task auto-created
│   [20-30s] Schedule reminder → show notification
│   [30-45s] Natural language search with Gemini
│   [45-55s] Kubernetes dashboard (pods, services)
│   [55-60s] Kafka topics with events flowing
├─ Recording tools: OBS Studio / Loom
├─ Editing: Cut to 90 seconds exactly
└─ Upload to YouTube (unlisted link for judges)

Phase 6.3: Repository Finalization
├─ Clean up code (remove debug logs, TODOs)
├─ Organize folder structure:
│   /specs - Specifications from all phases
│   /k8s - Kubernetes manifests
│   /dapr-components - Dapr configurations
│   /backend - FastAPI + MCP
│   /frontend - Next.js chatbot
│   /services - Recurring Task, Notification services
│   /tests - Unit and integration tests
│   /.github/workflows - CI/CD pipeline
├─ Update README.md:
│   ├─ Project overview
│   ├─ Architecture diagram
│   ├─ Setup instructions (Minikube + Cloud)
│   ├─ Deployment URLs
│   └─ Demo video link
└─ Final commit: "Phase V: Advanced Cloud Deployment Complete"

Phase 6.4: Submission Checklist
□ GitHub repo URL
□ /specs folder with all specifications
□ CLAUDE.md with Claude Code instructions
□ README.md with comprehensive documentation
□ Deployed URLs:

Frontend: https://taskflow.your-domain.com
Backend API: https://api.taskflow.your-domain.com/docs
□ Demo video (max 90 seconds)
□ WhatsApp number for presentation invitation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ESTIMATED TIMELINE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- Advanced Features (Recurring, Reminders, Search)
- Event-Driven Architecture (Kafka + Microservices)
- Dapr Integration (Pub/Sub, State, Jobs, Secrets)
- Local Deployment (Minikube + Full Testing)
- Cloud Deployment (AKS/GKE/OKE + CI/CD + Monitoring)
- Documentation and Demo Video
RISK MITIGATION:

Kafka issues? Switch to RabbitMQ via Dapr config change
Gemini rate limits? Add request queue and exponential backoff
Cloud costs? Use Oracle OKE (always free) instead of Azure/GCP
Time constraint? Reduce scope (skip Audit Service)

## Response snapshot

**Phase 0 - Research Completed:**
- R1: Dapr Jobs API - One-time jobs at `/v1.0-alpha1/jobs/` with callback endpoint
- R2: Strimzi Kafka - Ephemeral 1-broker cluster with 3 topics (3 partitions each)
- R3: Redpanda Cloud - SASL auth, store credentials in K8s secrets
- R4: WebSocket - Notification Service exposes `/ws/notifications` endpoint
- R5: PostgreSQL Arrays - `text[]` with GIN index for `@>` containment queries

**Phase 1 - Design Artifacts Created:**
- Data Model: Task, Reminder, AuditLogEntry entities with SQLAlchemy models
- OpenAPI Contract: 20 endpoints for tasks, reminders, chat, health
- Kafka Events: 14 event types across 3 topics (task-events, reminders, task-updates)
- Quickstart Guide: Minikube, Dapr, Strimzi, PostgreSQL setup instructions
- Agent Context: CLAUDE.md updated with Python 3.11 + FastAPI + Dapr + Kafka tech stack

**Constitution Gates - All Passed:**
1. ✅ Testable acceptance criteria defined
2. ✅ All research unknowns resolved
3. ✅ Data model complete with relationships
4. ✅ API contracts generated
5. ✅ No external service dependencies blocking local dev
6. ✅ Single-user demo mode - no auth complexity
7. ✅ Documentation standards met

## Outcome

- ✅ Impact: Complete Phase V implementation plan with 6 milestones, 24 phases, and 100+ tasks
- 🧪 Tests: N/A - planning phase, no tests run
- 📁 Files: 7 artifacts created (plan.md, research.md, data-model.md, quickstart.md, openapi.yaml, events.yaml, CLAUDE.md updated)
- 🔁 Next prompts: `/sp.tasks` to generate dependency-ordered task list
- 🧠 Reflection: Research-first approach successfully resolved all technical unknowns before design. Constitution gates validated completeness before proceeding.

## Evaluation notes (flywheel)

- Failure modes observed: N/A - planning phase successful
- Graders run and results (PASS/FAIL): N/A
- Prompt variant (if applicable): N/A
- Next experiment (smallest change to try): N/A
