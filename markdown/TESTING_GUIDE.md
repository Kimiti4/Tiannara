# Tiannara SaaS - Quick Testing Guide

## 🚀 Start the Application

### Backend (API Gateway)
```bash
cd tiannara_api
python -m uvicorn main:app --reload --port 8004
```

### Frontend (SaaS Dashboard)
```bash
cd tiannara_saas
npm run dev
```

---

## 🧪 Test New Features

### 1. Interactive Demos Page
**URL:** `http://localhost:3000/demos`

**Test Steps:**
1. Navigate to `/demos`
2. Click "Run Demo" on any of the three cards:
   - **Run a Prediction** - Should show prediction results after 2.5s
   - **Try a Workflow** - Should display workflow execution steps
   - **Analyze Sample Data** - Should show AI insights
3. Verify results panel appears with formatted output
4. Check "Get Started Free" CTA button is visible

**Expected Behavior:**
- Loading spinner during demo execution
- Smooth fade-in animation for results
- Color-coded confidence scores
- Responsive layout on mobile

---

### 2. API Documentation & Playground
**URL:** `http://localhost:3000/docs`

**Test Steps:**

#### Getting Started Tab
1. Verify base URL is displayed
2. Check curl example is properly formatted
3. Confirm feature cards are visible

#### Authentication Tab
1. Read JWT token format instructions
2. Verify API key generation steps are clear

#### API Endpoints Tab
1. Browse all endpoint categories (Analytics, Workflows, Automations, Auth)
2. Click copy button on any endpoint
3. Verify clipboard contains correct text
4. Check method badges are color-coded (GET=blue, POST=green, etc.)

#### API Playground Tab
1. Login first (navigate to `/login` and authenticate)
2. Select method (GET/POST/PUT/DELETE)
3. Enter endpoint path (e.g., `/api/v1/analytics/dashboard`)
4. Click "Run" button
5. Verify response displays with status code
6. Test error handling (try invalid endpoint)

#### SDKs Tab
1. View Python SDK example
2. View JavaScript SDK example
3. Click copy button on code examples
4. Verify installation commands are correct

**Expected Behavior:**
- All sections load without errors
- Copy-to-clipboard works with visual feedback
- API playground requires authentication
- Responses display in formatted JSON
- Code examples are syntax-highlighted

---

### 3. Enhanced Automations Page
**URL:** `http://localhost:3000/dashboard/automations`

**Test Steps:**

#### Create Automation Modal
1. Click "Create Automation" button in header
2. Verify modal opens with backdrop blur
3. Fill out form:
   - Name: "Daily Churn Alert"
   - Description: "Alert when churn rate exceeds 5%"
   - Trigger Type: Select "Threshold"
   - Workflow: Select "Customer Churn Analysis"
4. Click "Create Automation"
5. Verify modal closes and page refreshes

#### Quick Action Cards
1. Click any quick action card (Threshold Alert/Scheduled Task/Event Trigger)
2. Verify modal opens
3. Check trigger type is pre-selected based on card clicked

#### Empty State
1. If no automations exist, verify empty state shows
2. Click "Create Your First Automation" button
3. Verify modal opens

#### Form Validation
1. Try submitting with empty name → Should show error
2. Try submitting without selecting workflow → Should show error
3. Fill all required fields → Should submit successfully

**Expected Behavior:**
- Modal has smooth open/close animation
- Form validation prevents invalid submissions
- Loading state shows during creation
- Success triggers page refresh
- Backdrop click closes modal (optional enhancement)

---

## 🔍 Test Existing Features

### Dashboard with Real-Time Metrics
**URL:** `http://localhost:3000/dashboard`

**Test Steps:**
1. Login and navigate to dashboard
2. Check connection status badge (top-right):
   - Green = WebSocket connected
   - Yellow = Polling mode
3. Wait 5-10 seconds
4. Verify metrics update automatically
5. Check stats cards show real data:
   - API Usage
   - Active Workflows
   - System Insights
   - Prediction Accuracy

