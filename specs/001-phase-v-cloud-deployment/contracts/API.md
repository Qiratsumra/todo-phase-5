# TaskFlow API Documentation

## Base URL

| Environment | URL |
|-------------|-----|
| Development | `http://localhost:8000` |
| Production | `https://api.taskflow.app` |

## Endpoints

### Health Check

**GET** `/health`

Check API health status.

```json
{
  "status": "healthy",
  "services": {
    "database": "connected",
    "kafka": "connected"
  },
  "version": "1.0.0"
}
```

---

### Tasks

#### List Tasks

**GET** `/api/tasks/`

Query parameters:
- `status` - Filter by status (`pending`, `completed`, `all`)
- `priority` - Filter by priority (`high`, `medium`, `low`)
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 20)

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "Complete report",
      "description": "Finish Q4 report",
      "completed": false,
      "priority": "High",
      "due_date": "2024-01-15T10:00:00Z",
      "tags": ["#work", "#urgent"],
      "created_at": "2024-01-10T08:00:00Z",
      "updated_at": "2024-01-12T14:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "total_pages": 3
  }
}
```

#### Create Task

**POST** `/api/tasks/`

```json
{
  "title": "Complete report",
  "description": "Finish Q4 report",
  "priority": "high",
  "due_date": "2024-01-15T10:00:00Z",
  "tags": ["#work", "#urgent"],
  "recurrence": "weekly"
}
```

Response:

```json
{
  "success": true,
  "data": {
    "id": 1,
    "title": "Complete report",
    "message": "Task created successfully"
  }
}
```

#### Get Task

**GET** `/api/tasks/{task_id}/`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "title": "Complete report",
    "description": "Finish Q4 report",
    "completed": false,
    "priority": "High",
    "due_date": "2024-01-15T10:00:00Z",
    "tags": ["#work", "#urgent"],
    "created_at": "2024-01-10T08:00:00Z"
  }
}
```

#### Update Task

**PUT** `/api/tasks/{task_id}/`

```json
{
  "title": "Updated title",
  "description": "Updated description",
  "priority": "medium",
  "due_date": "2024-01-20T10:00:00Z"
}
```

#### Complete Task

**POST** `/api/tasks/{task_id}/complete`

For recurring tasks, this creates the next occurrence.

```json
{
  "success": true,
  "data": {
    "id": 1,
    "completed": true,
    "next_occurrence": {
      "id": 2,
      "due_date": "2024-01-22T10:00:00Z"
    },
    "message": "Task completed. Next occurrence created."
  }
}
```

#### Delete Task

**DELETE** `/api/tasks/{task_id}/`

```json
{
  "success": true,
  "message": "Task deleted successfully"
}
```

#### Search Tasks

**POST** `/api/tasks/search`

```json
{
  "query": "report",
  "filters": {
    "status": "pending",
    "priority": "high",
    "tags": ["#work"],
    "due_date_from": "2024-01-01T00:00:00Z",
    "due_date_to": "2024-01-31T23:59:59Z"
  },
  "sort": {
    "field": "due_date",
    "order": "asc"
  },
  "page": 1,
  "limit": 20
}
```

Response:

```json
{
  "success": true,
  "results": [...],
  "total_count": 5,
  "page": 1,
  "limit": 20
}
```

---

### Priority

#### Update Priority

**PUT** `/api/tasks/{task_id}/priority`

```json
{
  "priority": "high"
}
```

Response:

```json
{
  "success": true,
  "data": {
    "id": 1,
    "priority": "high",
    "message": "Priority updated to High"
  }
}
```

---

### Tags

#### Add Tags

**POST** `/api/tasks/{task_id}/tags`

```json
{
  "tags": ["#work", "#urgent"]
}
```

Response:

```json
{
  "success": true,
  "data": {
    "id": 1,
    "tags": ["#work", "#urgent", "#important"],
    "message": "Tags added successfully"
  }
}
```

