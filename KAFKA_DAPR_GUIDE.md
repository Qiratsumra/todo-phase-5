# Kafka & Dapr Setup Guide

Complete guide for running the Todo Application with Kafka message broker and Dapr sidecars for event-driven architecture.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Development Workflows](#development-workflows)

## 🎯 Overview

This setup enables the complete event-driven architecture for the Todo Application:

- **Kafka**: Message broker for asynchronous event processing
- **Dapr**: Distributed application runtime providing pub/sub, state management, and service invocation
- **Microservices**: Notification and recurring task services that consume events

### What This Enables

- ✅ **Recurring Tasks**: Automatic creation of recurring tasks via scheduled events
- ✅ **Real-time Notifications**: WebSocket notifications for task updates
- ✅ **Event-Driven Architecture**: Decoupled services communicating via Kafka topics
- ✅ **State Management**: Distributed state storage across services
- ✅ **Audit Trail**: Complete event history for debugging and compliance

## 🏗️ Architecture

```
┌─────────────┐      ┌─────────────┐      ┌──────────────┐
│   Frontend  │─────▶│   Backend   │─────▶│  PostgreSQL  │
│  (Next.js)  │      │  (FastAPI)  │      │   Database   │
└─────────────┘      └──────┬──────┘      └──────────────┘
                            │
                            │ Dapr Sidecar (3500)
                            │
                     ┌──────▼──────┐
                     │    Kafka    │
                     │   Broker    │
                     └──────┬──────┘
                            │
           ┌────────────────┼────────────────┐
           │                │                │
    ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐
    │ task-events │  │  reminders  │  │task-updates │
    │    Topic    │  │    Topic    │  │    Topic    │
    └──────┬──────┘  └──────┬──────┘  └──────┬──────┘
           │                │                │
    ┌──────▼──────────┐    │         ┌──────▼──────────┐
    │   Recurring     │◀───┘         │  Notification   │
    │ Task Service    │              │    Service      │
    │ + Dapr (3501)   │              │  + Dapr (3502)  │
    └─────────────────┘              └─────────────────┘
```

### Kafka Topics

| Topic | Description | Retention | Partitions |
|-------|-------------|-----------|------------|
| `task-events` | Task lifecycle events (create, update, complete, delete) | 7 days | 3 |
| `reminders` | Reminder scheduling and delivery | 3 days | 3 |
| `task-updates` | Real-time task notifications | 1 day | 3 |
| `audit-events` | Audit trail for all operations | 30 days | 3 |

### Dapr Components

| Component | Type | Purpose |
|-----------|------|---------|
| `kafka-pubsub` | Pub/Sub | Kafka event messaging |
| `statestore` | State Store | PostgreSQL-backed state storage |

## 📦 Prerequisites

### System Requirements

- **Docker Desktop** or **Docker Engine** + **Docker Compose**
- **Bash shell** (Git Bash for Windows, or WSL)
- **4GB RAM minimum** (Kafka + Zookeeper + services)
- **10GB disk space** for Docker images

### Optional Tools

- **Dapr CLI** (auto-installed by setup script)
- **curl** for API testing
- **jq** for JSON parsing

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)

```bash
# Start everything with one command
./start-with-kafka.sh
```

This will:
1. Start PostgreSQL and Kafka infrastructure
2. Create Kafka topics
3. Start application services
4. Start microservices
5. Start Dapr sidecars

### Option 2: Manual Setup

```bash
# 1. Start Kafka infrastructure
docker compose --profile kafka up -d zookeeper kafka

# 2. Create Kafka topics
./scripts/create-kafka-topics.sh

# 3. Start core services
docker compose up -d backend frontend

# 4. Start microservices
docker compose --profile with-services up -d

# 5. Start Dapr sidecars
docker compose -f docker-compose.yml -f docker-compose.dapr.yml up -d
```

### Verify Setup

```bash
# Run integration tests
./scripts/test-kafka-dapr.sh
```

## 🔧 Detailed Setup

### Step 1: Start Kafka Infrastructure

```bash
# Start Zookeeper and Kafka
docker compose --profile kafka up -d zookeeper kafka

# Wait for Kafka to be ready (30-60 seconds)
docker logs -f todo-kafka
# Look for: "Kafka Server started"

# Optional: Start Kafka UI for visualization
docker compose --profile kafka up -d kafka-ui
```

**Access Kafka UI**: http://localhost:8080

### Step 2: Create Kafka Topics

The topics must be created before services can publish/consume:

```bash
./scripts/create-kafka-topics.sh
```

**Verify topics:**

```bash
docker exec todo-kafka kafka-topics --list --bootstrap-server localhost:9092
```

Expected output:
```
audit-events
reminders
task-events
task-updates
```

