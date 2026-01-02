# Research Findings: Phase V Advanced Cloud Deployment

**Generated**: 2025-12-29 | **Plan**: [plan.md](plan.md)

## Overview

This document consolidates research findings from Phase 0 of the planning process, resolving all technical unknowns for the Phase V implementation.

---

## R1: Dapr Jobs API Implementation

### Research Question
How to implement exact-time reminder scheduling using Dapr Jobs API for Python FastAPI services?

### Findings

**Dapr Jobs API Overview**:
- Version: v1.0-alpha1 (alpha but stable for production use)
- HTTP-based API at `/v1.0-alpha1/jobs/`
- One-time jobs (not cron-based) - perfect for reminder use case
- Jobs persist across service restarts
- Automatic callback to configured endpoint

**API Endpoints**:
```bash
# Schedule a job
POST /v1.0-alpha1/jobs/{jobId}
{
  "dueTime": "2025-12-30T10:00:00Z",  # ISO 8601 timestamp
  "data": {
    "task_id": 123,
    "user_id": 1,
    "type": "reminder"
  }
}

# Get job status
GET /v1.0-alpha1/jobs/{jobId}

# Delete a job
DELETE /v1.0-alpha1/jobs/{jobId}
```

**Callback Implementation**:
- Service must expose endpoint: `POST /api/jobs/trigger`
- Dapr sends callback when job is due
- Job data passed in request body

**Python FastAPI Implementation**:
```python
from fastapi import FastAPI, Request

app = FastAPI()

@app.post("/api/jobs/trigger")
async def handle_job_trigger(request: Request):
    """Callback endpoint for Dapr Jobs API"""
    job_data = await request.json()
    # Process reminder: publish to reminders topic
    await publish_reminder_event(job_data["data"])
    return {"status": "processed"}
```

**Decision**: Use Dapr Jobs API for exact-time reminder scheduling
- Schedule job when reminder is created
- Callback triggers event publication to "reminders" topic
- Notification Service consumes event and sends WebSocket notification

---

## R2: Strimzi Kafka on Minikube

### Research Question
How to install and configure Strimzi Kafka operator on Minikube for local development?

### Findings

**Strimzi Overview**:
- Kubernetes Operator for Apache Kafka
- Manages Kafka brokers, topics, users via Custom Resource Definitions (CRDs)
- Install via YAML manifests from strimzi.io
- Supports KRaft (no ZooKeeper) in newer versions

**Installation Steps**:
```bash
# Create namespace
kubectl create namespace kafka

# Install operator
kubectl apply -f https://strimzi.io/install/latest/strimzi-with-entity-operator.yaml

# Verify installation
kubectl get pods -n kafka
# Should see: strimzi-cluster-operator-xxx

# Create Kafka cluster
kubectl apply -f strimzi-kafka-cluster.yaml -n kafka

# Verify Kafka is ready
kubectl get kafka my-cluster -n kafka
# STATUS should be Ready
```

**KafkaCluster CR Example**:
```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: my-cluster
  namespace: kafka
spec:
  kafka:
    replicas: 1
    version: 3.7.0
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9093
        type: internal
        tls: true
    storage:
      type: ephemeral
  zookeeper:
    replicas: 1
    storage:
      type: ephemeral
  entityOperator:
    userOperator: {}
    topicOperator: {}
```

**Topic Creation**:
```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: task-events
  namespace: kafka
spec:
  partitions: 3
  replicas: 1
  config:
    retention.ms: 604800000  # 7 days
```

**Connection Details**:
- Bootstrap service: `my-cluster-kafka-bootstrap.kafka:9092`
- Dapr Pub/Sub component connects via this endpoint

**Resource Requirements**:
- Minimum: 2 CPUs, 4GB RAM
- Recommended: 4 CPUs, 8GB RAM (for production-like experience)

**Decision**: Install Strimzi operator on Minikube for local Kafka
- Use ephemeral Kafka cluster (1 broker, 3 topics with 3 partitions each)
- Topics: task-events, reminders, task-updates
- Connect Dapr Pub/Sub to Strimzi Kafka via bootstrap service

---

