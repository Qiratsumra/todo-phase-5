# Docker Setup Guide

Complete Docker setup for the Todo Application with all microservices.

> 📘 **For Kafka & Dapr Setup**: See [KAFKA_DAPR_GUIDE.md](./KAFKA_DAPR_GUIDE.md) for complete event-driven architecture with message brokers and Dapr sidecars.

## 📦 Available Docker Images

All images are built and ready:

- **todo-backend:latest** (415MB) - FastAPI backend service
- **todo-frontend:latest** (296MB) - Next.js frontend
- **todo-notification:latest** (285MB) - Notification microservice
- **todo-recurring:latest** (288MB) - Recurring task microservice

## 🚀 Quick Start

### 1. Start Core Services (Recommended)

```bash
# Start PostgreSQL, Backend, and Frontend
./docker-run.sh
```

This starts:
- PostgreSQL database (port 5432)
- Backend API (port 8000)
- Frontend (port 3000)

### 2. Start All Services (Including Microservices)

```bash
# Start all services including notification and recurring task services
./docker-run.sh --with-services
```

This adds:
- Notification Service (port 8002)
- Recurring Task Service (port 8001)

**Note:** Microservices require Dapr and Kafka to function properly.

## 📜 Available Scripts

### Build Scripts

```bash
# Build all Docker images
./docker-build.sh
```

### Run Scripts

```bash
# Start core services
./docker-run.sh

# Start with microservices
./docker-run.sh --with-services

# Build and start
./docker-run.sh --build

# Show help
./docker-run.sh --help
```

### Stop Scripts

```bash
# Stop all services (keep data)
./docker-stop.sh

# Stop and remove all data (WARNING: deletes database)
./docker-stop.sh --volumes

# Show help
./docker-stop.sh --help
```

### Log Scripts

```bash
# View all logs
./docker-logs.sh

# View specific service logs
./docker-logs.sh backend
./docker-logs.sh frontend
./docker-logs.sh postgres

# View logs without following
./docker-logs.sh --no-follow

# Show help
./docker-logs.sh --help
```

## 🌐 Access Points

Once running, access the application at:

| Service | URL | Description |
|---------|-----|-------------|
| Frontend | http://localhost:3000 | Main application UI |
| Backend API | http://localhost:8000 | REST API |
| API Documentation | http://localhost:8000/docs | Interactive API docs (Swagger) |
| Database | localhost:5432 | PostgreSQL (credentials in .env) |
| Notification Service* | http://localhost:8002 | WebSocket notifications |
| Recurring Task Service* | http://localhost:8001 | Task scheduling |

\* Only available with `--with-services` flag

## 🔧 Manual Docker Commands

### Using Docker Compose

```bash
# Start services
docker compose up -d

# Start with microservices
docker compose --profile with-services up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# View specific service logs
docker compose logs -f backend

# Restart a service
docker compose restart backend

# Rebuild and restart
docker compose up -d --build backend
```

### Using Docker CLI

```bash
# List running containers
docker ps

# View all images
docker images | grep todo

# Stop a specific container
docker stop todo-backend

# Remove a container
docker rm todo-backend

# Remove an image
docker rmi todo-backend:latest

# View container logs
docker logs -f todo-backend

# Execute command in container
docker exec -it todo-backend /bin/sh
```

## 🗄️ Database Access

### Connect to PostgreSQL

```bash
# Using Docker
docker exec -it todo-db psql -U postgres

# Using psql directly
psql -h localhost -p 5432 -U postgres -d postgres
```

Password: `Qir@t_S2eed123` (from docker-compose.yml)

### Database Migrations

```bash
# Run migrations in backend container
docker exec -it todo-backend alembic upgrade head

# Create new migration
docker exec -it todo-backend alembic revision --autogenerate -m "description"
```

## 📊 Health Checks

All services have health checks configured:

```bash
# Check health status
docker ps --format "table {{.Names}}\t{{.Status}}"

# Backend health
curl http://localhost:8000/health

# Frontend health (if API endpoint exists)
curl http://localhost:3000/api/health
```

## 🐛 Troubleshooting

### Services Won't Start

```bash
# Check logs
./docker-logs.sh

# Check container status
docker ps -a

# Remove and restart
docker compose down
docker compose up -d
```

### Port Conflicts

If ports are already in use:

1. Stop conflicting services
2. Or modify ports in `docker-compose.yml`

### Database Connection Issues

```bash
# Check database is running
docker ps | grep todo-db

# Check backend can connect
docker exec -it todo-backend env | grep DATABASE

# Restart database
docker compose restart postgres
```

### Image Build Failures

```bash
# Clear build cache
docker builder prune

# Rebuild specific service
docker compose build --no-cache backend
```

## 🔄 Development Workflow

### Making Code Changes

1. **Backend changes:**
   ```bash
   # Rebuild backend image
   cd backend && docker build -t todo-backend:latest .

   # Or use docker-compose
   docker compose up -d --build backend
   ```

2. **Frontend changes:**
   ```bash
   # Rebuild frontend image
   cd frontend && docker build -t todo-frontend:latest .

   # Or use docker-compose
   docker compose up -d --build frontend
   ```

### Viewing Realtime Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend
```

## 📦 Docker Compose Configuration

The `docker-compose.yml` includes:

- **Networks:** Custom bridge network for service communication
- **Volumes:** Persistent PostgreSQL data
- **Health Checks:** Automatic service health monitoring
- **Profiles:** Optional microservices (`--profile with-services`)
- **Environment Variables:** Configured for local development

## 🏗️ Production Considerations

For production deployment:

1. **Update environment variables** (use secrets management)
2. **Use production-ready database** (managed PostgreSQL)
3. **Configure reverse proxy** (nginx/traefik)
4. **Enable SSL/TLS**
5. **Set up monitoring** (Prometheus/Grafana)
6. **Configure log aggregation** (ELK stack)
7. **Use container registry** (Docker Hub, AWS ECR, GCR)

## 📝 Notes

- **Microservices** (notification, recurring) require Dapr and Kafka infrastructure
- **Database data** persists in Docker volume `postgres_data`
- **Hot reload** not available in containers (rebuild for code changes)
- **Windows users:** Use Git Bash or WSL to run shell scripts

## 🆘 Getting Help

```bash
# Script help
./docker-run.sh --help
./docker-stop.sh --help
./docker-logs.sh --help

# Docker Compose help
docker compose --help

# View service configuration
docker compose config
```

## 🎯 Common Tasks Cheatsheet

```bash
# Fresh start (remove all data)
./docker-stop.sh --volumes && ./docker-run.sh --build

# Quick restart
./docker-stop.sh && ./docker-run.sh

# View backend logs only
./docker-logs.sh backend

# Check what's running
docker ps

# Clean up everything
docker compose down -v --rmi local
docker system prune -af
```
