# Tiannara SaaS Repository Separation Guide

**Date**: May 1, 2026  
**Status**: ✅ **IMPLEMENTED**  
**Goal**: Separate Tiannara SaaS from Core for independent deployment

---

## ��� **Architecture Overview**

Tiannara SaaS and Tiannara Core are now **completely separated** with API-based communication:

```
┌─────────────────────┐    HTTP/API Calls     ┌──────────────────────┐
│   Tiannara SaaS     │ ◀──────────────────▶  │   Tiannara Core      │
│                     │                       │                      │
│ • Next.js Frontend  │                       │ • Reasoning Engine   │
│ • FastAPI Backend   │                       │ • Domain Modules     │
│ • Payment/Billing   │                       │ • AI Features        │
│ • User Auth         │                       │ • Evolution System   │
│ • Core Proxy Layer  │──→ Proxies to Core   │ • Internal APIs      │
└─────────────────────┘                       └──────────────────────┘
     Deploy to:                                      Deploy to:
  Vercel + Railway                              Separate Server/VPS
  (Public-facing)                            (Private/Internal API)
```

---

## ✅ **What's Been Implemented**

### **1. Core Proxy Layer** ⭐ NEW

Created `tiannara_api/routes/core_proxy.py` that acts as a bridge between SaaS and Core:

**Endpoints Added:**
- `POST /api/v1/core/reason` - Submit reasoning tasks
- `GET /api/v1/core/domains` - List available domain engines
- `POST /api/v1/core/predict` - Get ML predictions
- `POST /api/v1/core/evolve` - Trigger evolution processes
- `POST /api/v1/core/skill-transfer` - Cross-domain skill transfer
- `GET /api/v1/core/status` - Health check for Core service

**Features:**
- ✅ Async HTTP client for efficient Core communication
- ✅ API key authentication support
- ✅ Error handling and timeout management
- ✅ Health check endpoint
- ✅ Comprehensive documentation

### **2. Updated Main Application**

Modified `tiannara_api/main.py`:
- ✅ Imported `core_proxy_router`
- ✅ Registered router at `/api/v1/core/*`
- ✅ Ready to proxy requests to Core

### **3. Environment Configuration**

Updated `.env.template`:
```bash
# Core API Configuration
CORE_API_URL=http://localhost:8001
CORE_API_KEY=your-core-api-key  # Optional
```

---

## ��� **Repository Structure After Separation**

### **Repository 1: Tiannara-SaaS** (https://github.com/Kimiti4/Tiannara-SaaS)

```
Tiannara-SaaS/
├── backend/
│   └── tiannara_api/
│       ├── routes/
│       │   ├── auth.py              # User authentication
│       │   ├── payment.py           # Payment processing
│       │   ├── users.py             # User management
│       │   ├── core_proxy.py        # ← NEW: Core API proxy
│       │   └── ...                  # Other SaaS routes
│       ├── database/                # Database models
│       ├── main.py                  # FastAPI entry point
│       ├── payment.py               # Payment processor
│       └── schemas.py               # Pydantic models
│
├── frontend/
│   └── tiannara_gui/ OR tiannara_saas/
│       ├── app/                     # Next.js pages
│       ├── components/              # React components
│       ├── lib/                     # Utilities & API clients
│       └── package.json
│
├── docs/deployment/                 # Deployment guides
├── .env.template                    # Environment config
├── Procfile                         # Railway deployment
├── runtime.txt                      # Python version
├── requirements.txt                 # Python dependencies
├── DEPLOY_NOW.md
├── DEPLOYMENT_CHECKLIST.md
└── README.md
```

**Dependencies:**
- FastAPI, Uvicorn
- Stripe, Lemon Squeezy SDKs
- PostgreSQL adapter
- HTTPX (for Core API calls)
- Authentication libraries

**Does NOT Include:**
- ❌ tiannara_core/ (entire directory)
- ❌ PyTorch/TensorFlow
- ❌ Core AI implementation
- ❌ Domain engine code
- ❌ Evolution algorithms

---

### **Repository 2: Tiannara-Core** (Separate, Private)

