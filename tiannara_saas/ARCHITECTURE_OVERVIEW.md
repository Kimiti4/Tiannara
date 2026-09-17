# Tiannara SaaS Architecture Overview

## Complete System Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                    TIANNARA SAAS PLATFORM                        │
└─────────────────────────────────────────────────────────────────┘
                              │
            ┌─────────────────┴─────────────────┐
            │                                   │
    ┌───────▼────────┐              ┌──────────▼──────────┐
    │  PUBLIC PAGES   │              │  AUTHENTICATED      │
    │  (No Login)     │              │  (Requires Auth)    │
    └───────┬────────┘              └──────────┬──────────┘
            │                                   │
    ┌───────▼────────┐              ┌──────────▼──────────┐
    │ • Landing Page  │              │                     │
    │ • Pricing       │              │   CUSTOMER DASHBOARD│
    │ • Features      │              │   (Layer 2-3)       │
    │ • Use Cases     │              │                     │
    │ • API Docs      │              │  ┌────────────────┐ │
    │ • Login/Signup  │              │  │ Onboarding     │ │
    └────────────────┘              │  │ (First Login)  │ │
                                    │  └───────┬────────┘ │
                                    │          │           │
                                    │  ┌───────▼────────┐ │
                                    │  │ Main Dashboard │ │
                                    │  │ • Stats Cards  │ │
                                    │  │ • Workflows    │ │
                                    │  │ • Insights     │ │
                                    │  └───────┬────────┘ │
                                    │          │           │
                                    │  ┌───────▼────────┐ │
                                    │  │ Sidebar Nav:   │ │
                                    │  │                │ │
                                    │  │ MAIN:          │ │
                                    │  │ • Dashboard    │ │
                                    │  │ • Workflows ▼  │ │
                                    │  │   - All        │ │
                                    │  │   - Templates  │ │
                                    │  │ • Automations  │ │
                                    │  │ • Analytics    │ │
                                    │  │ • Forecasting  │ │
                                    │  │                │ │
                                    │  │ WORKSPACE:     │ │
                                    │  │ • Team         │ │
                                    │  │ • API Access   │ │
                                    │  │ • Billing      │ │
                                    │  │ • Settings     │ │
                                    │  └────────────────┘ │
                                    └─────────────────────┘
                                              │
                        ┌─────────────────────┼─────────────────────┐
                        │                     │                     │
              ┌─────────▼─────────┐  ┌───────▼────────┐  ┌───────▼────────┐
              │ INTELLIGENCE LAYER│  │ TEAM WORKSPACE │  │ ADMIN DASHBOARD│
              │ (Layer 3)         │  │                │  │ (Org Admins)   │
              │                   │  │ • Teams Mgmt   │  │                │
              │ • Workflow Builder│  │ • Shared Flows │  │ • Sys Monitor  │
              │ • Visual Editor   │  │ • Activity Log │  │ • User Mgmt    │
              │ • Templates       │  │ • Permissions  │  │ • Domain Eng.  │
              │ • Components Panel│  └────────────────┘  │ • Live Logs    │
              │ • Output Preview  │                      │ • RBAC Control │
              └───────────────────┘                      └────────────────┘
```

---

## Two Distinct User Journeys

### 🎯 **Customer Journey** (SaaS Users)
```
Landing Page → Sign Up → Payment → Onboarding Wizard → Customer Dashboard
                                                              │
                                              ┌───────────────┴───────────────┐
                                              │                               │
                                      Build Workflows                 Manage Team
                                      Run Automations                 View Analytics
                                      Get Insights                    Monitor Usage
```

**Focus:** Business outcomes, ease of use, no technical complexity

---

### 🔧 **Admin Journey** (Organization Admins)
```
Login → Admin Dashboard → System Monitoring
                              │
              ┌───────────────┼───────────────┐
              │               │               │
        View Metrics    Manage Users    Check Logs
        Restart Engines Assign Roles   Debug Issues
        Track Health    Audit Activity Monitor Errors
```

**Focus:** System health, user management, operational control

---

## Key Architectural Decisions

### 1. **Separation of Concerns**
- **Customer Dashboard:** Business-focused, user-friendly naming
- **Admin Dashboard:** Technical monitoring, internal operations
- **No overlap:** Each serves distinct purposes

### 2. **Progressive Disclosure**
- Layer 1: Onboarding (guides new users)
- Layer 2: Workspace (main dashboard)
- Layer 3: Intelligence (advanced features)

### 3. **User-Friendly Naming Translation**
```
Technical Term          →  Customer-Facing Name
─────────────────────────────────────────────────
Causal Engine           →  Root Cause Analysis
Reverse Engineering     →  Pattern Intelligence
Prediction Domain       →  Forecasting
Workflow Orchestrator   →  Automation Engine
```

### 4. **Role-Based Access Control**
```
Admin Role:
  ✓ Full system access
  ✓ User management
  ✓ Admin dashboard
  ✓ Billing control

