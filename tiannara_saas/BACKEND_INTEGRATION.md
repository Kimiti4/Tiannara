# Tiannara SaaS Backend Integration Guide

## Overview

This document outlines the backend integration between the **Tiannara SaaS frontend** (`tiannara_saas/`) and the **Tiannara API backend** (`tiannara_api/`).

---

## Architecture

```
┌─────────────────────┐
│  Tiannara SaaS      │  Next.js Frontend (Port 3001)
│  (tiannara_saas/)   │  - Dashboard pages
│                     │  - Authentication UI
│                     │  - Payment flows
└──────────┬──────────┘
           │ HTTP/REST + JWT
           │
┌──────────▼──────────┐
│  Tiannara API       │  FastAPI Backend (Port 8000)
│  (tiannara_api/)    │  - Auth endpoints
│                     │  - API key management
│                     │  - Usage tracking
│                     │  - Payment processing
└──────────┬──────────┘
           │ Internal calls
           │
┌──────────▼──────────┐
│  Tiannara Core      │  Python Intelligence Layer
│  (tiannara_core/)   │  - Domain engines
│                     │  - Orchestration
│                     │  - Evolution systems
└─────────────────────┘
```

---

## ✅ Completed Integration Components

### 1. **API Client Library** (`tiannara_saas/lib/api.ts`)

Centralized HTTP client with:
- ✅ JWT token management
- ✅ Automatic authentication headers
- ✅ Error handling
- ✅ Type-safe request/response interfaces
- ✅ Singleton pattern for consistent state

**Key Methods:**
```typescript
// Authentication
apiClient.login(email, password)
apiClient.signup(name, email, password)
apiClient.getProfile()
apiClient.updateProfile(data)

// API Keys
apiClient.getApiKeys()
apiClient.createApiKey(name)
apiClient.revokeApiKey(keyId)

// Usage Analytics
apiClient.getUsageMetrics(timeRange)
apiClient.getActivityLogs(limit)

// Billing
apiClient.getSubscription()
apiClient.getPaymentHistory()
apiClient.createCheckoutSession(plan, successUrl, cancelUrl)
apiClient.getPricingPlans()

// Domain Engines
apiClient.getDomainEngines()
apiClient.testEngine(engine, payload)
```

### 2. **Authentication Context** (`tiannara_saas/contexts/AuthContext.tsx`)

React context provider for:
- ✅ Session persistence (localStorage)
- ✅ Auto-login on page refresh
- ✅ Global auth state
- ✅ Login/signup/logout functions
- ✅ Profile refresh capability

**Usage:**
```tsx
import { useAuth } from '@/contexts/AuthContext'

function MyComponent() {
  const { user, login, logout, isAuthenticated } = useAuth()
  
  if (!isAuthenticated) return <LoginPrompt />
  
  return <div>Welcome, {user?.name}</div>
}
```

### 3. **Environment Configuration**

Created `.env.local` with:
```env
NEXT_PUBLIC_API_BASE_URL=http://localhost:8000/api/v1
NEXT_PUBLIC_FLUTTERWAVE_PUBLIC_KEY=FLWPUBK_TEST-SANDBOXDEMO-X
JWT_SECRET=your-secret-key
```

---

## 🔧 Backend Endpoints Required

The following endpoints need to be implemented in `tiannara_api/`:

### **Authentication Routes** (`/api/v1/auth/*`)

```python
# POST /api/v1/auth/register
# Register new user
Request: { name: str, email: str, password: str }
Response: { token: str, user: UserProfile }

# POST /api/v1/auth/login
# Authenticate user
Request: { email: str, password: str }
Response: { token: str, user: UserProfile }

# GET /api/v1/auth/me
# Get current user profile
Headers: Authorization: Bearer <token>
Response: UserProfile

# PUT /api/v1/auth/profile
# Update user profile
Headers: Authorization: Bearer <token>
Request: { name?: str, email?: str, company?: str, role?: str }
Response: UserProfile
```

**Implementation Notes:**
- Use `passlib` for password hashing
- Generate JWT tokens with `python-jose`
- Store users in PostgreSQL `users` table
- Token expiration: 24 hours

---

### **API Key Routes** (`/api/v1/keys/*`)

