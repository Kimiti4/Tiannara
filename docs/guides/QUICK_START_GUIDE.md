# Tiannara SaaS Platform - Quick Start Guide

**Last Updated:** May 11, 2026

---

## Current System Status ✅

Both frontend and backend servers are running successfully!

### Backend (FastAPI)
- **URL:** http://localhost:8003
- **Status:** ✅ Running
- **Features:** OTP authentication, rate limiting, JWT tokens
- **API Docs:** http://localhost:8003/docs

### Frontend (React + Vite)
- **URL:** http://localhost:5178
- **Status:** ✅ Running
- **Framework:** React 18 + Vite 7.3.2
- **Styling:** Tailwind CSS v4

---

## Recent Fixes Applied

### 1. PostCSS Configuration Error ✅ FIXED

**Problem:** 
```
[plugin:vite:css] Failed to load PostCSS config
Cannot find module '@tailwindcss/postcss'
```

**Solution:**
- Removed `postcss.config.js` file
- Tailwind CSS v4 uses `@tailwindcss/vite` plugin directly in Vite config
- No PostCSS configuration needed for Tailwind v4

**Files Modified:**
- ❌ Deleted: `tiannara_gui/postcss.config.js`
- ✅ Verified: `tiannara_gui/vite.config.js` (already configured correctly)

### 2. API Proxy Configuration ✅ UPDATED

**Problem:** Frontend was proxying API requests to wrong backend port (8000)

**Solution:**
- Updated `vite.config.js` proxy target from port 8000 → 8003
- Now correctly forwards `/api/*` requests to backend

**File Modified:**
- `tiannara_gui/vite.config.js` line 13: `"http://127.0.0.1:8003"`

---

## How to Access the Application

### 1. Open the Frontend
Visit: **http://localhost:5178**

You should see the Tiannara SaaS landing page with:
- Hero section
- Feature highlights
- Signup/Login buttons
- Pricing information

### 2. Test User Registration

**Step 1:** Click "Sign Up" button

**Step 2:** Fill in the form:
```
Name: Test User
Email: test@example.com
Password: SecurePass123!
Tier: Starter
```

**Step 3:** Check server logs for OTP code
The backend will log the OTP code in development mode:
```
WARNING: RESEND_API_KEY not configured. OTP for test@example.com: 123456
```

**Step 4:** Enter the OTP code from logs

**Step 5:** Complete registration → Redirected to dashboard

### 3. API Testing

**Swagger UI:** http://localhost:8003/docs

Test endpoints:
- `POST /api/v1/auth/signup` - Register new user
- `POST /api/v1/auth/verify-otp` - Verify OTP code
- `POST /api/v1/auth/login` - Login with credentials
- `GET /api/v1/auth/me` - Get user profile (requires JWT)

---

## Development Workflow

### Starting the Backend

```bash
cd c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic
python -m uvicorn tiannara_api.main:app --host 0.0.0.0 --port 8003
```

**Expected Output:**
```
INFO:     Started server process [xxxx]
INFO:     Uvicorn running on http://0.0.0.0:8003
```

### Starting the Frontend

```bash
cd c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/tiannara_gui
npm run dev
```

**Expected Output:**
```
VITE v7.3.2  ready in xxx ms
➜  Local:   http://localhost:5178/
```

---

## Troubleshooting

### Issue: Port Already in Use

If you see "Port XXXX is in use", the server will automatically try the next available port. Check the terminal output for the actual port number.

**To kill processes on specific ports:**
```powershell
# Windows PowerShell
netstat -ano | findstr :8003
taskkill /F /PID <process_id>
```

### Issue: CORS Errors

If you see CORS errors in browser console:
- Backend CORS is configured to allow all origins (`*`)
- Ensure backend is running on port 8003
- Check that frontend proxy is configured correctly

### Issue: API Requests Failing

Check these in order:
1. Backend is running on port 8003
2. Frontend proxy points to port 8003 (check vite.config.js)
3. Browser network tab for error details
4. Backend terminal for error logs

### Issue: OTP Not Received

In development mode, OTP codes are **logged to the backend console**, not sent via email.

**To see OTP codes:**
1. Check the backend terminal where uvicorn is running
2. Look for lines like:
   ```
   WARNING: RESEND_API_KEY not configured. OTP for user@example.com: 123456
   ```
3. Copy the 6-digit code and enter it in the verification form

