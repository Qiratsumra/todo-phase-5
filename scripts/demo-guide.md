# Demo Video Guide for Phase V - TaskFlow

## SC-027: Demo Video (under 90 seconds)

This guide outlines the demo video that demonstrates all key features of Phase V.

---

## Video Structure (90 seconds)

### 0:00-0:10 - Introduction (10s)
- Title card: "Phase V: Advanced Cloud Deployment"
- Show 3 key technologies:
  - Dapr for microservices
  - Kafka for event-driven architecture
  - Kubernetes for orchestration

### 0:10-0:30 - Recurring Tasks (20s)
- Action: User says "Create a weekly meeting task due every Monday"
- Show: Task created with recurrence: "weekly"
- Show: Task appears in task list with weekly badge

### 0:30-0:50 - Task Completion & Auto-Creation (20s)
- Action: User clicks "Complete" on the weekly task
- Show: Task status changes to "completed"
- Show: NEW task appears automatically within 5 seconds with next Monday's date
- Show: Parent-child relationship in task details

### 0:50-1:10 - Reminder Scheduling (20s)
- Action: User creates task "Submit report due Friday"
- Action: User clicks "Set reminder for 1 day before"
- Show: Reminder icon appears on task
- Show: Reminder details in task panel

### 1:10-1:30 - Priority & Tags (20s)
- Action: Multiple tasks displayed
- Show: Priority badges (low=green, medium=yellow, high=red)
- Show: Tags displayed (#work, #urgent)
- Action: User says "Set this task to high priority and tag #critical"
- Show: Priority updates to high, #critical tag added

### 1:30-1:50 - Natural Language Search (20s)
- Action: User says "Show me all high priority work tasks due this week"
- Show: Results filter by priority AND tag AND date
- Show: Results appear <200ms (show response time)
- Show: "Found 3 tasks" message

### 1:50-1:55 - WebSocket Notifications (5s)
- Action: Wait for scheduled reminder time
- Show: Toast notification appears "Reminder: Submit report due tomorrow"
- Show: Notification badge updates without page refresh
- Show: WebSocket connection status indicator

### 1:55-2:00 - Kubernetes Dashboard (5s)
- Action: Switch to dashboard view
- Show: All services running (backend, recurring-service, notification-service)
- Show: Dapr sidecars active
- Show: Kafka topics and partitions
- Show: HPA status (scale indicators)

### 2:00-2:30 - Architecture Summary (30s)
- Action: Architecture diagram overlay
- Show: Event flow arrows (backend → Kafka → services)
- Show: Tech stack badges (FastAPI, Next.js, Dapr, Kafka)
- Show: Call to action / URL link

---

## Recording Checklist

### Prerequisites
- [ ] Minikube cluster running with all services deployed
- [ ] All pods healthy (kubectl get pods)
- [ ] Kafka topics created (kubectl get kafkatopics)
- [ ] Dapr components installed (kubectl get components)
- [ ] Gemini API key configured

### Demo Preparation
- [ ] Test all user flows manually first
- [ ] Clear test data before recording
- [ ] Prepare example tasks and commands
- [ ] Set up terminal windows for visibility:
  - Window 1: kubectl get pods -w
  - Window 2: kubectl logs -f [pod-name]
  - Window 3: Browser with developer console open
  - Window 4: Dapr dashboard running

### During Recording
- [ ] Speak clearly at measured pace
- [ ] Point to relevant UI elements with mouse
- [ ] Show command line outputs for transparency
- [ ] Keep transitions smooth between features
- [ ] Time each section to stay within 90 seconds total

### After Recording
- [ ] Verify audio is clear
- [ ] Check all text is readable
- [ ] Trim to exactly 90 seconds
- [ ] Add captions (optional)
- [ ] Upload to YouTube/Drive
- [ ] Link in README.md under "Demo Video"

---

## Script Template for Demo

```bash
#!/bin/bash
# Demo Setup Script - Run before recording

# Reset database to clean state
kubectl exec -n todo-app deploy/postgres-1 -- \
    psql -U postgres -d taskflow -c "TRUNCATE TABLE tasks, reminders, audit_log CASCADE;"

# Create demo tasks via API
curl -X POST http://localhost:8000/api/tasks/ \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Weekly Team Standup",
    "description": "Recurring weekly meeting",
    "recurrence": "weekly",
    "priority": "medium",
    "tags": ["#work", "#meetings"]
  }'

curl -X POST http://localhost:8000/api/tasks/ \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Monthly Budget Review",
    "description": "Review monthly budget",
    "recurrence": "monthly",
    "priority": "high",
    "tags": ["#finance"]
  }'

echo "Demo tasks created. Ready to start recording."
```

---

## Success Criteria

| Criteria | Requirement | Verification |
|----------|-------------|-------------|
| Length | Under 90 seconds | Time the video |
| Recurring Tasks | Shown creation and auto-creation | Test flow works |
| Reminders | Shown scheduling and delivery | Dapr Jobs API works |
| Priorities & Tags | Shown setting and display | UI works correctly |
| Search | NL query with filters shown | Results appear fast |
| Notifications | WebSocket delivery shown | Real-time works |
| K8s Dashboard | Services and Dapr visible | Infrastructure visible |
| Audio | Clear and understandable | Test playback |
| Text | Readable in thumbnails | Test at small size |
| Call to Action | GitHub link displayed | README updated |

---

## Recording Tools

- **OBS Studio** - Free, cross-platform, 90s limit
- **Loom** - Easy sharing, 5 min free limit
- **Windows Game Bar** - Built-in screen recording
- **QuickTime Player** - macOS built-in recorder

---

## Post-Recording Actions

1. **Upload to YouTube** as "Unlisted" for sharing
2. **Update README.md** with embedded video:
   ```markdown
   ## Demo Video

   [![Phase V Demo](https://www.youtube.com/watch?v=VIDEO_ID)]

   A 90-second demonstration of Phase V features including recurring tasks, reminders, natural language search, and Kubernetes deployment.
   ```

3. **Add to acceptance-criteria.md** under SC-027:
   ```yaml
   - [x] SC-027: Demo video (<90s) created and linked
   ```

---

## Quick Demo Commands

```bash
# Start port forwards for recording
kubectl port-forward -n todo-app svc/taskflow-backend 8000:80 &
kubectl port-forward -n todo-app svc/taskflow-frontend 3000:80 &

# Watch all pods during demo
watch kubectl get pods -n todo-app

# Open Dapr dashboard in new terminal
dapr dashboard -k &

# Monitor Kafka events
kubectl exec -n strimzi deploy/my-cluster-kafka-0 -- \
  bin/kafka-console-consumer --bootstrap-server my-cluster-kafka-bootstrap:9092 \
  --topic task-events --from-beginning
```
