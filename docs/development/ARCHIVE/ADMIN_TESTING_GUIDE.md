# Admin Dashboard Testing Guide

## Quick Start

### 1. Setup Admin User (One-time)

Run the admin setup script to create your admin account:

```bash
python setup_admin.py
```

**Default Credentials:**
- Email: `admin@tiannara.com`
- Password: `admin123`
- Role: ADMIN ✓

### 2. Start Backend Server

```bash
cd c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic
python -m uvicorn tiannara_api.main:app --reload --port 8003
```

The server should start on `http://localhost:8003`

### 3. Start Frontend Development Server

```bash
cd tiannara_gui
npm run dev
```

The frontend should start on `http://localhost:5173` (or next available port)

### 4. Login as Admin

1. Navigate to `http://localhost:5173/login`
2. Enter credentials:
   - Email: `admin@tiannara.com`
   - Password: `admin123`
3. Complete OTP verification (check console for code in dev mode)
4. You'll be redirected to the dashboard

### 5. Access Admin Dashboard

**Option A:** Click the purple "Admin" button in the top navigation bar

**Option B:** Directly navigate to `http://localhost:5173/admin`

---

## Testing Checklist

### ✅ Authentication & Authorization

- [ ] Login with admin credentials succeeds
- [ ] JWT token contains `is_admin: true` field
- [ ] Non-admin users cannot access `/admin` route (should get 403 error)
- [ ] Admin button only visible to admin users (future enhancement)

### ✅ Metrics Display

Verify all metrics cards show data:

- [ ] **Total API Requests**: Shows number with percentage change
- [ ] **Active Users**: Displays count with trend indicator
- [ ] **Average Latency**: Shows ms value with performance trend
- [ ] **Success Rate**: Displays percentage (should be ~99.7%)

### ✅ Domain Engine Status

Check all 4 engines are displayed:

- [ ] **Predict Engine**: Status, version, requests, health bar
- [ ] **Analyze Engine**: Status, version, requests, health bar
- [ ] **Reason Engine**: Status, version, requests, health bar
- [ ] **NLP Engine**: Status, version, requests, health bar

Each engine should show:
- [ ] Green status indicator (running)
- [ ] Version number (e.g., v1.5.3)
- [ ] Request count (randomized 10k-50k)
- [ ] Health bar at 100%
- [ ] Restart button

### ✅ System Health Monitor

Verify resource monitoring:

- [ ] **CPU Usage**: Progress bar with percentage
- [ ] **Memory Usage**: Progress bar with percentage
- [ ] **Disk Usage**: Progress bar with percentage
- [ ] **Network I/O**: Progress bar with percentage
- [ ] **Uptime**: Shows 99.98%

Color coding:
- Green: < 60%
- Yellow: 60-80%
- Red: > 80%

### ✅ Orchestration Flows

Check workflow status display:

- [ ] Data Ingestion Pipeline (active)
- [ ] Model Training Workflow (queued)
- [ ] Analytics Processing (completed)
- [ ] Report Generation (failed)

Each flow shows:
- [ ] Flow name
- [ ] Status badge (color-coded)
- [ ] Duration

### ✅ Recent Logs Terminal

Verify log display:

- [ ] Shows recent system logs
- [ ] Timestamps formatted correctly
- [ ] Log levels color-coded:
  - INFO: Green
  - WARN: Yellow
  - ERROR: Red
- [ ] Scrollable if more than 20 logs
- [ ] At least 10 sample logs visible

### ✅ Interactive Features

Test all interactive elements:

- [ ] **Refresh Button**: Manually refreshes all metrics
- [ ] **Restart Engine Button**: Opens confirmation modal
- [ ] **Modal Cancel**: Closes modal without action
- [ ] **Modal Restart**: Initiates engine restart
- [ ] Auto-refresh every 10 seconds (watch metrics update)

### ✅ API Endpoint Testing

Test backend endpoints directly:

#### 1. Get Admin Metrics
```bash
curl -X GET "http://localhost:8003/api/v1/admin/metrics" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

Expected response structure:
```json
{
  "metrics": {...},
  "engines": [...],
  "system_health": {...},
  "flows": [...],
  "recent_logs": [...]
}
```

#### 2. Restart Engine
```bash
curl -X POST "http://localhost:8003/api/v1/admin/engines/predict/restart" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

Expected response:
```json
{
  "status": "restarting",
  "engine": "predict",
  "message": "Engine 'predict' restart initiated successfully"
}
```

#### 3. Get All Engines
```bash
curl -X GET "http://localhost:8003/api/v1/admin/engines" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

#### 4. Get System Logs
```bash
curl -X GET "http://localhost:8003/api/v1/admin/logs?limit=50" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

