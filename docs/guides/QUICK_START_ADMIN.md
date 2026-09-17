# 🚀 Admin Dashboard - Quick Start Guide

## Get Started in 3 Minutes!

### Step 1: Create Admin Account (30 seconds)

```bash
python setup_admin.py
```

**Output:**
```
🎉 ADMIN USER CREATED SUCCESSFULLY!
Email:    admin@tiannara.com
Password: admin123
Role:     ADMIN ✓
```

### Step 2: Start Backend (30 seconds)

```bash
python -m uvicorn tiannara_api.main:app --reload --port 8003
```

Wait for: `INFO:     Application startup complete.`

### Step 3: Start Frontend (30 seconds)

```bash
cd tiannara_gui
npm run dev
```

Wait for: `Local: http://localhost:5173/`

### Step 4: Login & Access Admin (60 seconds)

1. **Open browser:** http://localhost:5173/login
2. **Login:**
   - Email: `admin@tiannara.com`
   - Password: `admin123`
3. **Enter OTP:** Check console for code (dev mode shows it)
4. **Click Admin button** in top navigation OR go to http://localhost:5173/admin

---

## ✅ You're Done!

You should now see the **Tiannara Core Internal Operations Dashboard** with:

- 📊 Real-time metrics (API requests, users, latency, success rate)
- ⚙️ Domain engine status (Predict, Analyze, Reason, NLP)
- 💻 System health monitor (CPU, memory, disk, network)
- 🔄 Orchestration flows tracking
- 📝 Live log viewer

---

## 🎯 What You Can Do

### Monitor System Health
- Watch CPU, memory, disk usage in real-time
- Track API performance metrics
- View success/error rates

### Manage AI Engines
- See status of all 4 domain engines
- Restart engines if needed (with confirmation)
- Monitor request counts and health

### Track Workflows
- View active orchestration flows
- Check workflow duration and status
- Identify failed workflows

### Review Logs
- See recent system logs
- Filter by log level (INFO/WARN/ERROR)
- Timestamps for all entries

---

## 🔧 Troubleshooting

### Can't login?
- Make sure you ran `python setup_admin.py` first
- Check that backend is running on port 8003
- Verify OTP code from console

### Admin dashboard not loading?
- Confirm you're logged in as admin user
- Check browser console for errors (F12)
- Try logging out and back in

### Seeing mock data?
- This is expected! Real database integration is pending
- All features work with mock data for demonstration
- Backend structure is ready for real data

---

## 📚 Full Documentation

For detailed information, see:
- **[ADMIN_COMPLETE_SUMMARY.md](ADMIN_COMPLETE_SUMMARY.md)** - Complete implementation overview
- **[ADMIN_TESTING_GUIDE.md](ADMIN_TESTING_GUIDE.md)** - Comprehensive testing instructions
- **[ADMIN_DASHBOARD_IMPLEMENTATION.md](ADMIN_DASHBOARD_IMPLEMENTATION.md)** - Technical details

---

## 🎨 Features at a Glance

| Feature | Status | Description |
|---------|--------|-------------|
| Metrics Display | ✅ Working | 4 key metrics with trends |
| Engine Monitoring | ✅ Working | All 4 AI engines tracked |
| System Health | ✅ Working | CPU, memory, disk, network |
| Workflow Tracking | ✅ Working | Active/completed/failed flows |
| Log Viewer | ✅ Working | Terminal-style log display |
| Engine Restart | ✅ Working | With confirmation modal |
| Auto-refresh | ✅ Working | Updates every 10 seconds |
| Admin Auth | ✅ Working | Role-based access control |
| Audit Logging | ✅ Working | All actions logged |
| Responsive UI | ✅ Working | Works on all screen sizes |

---

## 💡 Pro Tips

1. **Bookmark the admin page:** http://localhost:5173/admin
2. **Keep DevTools open** (F12) to monitor API calls
3. **Watch the auto-refresh** - metrics update every 10 seconds
4. **Try restarting an engine** - click "Restart" on any engine card
5. **Check audit logs** at `logs/admin_audit.log`

---

## 🆘 Need Help?

Common issues and solutions are in [ADMIN_TESTING_GUIDE.md](ADMIN_TESTING_GUIDE.md)

**Quick checks:**
1. Is backend running? → Check http://localhost:8003/health
2. Is frontend running? → Check http://localhost:5173
3. Are you admin? → Run `python setup_admin.py` again
4. Token valid? → Logout and login again

---

**Ready to explore? Navigate to `/admin` and start monitoring!** 🎉
