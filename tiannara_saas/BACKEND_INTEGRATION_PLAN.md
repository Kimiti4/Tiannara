# Tiannara Backend Integration - Complete Implementation Plan

## ✅ Architecture Confirmed (architecture.md lines 851-1386)

### **Three-Tier Architecture:**
```
Frontend (Next.js:3000) 
    ↓ HTTP/REST + JWT
API Gateway (FastAPI:8004)
    ↓ Internal Python calls
Tiannara Core (Python Intelligence)
```

### **Key Principles:**
✅ Frontend NEVER talks directly to Core  
✅ Gateway handles auth, billing, routing  
✅ Core stays private and protected  
✅ Modular monolith (not microservices yet)  

---

## 📋 Backend Routes Available (tiannara_api/routes/)

**Authentication & User Management:**
- ✅ `auth.py` - Login, signup, OTP verification, profile management
- ✅ `sso.py` - OAuth 2.0 / SAML single sign-on
- ✅ `workspaces.py` - Team workspaces and collaboration
- ✅ `audit.py` - Audit logging for compliance

**Business Logic:**
- ✅ `payment.py` - Stripe/LemonSqueezy payment processing
- ✅ `usage.py` - Usage metrics and quota tracking
- ✅ `analytics.py` - Advanced analytics and insights
- ✅ `admin.py` - Admin dashboard and monitoring

**Core AI Proxy:**
- ✅ `core_proxy.py` - Secure proxy to Tiannara Core
- ✅ `modules.py` - Domain engine management
- ✅ `status.py` - System health and status

**Advanced Features:**
- ✅ `monitoring.py` - Issue detection and monitoring
- ✅ `autonomous_testing.py` - Autonomous test execution
- ✅ `explanations.py` - EU AI Act compliance explanations
- ✅ `mapek_security.py` - MAPE-K security loop
- ✅ `white_label.py` - White-label branding
- ✅ `efficiency.py` - Efficiency optimization
- ✅ `moderation.py` - Content moderation

---

## ⚠️ Missing Frontend API Methods

The frontend `lib/api.ts` needs these additional methods to replace mock data:

### **1. Workflow Management**
```typescript
// Add to lib/api.ts

export interface Workflow {
  id: string
  name: string
  description: string
  nodes: any[]
  edges: any[]
  status: 'draft' | 'active' | 'paused' | 'archived'
  created_at: string
  updated_at: string
  last_run?: string
  run_count: number
}

async getWorkflows(): Promise<ApiResponse<Workflow[]>> {
  return this.request('/workflows')
}

async getWorkflow(id: string): Promise<ApiResponse<Workflow>> {
  return this.request(`/workflows/${id}`)
}

async createWorkflow(data: Partial<Workflow>): Promise<ApiResponse<Workflow>> {
  return this.request('/workflows', {
    method: 'POST',
    body: JSON.stringify(data),
  })
}

async updateWorkflow(id: string, data: Partial<Workflow>): Promise<ApiResponse<Workflow>> {
  return this.request(`/workflows/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  })
}

async deleteWorkflow(id: string): Promise<ApiResponse> {
  return this.request(`/workflows/${id}`, {
    method: 'DELETE',
  })
}

async runWorkflow(id: string, input?: any): Promise<ApiResponse> {
  return this.request(`/workflows/${id}/run`, {
    method: 'POST',
    body: JSON.stringify({ input }),
  })
}
```

### **2. Automations**
```typescript
export interface Automation {
  id: string
  name: string
  description: string
  trigger_type: 'scheduled' | 'event' | 'threshold'
  trigger_config: any
  workflow_id: string
  status: 'active' | 'paused' | 'disabled'
  last_triggered?: string
  created_at: string
}

async getAutomations(): Promise<ApiResponse<Automation[]>> {
  return this.request('/automations')
}

async createAutomation(data: Partial<Automation>): Promise<ApiResponse<Automation>> {
  return this.request('/automations', {
    method: 'POST',
    body: JSON.stringify(data),
  })
}

