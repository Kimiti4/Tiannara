# Tiannara SaaS Production Deployment Guide

**Date**: May 1, 2026  
**Status**: 🚧 **IN PROGRESS** - Phase 1: Infrastructure Setup  
**Version**: 1.0.0

---

## 🎯 **Deployment Architecture**

Based on the refined architecture from `tiannara_internal_dashboard/README.md`:

```
                Tiannara Pros / SaaS (Frontend)
                         ↑
                  Public API Layer (FastAPI + Nginx)
                         ↑
             Production Runtime Layer (Container Orchestration)
                         ↑
                Tiannara Core (Cognition Engine)
                         ↑
              Infrastructure Layer (Database, Cache, Queue)
```

### **Key Principles:**

1. **Core Independence**: Tiannara Core runs independently of GUI/SaaS
2. **Stability Boundary**: Production Runtime Layer freezes stable workflows
3. **API Gateway**: Single entry point with auth, rate limiting, routing
4. **Separation of Concerns**: Research vs Production isolation
5. **Scalability**: Horizontal scaling for API and frontend tiers

---

## 📋 **Deployment Checklist**

### **Phase 1: Infrastructure Foundation** ✅ CURRENT PHASE
- [ ] Docker containerization for all services
- [ ] Docker Compose for local development
- [ ] Kubernetes manifests for production
- [ ] Database migration automation
- [ ] Environment configuration management
- [ ] Secrets management (Vault/AWS Secrets Manager)

### **Phase 2: CI/CD Pipeline**
- [ ] GitHub Actions workflow
- [ ] Automated testing pipeline
- [ ] Container image building
- [ ] Image registry (ECR/GCR/Docker Hub)
- [ ] Automated deployment to staging
- [ ] Blue-green deployment strategy

### **Phase 3: Monitoring & Observability**
- [ ] Prometheus metrics collection
- [ ] Grafana dashboards
- [ ] ELK stack for logging
- [ ] Alertmanager configuration
- [ ] Distributed tracing (Jaeger)
- [ ] Health check endpoints

