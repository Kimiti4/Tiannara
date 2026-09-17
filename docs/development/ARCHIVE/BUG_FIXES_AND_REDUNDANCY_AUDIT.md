# Tiannara Project - Bug Fixes & Redundancy Audit
## Date: 2026-04-30

---

##  PART 1: CRITICAL BUGS FIXED ✅

### BUG #1: Hardcoded Backend Port Mismatch ✅ FIXED
**Severity:** CRITICAL  
**Files:**
- `tiannara_saas/app/admin/page.tsx`
- `tiannara_saas/app/admin/users/page.tsx`

**Issue:** Admin pages hardcoded to `localhost:8003` while backend runs on port 8004

**Fix Applied:**
```typescript
// BEFORE (BROKEN):
const response = await fetch('http://localhost:8003/api/v1/admin/metrics', {

// AFTER (FIXED):
const baseUrl = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8004/api/v1'
const response = await fetch(`${baseUrl}/admin/metrics`, {
```

**Status:** ✅ Complete

---

### BUG #2: Auth Token Not Sent After Fast Refresh ✅ FIXED
**Severity:** CRITICAL  
**File:** `tiannara_saas/lib/api.ts`

**Issue:** After Next.js Fast Refresh, new apiClient instance had `this.token = null`, causing 401 errors

**Fix Applied:**
```typescript
// BEFORE (BROKEN):
if (this.token) {
  headers['Authorization'] = `Bearer ${this.token}`
}

// AFTER (FIXED):
const storedToken = typeof window !== 'undefined' ? localStorage.getItem('tiannara_token') : null
const currentToken = this.token || storedToken

if (currentToken) {
  headers['Authorization'] = `Bearer ${currentToken}`
  console.log(' Using token for request')
}
```

**Status:** ✅ Complete

---

### BUG #3: Login Response Structure Mismatch ✅ FIXED
**Severity:** CRITICAL  
**File:** `tiannara_api/routes/auth.py`

**Issue:** Backend returned `{success, message, token, user}` but frontend expected `{success, message, data: {token, user}}`

**Fix Applied:**
```python
# BEFORE (BROKEN):
return LoginResponse(
    success=True,
    message="Login successful",
    token=jwt_token,
    user={...}
)

# AFTER (FIXED):
return LoginResponse(
    success=True,
    message="Login successful",
    data={
        "token": jwt_token,
        "user": {...}
    }
)
```

**Status:** ✅ Complete

---

### BUG #4: Missing Usage Metrics Endpoint ✅ FIXED
**Severity:** HIGH  
**File:** Created `tiannara_api/routes/usage.py`

**Issue:** Frontend called `/api/v1/usage/metrics` but endpoint didn't exist

**Fix Applied:**
- Created new `usage.py` route file with `/metrics` endpoint
- Registered in `tiannara_api/main.py`
- Returns usage statistics with daily breakdown and domain breakdown

**Status:** ✅ Complete

---

### BUG #5: Environment Variable Configuration ✅ FIXED
**Severity:** HIGH  
**File:** Created `tiannara_saas/.env.local`

**Issue:** Frontend defaulted to port 8000, backend on port 8003/8004

**Fix Applied:**
```env
NEXT_PUBLIC_API_BASE_URL=http://localhost:8004/api/v1
```

**Status:** ✅ Complete

---

##  PART 2: REMAINING HIGH-PRIORITY BUGS (Not Yet Fixed)

### BUG #6: Bare `except:` Statements (26 instances)
**Severity:** HIGH  
**Files Affected:**
- `tiannara_api/routes/admin.py` (12 instances)
- `tiannara_api/routes/monitoring.py` (1 instance)
- `tiannara_core/evaluation/episode_logger.py` (3 instances)
- `tiannara_core/interpretability/do_calculus_extended.py` (2 instances)
- `tiannara_core/evolution/temporal_evolution_engine.py` (2 instances)
- `tiannara_core/evolution/causal_system_evolver.py` (2 instances)
- And 4 more files...

**Issue:**
```python
except:  # BAD - catches SystemExit, KeyboardInterrupt, etc.
    pass
```

**Should Be:**
```python
except Exception as e:  # GOOD
    logger.error(f"Error: {e}")
```

**Impact:**
- Cannot interrupt with Ctrl+C
- Errors silently swallowed
- No debugging information
- Can hide critical failures

**Status:**  Needs fixing (not critical for current functionality)

---

