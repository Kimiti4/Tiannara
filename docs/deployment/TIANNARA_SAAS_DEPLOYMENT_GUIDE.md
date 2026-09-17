# Tiannara SaaS - Separate Deployment Guide

**Date**: May 1, 2026  
**Status**: 📋 **DEPLOYMENT GUIDE**  
**Architecture**: SaaS Frontend → API Gateway → Tiannara Core (separate services)

---

## 🎯 **Overview**

This guide explains how to deploy Tiannara SaaS (Next.js frontend) **separately** from Tiannara Core (FastAPI backend). This separation provides:

✅ **Independent scaling** - Frontend and backend scale separately  
✅ **Technology isolation** - Different tech stacks don't interfere  
✅ **Deployment flexibility** - Update frontend without touching backend  
✅ **Cost optimization** - Choose best hosting for each service  
✅ **Fault isolation** - Backend issues don't crash frontend  

---

## 🏗️ **Architecture**

```
┌─────────────────────────────────────────┐
│   Tiannara SaaS (Next.js Frontend)      │
│   Deployed on: Vercel / Netlify         │
│   URL: https://app.tiannara.com         │
└──────────────┬──────────────────────────┘
               │ HTTPS API Calls
               ▼
┌─────────────────────────────────────────┐
│   Tiannara API (FastAPI Backend)        │
│   Deployed on: Railway / Render / AWS   │
│   URL: https://api.tiannara.com         │
└──────────────┬──────────────────────────┘
               │ Internal Calls
               ▼
┌─────────────────────────────────────────┐
│   Tiannara Core (Python Engine)         │
│   Deployed with API or separately       │
│   Services: AI, Analytics, Moderation   │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│   Infrastructure Layer                  │
│   PostgreSQL + Redis + Storage          │
└─────────────────────────────────────────┘
```

---

## 📦 **What Gets Deployed Where**

### **Tiannara SaaS (Frontend)**
- **Technology**: Next.js 14+ (React)
- **Location**: `tiannara_saas/` directory
- **Deploy to**: Vercel (recommended) or Netlify
- **Contains**:
  - React components
  - Pages and routing
  - UI/UX logic
  - API client calls
  - Static assets

### **Tiannara API (Backend)**
- **Technology**: FastAPI (Python)
- **Location**: `tiannara_api/` directory
- **Deploy to**: Railway, Render, AWS, GCP
- **Contains**:
  - REST API endpoints
  - Authentication
  - Database operations
  - Business logic
  - Service integrations (Paystack, etc.)

### **Tiannara Core (AI Engine)**
- **Technology**: Python
- **Location**: `tiannara_core/` directory
- **Deploy to**: Same as API or separate workers
- **Contains**:
  - AI/ML models
  - Causal analysis
  - Moderation service
  - Recommendation engine
  - Autonomous systems

---

## 🚀 **Deployment Options**

### **Option 1: Vercel + Railway (Recommended for MVP)** ⭐

**Best for**: Quick deployment, low cost, easy setup

```
Frontend: Vercel (Free tier available)
Backend:  Railway ($5-20/month)
Database: Railway PostgreSQL or Neon (Free tier)
```

**Pros:**
- ✅ Easiest setup
- ✅ Automatic HTTPS
- ✅ Built-in CI/CD
- ✅ Free tiers available
- ✅ Great for startups

**Cons:**
- ⚠️ Limited customization
- ⚠️ Vendor lock-in
- ⚠️ Cold starts on free tier

---

### **Option 2: Vercel + AWS (Production)**

**Best for**: Scale, control, enterprise

```
Frontend: Vercel
Backend:  AWS ECS/EKS or Lambda
Database: AWS RDS PostgreSQL
Cache:    AWS ElastiCache (Redis)
Storage:  AWS S3
CDN:      CloudFront
```

**Pros:**
- ✅ Full control
- ✅ Unlimited scale
- ✅ Enterprise features
- ✅ Compliance ready

**Cons:**
- ❌ Complex setup
- ❌ Higher cost
- ❌ Requires DevOps expertise

---

### **Option 3: Self-Hosted (Maximum Control)**

**Best for**: Complete control, data sovereignty

```
Frontend: Nginx + Docker
Backend:  Docker Compose / Kubernetes
Database: Self-hosted PostgreSQL
All on:   VPS (Hetzner, DigitalOcean, Linode)
```

**Pros:**
- ✅ Complete control
- ✅ Lower long-term cost
- ✅ Data sovereignty
- ✅ No vendor lock-in

**Cons:**
- ❌ High maintenance
- ❌ Requires sysadmin skills
- ❌ You handle everything

---

## 📋 **Pre-Deployment Checklist**

### **For Tiannara SaaS (Frontend):**

