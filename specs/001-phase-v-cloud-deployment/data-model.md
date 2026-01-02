# Data Model: Phase V Advanced Cloud Deployment

**Generated**: 2025-12-29 | **Plan**: [plan.md](plan.md)

## Entity Relationship Diagram

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│    Task     │───────│  Reminder   │       │AuditLogEntry│
│             │ 1:N   │             │       │             │
└─────────────┘       └─────────────┘       └─────────────┘
      │                     │
      │                     │
      └────────┬────────────┘
               │ N:1 (parent_task_id)
               ↓
        ┌─────────────┐
        │    Task     │ (recurring chain)
        │ (next occ.) │
        └─────────────┘

┌─────────────┐
│Conversation │
│   State     │ (Dapr state store)
└─────────────┘
```

---

## Task Entity

### Database Schema

```sql
CREATE TYPE recurrence_enum AS ENUM ('none', 'daily', 'weekly', 'monthly');
CREATE TYPE priority_enum AS ENUM ('low', 'medium', 'high');
CREATE TYPE task_status_enum AS ENUM ('pending', 'completed');

CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT DEFAULT '',
    due_date TIMESTAMP WITH TIME ZONE,
    recurrence recurrence_enum DEFAULT 'none',
    priority priority_enum DEFAULT 'medium',
    tags TEXT[] DEFAULT '{}',
    status task_status_enum DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    parent_task_id INTEGER REFERENCES tasks(id),
    reminder_offset INTERVAL
);

-- Indexes
CREATE INDEX idx_tasks_priority_due_date ON tasks (priority, due_date);
CREATE INDEX idx_tasks_tags_gin ON tasks USING GIN (tags);
CREATE INDEX idx_tasks_parent_id ON tasks (parent_task_id);
CREATE INDEX idx_tasks_status ON tasks (status);
CREATE INDEX idx_tasks_created_at ON tasks (created_at);
```

### Python Model (SQLAlchemy)

```python
from datetime import datetime
from enum import Enum
from typing import List, Optional
from sqlalchemy import Column, Integer, String, Text, DateTime, Enum as SQLEnum, Boolean, ForeignKey, Index
from sqlalchemy.dialects.postgresql import ARRAY, TIMESTAMP, INTERVAL
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

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