### BUG #7: AuthContext Clears Token on Any Error
**Severity:** MEDIUM-HIGH  
**File:** `tiannara_saas/contexts/AuthContext.tsx`

**Issue:** Network blip or temporary 401 on one endpoint logs out user completely

```typescript
catch (error) {
  console.error('Auth check failed:', error)
  apiClient.clearToken()  // ❌ Clears token on ANY error
}
```

**Should Be:**
```typescript
catch (error) {
  if (error.status === 401) {
    apiClient.clearToken()  // Only clear on auth failure
  }
}
```

**Status:**  Needs fixing

---

### BUG #8: Debug Console Logs in Production Code
**Severity:** LOW  
**File:** `tiannara_saas/lib/api.ts` (15 console.log statements)

**Issue:** Debug logging left in production code

**Status:**  Needs cleanup before production deployment

---

##  PART 3: DASHBOARD REDUNDANCY AUDIT

### Current Dashboard Structure

#### Dashboard #1: **tiannara_saas/** (Next.js 16 + Turbopack)
- **Purpose:** SaaS customer-facing platform
- **Port:** 3000
- **Tech Stack:** Next.js 16.2.6, React 19, Tailwind CSS v4
- **Contains:**
  - Public landing page
  - User authentication (login/signup)
  - User dashboard (`/dashboard`)
  - Admin dashboard (`/admin`) ← **Customer admin view**
  - API key management
  - Billing & subscriptions
  - Usage analytics
- **Status:** ✅ Active, currently running
- **API Connection:** FastAPI backend on port 8004

---

#### Dashboard #2: **tiannara_gui/** (Vite + React)
- **Purpose:** Tiannara Core control dashboard
- **Port:** Not currently running
- **Tech Stack:** Vite 7.3.1, React 19, React Router, Tailwind CSS v4
- **Contains:**
  - 18 pages of core functionality
  - Testing dashboard
  - Engine controls
  - Core system monitoring
  - Experimental features
- **Status:** Built but not actively running
- **API Connection:** Likely connects directly to Tiannara Core

---

#### Dashboard #3: **tiannara_internal_dashboard/** (Next.js 14)
- **Purpose:** Internal operations dashboard
- **Port:** Not currently running
- **Tech Stack:** Next.js 14.2.3, React 18, Tailwind CSS v3
- **Contains:**
  - Core monitoring pages
  - Gateway health checks
  - Engine status monitoring
  - Internal metrics
- **Status:** Built but not actively running
- **API Connection:** Internal API endpoints

---

### Redundancy Analysis

#### REDUNDANCY #1: Three Dashboards Exist
**Issue:** Project has THREE separate dashboard implementations:
1. `tiannara_saas/` - Customer SaaS platform (Next.js 16)
2. `tiannara_gui/` - Core control panel (Vite)
3. `tiannara_internal_dashboard/` - Internal ops (Next.js 14)

**Intended Architecture (from your description):**
- ✅ **Dashboard 1:** Next.js for SaaS customers → `tiannara_saas/`
- ✅ **Dashboard 2:** Control dashboard for Tiannara Core → Should be ONE of the other two

**Problem:**
- `tiannara_gui/` and `tiannara_internal_dashboard/` appear to serve similar purposes
- Both monitor Tiannara Core functionality
- Maintaining both is redundant and creates confusion

**Recommendation:**

**Option A (Recommended):** Keep `tiannara_gui/` (Vite-based)
- More modern tech stack (Vite 7 vs Next.js 14)
- React 19 (latest)
- Already has 18 pages of core functionality
- Delete `tiannara_internal_dashboard/`
- Move any unique features from internal_dashboard to tiannara_gui

**Option B:** Keep `tiannara_internal_dashboard/` (Next.js-based)
- Consistent with SaaS platform (both Next.js)
- Better for sharing components between SaaS and internal dash
- Downgrade: React 18, Next.js 14 (older versions)
- Delete `tiannara_gui/`
- Migrate 18 pages from tiannara_gui to internal_dashboard

**Option C:** Consolidate everything into `tiannara_saas/`
- Single Next.js 16 application
- Separate routes for SaaS vs internal:
  - `/dashboard` → Customer dashboard
  - `/admin` → Customer admin
  - `/internal` → Tiannara Core control dashboard
- Pros: Single codebase, shared components, unified auth
- Cons: Larger bundle size, potential security concerns if not properly isolated

---