#### Remove Tags

**DELETE** `/api/tasks/{task_id}/tags`

```json
{
  "tags": ["#urgent"]
}
```

---

### Reminders

#### Create Reminder

**POST** `/api/reminders/`

```json
{
  "task_id": 1,
  "offset_minutes": 60,
  "message": "Task due soon!"
}
```

Response:

```json
{
  "success": true,
  "data": {
    "id": 1,
    "task_id": 1,
    "scheduled_at": "2024-01-15T09:00:00Z",
    "message": "Reminder created"
  }
}
```

#### List Reminders

**GET** `/api/reminders/`

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "task_id": 1,
      "task_title": "Complete report",
      "scheduled_at": "2024-01-15T09:00:00Z",
      "status": "pending"
    }
  ]
}
```

#### Cancel Reminder

**DELETE** `/api/reminders/{reminder_id}/`

```json
{
  "success": true,
  "message": "Reminder cancelled"
}
```

---

### Statistics

#### Get Task Stats

**GET** `/api/stats/`

```json
{
  "success": true,
  "data": {
    "total_tasks": 45,
    "completed_tasks": 20,
    "pending_tasks": 25,
    "overdue_tasks": 3,
    "by_priority": {
      "high": 10,
      "medium": 25,
      "low": 10
    },
    "by_status": {
      "pending": 25,
      "completed": 20
    },
    "recurring_tasks": 5,
    "due_today": 2
  }
}
```

---

## Error Responses

All errors follow this format:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid priority value. Must be 'high', 'medium', or 'low'."
  }
}
```

### Common Error Codes

| Code | Status | Description |
|------|--------|-------------|
| `VALIDATION_ERROR` | 400 | Invalid input data |
| `NOT_FOUND` | 404 | Resource not found |
| `UNAUTHORIZED` | 401 | Invalid or missing API key |
| `QUOTA_EXCEEDED` | 429 | Rate limit exceeded |
| `INTERNAL_ERROR` | 500 | Server error |

---

## Rate Limits

| Tier | Requests/minute |
|------|-----------------|
| Free | 60 |
| Pro | 300 |
| Enterprise | Unlimited |

---

## WebSocket Events

### Connection

**Endpoint**: `ws://api.taskflow.app/ws/{user_id}`

### Event Types

#### reminder

```json
{
  "type": "reminder",
  "task_id": 1,
  "task_title": "Complete report",
  "reminder_type": "due_soon",
  "message": "Task due in 30 minutes",
  "due_date": "2024-01-15T10:00:00Z"
}
```

#### ping/pong

```json
// Client sends:
{ "type": "ping" }

// Server responds:
{ "type": "pong", "timestamp": "2024-01-15T09:30:00Z" }
```

---

## Dapr Topics

### Task Events

**Topic**: `task-events`

#### task.created

```json
{
  "event_type": "task.created",
  "task_id": 1,
  "user_id": "user123",
  "title": "Complete report",
  "priority": "high",
  "created_at": "2024-01-10T08:00:00Z"
}
```

#### task.completed

```json
{
  "event_type": "task.completed",
  "task_id": 1,
  "user_id": "user123",
  "title": "Complete report",
  "priority": "high",
  "recurrence": "weekly",
  "completed_at": "2024-01-10T08:30:00Z"
}
```

### Reminder Events

**Topic**: `reminders`

#### reminder.triggered

```json
{
  "event_type": "reminder.triggered",
  "user_id": "user123",
  "task_id": 1,
  "task_title": "Complete report",
  "reminder_type": "due_soon",
  "scheduled_at": "2024-01-15T09:00:00Z",
  "message": "Task due in 30 minutes"
}
```

---

## Changelog

### v1.0.0 (2024-01-10)

- Initial release
- Task CRUD operations
- Priority and tag support
- Recurring tasks
- Reminders
- AI chat interface