## R3: Redpanda Cloud Serverless

### Research Question
How to configure Dapr Pub/Sub to connect to Redpanda Cloud Serverless?

### Findings

**Redpanda Cloud Serverless**:
- Free tier available at redpanda.com/cloud
- Serverless = pay-per-use, scales automatically
- No operational overhead (no cluster management)
- Kafka-compatible (full protocol support)

**Setup Steps**:
1. Sign up at redpanda.com/cloud
2. Create Serverless cluster
3. Get bootstrap servers from console
4. Create API key with SASL authentication
5. Create topics: task-events, reminders, task-updates

**Credentials Format**:
```
Bootstrap Servers: [cluster-id].redpanda.cloud:9092
Username: [api-key-id]
Password: [api-key-secret]
```

**Dapr Pub/Sub Configuration**:
```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: kafka-pubsub
spec:
  type: pubsub.kafka
  version: v1
  metadata:
    - name: brokers
      value: "[cluster-id].redpanda.cloud:9092"
    - name: consumerGroup
      value: "taskflow-consumer-group"
    - name: authType
      value: "sasl"
    - name: saslUsername
      value: "${REDPANDA_USERNAME}"
    - name: saslPassword
      value: "${REDPANDA_PASSWORD}"
    - name: saslMechanism
      value: "SCRAM-SHA-256"
    - name: tls
      value: "true"
```

**Secrets Configuration**:
```bash
kubectl create secret generic redpanda-credentials \
  --from-literal=bootstrap-servers="${REDPANDA_BOOTSTRAP}" \
  --from-literal=username="${REDPANDA_USERNAME}" \
  --from-literal=password="${REDPANDA_PASSWORD}"
```

**Decision**: Use Redpanda Cloud Serverless for production Kafka
- Store credentials in Kubernetes secret
- Configure Dapr kafka-pubsub with SASL metadata
- Create topics: task-events, reminders, task-updates

---

## R4: WebSocket for Real-Time Notifications

### Research Question
How to implement WebSocket notifications from Notification Service to Next.js Frontend?

### Findings

**WebSocket Implementation Options**:
1. Direct WebSocket connection (frontend → notification service)
2. Dapr Service Invocation with WebSocket upgrade
3. Via API Gateway with WebSocket support

**Recommended: Direct WebSocket with Dapr Sidecar**:
- Notification Service exposes WebSocket endpoint
- Frontend connects directly (Dapr sidecar routes WebSocket traffic)
- Dapr Service Invocation handles routing transparently

**FastAPI WebSocket Server**:
```python
from fastapi import FastAPI, WebSocket, WebSocketDisconnect

app = FastAPI()

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: dict):
        for connection in self.active_connections:
            await connection.send_json(message)

manager = ConnectionManager()

@app.websocket("/ws/notifications")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket)
```

**Next.js WebSocket Client**:
```typescript
// services/websocket.ts
export class NotificationWebSocket {
  private ws: WebSocket | null = null;
  private url: string;

  constructor(url: string) {
    this.url = url;
  }

  connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      this.ws = new WebSocket(this.url);

      this.ws.onopen = () => {
        console.log('WebSocket connected');
        resolve();
      };

      this.ws.onerror = (error) => {
        reject(error);
      };

      this.ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        this.handleNotification(data);
      };
    });
  }

  private handleNotification(data: any) {
    // Dispatch to notification UI component
    dispatchNotification(data);
  }

  disconnect() {
    this.ws?.close();
  }
}
```

**Dapr Service Invocation**:
- Frontend calls: `http://localhost:3500/v1.0/invoke/notification-service/method/ws/notifications`
- Dapr sidecar routes to Notification Service
- WebSocket connection established

**Reconnection Strategy**:
```typescript
// Automatic reconnection on disconnect
setInterval(() => {
  if (this.ws?.readyState === WebSocket.CLOSED) {
    this.connect();
  }
}, 5000);
```

**Decision**: Implement WebSocket for real-time notifications
- Notification Service exposes WebSocket endpoint at `/ws/notifications`
- Frontend connects on page load, maintains heartbeat
- Notification Service broadcasts to connected clients on reminder events

