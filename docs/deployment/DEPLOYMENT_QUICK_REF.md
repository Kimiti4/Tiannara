# Production Deployment - Quick Reference

**Date**: May 1, 2026  
**Status**: ✅ **Ready for Deployment**

---

## 🎯 **Deployment Overview**

Tiannara SaaS is ready for production deployment with the following architecture:

```
                Tiannara SaaS (Next.js Frontend)
                         ↑
                  Nginx Reverse Proxy (SSL/TLS)
                         ↑
              FastAPI Backend (API Gateway)
                         ↑
            Tiannara Core (Cognition Engine)
                         ↑
         PostgreSQL + Redis (Infrastructure)
```

---

## 📋 **Deployment Phases**

### **✅ Phase 1: Infrastructure Foundation (COMPLETE)**
- Docker containerization for all services
- Docker Compose for local development
- Kubernetes manifests documented
- Environment configuration templates
- Paystack payment integration configured

### **⏳ Phase 2: CI/CD Pipeline (NEXT)**
- GitHub Actions workflow
- Automated testing
- Container image building
- Automated deployment to staging

### **⏳ Phase 3: Monitoring & Observability**
- Prometheus metrics
- Grafana dashboards
- Alert configuration
- Logging setup

---

## 🔧 **Quick Start Commands**

### **Local Development:**

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f tiannara-api

# Stop services
docker-compose down
```

### **Production Deployment:**

```bash
# Build images
./deploy.sh v1.0.0 v1.0.0

# Apply Kubernetes configs
kubectl apply -f kubernetes/

# Verify deployment
kubectl get pods -n tiannara-production
```

---

## 🔐 **Required Secrets**

Create these before deployment:

```bash
# Database
POSTGRES_PASSWORD=<strong-password>
REDIS_PASSWORD=<strong-password>

# Authentication
JWT_SECRET_KEY=<64-char-random-string>

# OAuth SSO
GOOGLE_CLIENT_ID=<id>
GOOGLE_CLIENT_SECRET=<secret>

# Paystack (Payment Gateway)
PAYSTACK_PUBLIC_KEY=pk_live_xxxxx
PAYSTACK_SECRET_KEY=sk_live_xxxxx
PAYSTACK_WEBHOOK_SECRET=whsec_xxxxx
PAYSTACK_STARTER_PLAN=PLN_xxxxx
PAYSTACK_PROFESSIONAL_PLAN=PLN_xxxxx

# Email
RESEND_API_KEY=<key>

# AI Providers
OPENAI_API_KEY=<key>
```

---

## 🌐 **Domain Configuration**

Configure DNS records:

| Domain | Points To | Purpose |
|--------|-----------|---------|
| `api.tiannara.com` | Load Balancer IP | API Gateway |
| `app.tiannara.com` | Load Balancer IP | SaaS Frontend |
| `*.tiannara.com` | Load Balancer IP | Wildcard (optional) |

---

## 📊 **Health Check Endpoints**

Verify deployment health:

```bash
# API Health
curl https://api.tiannara.com/api/v1/health

# Expected Response:
# {"status": "healthy", "timestamp": "..."}
```

---

## 🚨 **Common Issues**

### **1. Database Connection Failed**

**Check**:
```bash
kubectl logs -n tiannara-production deployment/tiannara-api | grep database
```

**Fix**: Verify DATABASE_URL in secrets

### **2. Webhook Not Working**

**Check**:
```bash
# Test webhook endpoint
curl -X POST https://api.tiannara.com/api/v1/billing/webhook \
  -H "Content-Type: application/json" \
  -d '{"test": true}'
```

**Fix**: Verify PAYSTACK_WEBHOOK_SECRET and Nginx config

### **3. SSL Certificate Issues**

**Check**:
```bash
openssl s_client -connect api.tiannara.com:443
```

**Fix**: Renew Let's Encrypt certificate

---

## 📈 **Monitoring URLs**

Once deployed:

- **Grafana**: https://grafana.tiannara.com
- **Prometheus**: https://prometheus.tiannara.com
- **Kibana Logs**: https://logs.tiannara.com
- **Paystack Dashboard**: https://dashboard.paystack.com

---

## 🔄 **Rollback Commands**

If deployment fails:

```bash
# Rollback API
kubectl rollout undo deployment/tiannara-api -n tiannara-production

# Rollback to specific version
kubectl set image deployment/tiannara-api \
  api=tiannara/api:v0.9.0 -n tiannara-production
```

---

## 📞 **Support Contacts**

- **DevOps**: #ops-alerts (Slack)
- **Backend**: #backend-team (Slack)
- **Emergency**: PagerDuty rotation
- **Paystack Support**: support@paystack.com

---

## 📚 **Documentation Links**

- **Full Deployment Guide**: [`PRODUCTION_DEPLOYMENT_GUIDE.md`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/PRODUCTION_DEPLOYMENT_GUIDE.md)
- **Paystack Integration**: [`DEPLOYMENT_PAYSTACK_UPDATE.md`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/DEPLOYMENT_PAYSTACK_UPDATE.md)
- **Setup Guide**: [`PAYSTACK_SETUP_NOW.md`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/PAYSTACK_SETUP_NOW.md)
- **Complete Roadmap**: [`COMPLETE_ROADMAP_2026.md`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/COMPLETE_ROADMAP_2026.md)

---

**Status**: ✅ **Infrastructure Ready** | ⏳ **Awaiting CI/CD Setup**
