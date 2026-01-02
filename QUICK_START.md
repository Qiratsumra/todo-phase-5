# Quick Start Guide

Choose your deployment mode:

## 🚀 Simple Mode (Core Services Only)

**Best for**: Development without event-driven features

```bash
# Start PostgreSQL, Backend, Frontend
./docker-run.sh

# Access
# - Frontend: http://localhost:3000
# - Backend:  http://localhost:8000
# - API Docs: http://localhost:8000/docs
```

## 🎯 Full Mode (With Event-Driven Architecture)

**Best for**: Testing complete feature set with Kafka & Dapr

```bash
# Start everything (Kafka, Dapr, all services)
./start-with-kafka.sh

# Test setup
./scripts/test-kafka-dapr.sh

# Access
# - Frontend:     http://localhost:3000
# - Backend:      http://localhost:8000
# - Kafka UI:     http://localhost:8080
# - Backend Dapr: http://localhost:3500
```

## 📊 What's Included

### Simple Mode
✅ PostgreSQL Database
✅ Backend API (FastAPI)
✅ Frontend (Next.js)
✅ Core CRUD Operations
✅ Priority & Tags
✅ Search & Filter

### Full Mode
✅ **Everything in Simple Mode**
✅ Kafka Message Broker
✅ Dapr Runtime
✅ Notification Service
✅ Recurring Task Service
✅ Event-Driven Architecture
✅ Real-time Updates

## 🛑 Stop Services

```bash
# Simple mode
./docker-stop.sh

# Full mode
./stop-all.sh

# Remove all data (CAUTION!)
./stop-all.sh --volumes
```

## 📚 Detailed Guides

- **Docker Setup**: See [DOCKER_README.md](./DOCKER_README.md)
- **Kafka & Dapr**: See [KAFKA_DAPR_GUIDE.md](./KAFKA_DAPR_GUIDE.md)
- **Deployment**: See [DEPLOYMENT_READY.md](./DEPLOYMENT_READY.md)

## 🔍 Troubleshooting

```bash
# Check what's running
docker ps

# View logs
docker compose logs -f

# Health check
curl http://localhost:8000/health

# Restart everything
./stop-all.sh && ./start-with-kafka.sh
```

## 💡 Tips

- **First time?** Start with Simple Mode
- **Testing events?** Use Full Mode
- **Low on RAM?** Stick to Simple Mode (needs 2GB vs 4GB)
- **Production?** See deployment guides in docs/

## 📋 Requirements

**Minimum** (Simple Mode):
- Docker Desktop or Docker Engine
- 2GB RAM
- 5GB disk space

**Recommended** (Full Mode):
- Docker Desktop or Docker Engine
- 4GB RAM
- 10GB disk space

---

**Need help?** Check the detailed guides or run:
```bash
./docker-run.sh --help
./start-with-kafka.sh --help (if it exists)
```