```
Tiannara-Core/
├── tiannara_core/
│   ├── reasoning/                   # Reasoning engine
│   ├── domains/                     # Domain modules
│   ├── evolution/                   # Evolution system
│   ├── memory/                      # Memory systems
│   ├── api/                         # REST API for SaaS
│   └── main.py                      # Runs on port 8001
│
├── tests/                           # Core test suites
├── benchmarks/                      # Performance tests
└── requirements.txt                 # Core dependencies
```

**Dependencies:**
- PyTorch/TensorFlow
- NumPy, SciPy
- Domain-specific libraries
- Research/experimental packages

**Does NOT Include:**
- ❌ Payment processing
- ❌ User authentication
- ❌ Subscription management
- ❌ Frontend code

---

## ��� **How Communication Works**

### **Request Flow**

```
User Browser
    ↓
SaaS Frontend (Next.js on Vercel)
    ↓ HTTP POST /api/v1/core/reason
SaaS Backend (FastAPI on Railway)
    ↓ HTTP POST /api/v1/reason (proxy)
Core API (on separate server)
    ↓ Processing
Core AI Engine
    ↓ Returns results
Back through the chain to user
```

### **Example: Reasoning Task**

**Frontend Code:**
```typescript
// frontend/lib/api.ts
const response = await fetch('/api/v1/core/reason', {
  method: 'POST',
  body: JSON.stringify({
    query: "What is the optimal strategy?",
    domain: "strategic_planning"
  })
});
const result = await response.json();
```

**SaaS Backend (Proxy):**
```python
# tiannara_api/routes/core_proxy.py
@router.post("/reason")
async def submit_reasoning_task(task: dict):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{CORE_API_URL}/api/v1/reason",
            json=task
        )
        return response.json()
```

**Core API:**
```python
# tiannara_core/api/main.py (separate repo)
@app.post("/api/v1/reason")
def reason(task: dict):
    # Actual AI processing happens here
    result = reasoning_engine.process(task)
    return result
```

---

## ��� **Deployment Architecture**

### **Local Development**

```bash
# Terminal 1: Start Core
cd Tiannara-Core
uvicorn tiannara_core.main:app --port 8001

# Terminal 2: Start SaaS Backend
cd Tiannara-SaaS/backend
uvicorn tiannara_api.main:app --port 8000

# Terminal 3: Start SaaS Frontend
cd Tiannara-SaaS/frontend
npm run dev
```

### **Production Deployment**

