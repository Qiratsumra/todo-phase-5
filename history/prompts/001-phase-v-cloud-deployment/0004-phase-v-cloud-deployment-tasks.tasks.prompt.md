---
id: "0004"
title: "Phase V Cloud Deployment Tasks"
stage: "tasks"
date: "2025-12-29"
surface: "agent"
model: "claude-opus-4-5-20251101"
feature: "001-phase-v-cloud-deployment"
branch: "001-phase-v-cloud-deployment"
user: "human"
command: "/sp.tasks"
labels: ["phase-v","cloud-deployment","tasks","planning"]
links:
  spec: "specs/001-phase-v-cloud-deployment/spec.md"
  ticket: "null"
  adr: "null"
  pr: "null"
files:
  - specs/001-phase-v-cloud-deployment/tasks.md
  - specs/001-phase-v-cloud-deployment/plan.md
  - specs/001-phase-v-cloud-deployment/spec.md
tests: []
---

## Prompt

Phase V Master Task Breakdown

Break Phase V into atomic units:

1. Implement Priorities and Tags in task model and chat tools
2. Implement Search, Filter, Sort commands in chatbot
3. Add Recurring Tasks support (frequency parsing, metadata storage)
4. Implement recurring task creation on completion (publish event)
5. Implement Due Dates parsing and reminder scheduling via Dapr Jobs
6. Refactor all event publishing to Dapr Pub/Sub HTTP API
7. Create Recurring Task Service (consumer of task-events)
8. Create Notification Service (triggered by Dapr Jobs)
9. Define Dapr components: kafka-pubsub, statestore, kubernetes-secrets
10. Create Helm charts with Dapr sidecar annotations for all services
11. Set up Minikube testing environment with Dapr and Redpanda
12. Deploy and test full stack locally on Minikube
13. Provision Oracle OKE cluster (or alternative)
14. Configure Redpanda Cloud cluster and topics
15. Deploy full stack to cloud cluster
16. Create GitHub Actions CI/CD workflow
17. Configure monitoring (Dapr metrics + basic logging)
18. Update documentation (specs, README, CLAUDE.md)
19. Record 90-second demo video

Each task will be implemented individually via /sp.implement.

## Response snapshot

**Generated tasks.md with 92 atomic tasks organized by user story:**

| Phase | Tasks | Description |
|-------|-------|-------------|
| Phase 1: Setup | 9 | Service directories, K8s manifests, Dapr components |
| Phase 2: Foundational | 11 | Task/Reminder/Audit models, enums, database, event publisher, Dapr clients |
| Phase 3: US1 Recurring Tasks | 8 | Recurrence service, MCP tools, task completion endpoint, Recurring Task Service |
| Phase 4: US2 Reminders | 10 | Reminder service, Dapr Jobs, Notification Service with WebSocket |
| Phase 5: US3 Priorities/Tags | 11 | Priority/tag models, MCP tools, API endpoints, frontend UI |
| Phase 6: US4 Search/Filter/Sort | 9 | Search service, GIN index, advanced search endpoint |
| Phase 7: US5 Minikube Deploy | 12 | Strimzi Kafka, K8s manifests with Dapr, ingress, secrets, scripts |
| Phase 8: US6 Cloud Deploy | 12 | OKE overlay, Redpanda Cloud SASL, CI/CD, HPA, monitoring, TLS |
| Phase 9: Polish | 10 | Documentation, logging, audit service, troubleshooting |

**Key Organization Decisions:**
- Tasks organized by 6 user stories (US1-US6) per spec.md priorities
- Each user story has independent test criteria
- [P] marker for parallelizable tasks (different files, no dependencies)
- US1-US4 can proceed in parallel after foundational phase
- US5 depends on US1-US4 completion (requires services)
- US6 depends on US5 completion (requires working local deployment)

## Outcome

- ✅ Impact: 92 atomic tasks enabling independent implementation and testing of each user story
- 🧪 Tests: N/A - tests not requested in spec.md
- 📁 Files: tasks.md created with full task breakdown
- 🔁 Next prompts: /sp.implement to execute tasks in dependency order
- 🧠 Reflection: Organized by user story to enable MVP delivery (US1 only) and incremental expansion

## Evaluation notes (flywheel)

- Failure modes observed: N/A - tasks generation successful
- Graders run and results (PASS/FAIL): N/A
- Prompt variant (if applicable): N/A
- Next experiment (smallest change to try): N/A