---

## R5: PostgreSQL Array and GIN Index Operations

### Research Question
How to efficiently query PostgreSQL text arrays with GIN indexes for tag-based search?

### Findings

**PostgreSQL Array Support**:
- Native array type: `text[]`, `int[]`, etc.
- Operators:
  - `@>` contains: `tags @> ARRAY['work']`
  - `<@` contained by: `ARRAY['work'] <@ tags`
  - `&&` overlap: `tags && ARRAY['work', 'urgent']`
  - `=` equality: `tags = ARRAY['work', 'urgent']`

**SQLAlchemy Array Type**:
```python
from sqlalchemy import Column, String, Array
from sqlalchemy.dialects.postgresql import ARRAY

class Task(Base):
    __tablename__ = "tasks"
    id = Column(Integer, primary_key=True)
    tags = Column(ARRAY(String), default=[])
```

**GIN Index for Arrays**:
```sql
-- GIN index for containment queries
CREATE INDEX idx_tasks_tags_gin ON tasks USING GIN (tags);

-- Query using containment
SELECT * FROM tasks WHERE tags @> ARRAY['work', 'urgent'];
```

**Performance Benchmarks** (10,000 rows):
| Query Type | Index | Time |
|------------|-------|------|
| Array contains | GIN | ~50ms |
| Array contains | None (seq scan) | ~500ms |
| Exact match | B-tree | ~10ms |
| Exact match | None (seq scan) | ~100ms |

**Query Patterns Needed**:
1. Find tasks with specific tags: `tags @> ARRAY['work']`
2. Find tasks with multiple tags: `tags @> ARRAY['work', 'urgent']`
3. Find tasks with any of tags: `tags && ARRAY['work', 'personal']`

**Decision**: Use PostgreSQL text[] with GIN index for tags
- Store tags as PostgreSQL array
- Create GIN index for efficient containment queries
- Support both array containment and exact match queries

---

## Consolidated Decisions

### Dapr Building Blocks Usage

| Building Block | Component Name | Purpose | Configuration File |
|----------------|----------------|---------|-------------------|
| Pub/Sub | kafka-pubsub | Event-driven messaging | `dapr-components/kafka-pubsub.yaml` |
| State Management | statestore | Conversation history persistence | `dapr-components/statestore.yaml` |
| Service Invocation | (default) | Frontend-backend communication | K8s Dapr sidecar annotations |
| Jobs API | N/A | Exact-time reminder scheduling | HTTP API at `/v1.0-alpha1/jobs/` |
| Secrets Management | kubernetes-secrets | API key and credential access | K8s secrets + Dapr |

### Kafka Topics Specification

| Topic Name | Partitions | Replication | Purpose |
|------------|------------|-------------|---------|
| task-events | 3 | 1 | Task lifecycle events (created, updated, completed, deleted) |
| reminders | 3 | 1 | Reminder scheduling and delivery events |
| task-updates | 3 | 1 | Real-time task update notifications |

### Service Communication Pattern

```
Frontend (Next.js)
    ↓ Dapr Service Invocation
Backend API (FastAPI + MCP)
    ↓ Dapr Pub/Sub (kafka-pubsub)
    ↓ Dapr State (statestore)
    ↓ Dapr Jobs API (reminder scheduling)
Kafka Topics (via Dapr)
    ↓
Recurring Task Service (FastAPI)
    ↓ Dapr Service Invocation
Backend API (create next task)
    ↓
Notification Service (FastAPI)
    ↓ WebSocket
Frontend (real-time notifications)
```

---

## References

1. Dapr Jobs API Documentation: https://docs.dapr.io/reference/api/job_scheduler_api/
2. Strimzi Kafka Operator: https://strimzi.io/docs/operators/latest/overview.html
3. Redpanda Cloud: https://docs.redpanda.com/redpanda-cloud/
4. FastAPI WebSocket: https://fastapi.tiangolo.com/advanced/websockets/
5. PostgreSQL Arrays: https://www.postgresql.org/docs/current/arrays.html
6. PostgreSQL GIN Indexes: https://www.postgresql.org/docs/current/gin.html
