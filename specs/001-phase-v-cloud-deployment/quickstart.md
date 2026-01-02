# Quickstart Guide: Phase V Advanced Cloud Deployment

**Generated**: 2025-12-29 | **Plan**: [plan.md](plan.md)

## Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Docker | 24.0+ | Containerization |
| kubectl | 1.28+ | Kubernetes CLI |
| Minikube | 1.32+ | Local Kubernetes (Part B) |
| Python | 3.11+ | Backend services |
| Node.js | 18+ | Frontend (Next.js) |
| Git | 2.0+ | Version control |

### Optional Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Dapr CLI | 1.13+ | Dapr runtime |
| Helm | 3.14+ | Kubernetes package manager |
| k6 | 0.46+ | Load testing |
| jq | 1.7+ | JSON processing |

---

## Local Development Setup

### Step 1: Start Minikube

```bash
# Start Minikube with sufficient resources
minikube start --cpus=4 --memory=8192 --driver=docker

# Enable required addons
minikube addons enable ingress
minikube addons enable metrics-server

# Verify status
minikube status
```

### Step 2: Install Dapr

```bash
# Install Dapr CLI
curl -fsSL https://dapr.io/install.sh | bash

# Initialize Dapr on Minikube
dapr init -k

# Verify installation
kubectl get pods -n dapr-system

# Start Dapr Dashboard (runs on port 8080)
dapr dashboard -k
```

### Step 3: Install Strimzi Kafka

```bash
# Create Kafka namespace
kubectl create namespace kafka

# Install Strimzi operator
kubectl apply -f https://strimzi.io/install/latest/strimzi-with-entity-operator.yaml

# Wait for operator to be ready
kubectl wait --for=condition=ready pod -l name=strimzi-cluster-operator -n kafka --timeout=120s

# Create Kafka cluster
kubectl apply -f https://raw.githubusercontent.com/strimzi/strimzi-kafka-operator/main/examples/kafka/kafka-persistent-single.yaml -n kafka

# Wait for Kafka to be ready
kubectl wait --for=condition=Ready kafka/my-cluster -n kafka --timeout=300s

# Create Kafka topics
cat <<EOF | kubectl apply -f -
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: task-events
  namespace: kafka
spec:
  partitions: 3
  replicas: 1
---
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: reminders
  namespace: kafka
spec:
  partitions: 3
  replicas: 1
---
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: task-updates
  namespace: kafka
spec:
  partitions: 3
  replicas: 1
EOF
```

### Step 4: Set Up PostgreSQL

```bash
# Using Docker Compose (for local development)
cat <<EOF > docker-compose.yml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: taskflow
      POSTGRES_USER: taskflow
      POSTGRES_PASSWORD: taskflow
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U taskflow -d taskflow"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
EOF

# Start PostgreSQL
docker-compose up -d postgres

# Verify connection
PGPASSWORD=taskflow psql -h localhost -U taskflow -d taskflow -c "SELECT 1"
```

### Step 5: Clone and Configure Repository

```bash
# Clone repository
git clone https://github.com/your-org/todo-hackathon02-phase-05.git
cd todo-hackathon02-phase-05

# Create environment file
cat <<EOF > .env
# Database
DATABASE_URL=postgresql://taskflow:taskflow@localhost:5432/taskflow

# Gemini API
GEMINI_API_KEY=your_gemini_api_key

# Dapr
DAPR_HTTP_PORT=3500
DAPR_GRPC_PORT=50001

# Kafka (Strimzi local)
KAFKA_BOOTSTRAP_SERVERS=my-cluster-kafka-bootstrap.kafka:9092
EOF
```

### Step 6: Install Backend Dependencies

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run database migrations
alembic upgrade head

# Start backend service (development mode)
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

### Step 7: Install Frontend Dependencies

```bash
cd frontend

# Install dependencies
npm install

# Start frontend (development mode)
npm run dev
```

### Step 8: Verify Installation

```bash
# Check backend health
curl http://localhost:8000/health

# Expected response:
# {"status": "healthy", "services": {"database": "connected", "kafka": "connected"}}

# Check frontend
curl http://localhost:3000

# Access chatbot
# Open browser to http://localhost:3000
```

---

## Dapr Components Configuration

### kafka-pubsub.yaml

```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: kafka-pubsub
  namespace: default
spec:
  type: pubsub.kafka
  version: v1
  metadata:
    - name: brokers
      value: "my-cluster-kafka-bootstrap.kafka:9092"
    - name: consumerGroup
      value: "taskflow-consumer-group"
    - name: authType
      value: "none"  # Use "sasl" for production
    - name: tls
      value: "false"
```

### statestore.yaml

```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore
  namespace: default
spec:
  type: state.postgresql
  version: v1
  metadata:
    - name: connectionString
      value: "postgresql://taskflow:taskflow@postgres:5432/taskflow"
    - name: tableName
      value: "dapr_state"
```

### Apply Dapr Components