class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, autoincrement=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, default="")
    due_date = Column(TIMESTAMP(timezone=True), nullable=True)
    recurrence = Column(
        SQLEnum(RecurrenceEnum),
        default=RecurrenceEnum.NONE,
        nullable=False
    )
    priority = Column(
        SQLEnum(PriorityEnum),
        default=PriorityEnum.MEDIUM,
        nullable=False
    )
    tags = Column(ARRAY(String), default=[])
    status = Column(
        SQLEnum(TaskStatusEnum),
        default=TaskStatusEnum.PENDING,
        nullable=False
    )
    created_at = Column(
        TIMESTAMP(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )
    updated_at = Column(
        TIMESTAMP(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False
    )
    completed_at = Column(TIMESTAMP(timezone=True), nullable=True)
    parent_task_id = Column(Integer, ForeignKey("tasks.id"), nullable=True)
    reminder_offset = Column(INTERVAL, nullable=True)

    # Relationships
    parent = relationship("Task", remote_side=[id], backref="occurrences")
    reminders = relationship("Reminder", back_populates="task")
    audit_entries = relationship("AuditLogEntry", back_populates="task")

    # Indexes
    __table_args__ = (
        Index("idx_tasks_priority_due_date", "priority", "due_date"),
        Index("idx_tasks_tags_gin", "tags", postgresql_using="gin"),
        Index("idx_tasks_parent_id", "parent_task_id"),
        Index("idx_tasks_status", "status"),
        Index("idx_tasks_created_at", "created_at"),
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "due_date": self.due_date.isoformat() if self.due_date else None,
            "recurrence": self.recurrence.value if self.recurrence else None,
            "priority": self.priority.value if self.priority else None,
            "tags": self.tags or [],
            "status": self.status.value if self.status else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "parent_task_id": self.parent_task_id,
            "reminder_offset": str(self.reminder_offset) if self.reminder_offset else None,
        }
```

---

## Reminder Entity

### Database Schema

```sql
CREATE TYPE reminder_status_enum AS ENUM ('pending', 'sent', 'failed', 'cancelled');

CREATE TABLE reminders (
    id SERIAL PRIMARY KEY,
    task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL DEFAULT 1,  -- Single-user demo
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    reminder_type VARCHAR(50) DEFAULT 'websocket',
    status reminder_status_enum DEFAULT 'pending',
    retry_count INTEGER DEFAULT 0,
    dapr_job_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT fk_task FOREIGN KEY (task_id) REFERENCES tasks(id)
);

CREATE INDEX idx_reminders_task_id ON reminders(task_id);
CREATE INDEX idx_reminders_status ON reminders(status);
CREATE INDEX idx_reminders_scheduled_at ON reminders(scheduled_at);
```

### Python Model (SQLAlchemy)

```python
class ReminderStatusEnum(str, Enum):
    PENDING = "pending"
    SENT = "sent"
    FAILED = "failed"
    CANCELLED = "cancelled"

class Reminder(Base):
    __tablename__ = "reminders"

    id = Column(Integer, primary_key=True, autoincrement=True)
    task_id = Column(Integer, ForeignKey("tasks.id"), nullable=False)
    user_id = Column(Integer, default=1, nullable=False)  # Single-user demo
    scheduled_at = Column(TIMESTAMP(timezone=True), nullable=False)
    reminder_type = Column(String(50), default="websocket")
    status = Column(
        SQLEnum(ReminderStatusEnum),
        default=ReminderStatusEnum.PENDING,
        nullable=False
    )
    retry_count = Column(Integer, default=0)
    dapr_job_id = Column(String(255), nullable=True)
    created_at = Column(
        TIMESTAMP(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )
    sent_at = Column(TIMESTAMP(timezone=True), nullable=True)

    # Relationships
    task = relationship("Task", back_populates="reminders")

    # Indexes
    __table_args__ = (
        Index("idx_reminders_task_id", "task_id"),
        Index("idx_reminders_status", "status"),
        Index("idx_reminders_scheduled_at", "scheduled_at"),
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "task_id": self.task_id,
            "user_id": self.user_id,
            "scheduled_at": self.scheduled_at.isoformat() if self.scheduled_at else None,
            "reminder_type": self.reminder_type,
            "status": self.status.value if self.status else None,
            "retry_count": self.retry_count,
            "dapr_job_id": self.dapr_job_id,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "sent_at": self.sent_at.isoformat() if self.sent_at else None,
        }
```

---

## AuditLogEntry Entity

### Database Schema

```sql
CREATE TABLE audit_log_entries (
    id SERIAL PRIMARY KEY,
    event_id VARCHAR(255) NOT NULL UNIQUE,
    event_type VARCHAR(100) NOT NULL,
    task_id INTEGER,
    parent_task_id INTEGER,
    user_id INTEGER NOT NULL DEFAULT 1,
    event_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_audit_event_id ON audit_log_entries(event_id);
CREATE INDEX idx_audit_event_type ON audit_log_entries(event_type);
CREATE INDEX idx_audit_task_id ON audit_log_entries(task_id);
CREATE INDEX idx_audit_created_at ON audit_log_entries(created_at);
```

### Python Model (SQLAlchemy)

```python
class AuditLogEntry(Base):
    __tablename__ = "audit_log_entries"

    id = Column(Integer, primary_key=True, autoincrement=True)
    event_id = Column(String(255), unique=True, nullable=False)
    event_type = Column(String(100), nullable=False)
    task_id = Column(Integer, nullable=True)
    parent_task_id = Column(Integer, nullable=True)
    user_id = Column(Integer, default=1, nullable=False)
    event_data = Column(JSONB, nullable=False)
    created_at = Column(
        TIMESTAMP(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )

    # Relationships
    task = relationship("Task", back_populates="audit_entries")

    # Indexes
    __table_args__ = (
        Index("idx_audit_event_id", "event_id"),
        Index("idx_audit_event_type", "event_type"),
        Index("idx_audit_task_id", "task_id"),
        Index("idx_audit_created_at", "created_at"),
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "event_id": self.event_id,
            "event_type": self.event_type,
            "task_id": self.task_id,
            "parent_task_id": self.parent_task_id,
            "user_id": self.user_id,
            "event_data": self.event_data,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
```

---

## ConversationState Entity (Dapr State Store)

### Data Structure (JSON)

```json
{
  "user_id": 1,
  "history": [
    {
      "role": "user",
      "content": "Create a weekly task for team meetings",
      "timestamp": "2025-12-29T10:00:00Z"
    },
    {
      "role": "assistant",
      "content": "I've created a recurring task 'Weekly team meeting' due every Monday at 9:00 AM.",
      "timestamp": "2025-12-29T10:00:01Z"
    }
  ],
  "last_updated": "2025-12-29T10:00:01Z"
}
```

### State Key Format

```
conversation:{user_id}
```

Example: `conversation:1` for single-user demo

---

## Enums Reference

### RecurrenceEnum

| Value | Description | Next Due Calculation |
|-------|-------------|---------------------|
| `none` | Non-recurring task | N/A |
| `daily` | Repeats every day | due_date + 1 day |
| `weekly` | Repeats every week | due_date + 7 days |
| `monthly` | Repeats every month | due_date + 1 month |

### PriorityEnum

| Value | Numeric Weight | Use Case |
|-------|----------------|----------|
| `low` | 1 | Optional tasks, nice-to-have |
| `medium` | 2 | Normal tasks |
| `high` | 3 | Urgent, important tasks |

### TaskStatusEnum

| Value | Description |
|-------|-------------|
| `pending` | Task not yet completed |
| `completed` | Task marked as done |

### ReminderStatusEnum

| Value | Description |
|-------|-------------|
| `pending` | Reminder scheduled, not yet sent |
| `sent` | Notification delivered successfully |
| `failed` | All retry attempts exhausted |
| `cancelled` | User cancelled the reminder |

---

## Recurring Task Logic

### Next Occurrence Calculation

```python
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta

def calculate_next_due_date(current_due_date: datetime, recurrence: str) -> datetime:
    """Calculate next occurrence based on recurrence pattern."""
    if recurrence == "daily":
        return current_due_date + timedelta(days=1)
    elif recurrence == "weekly":
        return current_due_date + timedelta(weeks=1)
    elif recurrence == "monthly":
        return current_due_date + relativedelta(months=1)
    else:
        return None  # No recurrence
```

### Parent-Child Chain

```
Task #1 (Weekly meeting) - due 2025-12-29
  ↓ completed
Task #2 (Weekly meeting) - due 2026-01-05 (parent_task_id: 1)
  ↓ completed
Task #3 (Weekly meeting) - due 2026-01-12 (parent_task_id: 2)
  ↓ completed
Task #4 (Weekly meeting) - due 2026-01-19 (parent_task_id: 3)
```

---

## Validation Rules

### Task Validation

```python
from pydantic import BaseModel, Field

class CreateTaskRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    description: str = Field(default="", max_length=10000)
    due_date: Optional[datetime] = None
    recurrence: RecurrenceEnum = RecurrenceEnum.NONE
    priority: PriorityEnum = PriorityEnum.MEDIUM
    tags: List[str] = Field(default_factory=list)
    reminder_offset: Optional[str] = None  # e.g., "1 day", "1 hour"

    @validator("tags")
    def validate_tags(cls, v):
        if len(v) > 10:
            raise ValueError("Maximum 10 tags per task")
        for tag in v:
            if not tag.startswith("#"):
                raise ValueError("Tags must start with #")
            if len(tag) > 50:
                raise ValueError("Tag too long (max 50 characters)")
        return v

    @validator("reminder_offset")
    def validate_reminder_offset(cls, v):
        if v is not None:
            valid_offsets = [
                "15 minutes", "30 minutes", "1 hour",
                "2 hours", "1 day", "2 days", "1 week"
            ]
            if v not in valid_offsets:
                raise ValueError(f"Invalid reminder offset. Must be one of: {valid_offsets}")
        return v
```

---

## Database Migrations (Alembic)

### Migration: Add Phase V Columns

```python
"""add_phase_v_columns

Revision ID: 001
Revises:
Create Date: 2025-12-29

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers
revision = '001'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    # Create enums
    op.execute("CREATE TYPE recurrence_enum_v2 AS ENUM ('none', 'daily', 'weekly', 'monthly')")
    op.execute("CREATE TYPE priority_enum_v2 AS ENUM ('low', 'medium', 'high')")
    op.execute("CREATE TYPE task_status_enum_v2 AS ENUM ('pending', 'completed')")
    op.execute("CREATE TYPE reminder_status_enum_v2 AS ENUM ('pending', 'sent', 'failed', 'cancelled')")

    # Add columns to tasks
    op.add_column('tasks', sa.Column('recurrence', postgresql.ENUM('none', 'daily', 'weekly', 'monthly', name='recurrence_enum_v2'), nullable=True))
    op.add_column('tasks', sa.Column('priority', postgresql.ENUM('low', 'medium', 'high', name='priority_enum_v2'), nullable=True))
    op.add_column('tasks', sa.Column('tags', postgresql.ARRAY(sa.String()), nullable=True))
    op.add_column('tasks', sa.Column('parent_task_id', sa.Integer(), nullable=True))
    op.add_column('tasks', sa.Column('reminder_offset', postgresql.INTERVAL(), nullable=True))

    # Create reminders table
    op.create_table('reminders',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('task_id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('scheduled_at', postgresql.TIMESTAMP(timezone=True), nullable=False),
        sa.Column('reminder_type', sa.String(50), nullable=True),
        sa.Column('status', postgresql.ENUM('pending', 'sent', 'failed', 'cancelled', name='reminder_status_enum_v2'), nullable=True),
        sa.Column('retry_count', sa.Integer(), nullable=True),
        sa.Column('dapr_job_id', sa.String(255), nullable=True),
        sa.Column('created_at', postgresql.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('sent_at', postgresql.TIMESTAMP(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['task_id'], ['tasks.id'], ),
    )

    # Create indexes
    op.execute("CREATE INDEX idx_tasks_tags_gin ON tasks USING GIN (tags)")
    op.execute("CREATE INDEX idx_tasks_parent_id ON tasks (parent_task_id)")
    op.execute("CREATE INDEX idx_reminders_task_id ON reminders(task_id)")

def downgrade():
    op.execute("DROP INDEX idx_reminders_task_id")
    op.execute("DROP INDEX idx_tasks_parent_id")
    op.execute("DROP INDEX idx_tasks_tags_gin")
    op.drop_table('reminders')
    op.execute("DROP TYPE reminder_status_enum_v2")
    op.execute("DROP TYPE task_status_enum_v2")
    op.execute("DROP TYPE priority_enum_v2")
    op.execute("DROP TYPE recurrence_enum_v2")
    op.drop_column('tasks', 'reminder_offset')
    op.drop_column('tasks', 'parent_task_id')
    op.drop_column('tasks', 'tags')
    op.drop_column('tasks', 'priority')
    op.drop_column('tasks', 'recurrence')
```