Member Role:
  ✓ Create workflows
  ✓ View analytics
  ✓ Run automations
  ✗ No admin access

Viewer Role:
  ✓ Read-only dashboards
  ✓ View reports
  ✗ No modifications
  ✗ No admin access
```

---

## File Organization

```
tiannara_saas/
├── app/
│   ├── page.tsx                    # Landing page (public)
│   ├── pricing/page.tsx            # Pricing page (public)
│   ├── login/page.tsx              # Login (public)
│   ├── signup/page.tsx             # Signup (public)
│   │
│   ├── onboarding/                 # Layer 1: Onboarding
│   │   └── page.tsx
│   │
│   ├── dashboard/                  # Layer 2-3: Customer Dashboard
│   │   ├── layout.tsx              # Sidebar + Topbar layout
│   │   ├── page.tsx                # Main dashboard
│   │   │
│   │   ├── workflows/              # Intelligence Layer
│   │   │   ├── page.tsx            # Workflows list
│   │   │   ├── templates/page.tsx  # Template gallery
│   │   │   └── [id]/page.tsx       # Workflow builder
│   │   │
│   │   ├── automations/page.tsx    # Automation hub
│   │   ├── analytics/page.tsx      # Analytics center
│   │   ├── forecasting/page.tsx    # Forecasting center
│   │   ├── team/page.tsx           # Team workspace
│   │   ├── keys/page.tsx           # API access
│   │   ├── billing/page.tsx        # Billing
│   │   └── settings/page.tsx       # Settings
│   │
│   └── admin/                      # Admin Dashboard (separate)
│       ├── page.tsx                # System monitoring
│       └── users/page.tsx          # User management + RBAC
│
├── components/                     # Reusable UI components
├── lib/                            # Utilities and helpers
└── IMPLEMENTATION_STATUS.md        # Implementation tracking
```

---

## Navigation Flow

### **Customer Navigation:**
```
/dashboard
  ├── /dashboard/workflows
  │     ├── /dashboard/workflows (list)
  │     ├── /dashboard/workflows/templates
  │     └── /dashboard/workflows/[id] (builder)
  ├── /dashboard/automations
  ├── /dashboard/analytics
  ├── /dashboard/forecasting
  ├── /dashboard/team
  ├── /dashboard/keys
  ├── /dashboard/billing
  └── /dashboard/settings
```

### **Admin Navigation:**
```
/admin
  ├── /admin (overview tab)
  ├── /admin?tab=engines
  ├── /admin?tab=logs
  └── /admin/users (user management)
```

---

## Authentication & Authorization

### **Public Routes** (No auth required):
- `/` (Landing)
- `/pricing`
- `/login`
- `/signup`
- `/docs`

### **Protected Routes** (Auth required):
- `/dashboard/*` (Customer features)
- `/admin/*` (Admin features)

### **Role-Based Routes:**
- `/admin/*` → Requires `role === 'admin'`
- `/dashboard/team` → Requires `role !== 'viewer'`
- `/dashboard/workflows` → All authenticated users

---

## Technology Stack

### **Frontend:**
- Next.js 16 (App Router)
- React 18
- Tailwind CSS
- Lucide React (icons)

### **State Management:**
- React hooks (useState, useEffect)
- LocalStorage for persistence

### **Styling:**
- Dark theme (slate-950 base)
- Purple accent colors
- Gradient backgrounds
- Responsive design

### **Authentication:**
- Token-based (localStorage)
- Protected route checks
- Auto-redirect on unauthorized

---

## Design Philosophy

### **Customer-Facing:**
> "Build intelligent operational workflows without building AI infrastructure."

- ✅ Simple, intuitive interfaces
- ✅ Template-driven (no blank slate)
- ✅ Visual workflow builder
- ✅ Business outcome focused
- ✅ No technical jargon

### **Admin-Facing:**
> "Monitor, manage, and maintain system operations efficiently."

- ✅ Real-time metrics visibility
- ✅ Quick action controls
- ✅ Detailed system information
- ✅ User management tools
- ✅ Operational efficiency

---

## Summary

The Tiannara SaaS platform provides **two distinct experiences**:

1. **Customer Dashboard** - For end users to build and run AI workflows
   - Progressive UX (onboarding → workspace → intelligence)
   - Template-driven approach
   - User-friendly naming
   - Focus on business value

2. **Admin Dashboard** - For organization admins to manage the platform
   - System health monitoring
   - User management with RBAC
   - Live logs and debugging
   - Operational control

Both serve their specific audiences without feature overlap or confusion.