**SaaS (Public):**
- Frontend: Vercel (https://tiannara-saas.vercel.app)
- Backend: Railway (https://tiannara-backend.railway.app)
- Database: Railway PostgreSQL

**Core (Private):**
- Core API: Private VPS or internal network
- URL: https://core.tiannara.internal:8001
- Not exposed to public internet
- Protected by API key authentication

**Environment Variables:**

SaaS Backend (.env on Railway):
```bash
CORE_API_URL=https://core.tiannara.internal:8001
CORE_API_KEY=secret-api-key-here
```

---

## ��� **Files to Include in SaaS Repository**

### **Copy These Files:**

```bash
# From current project root
cd c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic

# 1. Backend (with core_proxy.py included)
xcopy /E /I tiannara_api\ Tiannara-SaaS\backend\tiannara_api\

# 2. Frontend
xcopy /E /I tiannara_gui\ Tiannara-SaaS\frontend\
# OR
xcopy /E /I tiannara_saas\ Tiannara-SaaS\frontend\

# 3. Configuration files
copy Procfile Tiannara-SaaS\
copy runtime.txt Tiannara-SaaS\
copy requirements.txt Tiannara-SaaS\
copy .env.template Tiannara-SaaS\
copy .gitignore Tiannara-SaaS\

# 4. Documentation
xcopy /E /I docs\ Tiannara-SaaS\docs\
copy DEPLOY_NOW.md Tiannara-SaaS\
copy DEPLOYMENT_CHECKLIST.md Tiannara-SaaS\
copy README.md Tiannara-SaaS\
copy SAAS_REPOSITORY_SEPARATION.md Tiannara-SaaS\
```

### **DO NOT Copy:**

```
❌ tiannara_core/              # Core AI engine
❌ tiannara_pros/              # Prosthetic modules
❌ rust_core/                  # Rust components
❌ mindcache/                  # MindCache core
❌ tests/                      # Core test suites
❌ archive/, runs/, checkpoints/  # Experiment data
❌ *.json experiment results
❌ *.jsonl training data
```

---

## ��� **Post-Separation Setup**

### **1. Create SaaS-Specific .gitignore**

In `Tiannara-SaaS/.gitignore`:

```gitignore
# Dependencies
node_modules/
__pycache__/
*.pyc

# Environment files
.env
.env.local
.env.production

# Build outputs
.next/
dist/

# Logs
logs/
*.log

# Database
*.db
*.sqlite
```

### **2. Update Frontend API Client**

Create `frontend/lib/coreApi.ts`:

```typescript
const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export const coreApi = {
  reason: (task: any) =>
    fetch(`${API_BASE}/api/v1/core/reason`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(task),
    }).then(r => r.json()),

  domains: () =>
    fetch(`${API_BASE}/api/v1/core/domains`)
      .then(r => r.json()),

  predict: (data: any) =>
    fetch(`${API_BASE}/api/v1/core/predict`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    }).then(r => r.json()),

  status: () =>
    fetch(`${API_BASE}/api/v1/core/status`)
      .then(r => r.json()),
};
```

### **3. Initialize Git Repository**

```bash
cd Tiannara-SaaS

git init
git remote add origin https://github.com/Kimiti4/Tiannara-SaaS.git

git add .
git commit -m "Initial commit: Tiannara SaaS with Core proxy layer

- Next.js frontend with authentication
- FastAPI backend with payment integration
- Core AI proxy layer for API-based Core communication
- Multi-provider payment (Lemon Squeezy + Stripe)
- PostgreSQL database
- Complete deployment documentation"

git branch -M main
git push -u origin main
```

---

## ✅ **Verification Checklist**

After separation, verify:

- [ ] Only SaaS files in new repository
- [ ] No Core AI implementation code included
- [ ] `core_proxy.py` exists in `tiannara_api/routes/`
- [ ] Backend starts: `uvicorn tiannara_api.main:app`
- [ ] Core proxy endpoints accessible: `/api/v1/core/status`
- [ ] Frontend builds: `npm run build`
- [ ] Environment variables configured
- [ ] CORE_API_URL set correctly
- [ ] All imports resolve (no tiannara_core imports)
- [ ] Repository pushes to GitHub successfully
- [ ] Can deploy to Railway/Vercel

---

## ��� **Benefits of This Architecture**

✅ **Clean Separation** - SaaS and Core completely independent  
✅ **API-Based Communication** - No code dependencies  
✅ **Independent Scaling** - Scale SaaS and Core separately  
✅ **Better Security** - Core can be private/internal  
✅ **Easier Maintenance** - Update one without affecting other  
✅ **Faster CI/CD** - Smaller repositories  
✅ **IP Protection** - Core AI kept in private repo  
✅ **Flexible Deployment** - Different hosting for each  

---

## ��� **Support Resources**

- **Deployment Guide**: [docs/deployment/DEPLOYMENT_QUICK_START.md](docs/deployment/DEPLOYMENT_QUICK_START.md)
- **Payment Integration**: [docs/deployment/COMPLETE_PAYMENT_INTEGRATION.md](docs/deployment/COMPLETE_PAYMENT_INTEGRATION.md)
- **Core Proxy Code**: [tiannara_api/routes/core_proxy.py](tiannara_api/routes/core_proxy.py)

---

## ��� **Next Steps**

1. ✅ Core proxy implemented
2. ✅ Main.py updated
3. ✅ Environment config updated
4. → Create Tiannara-SaaS directory
5. → Copy SaaS files only
6. → Initialize Git repository
7. → Push to GitHub
8. → Deploy to Railway + Vercel
9. → Deploy Core separately
10. → Test end-to-end communication

---

**The separation is ready! You can now create the Tiannara-SaaS repository with clean separation from Core.** ���
