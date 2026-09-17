# Audit Endpoints Testing Guide

**Date**: May 1, 2026  
**Status**: ⏳ **PENDING SERVER RESTART**

---

## 🚨 **Current Issue**

The backend server appears to be unresponsive. The audit routes have been implemented and import successfully, but the server needs to be restarted to pick up the new routes.

---

## 🔧 **How to Test After Server Restart**

### **Step 1: Restart Backend Server**

```bash
# Stop current server (Ctrl+C in the terminal where it's running)
# Then restart:
cd c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic
python -m uvicorn tiannara_api.main:app --reload --port 8004
```

### **Step 2: Get Authentication Token**

```bash
curl -X POST http://localhost:8004/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@tiannara.com", "password": "admin123"}' \
  > /tmp/login_response.json

# Extract token
TOKEN=$(python -c "import json; data=json.load(open('/tmp/login_response.json')); print(data['data']['token'])")
echo "Token: $TOKEN"
```

### **Step 3: Test Audit Endpoints**

#### **Test 1: List All Audit Logs**
```bash
curl http://localhost:8004/api/v1/audit/logs \
  -H "Authorization: Bearer $TOKEN" \
  | python -m json.tool
```

**Expected:** Empty list `[]` (no logs yet) or list of existing logs

---

#### **Test 2: Filter by Action Type**
```bash
curl "http://localhost:8004/api/v1/audit/logs?action=workspace.create" \
  -H "Authorization: Bearer $TOKEN" \
  | python -m json.tool
```

**Expected:** Logs filtered by workspace creation actions

---

#### **Test 3: Filter by Date Range**
```bash
curl "http://localhost:8004/api/v1/audit/logs?start_date=2026-05-01&end_date=2026-05-31" \
  -H "Authorization: Bearer $TOKEN" \
  | python -m json.tool
```

**Expected:** Logs within the specified date range

---

#### **Test 4: Workspace Activity History**
```bash
# First, get a workspace ID
WORKSPACE_ID=$(curl -s http://localhost:8004/api/v1/workspaces \
  -H "Authorization: Bearer $TOKEN" \
  | python -c "import sys, json; data=json.load(sys.stdin); print(data[0]['id'] if data else '')")

# Then get activity
curl "http://localhost:8004/api/v1/audit/workspace/$WORKSPACE_ID/activity" \
  -H "Authorization: Bearer $TOKEN" \
  | python -m json.tool
```

**Expected:** List of activities for that workspace

---

#### **Test 5: Security Alerts (Admin Only)**
```bash
curl "http://localhost:8004/api/v1/audit/security/alerts?hours=24" \
  -H "Authorization: Bearer $TOKEN" \
  | python -m json.tool
```

**Expected:** List of security-related events in last 24 hours

---

#### **Test 6: Pagination**
```bash
curl "http://localhost:8004/api/v1/audit/logs?limit=10&offset=0" \
  -H "Authorization: Bearer $TOKEN" \
  | python -m json.tool
```

**Expected:** First 10 logs

---

## 📊 **What to Verify**

✅ **Endpoint Accessibility** - All routes respond without 404 errors  
✅ **Authentication** - Requires valid JWT token  
✅ **Authorization** - Non-admin users see only their own logs  
✅ **Filtering** - Action, date, email filters work correctly  
✅ **Pagination** - Limit and offset parameters work  
✅ **Response Format** - Returns proper JSON with all fields  

---

## 🐛 **Common Issues & Solutions**

### **Issue 1: 404 Not Found**
**Cause:** Server hasn't reloaded with new routes  
**Solution:** Restart the backend server

### **Issue 2: 401 Unauthorized**
**Cause:** Invalid or missing JWT token  
**Solution:** Re-login and get fresh token

### **Issue 3: 403 Forbidden**
**Cause:** Trying to access admin-only endpoint as non-admin  
**Solution:** Use admin credentials or different endpoint

### **Issue 4: Empty Results**
**Cause:** No audit logs created yet  
**Solution:** Perform some actions (create workspace, invite member) to generate logs

---

## 🎯 **Next Steps After Testing**

Once endpoints are verified working:

1. **Integrate automatic logging** into workspace routes
2. **Add logging middleware** for all API requests
3. **Implement log retention policy** (auto-delete old logs)
4. **Add real-time WebSocket feed** for live monitoring
5. **Create audit dashboard UI** in frontend

---

## 📝 **Sample Audit Log Entry**

```json
{
  "id": "audit_abc123...",
  "action": "workspace.create",
  "resource_type": "workspace",
  "resource_id": "ws_xyz789...",
  "user_id": "user_def456...",
  "user_email": "admin@tiannara.com",
  "ip_address": "127.0.0.1",
  "request_method": "POST",
  "request_path": "/api/v1/workspaces",
  "status_code": "201",
  "success": true,
  "error_message": null,
  "metadata": "{\"workspace_name\": \"My Team\"}",
  "created_at": "2026-05-01T12:00:00+00:00"
}
```

---

**Status:** Ready for testing after server restart! 🚀
