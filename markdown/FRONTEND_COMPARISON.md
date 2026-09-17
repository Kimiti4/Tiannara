# Tiannara Frontend Comparison: tiannara_saas vs tiannara_gui

## 📊 Overview

| Feature | tiannara_gui | tiannara_saas |
|---------|--------------|---------------|
| **Framework** | Vite + React (SPA) | Next.js 16 (SSR/SSG) |
| **Language** | JavaScript (JSX) | TypeScript (TSX) |
| **Port** | 5173 | 3000 |
| **Build Tool** | Vite 7.3.2 | Next.js Turbopack |
| **Type** | Single Page Application | Server-Side Rendered App |
| **Primary Purpose** | Core AI Labs & Internal Dashboard | Customer-Facing SaaS Platform |

---

## 🎯 **Purpose & Audience**

### tiannara_gui (Core Intelligence Platform)
**Target Users:** Internal team, developers, AI researchers

**Primary Purpose:** 
- Internal Tiannara Core dashboard
- AI lab management (Discovery, Evolution, Autonomous)
- System monitoring and configuration
- Prosthetic control interface
- Legacy core system access

**Key Features:**
- Discovery Lab - Hypothesis generation & analysis
- Evolution Lab - Model evolution & mutation
- Autonomous Lab - Self-improvement cycles
- Pros Control - Prosthetic device control
- Runs & Reports - Historical data visualization
- Memory Explorer - Knowledge graph exploration
- Modules management - AI module configuration
- Settings - System configuration

**Architecture:**
- Client-side routing (react-router-dom)
- Direct API calls to backend
- Traditional SPA pattern
- Inline styles + Tailwind CSS

---

### tiannara_saas (SaaS Platform)
**Target Users:** External customers, paying subscribers

**Primary Purpose:**
- Customer-facing SaaS platform
- User registration & authentication
- Payment processing & subscriptions
- API usage management
- Billing & invoicing
- Marketing & landing pages

**Key Features:**
- Landing page with pricing tiers
- User signup/login flow
- SaaS user dashboard
- Admin dashboard (multi-tenant)
- Payment integration (Stripe, Flutterwave)
- API key management
- Usage analytics & billing
- Subscription management
- Documentation pages
- Demo showcases

**Architecture:**
- Server-side rendering (Next.js App Router)
- API routes for backend integration
- Next-auth for authentication
- TypeScript for type safety
- SEO-optimized pages

---

##  **File Structure Comparison**

### tiannara_gui Structure
```
tiannara_gui/
├── src/
│   ├── pages/              # Page components
│   │   ├── AdminDashboard.jsx
│   │   ├── SaaSDashboard.jsx
│   │   ├── LandingPage.jsx
│   │   ├── DiscoveryLab.jsx
│   │   ├── EvolutionLab.jsx
│   │   ├── AutonomousLab.jsx
│   │   ├── ProsControl.jsx
│   │   ├── MemoryLab.jsx
│   │   ├── ModulesPage.jsx
│   │   ├── SettingsPage.jsx
│   │   └── ...
│   ├── components/         # Reusable components
│   ├── api/               # API client
│   ├── hooks/             # Custom hooks
│   ├── router.jsx         # Client-side routing
│   └── main.jsx           # Entry point
├── public/
├── vite.config.js
└── package.json
```

### tiannara_saas Structure
```
tiannara_saas/
├── app/                   # Next.js App Router
│   ├── page.tsx          # Landing page
│   ├── layout.tsx        # Root layout
│   ├── globals.css       # Global styles
│   ├── dashboard/        # User dashboard
│   ├── admin/            # Admin dashboard
│   ├── login/            # Login page
│   ├── signup/           # Signup page
│   ├── pricing/          # Pricing page
│   ├── demos/            # Demo pages
│   └── docs/             # Documentation
├── components/           # Shared components
├── lib/                  # Utilities
├── contexts/             # React contexts
├── generated/            # Generated types
├── public/
└── package.json
```

---

## 🛠️ **Technology Stack Differences**

### tiannara_gui Dependencies
```json
{
  "dependencies": {
    "@tailwindcss/vite": "^4.3.0",
    "lucide-react": "^1.14.0",
    "react": "^19.2.0",
    "react-dom": "^19.2.0",
    "react-router-dom": "^7.13.1"
  }
}
```

**Key Libraries:**
- **Vite** - Fast build tool & dev server
- **React Router** - Client-side routing
- **Tailwind CSS v4** - Utility-first CSS
- **Lucide React** - Icon library
- **No payment libraries** - Not customer-facing

---

### tiannara_saas Dependencies
```json
{
  "dependencies": {
    "@stripe/stripe-js": "^9.4.0",
    "next": "16.2.6",
    "next-auth": "^4.24.14",
    "react": "19.2.4",
    "react-dom": "19.2.4",
    "recharts": "^3.8.1",
    "stripe": "^22.1.1",
    "flutterwave-react-v3": "^1.3.3",
    "jsonwebtoken": "^9.0.3",
    "bcryptjs": "^3.0.3"
  }
}
```

**Key Libraries:**
- **Next.js 16** - React framework with SSR
- **Next-auth** - Authentication library
- **Stripe SDK** - Payment processing
- **Flutterwave** - Alternative payment provider
- **Recharts** - Data visualization
- **bcryptjs** - Password hashing
- **jsonwebtoken** - JWT token handling

