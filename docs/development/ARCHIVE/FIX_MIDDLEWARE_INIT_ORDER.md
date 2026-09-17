# Fix: Middleware Initialization Order

**Date**: May 1, 2026  
**Issue**: RuntimeError when starting Tiannara API backend  
**Status**: ✅ **FIXED**

---

## 🐛 Error

```
RuntimeError: Cannot add middleware after an application has started
```

**Location**: `tiannara_api/main.py`, line 194 in `startup_event()`

**Root Cause**: 
The `init_metrics(app)` function was being called inside the `@app.on_event("startup")` handler, which runs **after** the FastAPI application has already started. By that point, Starlette (the ASGI framework underneath FastAPI) doesn't allow adding new middleware.

---

## ✅ Solution

Moved `init_metrics(app)` call to happen **during app initialization**, before any routes are registered and before the app starts.

### **Before (Broken)**:
```python
app = FastAPI(title="Tiannara API", version=APP_VERSION)

# Add security middleware
app.add_middleware(SecurityHeadersMiddleware)
...

@app.on_event("startup")
async def startup_event():
    # ❌ WRONG - App has already started!
    init_metrics(app)
    print("✅ Metrics collection enabled at /metrics")
```

### **After (Fixed)**:
```python
app = FastAPI(title="Tiannara API", version=APP_VERSION)

# ✅ CORRECT - Initialize metrics BEFORE app starts
init_metrics(app)

# Add security middleware
app.add_middleware(SecurityHeadersMiddleware)
...

@app.on_event("startup")
async def startup_event():
    # Just log that metrics are ready
    print("✅ Metrics collection enabled at /metrics")
```

---

## 📝 Changes Made

### **File**: [`tiannara_api/main.py`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/tiannara_api/main.py)

**Change 1**: Added `init_metrics(app)` right after app creation (line 59)
```python
app = FastAPI(title="Tiannara API", version=APP_VERSION)

# Initialize Prometheus metrics (must be before other middleware)
init_metrics(app)
```

**Change 2**: Removed duplicate `init_metrics(app)` from startup event (line 197)
```python
@app.on_event("startup")
async def startup_event():
    """
    Initialize application on server startup.
    - Initialize admin user (for development)
    """
    # Removed: init_metrics(app)
    print("✅ Metrics collection enabled at /metrics")
```

---

## 🔍 Why This Matters

### **FastAPI/Starlette Middleware Lifecycle**:

1. **App Creation** - `FastAPI()` constructor
2. **Middleware Addition** - `app.add_middleware()` calls
3. **Route Registration** - `app.include_router()` calls
4. **App Startup** - `@app.on_event("startup")` handlers run
5. **Request Handling** - App accepts HTTP requests

**Rule**: Middleware can only be added during steps 1-3. Once step 4 begins, it's too late.

---

## 🧪 Testing

### **Test the Fix**:

```bash
cd c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic
python -m uvicorn tiannara_api.main:app --reload --port 8004
```

**Expected Output**:
```
✅ Prometheus metrics initialized
✅ Metrics collection enabled at /metrics
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8004
```

### **Verify Metrics Endpoint**:

```bash
curl http://localhost:8004/metrics
```

Should return Prometheus-formatted metrics data.

---

## 📚 Related Documentation

- [FastAPI Lifespan Events](https://fastapi.tiangolo.com/advanced/events/)
- [Starlette Middleware](https://www.starlette.io/middleware/)
- [Week 24 Day 1: Prometheus Metrics](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/WEEK24_DAY1_COMPLETE.md)

---

## ⚠️ Important Notes

1. **Order Matters**: `init_metrics(app)` must be called **before** other middleware to ensure proper request tracking order.

2. **No Duplicate Calls**: Never call `init_metrics(app)` more than once, or you'll get duplicate middleware and metrics.

3. **SSO Integration Safe**: The OAuth 2.0 SSO implementation added today doesn't affect this fix - it uses routers, not middleware.

---

## ✅ Verification Checklist

- [x] Backend starts without errors
- [x] `/metrics` endpoint accessible
- [x] Prometheus metrics being collected
- [x] All middleware working correctly
- [x] SSO routes functional
- [x] No duplicate middleware registration

---

**Fix Applied**: May 1, 2026  
**Impact**: Zero downtime, immediate fix  
**Risk**: None - purely structural change
