# Admin Dashboard - Organization Management

## Overview
The Tiannara SaaS platform includes a comprehensive **Admin Dashboard** for organization administrators to manage users, monitor system health, and control RBAC (Role-Based Access Control).

---

## ✅ Admin Dashboard Features

### 📍 Location: `/admin`

The admin dashboard provides internal operations monitoring and management capabilities for organization admins.

### **Key Sections:**

#### 1. **Overview Tab** (`/admin`)
- **Real-time Metrics:**
  - Total API Requests (with trend indicators)
  - Active Users count
  - Average Latency tracking
  - Success Rate percentage
  
- **System Health Monitoring:**
  - CPU Usage (with color-coded thresholds)
  - Memory utilization
  - Disk space usage
  - Network bandwidth
  
- **Domain Engine Status:**
  - Live status indicators (running/stopped/error)
  - Uptime tracking
  - Request counts per engine
  - Average response times
  - One-click restart capability
  
- **Hover Tooltips:** All metrics include detailed explanations on hover

#### 2. **Domain Engines Tab** (`/admin?tab=engines`)
- Detailed view of each AI engine
- Individual engine cards with:
  - Status badges
  - Performance metrics
  - Restart controls
- Real-time status updates

#### 3. **Live Logs Tab** (`/admin?tab=logs`)
- Terminal-style log viewer
- Color-coded log levels (ERROR, WARN, INFO)
- Timestamps for all entries
- Scrollable log history
- Last N entries display

#### 4. **User Management** (`/admin/users`)
- Complete user administration interface
- **Features:**
  - User list with search and filtering
  - Role assignment (Admin, Member, Viewer)
  - Status management (Active/Inactive/Pending)
  - Invite new users
  - Edit user details
  - Activate/Deactivate accounts
  - Remove users
  - View user activity stats

---

## 🔐 Role-Based Access Control (RBAC)

### **Three-Tier Role System:**

#### **Admin Role**
- ✅ Full access to all features
- ✅ Manage users and roles
- ✅ View system logs and metrics
- ✅ Configure organization settings
- ✅ Manage billing and subscriptions
- ✅ Access admin dashboard
- ✅ Restart domain engines

#### **Member Role**
- ✅ Create and manage workflows
- ✅ View analytics and insights
- ✅ Run automations
- ✅ Access API keys
- ✅ Collaborate with team
- ❌ Cannot manage users
- ❌ Cannot access admin dashboard
- ❌ Cannot modify billing

#### **Viewer Role**
- ✅ View dashboards and reports
- ✅ Read-only access to workflows
- ✅ View analytics
- ❌ Cannot modify settings
- ❌ Cannot create resources
- ❌ Cannot access admin features
- ❌ Cannot manage API keys

---

## 📊 User Management Interface

### **Location:** `/admin/users`

### **Features:**

1. **User Statistics Cards:**
   - Total Users count
   - Active Users count
   - Admin count
   - Pending invitations

2. **Search & Filter:**
   - Search by name or email
   - Filter by role (All/Admin/Member/Viewer)
   - Real-time filtering

3. **User Table:**
   - User avatar (initials)
   - Name and email
   - Role badge (color-coded)
   - Status badge (Active/Inactive/Pending)
   - Workflow count
   - Last active timestamp
   - Action buttons:
     - 👁️ View Details
     - ✏️ Edit User
     - 🔒/🔓 Toggle Status
     - 🗑️ Remove User

4. **Role Permissions Display:**
   - Visual breakdown of each role's capabilities
   - Helps admins understand permission levels
   - Clear distinction between roles

5. **Invite User Modal:**
   - Add new team members
   - Assign initial role
   - Send invitation email

---

## 🎯 Use Cases

### **For Organization Admins:**

1. **Monitor System Health:**
   - Check CPU/memory usage trends
   - Identify performance bottlenecks
   - Track API request volumes
   - Monitor success rates

2. **Manage Team Members:**
   - Onboard new employees
   - Assign appropriate roles
   - Deactivate former employees
   - Review user activity

3. **Troubleshoot Issues:**
   - View live logs for debugging
   - Check engine status
   - Restart failed engines
   - Monitor error rates