- [ ] Environment variables configured (`.env.local`)
- [ ] API URL points to production backend
- [ ] Build succeeds locally (`npm run build`)
- [ ] No console errors in development
- [ ] All pages render correctly
- [ ] Authentication flow works
- [ ] API integration tested
- [ ] Responsive design verified
- [ ] SEO meta tags configured
- [ ] Favicon and branding set

### **For Tiannara API (Backend):**

- [ ] Database migrations ready
- [ ] Environment variables configured
- [ ] CORS configured for frontend domain
- [ ] Rate limiting enabled
- [ ] Authentication working
- [ ] All endpoints tested
- [ ] Error handling complete
- [ ] Logging configured
- [ ] Health check endpoint working
- [ ] Paystack/webhook URLs configured

---

## 🎯 **Deployment Method 1: Vercel + Railway**

### **Step 1: Deploy Backend to Railway**

#### **1.1 Prepare Backend**

Create `railway.json` in project root:

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "uvicorn tiannara_api.main:app --host 0.0.0.0 --port $PORT --workers 4",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

Create `Procfile`:

```
web: uvicorn tiannara_api.main:app --host 0.0.0.0 --port $PORT --workers 4
```

#### **1.2 Set Environment Variables in Railway**

In Railway dashboard, add these variables:

```env
# Database
DATABASE_URL=postgresql://user:pass@host:5432/tiannara

# Redis
REDIS_URL=redis://:password@host:6379

# JWT
JWT_SECRET_KEY=your-secret-key-here
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# CORS
CORS_ORIGINS=https://app.tiannara.com,https://tiannara-saas.vercel.app

# Paystack
PAYSTACK_PUBLIC_KEY=pk_live_xxxxx
PAYSTACK_SECRET_KEY=sk_live_xxxxx
PAYSTACK_WEBHOOK_SECRET=whsec_xxxxx

# OAuth
GOOGLE_CLIENT_ID=xxxxx
GOOGLE_CLIENT_SECRET=xxxxx

# Application
ENVIRONMENT=production
LOG_LEVEL=INFO
```

#### **1.3 Deploy to Railway**

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Link to your project
railway link

# Deploy
railway up
```

Or use GitHub integration:
1. Push code to GitHub
2. Connect Railway to repo
3. Auto-deploy on push

**Get your Railway URL**: `https://your-project.up.railway.app`

---

### **Step 2: Deploy Frontend to Vercel**

#### **2.1 Configure Environment Variables**

In `tiannara_saas/.env.local`:

```env
# Production API URL (from Railway)
NEXT_PUBLIC_API_URL=https://your-project.up.railway.app

# Or use custom domain
# NEXT_PUBLIC_API_URL=https://api.tiannara.com

# Analytics (optional)
NEXT_PUBLIC_GA_ID=G-xxxxx
```

#### **2.2 Update Next.js Config**

In `tiannara_saas/next.config.ts`:

```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // API rewrites (optional, for cleaner URLs)
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: `${process.env.NEXT_PUBLIC_API_URL}/api/:path*`,
      },
    ];
  },
  
  // Image optimization
  images: {
    domains: ['your-railway-domain.up.railway.app'],
  },
};

export default nextConfig;
```

#### **2.3 Deploy to Vercel**

**Option A: Vercel CLI**

```bash
# Install Vercel CLI
npm install -g vercel

# Navigate to SaaS directory
cd tiannara_saas

# Login
vercel login

# Deploy
vercel --prod
```

**Option B: GitHub Integration (Recommended)**