```python
# GET /api/v1/keys
# List all API keys for authenticated user
Headers: Authorization: Bearer <token>
Response: [ApiKey]

# POST /api/v1/keys
# Create new API key
Headers: Authorization: Bearer <token>
Request: { name: str }
Response: ApiKey

# DELETE /api/v1/keys/{key_id}
# Revoke API key (soft delete)
Headers: Authorization: Bearer <token>
Response: { success: bool }
```

**Implementation Notes:**
- Generate secure random keys (e.g., `tk_live_` prefix)
- Store hashed keys in `api_keys` table
- Track usage per key in `request_logs` table
- Soft delete sets `status='revoked'` instead of removing

---

### **Usage & Analytics Routes** (`/api/v1/usage/*`)

```python
# GET /api/v1/usage/metrics?range=7d|30d|90d
# Get usage metrics for time range
Headers: Authorization: Bearer <token>
Response: UsageMetrics

# GET /api/v1/usage/activity?limit=10
# Get recent API activity logs
Headers: Authorization: Bearer <token>
Response: [ActivityLog]
```

**Implementation Notes:**
- Query `request_logs` table filtered by user's API keys
- Calculate success rate, avg latency, error count
- Group by day for chart data
- Aggregate domain engine usage breakdown

---

### **Billing Routes** (`/api/v1/billing/*`)

```python
# GET /api/v1/billing/subscription
# Get current subscription details
Headers: Authorization: Bearer <token>
Response: Subscription

# GET /api/v1/billing/payments
# Get payment history
Headers: Authorization: Bearer <token>
Response: [PaymentHistory]
```

**Implementation Notes:**
- Link subscriptions to users via `user_id` foreign key
- Store subscription status, period dates, plan tier
- Payment history from `payments` table or Stripe/Flutterwave webhooks

---

### **Payment Routes** (Already Partially Implemented)

You have existing routes at `/api/v1/payment/*`:
- ✅ `GET /payment/plans` - List pricing plans
- ✅ `POST /payment/subscribe` - Create checkout session
- ⚠️ Currently uses Stripe - needs Flutterwave adaptation

**Required Updates:**
1. Add Flutterwave SDK integration
2. Implement Flutterwave webhook handler
3. Update subscription creation to use Flutterwave
4. Map Flutterwave payment events to database updates

---

### **Domain Engine Routes** (`/api/v1/engines/*`)

```python
# GET /api/v1/engines
# List available engines for user's tier
Headers: Authorization: Bearer <token>
Response: [DomainEngine]

# POST /api/v1/engines/{engine_name}/test
# Test engine with sample payload
Headers: Authorization: Bearer <token>
Request: { input: any }
Response: { result: any, latency_ms: number }
```

**Implementation Notes:**
- Filter engines based on user's subscription tier
- Connect to existing domain engine implementations in `tiannara_core/`
- Track test requests in usage logs

---

## 📊 Database Schema Requirements

Ensure these tables exist in PostgreSQL:

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    company VARCHAR(255),
    role VARCHAR(100),
    tier VARCHAR(50) DEFAULT 'starter',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- API Keys table
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    key_hash VARCHAR(255) NOT NULL,
    key_prefix VARCHAR(20), -- For display (first 8 chars)
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW(),
    last_used_at TIMESTAMP
);

-- Request Logs table
CREATE TABLE request_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    api_key_id UUID REFERENCES api_keys(id) ON DELETE CASCADE,
    endpoint VARCHAR(255),
    method VARCHAR(10),
    status_code INTEGER,
    latency_ms INTEGER,
    domain_engine VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Subscriptions table
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    plan VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    amount INTEGER, -- In cents
    currency VARCHAR(10) DEFAULT 'USD',
    current_period_start TIMESTAMP,
    current_period_end TIMESTAMP,
    flutterwave_subscription_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Payments table
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES subscriptions(id),
    amount INTEGER NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    status VARCHAR(20) DEFAULT 'pending',
    invoice_number VARCHAR(100),
    flutterwave_transaction_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🔐 Security Considerations

### JWT Token Structure
```python
{
  "sub": "user_id",
  "email": "user@example.com",
  "tier": "starter",
  "exp": 1234567890,  # Expiration timestamp
  "iat": 1234567890   # Issued at
}
```

