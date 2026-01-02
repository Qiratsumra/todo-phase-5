<!--
Sync Impact Report:
- Version change: [INITIAL] → 1.0.0
- Modified principles: N/A (initial version)
- Added sections: All core principles (I-VII), Deployment Standards, Development Workflow, Governance
- Removed sections: N/A
- Templates requiring updates:
  ✅ plan-template.md - Constitution Check section aligns with new principles
  ✅ spec-template.md - Requirements sections align with feature scope principles
  ✅ tasks-template.md - Task structure aligns with workflow principles
- Follow-up TODOs: None
-->

# Todo Chatbot Phase V Constitution

## Core Principles

### I. Agentic Development Workflow (NON-NEGOTIABLE)

All development MUST follow the strict sequence: `/sp.specify` → `/sp.clarify` → `/sp.plan` → `/sp.tasks` → `/sp.implement`

- No manual coding is permitted
- All code MUST be generated via AI (Claude Code recommended for infrastructure, Gemini API for chatbot logic)
- Every commit MUST reference the exact specifyplus command used
- Every commit MUST link to the corresponding spec file in `/specs/phase-v/`

**Rationale**: Ensures reproducible, auditable, and consistent development practices aligned with hackathon judging criteria.

### II. Event-Driven Architecture

Event-driven architecture using Kafka (or Dapr-swappable Pub/Sub) is MANDATORY for:
- Reminder/Notification System
- Recurring Task Engine
- Activity/Audit Log
- Real-time Sync Across Clients

**Kafka topics (exact names required)**:
- `task-events`
- `reminders`
- `task-updates`

**Rationale**: Enables scalable, decoupled microservices architecture with asynchronous processing capabilities.

### III. Dapr Integration (NON-NEGOTIABLE)

Full Dapr integration is REQUIRED across all services:
- **Pub/Sub**: All inter-service messaging via Dapr (no direct Kafka clients in application code)
- **State Management**: PostgreSQL via `dapr state.postgresql` component
- **Service Invocation**: All RPC calls via Dapr service-to-service invocation
- **Jobs API**: Exact-time reminder scheduling (PREFERRED over polling mechanisms)
- **Secrets Management**: Kubernetes secrets via `dapr secretstores.kubernetes`

**Rationale**: Ensures loose coupling, portability across infrastructure providers, and standardized building blocks for distributed systems.

### IV. Microservices Deployment Pattern

Services MUST be deployed as:
- Separate Kubernetes pods
- Each with dedicated Dapr sidecar
- No direct database or Kafka client dependencies in application code
- All communication through Dapr building blocks only

**Rationale**: Maximizes portability, testability, and adherence to cloud-native microservices best practices.

### V. Dual-Environment Deployment Standard

**Part B (Local - MANDATORY)**:
- Full deployment and testing on Minikube
- Dapr initialized with all required components
- Kafka/Redpanda running in-cluster
- All services deployed with sidecars and fully functional

**Part C (Cloud - MANDATORY)**:
- Production-grade deployment on: Oracle Cloud OKE (preferred - always free), Azure AKS, or Google GKE
- Full Dapr with all building blocks enabled
- Kafka via Redpanda Cloud (preferred - free serverless) or self-hosted Strimzi/Redpanda
- CI/CD pipeline via GitHub Actions
- Monitoring/logging configured (Prometheus/Grafana or cloud-native equivalent)

**Rationale**: Demonstrates both local development capability and production cloud deployment skills for comprehensive hackathon evaluation.

### VI. Feature Completeness Requirements

**Mandatory Advanced Features**:
- Recurring Tasks (event-driven implementation)
- Due Dates & Reminders (exact-time scheduling via Dapr Jobs API)

**Mandatory Intermediate Features**:
- Priorities
- Tags
- Search
- Filter
- Sort

**Rationale**: Meets minimum feature set requirements for Phase V hackathon judging criteria.

### VII. AI Integration Standard

Chatbot inference MUST use Gemini API (not OpenAI)

**Rationale**: Aligns with hackathon technology requirements and constraints.

## Architecture Standards

### Loose Coupling Mandate

- NO direct Kafka clients in application code
- NO direct database clients in application code (except via Dapr state store)
- ALL inter-service communication via Dapr Service Invocation
- ALL pub/sub via Dapr Pub/Sub component
- ALL secrets via Dapr Secrets Management

### Technology Stack

**Container Orchestration**: Kubernetes (Minikube local, OKE/AKS/GKE cloud)
**Service Mesh/Runtime**: Dapr (all building blocks)
**Message Broker**: Kafka - Redpanda Cloud (preferred) or self-hosted Strimzi/Redpanda
**State Store**: PostgreSQL via Dapr state component
**Secrets**: Kubernetes secrets via Dapr
**CI/CD**: GitHub Actions
**Monitoring**: Prometheus/Grafana or cloud-native equivalent

### Reminder Scheduling

Dapr Jobs API is PREFERRED for exact-time reminder triggers (no polling mechanisms)

## Documentation Standards

**Repository Structure**:
- `/specs/phase-v/` MUST contain all specification files generated via specifyplus commands
- `CLAUDE.md` MUST be updated with all Phase V prompts and iterations
- `README.md` MUST include clear Phase V deployment instructions for both local (Minikube) and cloud environments
- Helm charts from Phase IV SHOULD be reused/extended where applicable

**Traceability Requirements**:
- Every feature MUST have corresponding spec files
- Every commit MUST reference the command that generated the code
- Every architectural decision SHOULD be documented

## Development Workflow

### Command Sequence (STRICT)

1. `/sp.specify` - Create feature specification
2. `/sp.clarify` - Resolve ambiguities and underspecified areas
3. `/sp.plan` - Design architecture and implementation approach
4. `/sp.tasks` - Generate dependency-ordered task list
5. `/sp.implement` - Execute implementation

### Commit Standards

Format: `[/sp.xxxx] Description`

**Requirements**:
- Reference exact specifyplus command used
- Link to corresponding spec file in `/specs/phase-v/`
- No hard-coded credentials or connection strings

### Prompt Iteration

All prompts MUST be iterative and refined until implementation succeeds. Document all iterations in `CLAUDE.md`.

## Code Quality Standards

### Security

- NO hard-coded credentials in code
- NO hard-coded connection strings
- ALL secrets via Dapr Secrets Management (Kubernetes secrets)
- ALL credentials must be externalized

### Testing

Testing standards are defined per feature specification. When tests are required:
- Integration tests for event-driven workflows
- Contract tests for service boundaries
- End-to-end tests for user journeys

### Observability

- Structured logging required for all services
- Metrics exposure for Prometheus scraping (when monitoring configured)
- Distributed tracing context propagation via Dapr

## Governance

### Constitution Authority

This constitution supersedes all other development practices for Phase V. All work MUST demonstrably adhere to these standards for hackathon judging.

### Compliance Verification

- All PRs and code reviews MUST verify compliance with this constitution
- Deployment readiness checks MUST confirm both local (Minikube) and cloud deployment capability
- Feature completeness MUST be validated against mandatory feature list

### Amendment Process

- Amendments require explicit documentation and approval
- Version increments follow semantic versioning (MAJOR.MINOR.PATCH)
- All amendments MUST maintain backward compatibility with Phase V hackathon requirements

### Complexity Justification

Any violation of these principles MUST be explicitly justified with:
- Why the violation is needed
- What simpler alternatives were considered
- Why those alternatives were rejected

**Version**: 1.0.0 | **Ratified**: 2025-12-29 | **Last Amended**: 2025-12-29