### Step 3: Start Application Services

```bash
# Start database (if not already running)
docker compose up -d postgres

# Start backend API
docker compose up -d backend

# Start frontend
docker compose up -d frontend

# Verify services are healthy
docker ps --filter "name=todo-" --format "table {{.Names}}\t{{.Status}}"
```

### Step 4: Start Microservices

```bash
# Start notification and recurring task services
docker compose --profile with-services up -d notification-service recurring-task-service

# Check logs
docker compose logs -f notification-service recurring-task-service
```

### Step 5: Start Dapr Sidecars

```bash
# Start all Dapr sidecars
docker compose -f docker-compose.yml -f docker-compose.dapr.yml up -d

# Wait for initialization (10-15 seconds)
sleep 10

# Verify Dapr sidecars
docker ps --filter "name=dapr" --format "table {{.Names}}\t{{.Status}}"
```

Expected containers:
- `backend-dapr`
- `notification-dapr`
- `recurring-dapr`
- `dapr-placement`

### Step 6: Verify Setup

```bash
# Run comprehensive test suite
./scripts/test-kafka-dapr.sh
```

## ✅ Testing

### Automated Tests

```bash
# Full integration test
./scripts/test-kafka-dapr.sh
```

### Manual Testing

#### Test 1: Publish Event via Dapr

```bash
# Publish a task event
curl -X POST http://localhost:3500/v1.0/publish/kafka-pubsub/task-events \
  -H "Content-Type: application/json" \
  -d '{
    "taskId": "test-123",
    "action": "created",
    "title": "Test Task",
    "timestamp": "2024-01-01T00:00:00Z"
  }'

# Expected response: HTTP 204 No Content
```

#### Test 2: Check Dapr Metadata

```bash
# View loaded components
curl http://localhost:3500/v1.0/metadata | jq .
```

Expected output includes:
```json
{
  "components": [
    {
      "name": "kafka-pubsub",
      "type": "pubsub.kafka"
    },
    {
      "name": "statestore",
      "type": "state.postgresql"
    }
  ]
}
```

#### Test 3: Consume Messages

```bash
# View messages in Kafka UI
# Open http://localhost:8080
# Navigate to Topics → task-events → Messages
```

#### Test 4: Check Service Logs

```bash
# Watch for event processing
docker compose logs -f recurring-task-service

# Should see logs like:
# "Received task event: created"
# "Processing task: test-123"
```

### Performance Testing

```bash
# Publish multiple events
for i in {1..100}; do
  curl -X POST http://localhost:3500/v1.0/publish/kafka-pubsub/task-events \
    -H "Content-Type: application/json" \
    -d "{\"taskId\":\"test-$i\",\"action\":\"created\"}"
done

# Monitor consumer lag in Kafka UI
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Kafka Won't Start

**Symptom**: `todo-kafka` container exits immediately

**Solutions**:

```bash
# Check logs
docker logs todo-kafka

# Common issue: Port already in use
lsof -i :9092  # On Mac/Linux
netstat -ano | findstr :9092  # On Windows

# Kill conflicting process or change port in docker-compose.yml

# Restart Kafka
docker compose --profile kafka restart kafka
```

#### 2. Topics Not Created

**Symptom**: `./scripts/create-kafka-topics.sh` fails

**Solutions**:

```bash
# Ensure Kafka is running
docker ps | grep kafka

# Wait longer for Kafka to initialize
sleep 30

# Try creating topics manually
docker exec todo-kafka kafka-topics \
  --create --if-not-exists \
  --bootstrap-server localhost:9092 \
  --topic task-events \
  --partitions 3 \
  --replication-factor 1
```

#### 3. Dapr Sidecars Won't Start

**Symptom**: `backend-dapr` container fails

**Solutions**:

```bash
# Check Dapr sidecar logs
docker logs backend-dapr

# Verify component files exist
ls -la dapr-components/
ls -la dapr-config/

# Ensure backend service is running first
docker ps | grep todo-backend

# Restart Dapr sidecars
docker compose -f docker-compose.dapr.yml restart
```

#### 4. Components Not Loading

**Symptom**: Dapr metadata shows no components

**Solutions**:

```bash
# Check component file syntax
cat dapr-components/kafka-pubsub-docker.yaml

# Verify mount paths
docker inspect backend-dapr | grep -A 5 Mounts

# Check Dapr logs for errors
docker logs backend-dapr | grep -i error

# Restart with fresh components
docker compose -f docker-compose.dapr.yml down
docker compose -f docker-compose.dapr.yml up -d
```

#### 5. Messages Not Being Consumed

**Symptom**: Events published but not processed

**Solutions**:

```bash
# Check consumer group
docker exec todo-kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --describe \
  --group taskflow-consumer-group