#### REDUNDANCY #2: Admin Dashboard Duplication
**Issue:** Both `tiannara_saas/` and `tiannara_internal_dashboard/` have admin dashboards

**tiannara_saas/app/admin/page.tsx:**
- Customer-facing admin view
- Shows API metrics, engine status, system health
- Uses `/api/v1/admin/metrics` endpoint
- Port 8004

**tiannara_internal_dashboard/src/app/core/page.tsx:**
- Internal operations view
- Shows gateway health, engine status, metrics
- Uses internal API endpoints
- Not currently running

**Overlap:** Both show engine status, metrics, system health

**Recommendation:** 
- Keep `tiannara_saas/admin` for customer admin operations
- Keep ONE internal dashboard for Tiannara Core operations
- Ensure they serve different audiences and have different permissions

---

#### REDUNDANCY #3: API Client Duplication
**Files with API clients:**
1. `tiannara_saas/lib/api.ts` - SaaS API client
2. `tiannara_internal_dashboard/src/lib/api.ts` - Internal dashboard API client
3. `tiannara_gui/src/api/` - Core GUI API clients (5 files)

**Issue:** Three different API client implementations doing similar things

**Recommendation:**
- Consolidate into single shared API client package
- Or create `tiannara_shared/` package used by all frontends
- Reduces duplication and maintenance burden

---

##  PART 4: IMMEDIATE ACTION ITEMS

###  DONE ✅
1. ✅ Fixed hardcoded port mismatch in admin pages
2. ✅ Fixed token persistence after Fast Refresh
3. ✅ Fixed login response structure
4. ✅ Created missing usage metrics endpoint
5. ✅ Configured environment variables

###  HIGH PRIORITY (This Week)
6.  Fix AuthContext to not clear token on transient errors
7.  Fix all bare `except:` statements (26 instances)
8.  Decide which dashboard to keep: `tiannara_gui/` vs `tiannara_internal_dashboard/`
9.  Remove debug console logs from production code

###  MEDIUM PRIORITY (Next Sprint)
10. Consolidate API clients or create shared package
11. Implement proper logging infrastructure
12. Add error boundary components
13. Write integration tests for auth flow

###  LOW PRIORITY (Future)
14. Address 45+ TODO comments
15. Implement database persistence (replace in-memory store)
16. Add WebSocket support for real-time metrics
17. Performance optimization and bundle size reduction

---

##  PART 5: RECOMMENDED ARCHITECTURE

```
Tiannara Project Structure:

├── tiannara_api/              # FastAPI Backend (Port 8004)
│   ├── routes/                # API endpoints
│   ├── gateway/               # API gateway layer
│   └── main.py                # Application entry point
│
├── tiannara_core/             # Tiannara Core Engine
│   ├── evolution/             # Evolution engine
│   ├── reasoning/             # Reasoning engine
│   └── [other core modules]
│
├── tiannara_saas/             # SaaS Platform (Port 3000) ✅ ACTIVE
│   ├── app/
│   │   ├── dashboard/         # Customer dashboard
│   │   ├── admin/             # Customer admin dashboard
│   │   └── [other routes]
│   └── lib/api.ts             # API client
│
└── tiannara_gui/              # Core Control Dashboard ✅ KEEP THIS
    ├── src/pages/             # 18 pages of core functionality
    └── src/api/               # API clients
    (DELETE: tiannara_internal_dashboard/)
```

**Rationale:**
- `tiannara_saas/`: Customer-facing SaaS platform (Next.js 16)
- `tiannara_gui/`: Internal Tiannara Core control dashboard (Vite)
- Remove `tiannara_internal_dashboard/` to eliminate redundancy
- Two clear dashboards serving different audiences

---

##  SUMMARY

**Bugs Fixed:** 5 critical bugs ✅  
**Bugs Remaining:** 3 medium/high priority issues  
**Dashboards Found:** 3 (should be 2)  
**Redundancy:** `tiannara_gui/` and `tiannara_internal_dashboard/` serve same purpose  

**Next Steps:**
1. Test all fixes by logging in and using admin dashboard
2. Decide which dashboard to keep (recommend `tiannara_gui/`)
3. Fix AuthContext token clearing issue
4. Fix bare `except:` statements

---

**Questions for you:**
1. Which dashboard should we keep: `tiannara_gui/` (Vite) or `tiannara_internal_dashboard/` (Next.js 14)?
2. Should I proceed with fixing the remaining bugs?
3. Do you want me to create a shared API client package?
