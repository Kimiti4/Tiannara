# Tiannara SaaS - Next.js Admin Dashboard Setup

## ✅ What's Been Added

### 1. Admin Dashboard Page
- **Location**: `app/admin/page.tsx`
- **Features**:
  - Real-time system metrics (CPU, memory, disk, network)
  - Domain engine monitoring (Predict/Analyze/Reason/NLP)
  - Engine restart controls
  - Live log viewer
  - Tabbed interface (Overview/Engines/Logs)
  - Auto-refresh every 10 seconds
  - Mock data fallback if backend unavailable

### 2. Navigation Integration
- **Updated**: `app/dashboard/layout.tsx`
- Added "Admin Dashboard" link in sidebar under "Admin" section
- Purple styling to distinguish admin features

---

## 🚀 Quick Start

### Step 1: Create Admin User

Run this script to create an admin account:

```bash
cd c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic
python setup_admin.py
```

**Default Credentials:**
- Email: `admin@tiannara.com`
- Password: `admin123`

### Step 2: Start Backend Server

```bash
cd c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic
python -m uvicorn tiannara_api.main:app --reload --port 8003
```

Backend will be available at: `http://localhost:8003`

### Step 3: Start Next.js Frontend

```bash
cd c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic\tiannara_saas
npm run dev
```

Frontend will be available at: `http://localhost:3000`

### Step 4: Login & Access Admin Dashboard

1. Open browser: `http://localhost:3000/login`
2. Login with admin credentials
3. Navigate to: `http://localhost:3000/admin`
   - OR click "Admin Dashboard" in the sidebar

---

## 🔑 Authentication Flow

The admin dashboard uses JWT token authentication:

1. User logs in → receives JWT token
2. Token stored in `localStorage` as `'token'`
3. Admin page fetches metrics with token in Authorization header
4. Backend verifies admin role via `verify_admin_role()` middleware
5. Returns 403 Forbidden if user is not admin

---

## 📊 API Endpoints Used

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/admin/metrics` | GET | Fetch all admin metrics |
| `/api/v1/admin/engines/{name}/restart` | POST | Restart specific engine |
| `/api/v1/admin/users` | GET | List all users (future) |
| `/api/v1/admin/logs` | GET | Fetch recent logs (future) |

---

## 🎨 Features

### Overview Tab
- **Key Metrics**: Total requests, active users, latency, success rate
- **System Health**: CPU, memory, disk, network usage bars
- **Engine Status**: Running/stopped indicators with uptime and request counts
- **Quick Actions**: Restart engines directly from overview

### Engines Tab
- Detailed view of each domain engine
- Individual restart buttons
- Performance metrics per engine
- Status indicators (running/stopped/error)

### Logs Tab
- Terminal-style log viewer
- Color-coded log levels (ERROR/WARN/INFO)
- Timestamps for each entry
- Scrollable history

---

## 🔧 Customization

### Change Refresh Interval

Edit `app/admin/page.tsx`:

```typescript
// Line ~47
const interval = setInterval(fetchMetrics, 10000) // 10 seconds
```

Change `10000` to desired milliseconds.

### Update Backend URL

Edit `app/admin/page.tsx`:

```typescript
// Line ~63
const response = await fetch('http://localhost:8003/api/v1/admin/metrics', {
```

Change to your production backend URL.

### Modify Mock Data

Edit `setMockData()` function around line 95 in `app/admin/page.tsx`.

---

## 🛡️ Security Notes

1. **Admin Role Required**: Only users with `is_admin: true` can access
2. **JWT Validation**: All requests require valid bearer token
3. **Audit Logging**: All admin actions logged to `logs/admin_audit.log`
4. **No Client-Side Secrets**: All sensitive operations server-side

---

## 🐛 Troubleshooting

### Issue: "Not authenticated" error

**Solution**: 
1. Make sure you're logged in
2. Check localStorage has token: `localStorage.getItem('token')`
3. Try logging out and back in

### Issue: "Failed to load metrics"

**Solution**:
1. Verify backend is running on port 8003
2. Check browser console for CORS errors
3. Ensure admin user exists (`python setup_admin.py`)

### Issue: 403 Forbidden

**Solution**:
1. User doesn't have admin role
2. Run `python setup_admin.py` to create/upgrade admin account
3. Logout and login again to refresh token

### Issue: Admin link not showing in sidebar

**Solution**:
1. Clear browser cache
2. Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
3. Verify `app/dashboard/layout.tsx` has admin navigation code

---

## 📝 Development Tips

### Hot Reload
Next.js Turbopack provides instant hot reload. Changes to `app/admin/page.tsx` will reflect immediately.

### TypeScript Support
All components are fully typed. Add interfaces as needed.

### Component Reusability
Helper components (`MetricCard`, `HealthBar`) can be extracted to separate files for reuse.

### State Management
Currently using React `useState`. For complex state, consider:
- Context API
- Zustand
- Redux Toolkit

---

## 🔄 Migration from Vite Version

If migrating from `tiannara_gui` (Vite):

### Key Differences
| Vite (React) | Next.js |
|--------------|---------|
| `import React, { useState }` | `'use client'` directive |
| `<Router>` | File-based routing |
| `export default function` | Same |
| `.jsx` files | `.tsx` files |
| Vite config | `next.config.ts` |

### Files Migrated
- ✅ `AdminDashboard.jsx` → `app/admin/page.tsx`
- ✅ Sidebar navigation updated
- ⏳ Settings page (not yet migrated)
- ⏳ Billing page (already exists in Next.js)

---

## 📚 Additional Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [Next.js App Router](https://nextjs.org/docs/app)
- [Lucide Icons](https://lucide.dev/icons)
- [Tailwind CSS](https://tailwindcss.com/docs)

---

## 🎯 Next Steps

1. ✅ Admin dashboard created
2. ✅ Navigation integrated
3. ⏳ Add real database queries (replace mock data)
4. ⏳ Implement WebSocket for real-time updates
5. ⏳ Add user management page
6. ⏳ Add advanced log filtering
7. ⏳ Add export functionality (CSV/PDF)

---

**Status**: ✅ Ready to use!

Start the servers and visit `http://localhost:3000/admin` to see it in action.
