# SSO Routes Quick Test Guide

**Date**: May 1, 2026  
**Issue**: SSO endpoints returning "Not Found"  
**Status**: ✅ **FIXED**

---

## 🐛 Problem

When visiting:
```
http://localhost:8004/api/v1/auth/sso/google/authorize?redirect_uri=http://localhost:3000/callback
```

Got: `{"detail":"Not Found"}`

---

## ✅ Root Cause

The SSO router prefix was set to `/sso` instead of `/auth/sso`, causing a path mismatch.

**Before**:
- Router prefix: `/sso`
- Main app prefix: `/api/v1`
- **Actual path**: `/api/v1/sso/...` ❌

**After**:
- Router prefix: `/auth/sso`
- Main app prefix: `/api/v1`
- **Correct path**: `/api/v1/auth/sso/...` ✅

---

## 🔧 Fix Applied

**File**: [`tiannara_api/routes/sso.py`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/tiannara_api/routes/sso.py#L26)

Changed line 26:
```python
# Before
router = APIRouter(prefix="/sso", tags=["Authentication - SSO"])

# After
router = APIRouter(prefix="/auth/sso", tags=["Authentication - SSO"])
```

---

## 📋 Complete Route List

All SSO endpoints are now at: **`/api/v1/auth/sso/...`**

### **1. List Providers**
```
GET /api/v1/auth/sso/providers
```

**Test**:
```bash
curl http://localhost:8004/api/v1/auth/sso/providers
```

**Expected Response**:
```json
{
  "success": true,
  "providers": [
    {"provider_id": "google", "provider_name": "Google", "enabled": true},
    {"provider_id": "microsoft", "provider_name": "Microsoft", "enabled": true},
    {"provider_id": "github", "provider_name": "GitHub", "enabled": true}
  ]
}
```

---

### **2. Initiate OAuth Authorization**
```
GET /api/v1/auth/sso/{provider}/authorize?redirect_uri={url}
```

**Test** (Google):
```bash
curl "http://localhost:8004/api/v1/auth/sso/google/authorize?redirect_uri=http://localhost:3000/callback"
```

**Expected Response**:
```json
{
  "success": true,
  "authorization_url": "https://accounts.google.com/o/oauth2/v2/auth?client_id=...&redirect_uri=...&response_type=code&scope=openid+profile+email&state=xyz&code_challenge=abc&code_challenge_method=S256",
  "state": "xyz123..."
}
```

**Test** (Microsoft):
```bash
curl "http://localhost:8004/api/v1/auth/sso/microsoft/authorize?redirect_uri=http://localhost:3000/callback"
```

**Test** (GitHub):
```bash
curl "http://localhost:8004/api/v1/auth/sso/github/authorize?redirect_uri=http://localhost:3000/callback"
```

---

### **3. Handle OAuth Callback**
```
POST /api/v1/auth/sso/{provider}/callback
```

**Request Body**:
```json
{
  "code": "AUTHORIZATION_CODE_FROM_PROVIDER",
  "state": "STATE_TOKEN_FROM_AUTHORIZE",
  "redirect_uri": "http://localhost:3000/callback"
}
```

**Test**:
```bash
curl -X POST http://localhost:8004/api/v1/auth/sso/google/callback \
  -H "Content-Type: application/json" \
  -d '{
    "code": "4/0AY0e-g7...",
    "state": "xyz123...",
    "redirect_uri": "http://localhost:3000/callback"
  }'
```

**Expected Response**:
```json
{
  "success": true,
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "random_64_byte_token",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "John Doe",
    "tier": "starter",
    "is_admin": false,
    "provider": "google"
  }
}
```

---

### **4. Link OAuth Account**
```
POST /api/v1/auth/sso/link?current_user_email={email}
```

**Request Body**:
```json
{
  "provider_id": "google",
  "code": "AUTHORIZATION_CODE",
  "state": "STATE_TOKEN"
}
```

**Test**:
```bash
curl -X POST "http://localhost:8004/api/v1/auth/sso/link?current_user_email=user@example.com" \
  -H "Content-Type: application/json" \
  -d '{
    "provider_id": "google",
    "code": "4/0AY0e-g7...",
    "state": "xyz123..."
  }'
```

---

## 🧪 Full Integration Test

### **Step 1: Verify Backend is Running**

```bash
cd c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic
python -m uvicorn tiannara_api.main:app --reload --port 8004
```

Look for:
```
✅ Prometheus metrics initialized
✅ Metrics collection enabled at /metrics
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8004
```

---

### **Step 2: Check Available Providers**

```bash
curl http://localhost:8004/api/v1/auth/sso/providers
```

If you haven't configured OAuth credentials in `.env`, you'll get:
```json
{"success": true, "providers": []}
```

This is normal! Configure credentials to see providers.

---

### **Step 3: Configure OAuth Credentials (Optional)**

Create or update `.env` file:

```env
# Google OAuth
GOOGLE_CLIENT_ID=your_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_secret

# Microsoft OAuth
MICROSOFT_CLIENT_ID=your_client_id
MICROSOFT_CLIENT_SECRET=your_secret
MICROSOFT_TENANT_ID=common

# GitHub OAuth
GITHUB_CLIENT_ID=your_client_id
GITHUB_CLIENT_SECRET=your_secret
```

**How to get credentials**:
- **Google**: https://console.cloud.google.com/apis/credentials
- **Microsoft**: https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/RegisteredApps
- **GitHub**: https://github.com/settings/developers

**Important**: Configure callback URLs in provider dashboards:
- Google: `http://localhost:8004/api/v1/auth/sso/google/callback`
- Microsoft: `http://localhost:8004/api/v1/auth/sso/microsoft/callback`
- GitHub: `http://localhost:8004/api/v1/auth/sso/github/callback`

---

### **Step 4: Test Authorization Flow (Browser)**

1. **Configure Google OAuth credentials** in `.env`

2. **Restart backend**

3. **Visit in browser**:
   ```
   http://localhost:8004/api/v1/auth/sso/google/authorize?redirect_uri=http://localhost:3000/callback
   ```

4. **Should redirect to Google login page** ✅

5. **After login**, Google redirects to:
   ```
   http://localhost:8004/api/v1/auth/sso/google/callback?code=AUTH_CODE&state=STATE_TOKEN
   ```

6. **Frontend exchanges code for tokens** (see callback test above)

---

## 📊 Route Summary Table

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/auth/sso/providers` | List available SSO providers |
| GET | `/api/v1/auth/sso/{provider}/authorize` | Initiate OAuth flow |
| POST | `/api/v1/auth/sso/{provider}/callback` | Handle OAuth callback |
| POST | `/api/v1/auth/sso/link` | Link OAuth to existing account |

**Valid `{provider}` values**: `google`, `microsoft`, `github`

---

## ⚠️ Common Issues

### **Issue 1: "Not Found" Error**
**Cause**: Wrong URL path  
**Solution**: Use `/api/v1/auth/sso/...` not `/api/v1/sso/...`

### **Issue 2: Empty Providers List**
**Cause**: No OAuth credentials configured  
**Solution**: Add credentials to `.env` file

### **Issue 3: "Invalid state parameter"**
**Cause**: State token expired or mismatched  
**Solution**: Ensure state from authorize matches callback

### **Issue 4: "Token exchange failed"**
**Cause**: Invalid authorization code or credentials  
**Solution**: Check client ID/secret, ensure code is fresh

---

## 🎯 Next Steps

Now that routes are working:

1. ✅ **Test providers endpoint** - Should list configured providers
2. ✅ **Configure OAuth credentials** - Get keys from provider dashboards
3. ✅ **Test authorization flow** - Visit authorize URL in browser
4. ✅ **Implement frontend integration** - Add SSO buttons to login page
5. ⏳ **Continue with Day 2** - Implement SAML 2.0 support

---

**Fix Applied**: May 1, 2026  
**Impact**: All SSO routes now accessible at correct paths  
**Documentation Updated**: [`WEEK27_DAY1_COMPLETE.md`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/WEEK27_DAY1_COMPLETE.md)