1. Push `tiannara_saas/` to GitHub
2. Go to [vercel.com](https://vercel.com)
3. Click "New Project"
5. Select your repository
6. Configure:
   - **Root Directory**: `tiannara_saas`
   - **Framework**: Next.js (auto-detected)
   - **Build Command**: `npm run build`
   - **Output Directory**: `.next`
7. Add environment variables:
   ```
   NEXT_PUBLIC_API_URL=https://your-project.up.railway.app
   ```
8. Click "Deploy"

**Get your Vercel URL**: `https://tiannara-saas.vercel.app`

---

### **Step 3: Configure Custom Domains (Optional)**

#### **3.1 Backend Domain (Railway)**

1. In Railway dashboard → Settings → Domains
2. Add domain: `api.tiannara.com`
3. Update DNS:
   ```
   Type: CNAME
   Name: api
   Value: your-project.up.railway.app
   ```

#### **3.2 Frontend Domain (Vercel)**

1. In Vercel dashboard → Settings → Domains
2. Add domain: `app.tiannara.com`
3. Update DNS:
   ```
   Type: CNAME
   Name: app
   Value: cname.vercel-dns.com
   ```

#### **3.3 Update CORS**

In Railway environment variables, update:
```env
CORS_ORIGINS=https://app.tiannara.com
```

---

### **Step 4: Test Deployment**

#### **4.1 Verify Backend**

```bash
# Health check
curl https://api.tiannara.com/api/v1/health

# Expected response:
# {"status":"healthy","version":"1.3.0"}
```

#### **4.2 Verify Frontend**

Visit: `https://app.tiannara.com`

Check:
- ✅ Homepage loads
- ✅ Login works
- ✅ API calls succeed
- ✅ No CORS errors in console
- ✅ Authentication persists

#### **4.3 Test API Integration**

Open browser console on frontend and test:

```javascript
// Test API connection
fetch('https://api.tiannara.com/api/v1/health')
  .then(r => r.json())
  .then(data => console.log('API Status:', data));
```

---

## 🎯 **Deployment Method 2: Docker + VPS**

### **Step 1: Create Dockerfiles**

#### **Frontend Dockerfile** (`tiannara_saas/Dockerfile`)

```dockerfile
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci

# Copy source
COPY . .

# Build
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets
COPY --from=builder /app/out /usr/share/nginx/html

EXPOSE 3000

CMD ["nginx", "-g", "daemon off;"]
```

#### **Backend Dockerfile** (already exists at `docker/api/Dockerfile`)

---

### **Step 2: Create docker-compose.yml**

```yaml
version: '3.8'

services:
  # Frontend
  tiannara-saas:
    build:
      context: ./tiannara_saas
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://tiannara-api:8000
    depends_on:
      - tiannara-api
    networks:
      - tiannara-network

  # Backend
  tiannara-api:
    build:
      context: .
      dockerfile: docker/api/Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:pass@postgres:5432/tiannara
      - REDIS_URL=redis://redis:6379
      - CORS_ORIGINS=http://localhost:3000
    depends_on:
      - postgres
      - redis
    networks:
      - tiannara-network

  # Database
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: tiannara
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - tiannara-network

  # Cache
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    networks:
      - tiannara-network

volumes:
  postgres_data:
  redis_data:

networks:
  tiannara-network:
    driver: bridge
```

---

### **Step 3: Deploy to VPS**

```bash
# SSH into VPS
ssh user@your-vps-ip

# Clone repository
git clone https://github.com/yourusername/Tiannara-MindCache-Prosthetic.git
cd Tiannara-MindCache-Prosthetic

# Build and start
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

---

## 🔧 **Environment Configuration**

### **Frontend (.env.local)**

```env
# API Configuration
NEXT_PUBLIC_API_URL=https://api.tiannara.com

# Feature Flags
NEXT_PUBLIC_ENABLE_MODERATION=true
NEXT_PUBLIC_ENABLE_ANALYTICS=true

# Analytics
NEXT_PUBLIC_GA_ID=G-xxxxx

# Branding
NEXT_PUBLIC_APP_NAME=Tiannara
NEXT_PUBLIC_SUPPORT_EMAIL=support@tiannara.com
```

### **Backend (.env.production)**

```env
# Database
DATABASE_URL=postgresql://user:pass@host:5432/tiannara

# Redis
REDIS_URL=redis://:password@host:6379

# JWT
JWT_SECRET_KEY=generate-secure-random-string
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS
CORS_ORIGINS=https://app.tiannara.com

# Paystack
PAYSTACK_PUBLIC_KEY=pk_live_xxxxx
PAYSTACK_SECRET_KEY=sk_live_xxxxx
PAYSTACK_WEBHOOK_SECRET=whsec_xxxxx
PAYSTACK_STARTER_PLAN=PLN_xxxxx
PAYSTACK_PROFESSIONAL_PLAN=PLN_xxxxx

# OAuth
GOOGLE_CLIENT_ID=xxxxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=xxxxx

# Email
RESEND_API_KEY=re_xxxxx
EMAIL_FROM=noreply@tiannara.com

# Application
ENVIRONMENT=production
LOG_LEVEL=INFO
RATE_LIMIT_PER_MINUTE=600
```

---

## 🚨 **Common Issues & Solutions**

### **Issue 1: CORS Errors**

**Symptom**: Frontend can't reach backend

**Solution**:
```python
# In tiannara_api/main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://app.tiannara.com",
        "https://tiannara-saas.vercel.app",
        "http://localhost:3000"  # Development
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

### **Issue 2: API URL Mismatch**

**Symptom**: Frontend tries to call wrong API URL

**Solution**:
```env
# In tiannara_saas/.env.local
NEXT_PUBLIC_API_URL=https://api.tiannara.com

# Rebuild frontend
npm run build
```

---

### **Issue 3: Database Connection Fails**

**Symptom**: Backend crashes on startup

**Solution**:
```bash
# Check DATABASE_URL format
echo $DATABASE_URL
# Should be: postgresql://user:pass@host:5432/dbname

# Test connection
psql $DATABASE_URL -c "SELECT 1;"
```

---

### **Issue 4: Build Fails on Vercel**

**Symptom**: Vercel deployment fails

**Solution**:
```bash
# Test build locally first
cd tiannara_saas
npm run build

# Fix any errors
# Then commit and push
git add .
git commit -m "Fix build errors"
git push
```

---

## 📊 **Monitoring Setup**

### **Frontend Monitoring (Vercel)**

Vercel provides:
- ✅ Real-time analytics
- ✅ Performance metrics
- ✅ Error tracking
- ✅ Deployment previews

View at: `https://vercel.com/dashboard`

---

### **Backend Monitoring (Railway)**

Railway provides:
- ✅ Logs viewer
- ✅ Resource usage
- ✅ Uptime monitoring
- ✅ Crash alerts

View at: `https://railway.app/dashboard`

---

### **Custom Monitoring (Optional)**

Add to backend:

```python
# tiannara_api/metrics/prometheus.py
from prometheus_client import Counter, Histogram

REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests')
REQUEST_LATENCY = Histogram('http_request_duration_seconds', 'Request latency')
```

---

## 🔄 **CI/CD Pipeline**

### **Automatic Deployments**

**Frontend (Vercel)**:
- Push to `main` → Auto-deploy to production
- Pull request → Deploy to preview URL
- Rollback: One-click in dashboard

**Backend (Railway)**:
- Push to `main` → Auto-deploy
- Manual trigger option
- Rollback: Previous deployment

---

### **GitHub Actions (Optional)**

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy Tiannara

on:
  push:
    branches: [main]

jobs:
  deploy-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to Railway
        uses: railwayapp/cli@v1
        with:
          railwayToken: ${{ secrets.RAILWAY_TOKEN }}
        run: railway up --service backend

  deploy-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.ORG_ID }}
          vercel-project-id: ${{ secrets.PROJECT_ID }}
          working-directory: ./tiannara_saas
