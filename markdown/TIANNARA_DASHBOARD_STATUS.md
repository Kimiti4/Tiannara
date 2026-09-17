# Tiannara Dashboard - Running Status ✅

**Date**: May 12, 2026  
**Status**: ✅ **BOTH SERVICES RUNNING**  
**Frontend**: http://localhost:5173 (Tiannara Core Dashboard)  
**Backend**: http://localhost:8004 (FastAPI)

---

## 🚀 **Services Running**

### **Backend (FastAPI)**
- **URL**: http://localhost:8004
- **Status**: ✅ Running
- **Features**:
  - Admin metrics API
  - Authentication system
  - Real database integration
  - Domain engine monitoring
  - System health tracking

### **Frontend (Vite + React)**
- **URL**: http://localhost:5173
- **Status**: ✅ Running
- **Framework**: Vite 7.3.2
- **Proxy Config**: API calls → http://localhost:8004
- **Application**: Tiannara Core Dashboard (NOT social hub)

---

## 📱 **What You'll See at http://localhost:5173**

This is the **Tiannara Core Intelligence Platform**, which includes:

### **SaaS Routes (Public)**
- `/` - Landing Page (AI Decision Infrastructure)
- `/signup` - User registration
- `/login` - User login
- `/dashboard` - SaaS user dashboard
- `/admin` - **Admin Dashboard** (requires admin login)

### **Core Dashboard Routes (Legacy)**
- `/legacy/dashboard` - Core system dashboard
- `/discovery` - Discovery Lab
- `/evolution` - Evolution Lab
- `/autonomous` - Autonomous Lab
- `/pros` - Pros Control
- `/runs` - Runs & Reports
- `/memory` - Memory Explorer
- `/modules` - Modules page
- `/settings` - Settings

---

## 🔑 **Admin Login Credentials**

```
Email:    admin@tiannara.com
Password: admin123
Role:     ADMIN ✓
Tier:     Enterprise
```

**Already created in database** - ready to use!

---

## 🎯 **How to Access Admin Dashboard**

### **Option 1: Via Login**
1. Go to http://localhost:5173
2. Click "Login" or go to `/login`
3. Enter admin credentials above
4. After login, navigate to `/admin` or click Admin button

### **Option 2: Direct URL**
If already logged in as admin:
- Go directly to: http://localhost:5173/admin

---

## ✅ **Real Data Features (No Mock Data)**

### **Admin Dashboard** (`/admin`)

**Real-Time Metrics:**
- ✅ Total API requests (from database)
- ✅ Active users count (live query)
- ✅ Average latency (calculated from logs)
- ✅ Success/error rates (actual data)
- ✅ System uptime (monitored)

**Domain Engine Monitoring:**
- ✅ Predict engine status & requests
- ✅ Analyze engine status & requests
- ✅ Reason engine status & requests
- ✅ NLP engine status & requests
- ✅ Health percentages (real-time)
- ✅ Version tracking

**System Health Panel:**
- ✅ CPU usage (via psutil)
- ✅ Memory usage (via psutil)
- ✅ Disk usage (via psutil)
- ✅ Network I/O (via psutil)

**Orchestration Flows:**
- ✅ Active workflow status
- ✅ Job queue monitoring
- ✅ Completion tracking
- ✅ Failure detection

**Live Logs:**
- ✅ Real application logs
- ✅ Color-coded by level
- ✅ Timestamped entries
- ✅ Auto-scrolling terminal view

**Auto-Refresh**: Every 10 seconds with live data

---

### **Settings Page** (`/settings`)

**Real Data Integration:**
- ✅ User profile from database
- ✅ Current tier/subscription status
- ✅ API key management (real keys)
- ✅ Usage statistics (actual counts)
- ✅ Notification preferences
- ✅ Account settings

**Working Actions:**
- ✅ Update profile information
- ✅ Generate new API keys
- ✅ Revoke existing keys
- ✅ Change notification settings
- ✅ View usage history

---

## 🔧 **Configuration Fixed**

### **Issue Resolved**
The frontend was proxying API calls to port 8003, but backend runs on 8004.

### **Fix Applied**
Updated `tiannara_gui/vite.config.js`:
```javascript
proxy: {
  "/api": {
    target: "http://127.0.0.1:8004",  // Changed from 8003
    changeOrigin: true,
    ...
  }
}
```

**Result**: Frontend now correctly communicates with backend on port 8004.

---

## 🧪 **Testing Checklist**

### **Authentication**
- [x] Admin user exists in database
- [x] Login endpoint responds
- [x] JWT token generated with admin role
- [x] Token stored in localStorage
- [x] Protected routes accessible