# Verify microservices are subscribed
docker logs recurring-task-service | grep -i subscribe

# Check for errors in service logs
docker logs recurring-task-service
docker logs notification-service

# Reset consumer group (development only!)
docker exec todo-kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --group taskflow-consumer-group \
  --reset-offsets --to-earliest --all-topics --execute
```

### Debug Commands

```bash
# Check all containers
docker ps -a

# View all logs
docker compose logs --tail=50

# View Kafka logs
docker logs todo-kafka

# View Dapr placement logs
docker logs dapr-placement

# List topics and details
docker exec todo-kafka kafka-topics \
  --describe --bootstrap-server localhost:9092

# Check consumer groups
docker exec todo-kafka kafka-consumer-groups \
  --list --bootstrap-server localhost:9092

# View messages in topic
docker exec todo-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic task-events \
  --from-beginning --max-messages 10

# Test Dapr health
curl http://localhost:3500/v1.0/healthz
```

## 💻 Development Workflows

### Starting for Development

```bash
# Full stack with Kafka & Dapr
./start-with-kafka.sh

# View all logs
docker compose logs -f
```

### Making Code Changes

When you change service code:

```bash
# Rebuild and restart specific service
docker compose up -d --build backend

# Restart Dapr sidecar
docker compose -f docker-compose.dapr.yml restart backend-dapr
```

### Viewing Logs During Development

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend

# Dapr sidecars only
docker compose -f docker-compose.dapr.yml logs -f

# Follow multiple services
docker compose logs -f backend recurring-task-service
```

### Stopping Services

```bash
# Stop everything (keep data)
./stop-all.sh

# Stop and remove all data
./stop-all.sh --volumes

# Stop only Dapr
docker compose -f docker-compose.dapr.yml down

# Stop only Kafka
docker compose --profile kafka stop kafka zookeeper
```

### Restarting Individual Components

```bash
# Restart Kafka
docker compose --profile kafka restart kafka

# Restart backend + Dapr sidecar
docker compose restart backend
docker compose -f docker-compose.dapr.yml restart backend-dapr

# Restart all microservices
docker compose --profile with-services restart
```

## 📊 Monitoring

### Kafka UI Dashboard

Access: http://localhost:8080

Features:
- View topics and messages
- Monitor consumer groups
- Check broker health
- Manage topic configurations

### Dapr Dashboard (Optional)

```bash
# Install Dapr dashboard
dapr dashboard -p 9999

# Access at http://localhost:9999
```

### Health Checks

```bash
# Application health
curl http://localhost:8000/health

# Dapr health
curl http://localhost:3500/v1.0/healthz

# Kafka health
docker exec todo-kafka kafka-broker-api-versions \
  --bootstrap-server localhost:9092
```

## 📝 Configuration Files

### Dapr Configuration

- `dapr-config/dapr-config.yaml` - Dapr runtime configuration
- `dapr-components/kafka-pubsub-docker.yaml` - Kafka pub/sub component
- `dapr-components/statestore-docker.yaml` - PostgreSQL state store

### Docker Compose

- `docker-compose.yml` - Base services + Kafka
- `docker-compose.dapr.yml` - Dapr sidecar configuration

### Scripts

- `start-with-kafka.sh` - Complete automated setup
- `stop-all.sh` - Stop all services
- `scripts/create-kafka-topics.sh` - Topic creation
- `scripts/test-kafka-dapr.sh` - Integration testing

## 🔐 Security Notes

### For Development

- No authentication on Kafka (suitable for local dev only)
- Dapr uses default configuration
- All services on same Docker network

### For Production

Update configurations:

1. **Kafka**: Enable SASL authentication
2. **Dapr**: Configure mTLS between services
3. **Network**: Use separate networks per service tier
4. **Secrets**: Use Dapr secrets management

## 🎓 Learning Resources

### Dapr

- [Dapr Documentation](https://docs.dapr.io/)
- [Pub/Sub Overview](https://docs.dapr.io/developing-applications/building-blocks/pubsub/)
- [State Management](https://docs.dapr.io/developing-applications/building-blocks/state-management/)

### Kafka

- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Confluent Platform](https://docs.confluent.io/)

## 🆘 Getting Help

If you encounter issues:

1. Run the test script: `./scripts/test-kafka-dapr.sh`
2. Check logs: `docker compose logs`
3. Verify setup: `docker ps -a`
4. Restart everything: `./stop-all.sh && ./start-with-kafka.sh`

For persistent issues, check:
- Docker daemon is running
- Sufficient system resources (4GB RAM)
- No port conflicts (9092, 2181, 3500-3502)
- Firewall/antivirus not blocking Docker

---

**Last Updated**: January 2026
**Version**: 1.0.0