```

---

## 💰 **Cost Estimation**

### **Vercel + Railway (MVP)**

| Service | Plan | Cost/Month |
|---------|------|------------|
| Vercel (Frontend) | Hobby | $0 |
| Railway (Backend) | Starter | $5-20 |
| Railway (PostgreSQL) | Starter | $5-10 |
| Railway (Redis) | Starter | $5 |
| **Total** | | **$15-35/month** |

---

### **AWS (Production)**

| Service | Cost/Month |
|---------|------------|
| Vercel (Frontend) | $0-20 |
| AWS ECS (Backend) | $50-200 |
| AWS RDS (PostgreSQL) | $50-150 |
| AWS ElastiCache (Redis) | $20-50 |
| AWS S3 (Storage) | $5-20 |
| CloudFront (CDN) | $5-20 |
| **Total** | **$130-460/month** |

---

## 🎯 **Deployment Checklist**

### **Pre-Launch:**

- [ ] Backend deployed and healthy
- [ ] Frontend deployed and accessible
- [ ] Custom domains configured
- [ ] SSL certificates active
- [ ] CORS configured correctly
- [ ] Environment variables set
- [ ] Database migrations run
- [ ] Paystack webhooks configured
- [ ] OAuth providers configured
- [ ] Email service working
- [ ] Health checks passing
- [ ] Error monitoring setup
- [ ] Backup strategy in place

### **Post-Launch:**

- [ ] Monitor error rates
- [ ] Track API performance
- [ ] Watch database connections
- [ ] Check user feedback
- [ ] Review security logs
- [ ] Optimize slow queries
- [ ] Update documentation

---

## 📞 **Support Resources**

### **Vercel:**
- Docs: https://vercel.com/docs
- Support: https://vercel.com/support

### **Railway:**
- Docs: https://docs.railway.app
- Discord: https://discord.gg/railway

### **Tiannara:**
- API Docs: https://api.tiannara.com/docs
- Issues: GitHub repository

---

## 🚀 **Quick Start Commands**

### **Deploy Backend:**
```bash
cd Tiannara-MindCache-Prosthetic
railway up
```

### **Deploy Frontend:**
```bash
cd tiannara_saas
vercel --prod
```

### **Check Status:**
```bash
# Backend
curl https://api.tiannara.com/api/v1/health

# Frontend
curl https://app.tiannara.com
```

---

**Status**: ✅ **Guide Complete** | 🚀 **Ready to Deploy**

**Estimated Deployment Time**: 30-60 minutes (first time), 5 minutes (updates)