```bash
# Create dapr-components directory
mkdir -p dapr-components

# Save component files
cat <<EOF > dapr-components/kafka-pubsub.yaml
$(cat <<'YAML'
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: kafka-pubsub
  namespace: default
spec:
  type: pubsub.kafka
  version: v1
  metadata:
    - name: brokers
      value: "my-cluster-kafka-bootstrap.kafka:9092"
    - name: consumerGroup
      value: "taskflow-consumer-group"
    - name: authType
      value: "none"
    - name: tls
      value: "false"
YAML
)

cat <<EOF > dapr-components/statestore.yaml
$(cat <<'YAML'
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore
  namespace: default
spec:
  type: state.postgresql
  version: v1
  metadata:
    - name: connectionString
      value: "postgresql://taskflow:taskflow@postgres:5432/taskflow"
    - name: tableName
      value: "dapr_state"
YAML
)

# Apply to Kubernetes
kubectl apply -f dapr-components/
```

---

## Testing

### Unit Tests

```bash
cd backend
pytest tests/unit/ -v --cov=src --cov-report=html
```

### Integration Tests

```bash
cd backend
pytest tests/integration/ -v

# Run specific integration test
pytest tests/integration/test_recurring_tasks.py -v
```

### Contract Tests

```bash
cd backend
pytest tests/contract/ -v
```

### Load Tests

```bash
# Install k6
brew install k6  # macOS
# or: choco install k6  # Windows

# Run load test
k6 run tests/load/test-chat.js \
  -e USERS=50 \
  -e DURATION=60s \
  -e API_URL=http://localhost:8000
```

---

## Kubernetes Deployment (Local)

### Build Docker Images

```bash
# Point to Minikube Docker daemon
eval $(minikube docker-env)

# Build all images
docker build -t taskflow/backend:latest ./backend
docker build -t taskflow/frontend:latest ./frontend
docker build -t taskflow/recurring-task-service:latest ./services/recurring-task-service
docker build -t taskflow/notification-service:latest ./services/notification-service
```

### Deploy to Minikube

```bash
# Apply base Kubernetes manifests
kubectl apply -f k8s/base/

# Apply Dapr components
kubectl apply -f dapr-components/

# Check deployment status
kubectl get pods -n taskflow

# View logs
kubectl logs -n taskflow -l app=backend -c daprd
```

### Access the Application

```bash
# Get Minikube IP
minikube ip

# Access frontend
open http://$(minikube ip)

# Access backend API docs
open http://$(minikube ip)/docs
```

---

## Cloud Deployment (Oracle OKE)

### Prerequisites

- Oracle Cloud account
- OKE cluster created (4 OCPU, 24GB RAM)
- kubectl configured for OKE

### Configure kubectl

```bash
# Create kubeconfig for OKE
oci ce cluster create-kubeconfig \
  --cluster-id <your-cluster-ocid> \
  --file ~/.kube/config \
  --region <your-region>

# Verify connection
kubectl get nodes
```

### Create Secrets

```bash
# Create namespace
kubectl create namespace taskflow

# Create secrets
kubectl create secret generic taskflow-secrets \
  --from-literal=gemini-api-key="${GEMINI_API_KEY}" \
  --from-literal=neon-connection-string="${NEON_CONNECTION_STRING}" \
  --from-literal=redpanda-bootstrap="${REDPANDA_BOOTSTRAP}" \
  --from-literal=redpanda-username="${REDPANDA_USERNAME}" \
  --from-literal=redpanda-password="${REDPANDA_PASSWORD}" \
  -n taskflow
```

### Deploy to OKE

```bash
# Apply cloud-specific overlays
kubectl apply -f k8s/overlays/cloud/

# Check status
kubectl get pods -n taskflow

# View Dapr sidecar logs
kubectl logs -n taskflow -l app=backend -c daprd
```

### Configure Ingress

```bash
# Install NGINX Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml

# Create ingress
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: taskflow-ingress
  namespace: taskflow
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - taskflow.your-domain.com
      secretName: taskflow-tls
  rules:
    - host: taskflow.your-domain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend
                port:
                  number: 80
EOF
```

---

## Troubleshooting

### Kafka Connection Issues

```bash
# Check Kafka status
kubectl get kafka my-cluster -n kafka

# Check Kafka topics
kubectl -n kafka exec my-cluster-kafka-0 -- /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092

# Check Dapr Pub/Sub component
kubectl get component kafka-pubsub -n default
```

### Database Connection Issues

```bash
# Check PostgreSQL pod
kubectl get pods -n default | grep postgres

# Check PostgreSQL logs
kubectl logs -n default postgres-0

# Test database connection
kubectl exec -it postgres-0 -- psql -U taskflow -d taskflow
```

### Dapr Sidecar Issues

```bash
# Check Dapr system pods
kubectl get pods -n dapr-system

# Check Dapr sidecar in specific pod
kubectl logs -n taskflow -l app=backend -c daprd

# Check Dapr configuration
kubectl get configurations dapr-config -n default -o yaml
```

### Performance Issues

```bash
# Check resource usage
kubectl top pods -n taskflow

# Check for OOMKilled pods
kubectl get events -n taskflow --field-selector reason=OOMKilled

# Check Kafka consumer lag
kubectl -n kafka exec my-cluster-kafka-0 -- /opt/kafka/bin/kafka-consumer-groups.sh --describe --bootstrap-server localhost:9092 --group taskflow-consumer-group
```

---

## Next Steps

1. **Run Tests**: Execute test suite to verify installation
2. **Create Tasks**: Use `/sp.tasks` to generate implementation task list
3. **Implement Features**: Follow task list to implement each feature
4. **Deploy Locally**: Verify all services work in Minikube
5. **Deploy to Cloud**: Deploy to Oracle OKE for production
6. **Create Demo**: Record 90-second demo video
