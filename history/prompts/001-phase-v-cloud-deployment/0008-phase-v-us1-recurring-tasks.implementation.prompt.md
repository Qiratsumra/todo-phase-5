---
id: "0008"
title: "Phase V US1 Recurring Tasks Implementation"
stage: "implementation"
date: "2025-12-29"
surface: "agent"
model: "claude-opus-4-5-20251101"
feature: "001-phase-v-cloud-deployment"
branch: "001-phase-v-cloud-deployment"
user: "human"
command: "/sp.implement continuation"
labels: ["backend","recurring-tasks","mcp-tools"]
links:
  spec: "null"
  ticket: "null"
  adr: "null"
  pr: "null"
files:
  - backend/utils/recurrence_parser.py
  - backend/utils/recurrence_calculator.py
  - backend/mcp_tools/create_recurring_task.py
  - backend/mcp_tools/complete_task.py
  - backend/service.py
  - specs/001-phase-v-cloud-deployment/tasks.md
tests: []
---

## Prompt

Continue Phase V implementation. Implement Phase 3: User Story 1 - Manage Recurring Tasks (T016-T021):

T016: Implement recurrence frequency parser in backend/utils/recurrence_parser.py
- Parse daily/weekly/monthly patterns from natural language
- Support patterns like "daily", "weekly:monday", "monthly:15"

T017: Implement next_due_date calculator in backend/utils/recurrence_calculator.py
- Calculate next occurrence based on recurrence pattern
- Handle daily, weekly (with day of week), monthly (with day of month)

T018: Create create_recurring_task MCP tool in backend/mcp_tools/create_recurring_task.py
- Create task with recurrence pattern
- Parse and validate recurrence input

T019: Update complete_task MCP tool in backend/mcp_tools/complete_task.py
- Detect recurrence on task completion
- Create next occurrence automatically

T020: Update complete_task endpoint in backend/service.py
- Add recurrence detection and next occurrence creation
- Return next_occurrence in response

T021: Implement task.completed event publication
- Publish to task-events Kafka topic via Dapr Pub/Sub
- Include is_recurring and next_occurrence_id in event

Reference: specs/001-phase-v-cloud-deployment/tasks.md

## Response snapshot

Phase 3 US1 Recurring Tasks completed successfully. Created 4 new files and updated 2 existing files:
- recurrence_parser.py: Pattern parsing (daily/weekly/monthly)
- recurrence_calculator.py: Next due date calculation
- create_recurring_task.py: New MCP tool for creating recurring tasks
- complete_task.py: Updated with recurrence detection and next occurrence creation
- service.py: Updated complete_task method with event publication

All T016-T021 tasks marked complete in tasks.md.

## Outcome

- ✅ Impact: US1 complete - recurring tasks auto-create next occurrence on completion
- 🧪 Tests: Not requested in spec
- 📁 Files: 4 created, 2 modified
- 🔁 Next prompts: Continue with Phase 4: User Story 2 - Schedule Task Reminders (T022-T029)
- 🧠 Reflection: Following the specifyplus workflow successfully

## Evaluation notes (flywheel)

- Failure modes observed: none
- Graders run and results (PASS/FAIL): N/A
- Prompt variant (if applicable): continuation
- Next experiment (smallest change to try): N/A
