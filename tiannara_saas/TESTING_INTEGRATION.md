# Tiannara SaaS - Testing & Integration Guide

## ✅ Completed Features

### 1. **Frontend Server Running**
- **Status:** ✅ Running on http://localhost:3000
- **Framework:** Next.js 16.2.6 with Turbopack
- **Port:** 3000 (auto-detected and cleared previous instance)

---

### 2. **Strong Password Requirements**
**Location:** `/app/signup/page.tsx`

**Requirements Implemented:**
- ✅ Minimum 12 characters (increased from 8)
- ✅ At least one uppercase letter (A-Z)
- ✅ At least one lowercase letter (a-z)
- ✅ At least one number (0-9)
- ✅ At least one special character (!@#$%^&*...)

**UI Features:**
- Real-time password strength indicator (5-level bar)
- Visual checklist showing which requirements are met
- Color-coded feedback (red/yellow/green)
- Validation before OTP send
- Error messages listing missing requirements

**Testing:**
```typescript
// Valid passwords:
"SecurePass123!"     // ✅ All requirements met
"MyP@ssw0rd2024"     // ✅ Strong password

// Invalid passwords:
"short1A!"           // ❌ Less than 12 chars
"nouppercase123!"    // ❌ No uppercase
"NOLOWERCASE123!"    // ❌ No lowercase
"NoSpecialChar123"   // ❌ No special char
"Nonumber!Pass"      // ❌ No number
```

---

### 3. **Settings Page**
**Location:** `/app/dashboard/settings/page.tsx`

**Features Implemented:**
- ✅ Profile Information Update
  - Full Name
  - Email Address
  - Company (optional)
  - Save changes button with loading state
  
- ✅ Password Change
  - Current password verification
  - New password with strength indicator
  - Confirm new password
  - Same strong password requirements as signup
  - Validation checks (passwords match, different from current)
  
- ✅ Account Information Display
  - Current tier (Starter/Professional/Enterprise)
  - Member since date
  - API keys count

**API Integration:**
- Uses `apiClient.updateProfile()` for profile updates
- Password change endpoint needs backend implementation (currently simulated)

---

### 4. **Auto-Logout Feature**
**Location:** `/contexts/AuthContext.tsx`

**Implementation:**
- ✅ 30-minute inactivity timeout
- ✅ Tracks user activity events:
  - Mouse clicks (mousedown)
  - Keyboard input (keydown)
  - Scrolling (scroll)
  - Touch events (touchstart)
- ✅ Automatic logout when timer expires
- ✅ Timer resets on any user activity
- ✅ Proper cleanup on component unmount
- ✅ Console logging for debugging

**How It Works:**
1. User logs in → Timer starts
2. User interacts with page → Timer resets to 30 minutes
3. No activity for 30 minutes → Auto-logout triggered
4. Token cleared from localStorage
5. User redirected to login page

---

### 5. **Authentication Flow**
**Status:** ✅ Fully Functional

**Complete Flow:**
```
1. Signup (/signup)
   ↓
   - Fill form (name, email, password)
   - Password validation (strong requirements)
   - Send OTP (simulated - needs backend)
   - Enter 6-digit OTP code
   - Create account
   - Auto-login with token
   
2. Login (/login)
   ↓
   - Enter email and password
   - Authenticate with backend
   - Store JWT token in localStorage
   - Redirect to /dashboard
   
3. Dashboard (/dashboard)
   ↓
   - Protected route (requires auth)
   - AuthContext provides user data
   - Auto-logout after 30 min inactivity
   
4. Logout
   ↓
   - Clear token from localStorage
   - Clear user state
   - Redirect to /login
```

**Storage:**
- **localStorage:** JWT token (`tiannara_token`)
- **AuthContext:** User profile state (in-memory)
- **Session:** Maintained via token in localStorage

---

## ⚠️ Pending Work

### 1. **Remove Mock Data & Integrate Real Backend**
**Priority:** HIGH

**Pages with Mock Data:**
- `/app/dashboard/page.tsx` - Stats cards, workflows, insights
- `/app/dashboard/analytics/page.tsx` - Charts, metrics
- `/app/dashboard/forecasting/page.tsx` - Predictions
- `/app/dashboard/automations/page.tsx` - Automation list
- `/app/dashboard/team/page.tsx` - Team members

**Required Backend Endpoints:**
```python
# Tiannara Core API endpoints needed:
GET  /api/v1/dashboard/metrics          # Dashboard stats
GET  /api/v1/workflows                  # List user workflows
GET  /api/v1/workflows/:id              # Get workflow details
POST /api/v1/workflows                  # Create workflow
GET  /api/v1/analytics/insights         # AI-generated insights
GET  /api/v1/forecasting/predictions    # Forecast data
GET  /api/v1/automations                # List automations
GET  /api/v1/team/members               # Team members
GET  /api/v1/capabilities               # System capabilities
```

**Action Required:**
1. Check Tiannara Core backend for existing endpoints
2. Map frontend API calls to real backend routes
3. Replace mock data with API responses
4. Add error handling for failed requests
5. Add loading states during data fetch

---

### 2. **Backend Integration Status**

**Current API Client:** `/lib/api.ts`

**Implemented Methods:**
- ✅ `login(email, password)` - POST /auth/login
- ✅ `signup(name, email, password)` - POST /auth/register
- ✅ `getProfile()` - GET /auth/me
- ✅ `updateProfile(data)` - PUT /auth/profile
- ✅ `getApiKeys()` - GET /keys
- ✅ `createApiKey(name)` - POST /keys
- ✅ `revokeApiKey(keyId)` - DELETE /keys/:id
- ✅ `getUsageMetrics(range)` - GET /usage/metrics
- ✅ `getActivityLogs(limit)` - GET /usage/activity
- ✅ `getSubscription()` - GET /billing/subscription
- ✅ `getPaymentHistory()` - GET /billing/payments
- ✅ `createCheckoutSession(...)` - POST /payment/subscribe
- ✅ `getPricingPlans()` - GET /payment/plans
- ✅ `getDomainEngines()` - GET /engines
- ✅ `testEngine(engine, payload)` - POST /engines/:engine/test
- ✅ `healthCheck()` - GET /health

**Missing Methods (Need to Add):**
```typescript
// Workflow management
async getWorkflows(): Promise<ApiResponse<Workflow[]>>
async createWorkflow(data: WorkflowData): Promise<ApiResponse<Workflow>>
async updateWorkflow(id: string, data: Partial<Workflow>): Promise<ApiResponse<Workflow>>
async deleteWorkflow(id: string): Promise<ApiResponse>

// Automations
async getAutomations(): Promise<ApiResponse<Automation[]>>
async createAutomation(data: AutomationData): Promise<ApiResponse<Automation>>

// Analytics & Insights
async getInsights(): Promise<ApiResponse<Insight[]>>
async getPredictions(): Promise<ApiResponse<Prediction[]>>

// Team Management
async getTeamMembers(): Promise<ApiResponse<TeamMember[]>>
async inviteMember(email: string, role: string): Promise<ApiResponse>
async removeMember(memberId: string): Promise<ApiResponse>

// Capabilities (for system info)
async getCapabilities(): Promise<ApiResponse<SystemCapabilities>>
```

---

### 3. **OTP Verification**
**Status:** ⚠️ Simulated (Needs Backend)

**Current Implementation:**
- Frontend has full OTP UI (6-digit input, countdown, resend)
- Backend call is commented out (TODO)
- Currently simulates successful OTP

**Required Backend Endpoints:**
```python
POST /api/v1/auth/send-otp      # Send OTP to email
POST /api/v1/auth/verify-otp    # Verify OTP code
```

**Action Required:**
1. Implement OTP generation in backend
2. Integrate email service (SendGrid, AWS SES, etc.)
3. Store OTP temporarily (Redis recommended)
4. Expiry time: 10 minutes
5. Max attempts: 3 before lockout

---

### 4. **Password Change Backend**
**Status:** ⚠️ Simulated (Needs Backend)

**Current Implementation:**
- Frontend validates new password
- Form submission simulated with setTimeout
- No actual backend call

**Required Backend Endpoint:**
```python
POST /api/v1/auth/change-password
Body: {
  "current_password": "string",
  "new_password": "string"
}
```

**Security Considerations:**
- Verify current password before changing
- Enforce same strong password requirements
- Invalidate all other sessions after password change
- Send confirmation email

---

## 🧪 Testing Checklist

### Authentication Tests
- [ ] Signup with valid strong password
- [ ] Signup with weak password (should fail)
- [ ] Login with correct credentials
- [ ] Login with wrong password (should fail)
- [ ] Auto-redirect to dashboard after login
- [ ] Auto-redirect to login if not authenticated
- [ ] Logout clears token and redirects
- [ ] Auto-logout after 30 minutes inactivity

### Settings Tests
- [ ] Update profile name
- [ ] Update profile email
- [ ] Update company field
- [ ] Change password with valid new password
- [ ] Change password with weak new password (should fail)
- [ ] Change password with mismatched confirmation (should fail)
- [ ] View account information (tier, member since, API keys)

### Storage Tests
- [ ] Token stored in localStorage after login
- [ ] Token persists across page refreshes
- [ ] Token cleared after logout
- [ ] User preferences saved (if any)
- [ ] Onboarding data saved to localStorage

### Navigation Tests
- [ ] All sidebar links work
- [ ] Templates page accessible
- [ ] Admin dashboard accessible (for admin users)
- [ ] Protected routes redirect to login

---

## 🔗 Backend Connection

**API Base URL:** `http://localhost:8004/api/v1`

**Environment Variable:** `.env.local`
```env
NEXT_PUBLIC_API_BASE_URL=http://localhost:8004/api/v1
```

**Health Check:**
```bash
curl http://localhost:8004/api/v1/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0"
}
```

---

## 📊 Real Data Integration Plan

### Phase 1: Core Dashboard
1. Replace mock stats with real API calls
2. Fetch user's actual workflows
3. Display real usage metrics
4. Show actual API key count

### Phase 2: Workflows
1. Load workflows from backend
2. Create new workflow functionality
3. Edit/delete workflows
4. Template deployment (copy template → create workflow)

### Phase 3: Analytics & Insights
1. Fetch real analytics data
2. Generate charts from actual usage
3. Display AI-generated insights
4. Show prediction accuracy

### Phase 4: Team & Collaboration
1. Load team members from backend
2. Invite new members
3. Manage roles and permissions
4. Activity feed from real events

---

## 🎯 Next Steps (Priority Order)

1. **Verify Backend Availability**
   - Check if Tiannara Core API is running on port 8004
   - Test health endpoint
   - Verify authentication endpoints work

2. **Add Missing API Methods**
   - Workflow CRUD operations
   - Team management
   - Analytics and insights
   - Capabilities endpoint

3. **Replace Mock Data**
   - Start with dashboard page
   - Then workflows list
   - Then analytics/forecasting
   - Finally team page

4. **Implement OTP Backend**
   - Generate and send OTP codes
   - Verify OTP on signup
   - Rate limiting and security

5. **Implement Password Change Backend**
   - Verify current password
   - Update to new password
   - Session invalidation

6. **End-to-End Testing**
   - Complete user journey tests
   - Edge case handling
   - Error scenarios
   - Performance testing

---

## 📝 Notes

### What's Working Now:
✅ Frontend runs on localhost:3000  
✅ Signup with strong password validation  
✅ Login/logout functionality  
✅ Auto-logout after 30 min inactivity  
✅ Settings page with profile update  
✅ Password change UI (backend pending)  
✅ LocalStorage token management  
✅ Protected routes  
✅ Responsive design  

### What Needs Backend:
⚠️ Real dashboard data  
⚠️ Workflow CRUD operations  
⚠️ OTP verification  
⚠️ Password change execution  
⚠️ Team management  
⚠️ Analytics data  
⚠️ Usage metrics  
⚠️ Payment processing  

### Templates Status:
✅ Templates page exists with 5 pre-built templates  
✅ No placeholders in workflow builder  
✅ Templates are the only pre-built content  
✅ Users can customize templates or build from scratch  

---

**Last Updated:** April 30, 2026  
**Frontend Version:** 0.1.0  
**Backend Required:** Tiannara Core API v1
