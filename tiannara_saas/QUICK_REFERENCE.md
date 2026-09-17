# Tiannara SaaS - Quick Reference Guide

## 🚀 Getting Started

### Backend Server
```bash
cd tiannara_api
python -m uvicorn main:app --host 0.0.0.0 --port 8004 --reload
```
**URL:** http://localhost:8004  
**Health Check:** http://localhost:8004/health

### Frontend Server
```bash
cd tiannara_saas
npm run dev
```
**URL:** http://localhost:3000

---

## 📡 API Endpoints Reference

### Authentication
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - User login
- `GET /api/v1/auth/me` - Get current user profile
- `POST /api/v1/auth/send-otp` - Send OTP code
- `POST /api/v1/auth/verify-otp` - Verify OTP code
- `PUT /api/v1/auth/password` - Change password

### Workflows
- `GET /api/v1/workflows/` - List all workflows
- `GET /api/v1/workflows/{id}` - Get specific workflow
- `POST /api/v1/workflows/` - Create new workflow
- `PUT /api/v1/workflows/{id}` - Update workflow
- `DELETE /api/v1/workflows/{id}` - Delete workflow
- `POST /api/v1/workflows/{id}/run` - Execute workflow

### Automations
- `GET /api/v1/automations/` - List all automations
- `GET /api/v1/automations/{id}` - Get specific automation
- `POST /api/v1/automations/` - Create new automation
- `PUT /api/v1/automations/{id}` - Update automation
- `DELETE /api/v1/automations/{id}` - Delete automation
- `POST /api/v1/automations/{id}/toggle` - Toggle status

### Analytics
- `GET /api/v1/analytics/dashboard-metrics` - Dashboard stats
- `GET /api/v1/analytics/insights` - AI insights
- `GET /api/v1/analytics/predictions` - ML predictions
- `GET /api/v1/analytics/capabilities` - System capabilities

### Team
- `GET /api/v1/team/members` - List team members
- `POST /api/v1/team/invite` - Invite member
- `PUT /api/v1/team/members/{id}` - Update member
- `DELETE /api/v1/team/members/{id}` - Remove member
- `GET /api/v1/workspaces/activity` - Activity feed

---

## 🎯 Frontend Pages

### Customer-Facing Pages
1. **Dashboard** (`/dashboard`) - Overview with real metrics
2. **Workflows** (`/dashboard/workflows`) - Workflow management
3. **Analytics** (`/dashboard/analytics`) - Insights and trends
4. **Forecasting** (`/dashboard/forecasting`) - ML predictions
5. **Automations** (`/dashboard/automations`) - Trigger management
6. **Team** (`/dashboard/team`) - Member management
7. **Settings** (`/dashboard/settings`) - Profile & password
8. **API Keys** (`/dashboard/keys`) - Key management
9. **Billing** (`/dashboard/billing`) - Subscription

### Admin Pages
1. **Admin Dashboard** (`/admin`) - System monitoring
2. **User Management** (`/admin/users`) - RBAC control

### Public Pages
1. **Landing** (`/`) - Marketing page
2. **Login** (`/login`) - Authentication
3. **Signup** (`/signup`) - Registration with OTP

---

## 🔑 Key Features

### Security
- ✅ Strong password validation (12+ chars, uppercase, lowercase, number, special char)
- ✅ OTP verification during signup
- ✅ JWT token authentication
- ✅ Auto-logout after 30 minutes inactivity
- ✅ localStorage token persistence

### User Experience
- ✅ Loading spinners on all API calls
- ✅ Error handling with retry buttons
- ✅ Empty states for no data
- ✅ Real-time data updates
- ✅ Responsive design

### Data Integration
- ✅ All dashboard pages use real backend data
- ✅ No mock data in customer-facing features
- ✅ Parallel API fetching for performance
- ✅ TypeScript type safety throughout

---

## 🧪 Testing Checklist

### Authentication Flow
- [ ] Sign up with strong password
- [ ] Verify OTP code
- [ ] Login with credentials
- [ ] Navigate to dashboard
- [ ] Check auto-logout after inactivity
- [ ] Logout manually

### Dashboard Features
- [ ] View real metrics on dashboard
- [ ] Browse workflows list
- [ ] Check analytics insights
- [ ] View forecasting predictions
- [ ] Manage automations
- [ ] See team members

### Settings
- [ ] Update profile information
- [ ] Change password with validation
- [ ] Generate API keys
- [ ] View usage metrics

---

## 📊 Sample API Responses

### Dashboard Metrics
```json
{
  "success": true,
  "data": {
    "api_usage": {
      "current": 2221,
      "limit": 5000,
      "period": "this_month"
    },
    "active_workflows": 9,
    "avg_accuracy": 86.5,
    "total_requests_today": 441,
    "error_rate": 1.39,
    "avg_response_time_ms": 287
  }
}
```

### Insights
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "type": "root_cause",
      "title": "Customer Engagement Pattern Detected",
      "description": "High-value customers convert 2.3x more...",
      "confidence": 0.91,
      "created_at": "2026-05-12T22:45:14.160868+00:00"
    }
  ]
}
```

---

## 🛠️ Development Tips

### Adding New API Methods
1. Add method to `lib/api.ts`:
```typescript
async getNewData(): Promise<ApiResponse> {
  return this.request('/new-endpoint')
}
```

2. Use in component:
```typescript
const response = await apiClient.getNewData()
if (response.success && response.data) {
  setData(response.data)
}
```

### Creating New Backend Routes
1. Create file in `tiannara_api/routes/new_route.py`
2. Define router and endpoints
3. Import and register in `main.py`:
```python
from tiannara_api.routes.new_route import router as new_router
app.include_router(new_router, prefix="/api/v1")
```

---

## 🎨 UI Components

### Loading State
```tsx
<Loader2 className="w-8 h-8 text-purple-500 animate-spin" />
```

### Error State
```tsx
<div className="bg-red-500/10 border border-red-500/20 rounded-xl p-6">
  <p className="text-red-400">{error}</p>
  <button onClick={retry}>Retry</button>
</div>
```

### Empty State
```tsx
<p className="text-slate-400 text-center py-8">No data available.</p>
```

---

## 📝 Important Notes

### Current Limitations (Development Mode)
- In-memory storage (data resets on server restart)
- No database persistence yet
- No JWT middleware on all endpoints
- Single-user mode (no multi-tenancy)

### Production Readiness
- ✅ All UI features complete
- ✅ All API endpoints functional
- ✅ Error handling implemented
- ✅ Loading states everywhere
- ⚠️ Need PostgreSQL for persistence
- ⚠️ Need JWT auth on all routes
- ⚠️ Need user isolation

---

## 🔗 Useful Links

- **Backend Docs:** http://localhost:8004/docs (Swagger UI)
- **Frontend:** http://localhost:3000
- **Architecture:** See `docs/architecture/architecture.md`
- **Integration Guide:** See `FINAL_INTEGRATION_SUMMARY.md`

---

**🎉 Everything is ready! Login and explore all features!**