**Expected Behavior:**
- WebSocket connects automatically on page load
- Metrics update every 5 seconds
- Connection status reflects actual state
- Fallback to polling if WebSocket fails

---

### Workflow Builder
**URL:** `http://localhost:3000/dashboard/workflows/builder`

**Test Steps:**
1. Click component from sidebar (e.g., "Text Input")
2. Verify node appears on canvas
3. Click node to open properties panel
4. Configure node settings
5. Add multiple nodes and connect them
6. Click "Execute Workflow"
7. Verify output panel shows results

**Expected Behavior:**
- Nodes drag-and-drop correctly
- Properties panel updates on selection
- Templates load pre-built workflows
- Execution shows loading state
- Results display in output panel

---

### Analytics Center
**URL:** `http://localhost:3000/dashboard/analytics/center`

**Test Steps:**
1. Navigate to analytics center
2. Verify key metrics cards load
3. Check daily usage chart renders
4. Review domain breakdown progress bars
5. Examine workflow performance table
6. Test time range selector (7d/30d/90d)
7. Click "Export" button

**Expected Behavior:**
- All charts render without errors
- Time range change updates data
- Export downloads CSV file
- Loading states show during fetch

---

## 🐛 Common Issues & Fixes

### Issue: WebSocket Connection Fails
**Symptoms:** Yellow "Polling Mode" badge, no real-time updates

**Fix:**
1. Check backend is running on port 8004
2. Verify `NEXT_PUBLIC_WS_URL` in `.env.local`:
   ```
   NEXT_PUBLIC_WS_URL=ws://localhost:8004
   ```
3. Check browser console for WebSocket errors
4. Ensure JWT token is valid in localStorage

---

### Issue: API Playground Returns 401
**Symptoms:** "Not authenticated" error in playground

**Fix:**
1. Navigate to `/login` and authenticate
2. Verify token exists: `localStorage.getItem('tiannara_token')`
3. Check token hasn't expired
4. Re-login if necessary

---

### Issue: Automation Modal Doesn't Close
**Symptoms:** Modal stays open after clicking "Create"

**Fix:**
1. Check browser console for JavaScript errors
2. Verify `onSuccess` callback is called
3. Ensure form validation passes
4. Check React state updates correctly

---

### Issue: Demo Results Don't Appear
**Symptoms:** Loading spinner spins forever

**Fix:**
1. Check browser console for errors
2. Verify `setTimeout` isn't blocked
3. Ensure component state updates
4. Try refreshing page

---

## ✅ Success Checklist

Before considering implementation complete, verify:

- [ ] All three new pages load without errors
- [ ] WebSocket connection establishes successfully
- [ ] API playground returns real responses
- [ ] Automation modal creates entries (or simulates creation)
- [ ] Demo executions complete with results
- [ ] No console errors in browser DevTools
- [ ] Responsive design works on mobile/tablet
- [ ] All routes registered in `main.py` are accessible
- [ ] Authentication protects sensitive routes
- [ ] Loading states appear during async operations

---

## 📊 Performance Benchmarks

**Target Metrics:**
- Page load time: < 2 seconds
- API response time: < 500ms
- WebSocket latency: < 100ms
- Demo execution simulation: 2.5 seconds
- Modal open/close: < 200ms

**How to Measure:**
1. Open Chrome DevTools → Network tab
2. Reload page and check timing
3. Monitor WebSocket frames in WS tab
4. Use Lighthouse for performance audit

---

## 🎯 Next Steps After Testing

1. **Fix Bugs** - Address any issues found during testing
2. **Add Tests** - Write unit tests for critical functions
3. **Optimize** - Improve performance bottlenecks
4. **Document** - Update user-facing documentation
5. **Deploy** - Push to staging environment
6. **Beta Test** - Invite 10-50 users for feedback

---

**Testing Date:** _______________  
**Tester:** _______________  
**Status:** ☐ Pass  ☐ Fail  ☐ Partial  

**Notes:**
_______________________________________________________
_______________________________________________________
_______________________________________________________