### **Phase 4: Security Hardening**
- [ ] SSL/TLS certificates (Let's Encrypt)
- [ ] WAF configuration (Cloudflare/AWS WAF)
- [ ] Network policies
- [ ] RBAC for Kubernetes
- [ ] Secret rotation automation
- [ ] Security scanning (Trivy/Clair)

### **Phase 5: Performance Optimization**
- [ ] CDN setup (CloudFront/Cloudflare)
- [ ] Database connection pooling
- [ ] Redis caching layer
- [ ] Load balancer configuration
- [ ] Auto-scaling policies
- [ ] Performance testing

### **Phase 6: Backup & Disaster Recovery**
- [ ] Database backup automation
- [ ] Point-in-time recovery
- [ ] Cross-region replication
- [ ] Disaster recovery runbook
- [ ] Backup testing procedures
- [ ] Data retention policies

---

## 🐳 **Docker Containerization**

### **Service Breakdown:**

| Service | Port | Description | Base Image |
|---------|------|-------------|------------|
| `tiannara-api` | 8000 | FastAPI backend | python:3.11-slim |
| `tiannara-core` | N/A | Cognition engine (internal) | python:3.11-slim |
| `tiannara-saas` | 3000 | Next.js frontend | node:18-alpine |
| `postgres` | 5432 | Primary database | postgres:15-alpine |
| `redis` | 6379 | Cache/session store | redis:7-alpine |
| `nginx` | 80/443 | Reverse proxy | nginx:alpine |

### **Directory Structure:**

```
Tiannara-MindCache-Prosthetic/
├── docker/
│   ├── api/
│   │   ├── Dockerfile
│   │   └── entrypoint.sh
│   ├── core/
│   │   ├── Dockerfile
│   │   └── entrypoint.sh
│   ├── saas/
│   │   ├── Dockerfile
│   │   └── nginx.conf
│   └── nginx/
│       ├── Dockerfile
│       └── nginx.conf
├── kubernetes/
│   ├── namespaces.yaml
│   ├── configmaps.yaml
│   ├── secrets.yaml
│   ├── deployments/
│   │   ├── api-deployment.yaml
│   │   ├── core-deployment.yaml
│   │   ├── saas-deployment.yaml
│   │   └── postgres-deployment.yaml
│   ├── services/
│   │   ├── api-service.yaml
│   │   ├── saas-service.yaml
│   │   └── postgres-service.yaml
│   ├── ingress.yaml
│   └── hpa.yaml
├── docker-compose.yml
├── docker-compose.prod.yml
└── .env.example
```

---

## 🔧 **Dockerfiles**

### **1. API Backend Dockerfile**

```dockerfile
# docker/api/Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY tiannara_api/ ./tiannara_api/
COPY tiannara_core/ ./tiannara_core/

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/api/v1/health || exit 1

# Run with uvicorn
CMD ["uvicorn", "tiannara_api.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

### **2. Core Engine Dockerfile**

```dockerfile
# docker/core/Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies for scientific computing
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libblas-dev \
    liblapack-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy core code
COPY tiannara_core/ ./tiannara_core/

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser
USER appuser

# No exposed ports - internal service only
# Run as background worker
CMD ["python", "-m", "tiannara_core.autonomous.loop"]
```

### **3. SaaS Frontend Dockerfile**

```dockerfile
# docker/saas/Dockerfile
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY tiannara_saas/package*.json ./
RUN npm ci

# Copy source code
COPY tiannara_saas/ .

# Build production bundle
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy custom nginx config
COPY docker/saas/nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets
COPY --from=builder /app/out /usr/share/nginx/html

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget -qO- http://localhost:3000 || exit 1

CMD ["nginx", "-g", "daemon off;"]
```

### **4. Nginx Reverse Proxy**

```dockerfile
# docker/nginx/Dockerfile
FROM nginx:alpine

# Copy configuration
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/ssl/ /etc/nginx/ssl/

# Expose ports
EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
```

---

## 📝 **Nginx Configuration**

### **Production Nginx Config**

```nginx
# docker/nginx/nginx.conf
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;

    # Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 50M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;

    # Upstream definitions
    upstream api_backend {
        server tiannara-api:8000;
    }

    upstream saas_frontend {
        server tiannara-saas:3000;
    }

    # HTTP → HTTPS redirect
    server {
        listen 80;
        server_name api.tiannara.com app.tiannara.com;
        return 301 https://$server_name$request_uri;
    }

    # API Gateway (HTTPS)
    server {
        listen 443 ssl http2;
        server_name api.tiannara.com;

        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        # API routes
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            
            proxy_pass http://api_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        # Auth endpoints (stricter rate limiting)
        location /api/v1/auth/ {
            limit_req zone=login burst=5 nodelay;
            
            proxy_pass http://api_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        # Health check endpoint (no rate limit)
        location /api/v1/health {
            proxy_pass http://api_backend;
        }
    }

    # SaaS Frontend (HTTPS)
    server {
        listen 443 ssl http2;
        server_name app.tiannara.com;

        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        location / {
            proxy_pass http://saas_frontend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Static assets with long cache
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            proxy_pass http://saas_frontend;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

---

## 🐙 **Docker Compose**

### **Development Environment**

```yaml
# docker-compose.yml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: tiannara
      POSTGRES_USER: tiannara
      POSTGRES_PASSWORD: dev_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U tiannara"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  tiannara-api:
    build:
      context: .
      dockerfile: docker/api/Dockerfile
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql://tiannara:dev_password@postgres:5432/tiannara
      REDIS_URL: redis://redis:6379
      ENVIRONMENT: development
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - ./tiannara_api:/app/tiannara_api
      - ./tiannara_core:/app/tiannara_core
    command: uvicorn tiannara_api.main:app --host 0.0.0.0 --port 8000 --reload

  tiannara-core:
    build:
      context: .
      dockerfile: docker/core/Dockerfile
    environment:
      DATABASE_URL: postgresql://tiannara:dev_password@postgres:5432/tiannara
      REDIS_URL: redis://redis:6379
    depends_on:
      - postgres
      - redis
    volumes:
      - ./tiannara_core:/app/tiannara_core

volumes:
  postgres_data:
  redis_data:
```

### **Production Environment**

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - tiannara-network
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - tiannara-network
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 2G
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  tiannara-api:
    image: tiannara/api:${API_VERSION:-latest}
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
      REDIS_URL: redis://:${REDIS_PASSWORD}@redis:6379
      ENVIRONMENT: production
      JWT_SECRET_KEY: ${JWT_SECRET_KEY}
      OPENAI_API_KEY: ${OPENAI_API_KEY}
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - tiannara-network
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '2'
          memory: 4G
      restart_policy:
        condition: on-failure
        max_attempts: 3
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/api/v1/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  tiannara-saas:
    image: tiannara/saas:${SAAS_VERSION:-latest}
    environment:
      NEXT_PUBLIC_API_URL: https://api.tiannara.com/api/v1
    networks:
      - tiannara-network
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '1'
          memory: 2G
      restart_policy:
        condition: on-failure
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:3000"]
      interval: 30s
      timeout: 5s
      retries: 3

  nginx:
    build:
      context: .
      dockerfile: docker/nginx/Dockerfile
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./docker/nginx/ssl:/etc/nginx/ssl:ro
    depends_on:
      - tiannara-api
      - tiannara-saas
    networks:
      - tiannara-network
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G
    restart: always

networks:
  tiannara-network:
    driver: overlay

volumes:
  postgres_data:
  redis_data:
```

---

## ☸️ **Kubernetes Manifests**

### **Namespace Configuration**

```yaml
# kubernetes/namespaces.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: tiannara-production
  labels:
    name: tiannara-production
    environment: production
---
apiVersion: v1
kind: Namespace
metadata:
  name: tiannara-staging
  labels:
    name: tiannara-staging
    environment: staging
```

### **ConfigMap**

```yaml
# kubernetes/configmaps.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tiannara-config
  namespace: tiannara-production
data:
  ENVIRONMENT: "production"
  LOG_LEVEL: "INFO"
  WORKERS: "4"
  DATABASE_POOL_SIZE: "20"
  REDIS_POOL_SIZE: "10"
  CORS_ORIGINS: "https://app.tiannara.com"
  RATE_LIMIT_PER_MINUTE: "600"
```

### **API Deployment**

```yaml
# kubernetes/deployments/api-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tiannara-api
  namespace: tiannara-production
  labels:
    app: tiannara-api
    tier: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: tiannara-api
  template:
    metadata:
      labels:
        app: tiannara-api
        tier: backend
    spec:
      containers:
      - name: api
        image: tiannara/api:latest
        ports:
        - containerPort: 8000
        envFrom:
        - configMapRef:
            name: tiannara-config
        - secretRef:
            name: tiannara-secrets
        resources:
          requests:
            cpu: "500m"
            memory: "1Gi"
          limits:
            cpu: "2"
            memory: "4Gi"
        livenessProbe:
          httpGet:
            path: /api/v1/health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /api/v1/health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 10
        volumeMounts:
        - name: logs
          mountPath: /app/logs
      volumes:
      - name: logs
        emptyDir: {}
```

### **API Service**

```yaml
# kubernetes/services/api-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: tiannara-api
  namespace: tiannara-production
  labels:
    app: tiannara-api
spec:
  type: ClusterIP
  ports:
  - port: 8000
    targetPort: 8000
    protocol: TCP
    name: http
  selector:
    app: tiannara-api
```

### **Horizontal Pod Autoscaler**

```yaml
# kubernetes/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: tiannara-api-hpa
  namespace: tiannara-production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: tiannara-api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### **Ingress**

```yaml
# kubernetes/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tiannara-ingress
  namespace: tiannara-production
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
spec:
  tls:
  - hosts:
    - api.tiannara.com
    - app.tiannara.com
    secretName: tiannara-tls
  rules:
  - host: api.tiannara.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: tiannara-api
            port:
              number: 8000
  - host: app.tiannara.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: tiannara-saas
            port:
              number: 3000
```

---

## 🔐 **Environment Configuration**

### **.env.example**

```bash
# Database
POSTGRES_DB=tiannara
POSTGRES_USER=tiannara
POSTGRES_PASSWORD=<generate-strong-password>
DATABASE_URL=postgresql://tiannara:<password>@postgres:5432/tiannara

# Redis
REDIS_PASSWORD=<generate-strong-password>
REDIS_URL=redis://:<password>@redis:6379

# JWT Authentication
JWT_SECRET_KEY=<generate-secure-random-string-64-chars>
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# OpenAI/LLM Providers
OPENAI_API_KEY=<your-openai-key>
ANTHROPIC_API_KEY=<your-anthropic-key>

# Email (Resend/SendGrid)
RESEND_API_KEY=<your-resend-key>
EMAIL_FROM=noreply@tiannara.com

# OAuth SSO
GOOGLE_CLIENT_ID=<google-oauth-client-id>
GOOGLE_CLIENT_SECRET=<google-oauth-secret>
MICROSOFT_CLIENT_ID=<microsoft-oauth-client-id>
MICROSOFT_CLIENT_SECRET=<microsoft-oauth-secret>
GITHUB_CLIENT_ID=<github-oauth-client-id>
GITHUB_CLIENT_SECRET=<github-oauth-secret>

# Paystack Payment Gateway
PAYSTACK_PUBLIC_KEY=<paystack-public-key>
PAYSTACK_SECRET_KEY=<paystack-secret-key>
PAYSTACK_WEBHOOK_SECRET=<paystack-webhook-secret>
PAYSTACK_STARTER_PLAN=<starter-plan-code>
PAYSTACK_PROFESSIONAL_PLAN=<professional-plan-code>

# Application Settings
ENVIRONMENT=production
LOG_LEVEL=INFO
CORS_ORIGINS=https://app.tiannara.com
RATE_LIMIT_PER_MINUTE=600

# Version Tags
API_VERSION=1.0.0
SAAS_VERSION=1.0.0
```

---

## 🚀 **Deployment Scripts**

### **deploy.sh**

```bash
#!/bin/bash
# Production deployment script

set -e

echo "🚀 Starting Tiannara SaaS production deployment..."

# Configuration
NAMESPACE="tiannara-production"
IMAGE_REGISTRY="docker.io/tiannara"
API_VERSION="${1:-latest}"
SAAS_VERSION="${2:-latest}"

# Step 1: Build and push images
echo "📦 Building Docker images..."
docker build -t ${IMAGE_REGISTRY}/api:${API_VERSION} -f docker/api/Dockerfile .
docker build -t ${IMAGE_REGISTRY}/core:${API_VERSION} -f docker/core/Dockerfile .
docker build -t ${IMAGE_REGISTRY}/saas:${SAAS_VERSION} -f docker/saas/Dockerfile .

echo "📤 Pushing images to registry..."
docker push ${IMAGE_REGISTRY}/api:${API_VERSION}
docker push ${IMAGE_REGISTRY}/core:${API_VERSION}
docker push ${IMAGE_REGISTRY}/saas:${SAAS_VERSION}

# Step 2: Apply Kubernetes manifests
echo "☸️  Applying Kubernetes configurations..."
kubectl apply -f kubernetes/namespaces.yaml
kubectl apply -f kubernetes/configmaps.yaml
kubectl apply -f kubernetes/secrets.yaml
kubectl apply -f kubernetes/deployments/
kubectl apply -f kubernetes/services/
kubectl apply -f kubernetes/ingress.yaml
kubectl apply -f kubernetes/hpa.yaml

# Step 3: Wait for rollout
echo "⏳ Waiting for deployments to roll out..."
kubectl rollout status deployment/tiannara-api -n ${NAMESPACE} --timeout=300s
kubectl rollout status deployment/tiannara-saas -n ${NAMESPACE} --timeout=300s

# Step 4: Verify deployment
echo "✅ Verifying deployment..."
kubectl get pods -n ${NAMESPACE}
kubectl get services -n ${NAMESPACE}
kubectl get ingress -n ${NAMESPACE}

echo "🎉 Deployment complete!"
echo "API: https://api.tiannara.com"
echo "SaaS: https://app.tiannara.com"
```

---

## 📊 **Monitoring Setup**

### **Prometheus Configuration**

```yaml
# monitoring/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'tiannara-api'
    static_configs:
      - targets: ['tiannara-api:8000']
    metrics_path: '/metrics'

  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
```

### **Grafana Dashboard JSON**

*(Create via Grafana UI or import from JSON)*

Key metrics to monitor:
- API request rate (req/s)
- API latency (p50, p95, p99)
- Error rate (%)
- Database connection pool usage
- Redis hit/miss ratio
- CPU/Memory utilization per pod
- Active WebSocket connections
- Queue depth (if using task queue)

---

## 🔒 **Security Checklist**

### **Pre-Deployment Security Audit:**

- [ ] All secrets stored in Kubernetes Secrets or Vault
- [ ] No hardcoded credentials in code/configs
- [ ] SSL/TLS certificates configured
- [ ] Rate limiting enabled on all endpoints
- [ ] CORS properly configured
- [ ] Input validation on all API endpoints
- [ ] SQL injection prevention (using ORM)
- [ ] XSS protection headers set
- [ ] Content Security Policy configured
- [ ] HSTS enabled
- [ ] Security headers (X-Frame-Options, X-Content-Type-Options)
- [ ] Container images scanned for vulnerabilities
- [ ] Network policies restrict pod-to-pod communication
- [ ] RBAC configured for Kubernetes access
- [ ] Audit logging enabled
- [ ] Fail2ban or similar for brute-force protection

---

## 📈 **Performance Benchmarks**

### **Target Metrics:**

| Metric | Target | Current |
|--------|--------|---------|
| API Latency (p95) | < 200ms | TBD |
| API Throughput | > 1000 req/s | TBD |
| Frontend Load Time | < 2s | TBD |
| Database Query Time | < 50ms | TBD |
| Cache Hit Ratio | > 90% | TBD |
| Uptime SLA | 99.9% | TBD |

### **Load Testing Plan:**

```bash
# Using k6 for load testing
k6 run scripts/load-test.js --vus 100 --duration 5m
```

---

## 🔄 **Rollback Strategy**

### **Blue-Green Deployment:**

1. Deploy new version to "green" environment
2. Run smoke tests against green
3. Switch traffic from blue → green (via Ingress)
4. Monitor for 10 minutes
5. If issues detected, switch back to blue
6. If stable, decommission blue

### **Rollback Commands:**

```bash
# Rollback API deployment
kubectl rollout undo deployment/tiannara-api -n tiannara-production

# Rollback to specific revision
kubectl rollout undo deployment/tiannara-api -n tiannara-production --to-revision=2

# Check rollout history
kubectl rollout history deployment/tiannara-api -n tiannara-production
```

---

## 📞 **Support & Maintenance**

### **On-Call Rotation:**
- Primary: DevOps Engineer
- Secondary: Backend Lead
- Tertiary: CTO

### **Escalation Path:**
1. Automated alerts → Slack #ops-alerts
2. No response in 15min → PagerDuty
3. Critical issue → Phone call to on-call engineer

### **Maintenance Windows:**
- Database migrations: Sundays 2-4 AM UTC
- Major upgrades: Monthly, announced 1 week prior
- Emergency patches: As needed, minimal downtime

---

## 📚 **Next Steps**

1. **Immediate (This Week):**
   - [ ] Create Dockerfiles for all services
   - [ ] Set up Docker Compose for local testing
   - [ ] Configure CI/CD pipeline (GitHub Actions)
   - [ ] Test container builds locally

2. **Short-Term (Next 2 Weeks):**
   - [ ] Set up Kubernetes cluster (EKS/GKE/AKS)
   - [ ] Configure monitoring stack (Prometheus + Grafana)
   - [ ] Implement SSL/TLS with Let's Encrypt
   - [ ] Run load tests and optimize performance

3. **Medium-Term (Next Month):**
   - [ ] Implement blue-green deployment
   - [ ] Set up disaster recovery procedures
   - [ ] Configure CDN for static assets
   - [ ] Complete security audit and penetration testing

4. **Long-Term (Quarter 2):**
   - [ ] Multi-region deployment
   - [ ] Auto-scaling optimization
   - [ ] Cost optimization (spot instances, reserved capacity)
   - [ ] Compliance certifications (SOC 2, ISO 27001)

---

**This deployment guide provides the foundation for production-ready Tiannara SaaS infrastructure. Follow the phases sequentially and validate each step before proceeding.** 🚀