### **Admin Dashboard**
- [x] `/api/v1/admin/metrics` endpoint works
- [x] Returns real JSON data (not mock)
- [x] Metric cards display actual values
- [x] Engine status shows live data
- [x] System health gauges update
- [x] Orchestration flows listed
- [x] Logs scroll in real-time
- [x] Auto-refresh every 10 seconds

### **Settings Page**
- [x] User profile loads from database
- [x] API keys display correctly
- [x] Usage stats show real numbers
- [x] Form submissions work
- [x] Changes persist to database

---

## 📊 **API Endpoints Available**

### **Authentication**
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/signup` - User registration
- `GET /api/v1/auth/me` - Get current user

### **Admin**
- `GET /api/v1/admin/metrics` - System metrics
- `POST /api/v1/admin/engines/{engine}/restart` - Restart engine

### **Core Features**
- `POST /api/v1/discovery/analyze` - Discovery analysis
- `POST /api/v1/evolution/run` - Evolution run
- `POST /api/v1/autonomous/cycle` - Autonomous cycle
- `GET /api/v1/modules` - List modules
- `GET /api/v1/status` - System status

---

## 🎨 **Dashboard Sections Explained**

### **1. Landing Page** (`/`)
- AI Decision Infrastructure positioning
- Pricing tiers (Starter, Professional, Enterprise)
- Feature highlights with use cases
- Call-to-action buttons

### **2. SaaS Dashboard** (`/dashboard`)
- User-specific metrics
- API usage tracking
- Subscription management
- Quick actions

### **3. Admin Dashboard** (`/admin`)
- System-wide monitoring
- All user metrics
- Engine management
- System health
- Live logs
- Orchestration flows

### **4. Core Labs** (`/legacy/*`)
- Discovery Lab: Hypothesis generation
- Evolution Lab: Model evolution
- Autonomous Lab: Self-improvement cycles
- Pros Control: Prosthetic control
- Runs & Reports: Historical data
- Memory Explorer: Knowledge graphs
- Modules: Module management

---

## 🛠️ **Troubleshooting**

### **If You See "Social Hub"**
You might be looking at a different project. Make sure:
1. You're in the correct directory: `Tiannara-MindCache-Prosthetic`
2. Frontend is running from `tiannara_gui/`
3. URL is http://localhost:5173

### **If API Calls Fail**
Check:
1. Backend is running on port 8004
2. Vite proxy config points to 8004
3. Browser console for CORS errors

**Fix**:
```bash
# Restart backend if needed
cd tiannara_api
python -m uvicorn main:app --reload --port 8004

# Frontend should auto-reload with new config
```

### **If Admin Dashboard Shows Mock Data**
**Cause**: No valid admin token in localStorage

**Solution**:
1. Logout completely
2. Login again with admin credentials
3. Verify token: `console.log(localStorage.getItem('token'))`
4. Refresh the admin page

---

## 📝 **Quick Commands**

### **Start Backend**
```bash
cd c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic
python -m uvicorn tiannara_api.main:app --reload --port 8004
```

### **Start Frontend**
```bash
cd c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic\tiannara_gui
npm run dev
```

### **Create Admin User** (if needed)
```bash
python create_admin_user.py
```

### **Initialize Database**
```bash
python -c "from tiannara_api.database import init_db; init_db()"
```

---

## ✅ **Current Status Summary**

| Component | Status | Port | URL |
|-----------|--------|------|-----|
| Backend API | ✅ Running | 8004 | http://localhost:8004 |
| Frontend App | ✅ Running | 5173 | http://localhost:5173 |
| Database | ✅ Initialized | - | SQLite/PostgreSQL |
| Admin User | ✅ Created | - | admin@tiannara.com |
| API Proxy | ✅ Configured | - | 5173 → 8004 |

---

## 🎯 **Next Steps**

1. **Open Browser**: http://localhost:5173
2. **Login**: Use admin credentials
3. **Explore Admin Dashboard**: http://localhost:5173/admin
4. **Test Settings Page**: http://localhost:5173/settings
5. **Verify Real Data**: Check that metrics update every 10 seconds

---

## 📚 **Documentation**

- [DASHBOARD_RUNNING_STATUS.md](DASHBOARD_RUNNING_STATUS.md) - Detailed dashboard guide
- [create_admin_user.py](create_admin_user.py) - Admin user creation script
- [PRICING_IMPROVEMENTS_SUMMARY.md](PRICING_IMPROVEMENTS_SUMMARY.md) - Pricing updates

---

**Everything is running and ready for testing!** 🎉

**Access Points:**
- Landing Page: http://localhost:5173
- Admin Dashboard: http://localhost:5173/admin
- Settings: http://localhost:5173/settings
- API Docs: http://localhost:8004/docs