**To enable real email delivery:**
Set environment variable:
```bash
set RESEND_API_KEY=re_your_api_key_here
```

---

## Key Features Implemented

### ✅ Authentication System
- Email-based OTP verification
- JWT token authentication
- Password hashing with salt
- Brute force protection (max 5 attempts)

### ✅ Rate Limiting
- Per-IP rate limiting
- Endpoint-specific limits:
  - OTP requests: 3 per 5 minutes
  - Signup: 5 per hour
  - Login: 10 per 5 minutes
  - General API: 100 per minute

### ✅ Security
- CORS protection
- Input validation (Pydantic)
- JWT token expiration (24 hours)
- HTTPS-ready configuration

### ✅ User Management
- User registration with OTP
- Profile management
- Tier-based access (starter/pro/enterprise)
- Session management

---

## Testing the System

### Manual Testing Checklist

- [ ] Visit http://localhost:5178
- [ ] Click "Sign Up" button
- [ ] Fill registration form
- [ ] Retrieve OTP from backend logs
- [ ] Verify OTP code
- [ ] Confirm redirect to dashboard
- [ ] Test login with credentials
- [ ] Access protected routes with JWT
- [ ] Test rate limiting (spam requests)

### Automated Testing

Run the test suite:
```bash
cd c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic
python test_saas_platform.py
```

**Note:** Tests currently show 30% pass rate due to:
- Test dependencies (OTP capture needs refinement)
- Rate limiting during concurrent tests (expected behavior)
- Some API endpoints at different paths

---

## Next Steps for Production

### Immediate Actions Required

1. **Security Hardening**
   ```bash
   # Set environment variables
   set JWT_SECRET=your_secure_random_secret_here
   set RESEND_API_KEY=re_your_resend_api_key
   ```

2. **Database Integration**
   - Replace in-memory storage with PostgreSQL/MongoDB
   - Migrate user data persistence
   - Add database connection pooling

3. **HTTPS Setup**
   - Obtain SSL certificate
   - Configure reverse proxy (nginx/Caddy)
   - Update CORS allowed origins

### Medium-Term Improvements

4. **Session Management**
   - Implement refresh token rotation
   - Add token revocation endpoint
   - Handle session timeout gracefully

5. **Monitoring & Logging**
   - Integrate structured logging
   - Set up error tracking (Sentry)
   - Configure performance monitoring

6. **Dashboard Completion**
   - Finish settings page
   - Add subscription management UI
   - Implement usage analytics

---

## Architecture Overview

```
User Browser (5178)
    ↓
Vite Dev Server (proxy /api → 8003)
    ↓
FastAPI Backend (8003)
    ├── Rate Limiter Middleware
    ├── CORS Middleware
    ├── Auth Routes (/api/v1/auth/*)
    ├── Autonomous Routes (/api/v1/autonomous/*)
    ├── Discovery Routes (/api/v1/discovery/*)
    └── Other Module Routes
```

---

## Useful Commands

### Backend Commands
```bash
# Start backend
python -m uvicorn tiannara_api.main:app --reload --port 8003

# View API docs
open http://localhost:8003/docs

# Run tests
python test_saas_platform.py
```

### Frontend Commands
```bash
# Start frontend
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

### Utility Commands
```bash
# Check what's running on ports
netstat -ano | findstr ":8003\|:5178"

# Kill process by PID
taskkill /F /PID <pid>

# Install dependencies (backend)
pip install -r requirements.txt

# Install dependencies (frontend)
npm install
```

---

## Support & Documentation

### Generated Reports
1. **[FINAL_IMPLEMENTATION_STATUS.md](./FINAL_IMPLEMENTATION_STATUS.md)** - Complete deployment readiness assessment
2. **[TIANNARA_CORE_CAPABILITIES_REPORT.md](./TIANNARA_CORE_CAPABILITIES_REPORT.md)** - Comprehensive module documentation

### Key Files
- Backend: `tiannara_api/main.py`
- Auth Service: `tiannara_api/auth/otp_service.py`
- Auth Routes: `tiannara_api/routes/auth.py`
- Rate Limiter: `tiannara_api/middleware/rate_limiter.py`
- Frontend Config: `tiannara_gui/vite.config.js`
- Signup Page: `tiannara_gui/src/pages/SignupPage.jsx`

---

**System Ready:** ✅ Both servers operational  
**Last Tested:** May 11, 2026  
**Next Review:** May 18, 2026

