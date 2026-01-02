---
id: 0001
title: Phase V Constitution Standards
stage: constitution
date: 2025-12-29
surface: agent
model: claude-opus-4-5-20251101
feature: none
branch: master
user: User
command: /sp.constitution
labels: ["phase-v", "hackathon", "standards", "governance", "dapr", "kafka", "kubernetes"]
links:
  spec: null
  ticket: null
  adr: null
  pr: null
files:
  - .specify/memory/constitution.md
tests:
  - N/A
---

## Prompt

Phase V: Advanced Cloud Deployment

Project-wide quality standards for Phase V of the Todo Chatbot hackathon project:

1. Agentic Dev Stack Workflow (Strict Compliance)
   - All development MUST follow: /sp.specify → /sp.clarify → /sp.plan → /sp.tasks → /sp.implement
   - No manual coding permitted. All code must be generated via AI (Claude Code recommended, Gemini API for chatbot logic where applicable).
   - Every commit must reference the exact specifyplus command used and link to the corresponding spec file in /specs/phase-v/.

2. Feature Implementation Scope
   - Mandatory Advanced Features: Recurring Tasks (event-driven), Due Dates & Reminders (exact-time scheduling)
   - Mandatory Intermediate Features: Priorities, Tags, Search, Filter, Sort
   - Event-driven architecture using Kafka (or Dapr-swappable Pub/Sub) for:
     • Reminder/Notification System
     • Recurring Task Engine
     • Activity/Audit Log
     • Real-time Sync Across Clients
   - Full Dapr integration: Pub/Sub, State Management, Service Invocation, Jobs API (preferred for reminders), Secrets Management

3. Architecture & Technology Standards
   - Microservices deployed as separate pods with Dapr sidecars
   - Loose coupling: All inter-service communication via Dapr (no direct Kafka/DB clients in app code)
   - Kafka topics: task-events, reminders, task-updates (exact names required)
   - Preferred Kafka: Redpanda Cloud (free serverless) or self-hosted Strimzi/Redpanda in cluster
   - State store: PostgreSQL  via Dapr state.postgresql
   - Secrets: Kubernetes secrets via Dapr secretstores.kubernetes
   - Reminder scheduling: Dapr Jobs API (exact-time triggers, no polling)

4. Deployment Standards
   - Part B (Local): Full deployment and testing on Minikube
     • Minikube cluster
     • Dapr initialized with all components
     • Kafka/Redpanda running in cluster
     • All services deployed with sidecars
   - Part C (Cloud): Production-grade deployment
     • Preferred: Oracle Cloud OKE (always free) or Azure AKS / Google GKE
     • Full Dapr with all building blocks enabled
     • Kafka via Redpanda Cloud or self-hosted
     • CI/CD pipeline via GitHub Actions
     • Monitoring/logging configured (e.g., Prometheus/Grafana or cloud-native)

5. Documentation & Repository Standards
   - /specs/phase-v/ folder containing all specification files generated via specifyplus
   - CLAUDE.md updated with all Phase V prompts and iterations
   - README.md with clear Phase V deployment instructions
   - Helm charts from Phase IV reused/extended where applicable

6. Code & Process Quality
   - All prompts must be iterative and refined until implementation succeeds
   - Gemini API key used for chatbot inference (not OpenAI)
   - Commit messages must follow: "[/sp.xxxx] Description" format
   - No hard-coded credentials or connection strings in code

This constitution governs all Phase V development. All work must demonstrably adhere to these standards for hackathon judging.

## Response snapshot

Constitution successfully created at `.specify/memory/constitution.md` (version 1.0.0).

The constitution establishes 7 core principles:
1. Agentic Development Workflow (NON-NEGOTIABLE) - strict /sp.specify → /sp.clarify → /sp.plan → /sp.tasks → /sp.implement sequence
2. Event-Driven Architecture - Kafka with mandatory topics (task-events, reminders, task-updates)
3. Dapr Integration (NON-NEGOTIABLE) - Pub/Sub, State Management, Service Invocation, Jobs API, Secrets Management
4. Microservices Deployment Pattern - separate pods with Dapr sidecars
5. Dual-Environment Deployment Standard - Minikube (local) + OKE/AKS/GKE (cloud)
6. Feature Completeness Requirements - recurring tasks, reminders, priorities, tags, search, filter, sort
7. AI Integration Standard - Gemini API for chatbot inference

Additional sections cover Architecture Standards (loose coupling, technology stack), Documentation Standards (repository structure, traceability), Development Workflow (command sequence, commit standards), Code Quality Standards (security, testing, observability), and Governance (compliance, amendments, complexity justification).

All templates verified for alignment. Sync Impact Report embedded in constitution file.

## Outcome

- ✅ Impact: Established comprehensive governance framework for Phase V hackathon project with 7 core principles, architecture standards, deployment requirements, and code quality standards
- 🧪 Tests: N/A (governance document)
- 📁 Files: Created/updated `.specify/memory/constitution.md` (version 1.0.0, ratified 2025-12-29)
- 🔁 Next prompts: /sp.specify (to create first feature specification adhering to constitution), /sp.clarify (to refine specifications), /sp.plan (to design architecture)
- 🧠 Reflection: Constitution successfully captures all Phase V requirements including mandatory agentic workflow, event-driven architecture with Kafka/Dapr, dual-environment deployment (Minikube + cloud), and complete feature set. Templates validated for consistency. Ready for feature development.

## Evaluation notes (flywheel)

- Failure modes observed: None
- Graders run and results (PASS/FAIL): PASS - all placeholders resolved, version set, dates formatted correctly, principles are declarative and testable, templates verified for alignment
- Prompt variant (if applicable): N/A (initial constitution)
- Next experiment (smallest change to try): Begin feature specification workflow with /sp.specify for first Phase V feature (e.g., recurring tasks or reminder system)