---

## 🚀 **Deployment & Performance**

### tiannara_gui
- **Build Output:** Static assets (JS, CSS, HTML)
- **Deployment:** Can be deployed to any static host (Vercel, Netlify, CDN)
- **SEO:** Limited (SPA, client-rendered)
- **Initial Load:** Fast (small bundle)
- **Updates:** Hot reload in development

### tiannara_saas
- **Build Output:** Server-rendered pages + static assets
- **Deployment:** Requires Node.js server (Vercel, Railway, custom server)
- **SEO:** Excellent (server-side rendering)
- **Initial Load:** Slower first paint, but better perceived performance
- **Updates:** Server restarts for production

---

## 🔐 **Authentication & Security**

### tiannara_gui
- **Auth Method:** JWT tokens stored in localStorage
- **Security:** Basic (relies on backend API security)
- **User Types:** Single admin or developer
- **Multi-tenant:** No (single instance)

### tiannara_saas
- **Auth Method:** Next-auth with JWT sessions
- **Security:** Advanced (bcrypt password hashing, server-side validation)
- **User Types:** Multiple (free, starter, professional, enterprise)
- **Multi-tenant:** Yes (multiple customers)

---

## 💳 **Payment Integration**

### tiannara_gui
- **Payment Support:** ❌ None
- **Billing Features:** ❌ Not applicable
- **Subscription Management:** ❌ Not applicable

### tiannara_saas
- **Payment Support:** ✅ Stripe & Flutterwave
- **Billing Features:** ✅ Complete
- **Subscription Management:** ✅ Yes
- **Usage Tracking:** ✅ API request monitoring
- **Invoice Generation:** ✅ Planned

---

## 📊 **Dashboards Comparison**

### tiannara_gui Dashboards
1. **Discovery Lab** - AI hypothesis generation
2. **Evolution Lab** - Model evolution tracking
3. **Autonomous Lab** - Self-improvement metrics
4. **Pros Control** - Prosthetic device interface
5. **Runs & Reports** - Historical experiment data
6. **Memory Lab** - Knowledge graph visualization
7. **Modules Page** - AI module management
8. **Settings** - System configuration
9. **SaaS Dashboard** - Basic user metrics
10. **Admin Dashboard** - System-wide monitoring

### tiannara_saas Dashboards
1. **Landing Page** - Marketing & pricing
2. **User Dashboard** - Personal API usage
3. **Admin Dashboard** - Multi-tenant admin
4. **Billing Page** - Subscription management
5. **API Keys Page** - Key management
6. **Usage Analytics** - Request tracking
7. **Documentation** - API docs
8. **Demos** - Product showcases

---

## 🎨 **UI/UX Differences**

### tiannara_gui
- **Design:** Technical, developer-focused
- **Theme:** Dark mode primarily
- **Components:** Custom-built, inline styles
- **Responsiveness:** Basic mobile support
- **Animations:** Minimal

### tiannara_saas
- **Design:** Professional, customer-focused
- **Theme:** Light/dark mode support
- **Components:** Radix UI primitives, polished
- **Responsiveness:** Full mobile support
- **Animations:** Smooth transitions, gradients

---

## 🔄 **When to Use Which?**

### Use tiannara_gui when:
- ✅ Developing/testing AI core features
- ✅ Managing internal Tiannara systems
- ✅ Running experiments in labs
- ✅ Controlling prosthetic devices
- ✅ Debugging AI modules
- ✅ Internal team collaboration

### Use tiannara_saas when:
- ✅ Customer onboarding
- ✅ Payment processing
- ✅ API usage monitoring
- ✅ Subscription management
- ✅ Marketing & sales
- ✅ Multi-tenant administration
- ✅ Public-facing features

---

## 📈 **Current Status**

### tiannara_gui
- **Status:** ✅ Operational (legacy)
- **Port:** 5173
- **Backend:** Connects to port 8004
- **Active Features:** All core labs, admin dashboard

### tiannara_saas
- **Status:** ✅ Running (primary)
- **Port:** 3000
- **Backend:** Connects to port 8004
- **Active Features:** Landing page, auth, payments, dashboards

---

## 🔮 **Future Direction**

**Recommendation:** 
- **tiannara_saas** should be the **primary customer-facing frontend**
- **tiannara_gui** can serve as **internal developer tools**
- Consider migrating core lab features into tiannara_saas under `/labs/*` routes
- Eventually consolidate into a single Next.js application with proper role-based access

---

## 🎯 **Quick Reference**

| Aspect | tiannara_gui | tiannara_saas |
|--------|--------------|---------------|
| **URL** | http://localhost:5173 | http://localhost:3000 |
| **Framework** | Vite + React | Next.js 16 |
| **Language** | JavaScript | TypeScript |
| **Purpose** | Internal AI Labs | Customer SaaS |
| **Payments** | ❌ No | ✅ Stripe/Flutterwave |
| **Auth** | JWT + localStorage | Next-auth + sessions |
| **SEO** | Limited | Excellent |
| **Users** | Developers/Team | Customers |
| **Multi-tenant** |  No | ✅ Yes |
| **Production Ready** | Partial | ✅ Yes |

---

**Last Updated:** May 12, 2026
