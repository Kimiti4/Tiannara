# Tiannara SaaS Deployment - Quick Reference

**Date**: May 1, 2026  
**Status**: ✅ **Quick Start Guide**

---

## 🎯 **Architecture Overview**

```
Tiannara SaaS (Next.js)     → Vercel
         ↓ HTTPS
Tiannara API (FastAPI)      → Railway
         ↓ Internal
Tiannara Core (Python)      → Railway (same as API)
         ↓
PostgreSQL + Redis          → Railway/Neon
```

**Key Principle**: Frontend and backend are **completely separate deployments**.

---

## 🚀 **5-Minute Deployment**

### **Step 1: Deploy Backend (Railway)**

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Deploy
cd Tiannara-MindCache-Prosthetic
railway up
```

**Get URL**: `https://your-project.up.railway.app`

---

### **Step 2: Deploy Frontend (Vercel)**

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
cd tiannara_saas
vercel --prod
```

**Get URL**: `https://tiannara-saas.vercel.app`

---

### **Step 3: Connect Them**

In Vercel dashboard → Settings → Environment Variables:

```
NEXT_PUBLIC_API_URL=https://your-project.up.railway.app
```

Redeploy frontend.

---

## 🔑 **Required Environment Variables**

### **Backend (Railway):**

```env
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
JWT_SECRET_KEY=...
CORS_ORIGINS=https://tiannara-saas.vercel.app
PAYSTACK_SECRET_KEY=sk_live_...
GOOGLE_CLIENT_ID=...
```

### **Frontend (Vercel):**

```env
NEXT_PUBLIC_API_URL=https://your-project.up.railway.app
```

---

## ✅ **Verification**

### **Test Backend:**
```bash
curl https://your-project.up.railway.app/api/v1/health
```

**Expected**: `{"status":"healthy"}`

---

### **Test Frontend:**
Visit: `https://tiannara-saas.vercel.app`

Check:
- ✅ Loads without errors
- ✅ Can login
- ✅ API calls work
- ✅ No CORS errors

---

## 🚨 **Troubleshooting**

### **CORS Error?**
Add frontend URL to backend `CORS_ORIGINS`:
```env
CORS_ORIGINS=https://tiannara-saas.vercel.app,http://localhost:3000
```

---

### **API Not Found?**
Check `NEXT_PUBLIC_API_URL` in Vercel env vars matches Railway URL.

---

### **Build Fails?**
Test locally first:
```bash
cd tiannara_saas
npm run build
```

Fix errors, then commit and push.

---

## 💰 **Costs**

| Service | Cost/Month |
|---------|------------|
| Vercel (Frontend) | $0 (Hobby) |
| Railway (Backend) | $5-20 |
| Railway (Database) | $5-10 |
| **Total** | **$10-30** |

---

## 📞 **Useful Commands**

```bash
# View backend logs
railway logs

# View frontend logs
vercel logs

# Redeploy backend
railway up

# Redeploy frontend
cd tiannara_saas && vercel --prod

# Check backend status
curl https://your-project.up.railway.app/api/v1/health
```

---

## 📚 **Full Documentation**

See [`TIANNARA_SAAS_DEPLOYMENT_GUIDE.md`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/TIANNARA_SAAS_DEPLOYMENT_GUIDE.md) for complete guide.

---

**Status**: ✅ **Ready to Deploy**