async updateAutomation(id: string, data: Partial<Automation>): Promise<ApiResponse<Automation>> {
  return this.request(`/automations/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  })
}

async toggleAutomation(id: string): Promise<ApiResponse<Automation>> {
  return this.request(`/automations/${id}/toggle`, {
    method: 'POST',
  })
}
```

### **3. Analytics & Insights**
```typescript
export interface Insight {
  id: string
  type: 'root_cause' | 'pattern' | 'forecast' | 'anomaly'
  title: string
  description: string
  confidence: number
  created_at: string
  metadata?: any
}

export interface Prediction {
  id: string
  metric: string
  predicted_value: number
  confidence: number
  timeframe: string
  trend: 'up' | 'down' | 'stable'
  created_at: string
}

async getInsights(limit?: number): Promise<ApiResponse<Insight[]>> {
  return this.request(`/analytics/insights?limit=${limit || 10}`)
}

async getPredictions(metric?: string): Promise<ApiResponse<Prediction[]>> {
  const endpoint = metric 
    ? `/analytics/predictions?metric=${metric}`
    : '/analytics/predictions'
  return this.request(endpoint)
}

async getDashboardMetrics(): Promise<ApiResponse<{
  total_workflows: number
  active_automations: number
  api_usage_today: number
  accuracy_avg: number
  recent_insights: Insight[]
}>> {
  return this.request('/analytics/dashboard')
}
```

### **4. Team Management**
```typescript
export interface TeamMember {
  id: string
  user_id: string
  name: string
  email: string
  role: 'owner' | 'admin' | 'developer' | 'analyst' | 'viewer'
  status: 'active' | 'inactive' | 'pending'
  joined_at: string
  last_active?: string
}

async getTeamMembers(): Promise<ApiResponse<TeamMember[]>> {
  return this.request('/workspaces/members')
}

async inviteMember(email: string, role: string): Promise<ApiResponse> {
  return this.request('/workspaces/invite', {
    method: 'POST',
    body: JSON.stringify({ email, role }),
  })
}

async removeMember(memberId: string): Promise<ApiResponse> {
  return this.request(`/workspaces/members/${memberId}`, {
    method: 'DELETE',
  })
}

async updateMemberRole(memberId: string, role: string): Promise<ApiResponse> {
  return this.request(`/workspaces/members/${memberId}/role`, {
    method: 'PUT',
    body: JSON.stringify({ role }),
  })
}

async getActivityFeed(limit?: number): Promise<ApiResponse<any[]>> {
  return this.request(`/workspaces/activity?limit=${limit || 20}`)
}
```

### **5. Password Change**
```typescript
async changePassword(currentPassword: string, newPassword: string): Promise<ApiResponse> {
  return this.request('/auth/change-password', {
    method: 'POST',
    body: JSON.stringify({
      current_password: currentPassword,
      new_password: newPassword,
    }),
  })
}
```

### **6. OTP Verification**
```typescript
async sendOTP(email: string): Promise<ApiResponse> {
  return this.request('/auth/send-otp', {
    method: 'POST',
    body: JSON.stringify({ email }),
  })
}

async verifyOTP(email: string, otpCode: string): Promise<ApiResponse<{ token: string; user: UserProfile }>> {
  return this.request('/auth/verify-otp', {
    method: 'POST',
    body: JSON.stringify({ email, otp_code: otpCode }),
  })
}
```

### **7. System Capabilities**
```typescript
export interface SystemCapabilities {
  available_engines: string[]
  max_workflow_nodes: number
  max_api_keys: number
  features: {
    forecasting: boolean
    causal_analysis: boolean
    nlp: boolean
    automation: boolean
    team_collaboration: boolean
  }
}

async getCapabilities(): Promise<ApiResponse<SystemCapabilities>> {
  return this.request('/system/capabilities')
}
```

---

## 🎯 Implementation Priority

### **Phase 1: Critical Auth Fixes (Today)**
1. ✅ Add `changePassword()` method to api.ts
2. ✅ Add `sendOTP()` and `verifyOTP()` methods
3. Update signup page to use real OTP API
4. Update settings page to use real password change API

### **Phase 2: Dashboard Real Data (This Week)**
1. Add `getDashboardMetrics()` to api.ts
2. Replace mock stats in `/dashboard/page.tsx`
3. Add loading states and error handling
4. Test with real backend data

### **Phase 3: Workflows (Next Week)**
1. Add workflow CRUD methods to api.ts
2. Create backend route if not exists (`/workflows`)
3. Update workflows list page
4. Update workflow builder to save/load from backend

### **Phase 4: Analytics & Insights (Week 3)**
1. Add analytics methods to api.ts
2. Connect to real insight generation
3. Replace mock charts with real data
4. Implement real-time updates

### **Phase 5: Team Management (Week 4)**
1. Add team management methods
2. Use existing `/workspaces` endpoints
3. Update team page with real data
4. Test invite/remove functionality

---

## 🔧 Quick Wins - Replace Mock Data NOW

### **Files to Update:**

1. **`/app/dashboard/page.tsx`**
   - Replace hardcoded stats with `apiClient.getDashboardMetrics()`
   - Add useEffect to fetch real data
   - Show loading skeleton while fetching

2. **`/app/dashboard/analytics/page.tsx`**
   - Replace mock insights with `apiClient.getInsights()`
   - Fetch real predictions with `apiClient.getPredictions()`

3. **`/app/dashboard/forecasting/page.tsx`**
   - Replace mock forecasts with `apiClient.getPredictions()`
   - Show real confidence scores

4. **`/app/dashboard/automations/page.tsx`**
   - Replace mock automations with `apiClient.getAutomations()`

5. **`/app/dashboard/team/page.tsx`**
   - Replace mock members with `apiClient.getTeamMembers()`
   - Load real activity feed

6. **`/app/signup/page.tsx`**
   - Uncomment OTP API calls
   - Use `apiClient.sendOTP()` and `apiClient.verifyOTP()`

7. **`/app/dashboard/settings/page.tsx`**
   - Uncomment password change API call
   - Use `apiClient.changePassword()`

---

## 📝 Backend Endpoint Mapping

| Frontend Need | Backend Route | Status |
|--------------|---------------|--------|
| Login | POST `/auth/login` | ✅ Exists |
| Signup | POST `/auth/register` | ✅ Exists |
| Send OTP | POST `/auth/send-otp` | ✅ Exists |
| Verify OTP | POST `/auth/verify-otp` | ✅ Exists |
| Change Password | POST `/auth/change-password` | ⚠️ Need to add |
| Get Profile | GET `/auth/me` | ✅ Exists |
| Update Profile | PUT `/auth/profile` | ✅ Exists |
| Get Workflows | GET `/workflows` | ⚠️ Need to add |
| Create Workflow | POST `/workflows` | ⚠️ Need to add |
| Get Automations | GET `/automations` | ⚠️ Need to add |
| Get Insights | GET `/analytics/insights` | ✅ Exists |
| Get Predictions | GET `/analytics/predictions` | ⚠️ Need to add |
| Get Team Members | GET `/workspaces/members` | ✅ Exists |
| Invite Member | POST `/workspaces/invite` | ✅ Exists |
| Get Activity | GET `/workspaces/activity` | ✅ Exists |
| Get Dashboard Stats | GET `/analytics/dashboard` | ⚠️ Need to add |
| Get Capabilities | GET `/system/capabilities` | ⚠️ Need to add |

---

## 🚀 Next Steps

1. **Add missing methods to `lib/api.ts`** (I'll do this now)
2. **Update pages to use real API calls**
3. **Test each integration**
4. **Add error handling and loading states**
5. **Remove all mock data**

Would you like me to start implementing these changes now?