4. **Control Access:**
   - Implement least-privilege principle
   - Restrict sensitive operations
   - Audit user permissions
   - Maintain security compliance

---

## 🔧 Technical Implementation

### **Authentication:**
- Token-based authentication required
- Redirects to `/login` if not authenticated
- Checks `localStorage.getItem('tiannara_token')`
- Protected routes enforce auth checks

### **API Integration:**
- Fetches real-time metrics from backend
- Endpoint: `/api/v1/admin/metrics`
- Auto-refresh every 10 seconds
- Fallback to mock data if API unavailable

### **State Management:**
- React hooks for local state
- `useState` for UI state
- `useEffect` for data fetching
- Real-time updates via polling

### **UI Components:**
- Tailwind CSS for styling
- Lucide React icons
- Responsive design (mobile-friendly)
- Dark theme with purple accents
- Hover tooltips for all metrics

---

## 📁 File Structure

```
tiannara_saas/app/admin/
├── page.tsx              # Main admin dashboard
└── users/
    └── page.tsx          # User management interface
```

---

## 🚀 Navigation

### **From Customer Dashboard:**
Admin users can access the admin dashboard through:
1. Direct URL: `/admin`
2. Future: Add "Admin Panel" link in customer dashboard sidebar (for users with admin role)

### **From Admin Dashboard:**
- Back button to return to customer dashboard
- Tab navigation between Overview/Engines/Logs
- User Management button in top navigation

---

## 📈 Metrics Explained

### **Total Requests:**
- Total API requests processed across all services
- Includes discovery, evolution, and autonomous operations
- Shows percentage change from previous period

### **Active Users:**
- Unique users who made API calls in last 24 hours
- Indicates platform engagement
- Tracks user growth trends

### **Average Latency:**
- Mean response time for all API requests
- Target: <200ms
- Lower is better (inverse metric)

### **Success Rate:**
- Percentage of successful API responses (2xx status codes)
- Target: >99%
- Critical reliability indicator

### **System Health Thresholds:**

| Resource | Healthy | Warning | Critical |
|----------|---------|---------|----------|
| CPU      | <60%    | 60-80%  | >80%     |
| Memory   | <60%    | 60-80%  | >80%     |
| Disk     | <60%    | 60-80%  | >80%     |
| Network  | <60%    | 60-80%  | >80%     |

---

## 🔒 Security Considerations

1. **Authentication Required:**
   - All admin routes protected by token validation
   - Automatic redirect if not authenticated

2. **Role Verification:**
   - Backend should verify user has admin role
   - Frontend checks are UX only, not security

3. **Sensitive Operations:**
   - Engine restart requires confirmation
   - User deletion requires confirmation
   - Audit trail for all admin actions (future)

4. **Data Privacy:**
   - User emails visible only to admins
   - Activity logs accessible to authorized personnel
   - No PII exposed in client-side code

---

## 🎨 Design Principles

1. **Clarity:** All metrics clearly labeled with tooltips
2. **Actionability:** Quick actions available (restart, invite, etc.)
3. **Visibility:** System health at-a-glance
4. **Efficiency:** Minimal clicks to perform common tasks
5. **Consistency:** Matches overall Tiannara design language

---

## 📝 Future Enhancements

### **Planned Features:**
1. **Audit Log:** Track all admin actions with timestamps
2. **Activity Timeline:** Visual user activity history
3. **Bulk Operations:** Select multiple users for batch actions
4. **Export Data:** Download user lists as CSV
5. **Two-Factor Authentication:** Enhanced security for admin accounts
6. **IP Whitelisting:** Restrict admin access to specific IPs
7. **Session Management:** View and revoke active sessions
8. **Permission Templates:** Pre-defined role configurations
9. **Organization Settings:** Branding, SSO, custom domains
10. **Billing Integration:** Usage-based billing, invoices, payment methods

---

## ✅ Current Status

**Implementation:** ✅ Complete  
**Testing:** Ready for QA  
**Backend Integration:** Requires API endpoints  
**Documentation:** This file  

---

**Last Updated:** April 30, 2026  
**Maintained By:** Tiannara Engineering Team