---

## Troubleshooting

### Issue: Cannot access /admin route

**Solution:**
1. Verify you're logged in as admin user
2. Check browser console for authentication errors
3. Ensure JWT token is stored in localStorage
4. Try logging out and back in

### Issue: 403 Forbidden when accessing admin endpoints

**Solution:**
1. Run `python setup_admin.py` to create admin user
2. Verify user has `is_admin: true` in database
3. Check that JWT token includes admin flag
4. Restart backend server after creating admin user

### Issue: Metrics not updating

**Solution:**
1. Check browser console for API errors
2. Verify backend is running on port 8003
3. Check network tab for failed requests
4. Ensure CORS is configured correctly

### Issue: Mock data showing instead of real data

**Current Behavior:** This is expected! The backend currently returns mock data for demonstration.

**To enable real data:**
1. Implement actual database queries in `admin.py`
2. Connect to Tiannara Core instance
3. Replace mock values with real metrics from system

### Issue: Engine restart not working

**Solution:**
1. Check backend logs for errors
2. Verify engine name is valid (predict/analyze/reason/nlp)
3. Ensure core instance is initialized
4. Check audit log at `logs/admin_audit.log`

---

## Advanced Testing

### Load Testing

Test dashboard under load:

```bash
# Simulate multiple admin users
for i in {1..10}; do
  curl -X GET "http://localhost:8003/api/v1/admin/metrics" \
    -H "Authorization: Bearer $ADMIN_TOKEN" &
done
```

### Security Testing

Verify security measures:

1. **Unauthorized Access:**
   ```bash
   curl -X GET "http://localhost:8003/api/v1/admin/metrics"
   # Should return 401 Unauthorized
   ```

2. **Non-Admin Access:**
   ```bash
   curl -X GET "http://localhost:8003/api/v1/admin/metrics" \
     -H "Authorization: Bearer USER_TOKEN"
   # Should return 403 Forbidden
   ```

3. **Invalid Token:**
   ```bash
   curl -X GET "http://localhost:8003/api/v1/admin/metrics" \
     -H "Authorization: Bearer invalid_token"
   # Should return 401 Unauthorized
   ```

### Performance Testing

Measure response times:

```bash
# Time the metrics endpoint
time curl -X GET "http://localhost:8003/api/v1/admin/metrics" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

Expected: < 500ms for initial load

---

## Browser Console Debugging

Open browser DevTools (F12) and check:

### Network Tab
- Look for requests to `/api/v1/admin/metrics`
- Verify status code is 200
- Check response payload structure
- Monitor request timing

### Console Tab
- Watch for JavaScript errors
- Check for authentication warnings
- Verify WebSocket connections (if enabled)

### Application Tab
- Check localStorage for `token` key
- Verify token is valid JWT
- Inspect token payload for `is_admin: true`

---

## Expected Behavior Summary

| Feature | Expected Result |
|---------|----------------|
| Login | Successful with admin credentials |
| Admin Button | Visible in dashboard header |
| Navigation | Routes to /admin successfully |
| Metrics | Display with realistic values |
| Engines | All 4 shown with green status |
| Health Bars | Color-coded progress indicators |
| Logs | 10+ entries with timestamps |
| Refresh | Updates all metrics |
| Restart | Opens modal, confirms action |
| Auto-refresh | Updates every 10 seconds |
| Mobile | Responsive layout works |

---

## Next Steps After Testing

### Immediate Improvements
1. Replace mock data with real database queries
2. Add WebSocket support for live updates
3. Implement proper audit logging
4. Add user management interface

### Future Enhancements
1. Real-time charts and graphs
2. Alerting system for anomalies
3. Historical data analysis
4. Custom dashboard widgets
5. Export reports functionality

---

## Support

If you encounter issues:

1. Check this troubleshooting guide
2. Review backend logs for errors
3. Inspect browser console for client-side issues
4. Verify all services are running
5. Contact development team with error details

**Log Locations:**
- Backend: Terminal output + `logs/` directory
- Frontend: Browser console (F12)
- Audit: `logs/admin_audit.log`

---

## Success Criteria

✅ Admin user can login  
✅ Admin dashboard loads without errors  
✅ All metrics display correctly  
✅ Engine status is visible  
✅ System health monitoring works  
✅ Logs are displayed  
✅ Interactive features function  
✅ API endpoints respond correctly  
✅ Security restrictions enforced  
✅ Auto-refresh updates data  

If all checkboxes are complete, the admin dashboard is ready for production use!
