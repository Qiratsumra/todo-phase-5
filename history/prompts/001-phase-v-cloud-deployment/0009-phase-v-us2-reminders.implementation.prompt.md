---
id: "0009"
title: "Phase V US2 Schedule Task Reminders Implementation"
stage: "implementation"
date: "2025-12-29"
surface: "agent"
model: "claude-opus-4-5-20251101"
feature: "001-phase-v-cloud-deployment"
branch: "001-phase-v-cloud-deployment"
user: "human"
command: "/sp.implement continuation"
labels: ["backend","reminders","dapr-jobs"]
links:
  spec: "null"
  ticket: "null"
  adr: "null"
  pr: "null"
files:
  - backend/utils/reminder_parser.py
  - backend/routes/reminders.py
  - backend/routes/jobs.py
  - backend/mcp_tools/create_reminder.py
  - backend/mcp_tools/cancel_reminder.py
  - backend/main.py
  - specs/001-phase-v-cloud-deployment/tasks.md
tests: []
---

## Prompt

Continue Phase V implementation. Implement Phase 4: User Story 2 - Schedule Task Reminders (T022-T029):

T022: Implement reminder offset parser in backend/utils/reminder_parser.py
- Parse natural language offsets like "30 minutes before", "1 hour", "1 day"
- Support ISO duration format (PT30M, PT1H, P1D)
- Validate offset range (5 min to 7 days)

T023: Create Reminder model CRUD operations
- CRUD for reminders already in models.py
- Integration with TaskService for task reminders

T024: Dapr Jobs API schedule_reminder endpoint
- Already implemented in backend/services/dapr_jobs_client.py

T025: Implement reminder creation route in backend/routes/reminders.py
- POST /api/reminders/ - Create reminder with Dapr scheduling
- GET /api/reminders/{id} - Get reminder details
- DELETE /api/reminders/{id} - Cancel reminder
- GET /api/reminders/task/{task_id} - Get task reminders

T026: Implement /api/jobs/trigger callback endpoint in backend/routes/jobs.py
- Handle Dapr Jobs API callbacks
- Process reminder triggers and publish events

T027: Implement reminder event publication
- Already in backend/services/event_publisher.py (publish_reminder_scheduled, publish_reminder_triggered)

T028: Create create_reminder MCP tool in backend/mcp_tools/create_reminder.py
- Tool for Gemini agent to create reminders

T029: Create cancel_reminder MCP tool in backend/mcp_tools/cancel_reminder.py
- Tool for Gemini agent to cancel reminders

Reference: specs/001-phase-v-cloud-deployment/tasks.md

## Response snapshot

Phase 4 US2 Schedule Task Reminders completed successfully. Created 5 new files and updated 2 existing files:
- reminder_parser.py: Natural language offset parsing
- reminders.py: Full CRUD API for reminders with Dapr Jobs integration
- jobs.py: Dapr callback endpoint for job triggers
- create_reminder.py: MCP tool for creating reminders
- cancel_reminder.py: MCP tool for cancelling reminders
- main.py: Updated to include new routes

All T022-T029 tasks marked complete in tasks.md.

## Outcome

- ✅ Impact: US2 complete - reminders schedule via Dapr Jobs API and fire at exact times
- 🧪 Tests: Not requested in spec
- 📁 Files: 5 created, 2 modified
- 🔁 Next prompts: Continue with Phase 5: User Story 3 - Prioritize and Tag Tasks (T030-T036)
- 🧠 Reflection: Following the specifyplus workflow successfully

## Evaluation notes (flywheel)

- Failure modes observed: none
- Graders run and results (PASS/FAIL): N/A
- Prompt variant (if applicable): continuation
- Next experiment (smallest change to try): N/A