### API Key Format
```
tk_live_abc123def456ghi789jkl012mno345pqr
^^^ ^^^^ ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
|   |    |
|   |    Random key (32+ chars)
|   Environment (live/test)
Prefix (token type)
```

### Password Hashing
```python
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
hashed = pwd_context.hash(password)
verified = pwd_context.verify(password, hashed)
```

---

## 🚀 Deployment Checklist

### Backend (FastAPI)
- [ ] Set up PostgreSQL database
- [ ] Run schema migrations
- [ ] Configure environment variables:
  ```env
  DATABASE_URL=postgresql://user:pass@localhost:5432/tiannara
  JWT_SECRET=your-production-secret
  FLUTTERWAVE_PUBLIC_KEY=pk_live_...
  FLUTTERWAVE_SECRET_KEY=sk_live_...
  ```
- [ ] Implement all required endpoints (see above)
- [ ] Set up CORS for frontend domain
- [ ] Configure rate limiting
- [ ] Set up logging/monitoring

### Frontend (Next.js)
- [ ] Update `.env.local` with production API URL
- [ ] Configure Flutterwave public key
- [ ] Build optimized version: `npm run build`
- [ ] Deploy to Vercel/Netlify
- [ ] Set up custom domain (optional)
- [ ] Configure SSL/TLS

### Integration Testing
- [ ] Test user registration flow
- [ ] Test login/authentication
- [ ] Test API key CRUD operations
- [ ] Test usage analytics data accuracy
- [ ] Test subscription upgrade/downgrade
- [ ] Test Flutterwave payment flow
- [ ] Test webhook handling
- [ ] Verify rate limiting works
- [ ] Test error handling (invalid tokens, expired sessions)

---

## 📝 Implementation Priority

### Phase 1: Core Authentication (Week 1)
1. Implement `/auth/register`, `/auth/login`, `/auth/me`
2. Set up JWT middleware
3. Create user model and database table
4. Test authentication flow end-to-end

### Phase 2: API Key Management (Week 1-2)
1. Implement `/keys` CRUD endpoints
2. Create API key generation logic
3. Set up request logging middleware
4. Connect to existing domain engines

### Phase 3: Usage Tracking (Week 2)
1. Implement `/usage/metrics` endpoint
2. Aggregate data from `request_logs` table
3. Add time-range filtering
4. Test with real API traffic

### Phase 4: Billing Integration (Week 2-3)
1. Adapt existing payment routes for Flutterwave
2. Implement subscription management
3. Set up webhook handlers
4. Test payment flows in sandbox mode

### Phase 5: Polish & Testing (Week 3-4)
1. Add input validation
2. Improve error messages
3. Write unit tests
4. Load testing
5. Security audit

---

## 🛠️ Quick Start Commands

### Start Backend
```bash
cd tiannara_api
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### Start Frontend
```bash
cd tiannara_saas
npm install
npm run dev
```

### Test API Connection
```bash
curl http://localhost:8000/api/v1/health
```

Expected response:
```json
{
  "status": "healthy",
  "version": "1.3.0-phase5"
}
```

---

## 📞 Support & Debugging

### Common Issues

**Issue**: Frontend can't connect to backend
- Check `NEXT_PUBLIC_API_BASE_URL` in `.env.local`
- Verify backend is running on port 8000
- Check CORS configuration in `main.py`

**Issue**: Authentication fails
- Verify JWT secret matches between frontend and backend
- Check token expiration time
- Inspect browser console for errors

**Issue**: Payment flow doesn't complete
- Verify Flutterwave keys are correct
- Check webhook endpoint is accessible
- Review Flutterwave dashboard for transaction logs

### Logging

Backend logs to console by default. For production:
```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('tiannara_api.log'),
        logging.StreamHandler()
    ]
)
```

---

## 🎯 Success Metrics

After integration, you should see:
- ✅ Users can register and login successfully
- ✅ API keys can be created, viewed, and revoked
- ✅ Real-time usage data appears in dashboard charts
- ✅ Subscription upgrades process payments correctly
- ✅ Domain engines respond to API requests
- ✅ All pages load with real data (no mock data)

---

**Last Updated**: May 2026  
**Status**: Integration framework ready, backend endpoints pending implementation
