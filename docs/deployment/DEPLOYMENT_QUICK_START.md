# Tiannara SaaS Deployment Guide - Quick Start

**Date**: May 1, 2026  
**Status**: 📋 **DEPLOYMENT GUIDE**  
**Goal**: Deploy Tiannara SaaS for testing (custom domain later)

---

## 🎯 **Recommended Approach: Railway**

**Why Railway?**
- ✅ Free $5 credit/month (enough for testing)
- ✅ One-click PostgreSQL database
- ✅ Automatic environment variable management
- ✅ Auto-deploy from GitHub
- ✅ Built-in HTTPS
- ✅ Easy to add custom domain later

---

## 📋 **Pre-Deployment Checklist**

Before deploying, ensure you have:

- [ ] GitHub repository with latest code
- [ ] Lemon Squeezy account configured
- [ ] Stripe account configured
- [ ] Product descriptions created in both providers
- [ ] API keys ready (test mode)
- [ ] PostgreSQL database credentials (Railway provides this)

---

## 🚀 **Step-by-Step Deployment**

### **Phase 1: Prepare Your Repository**

#### **1. Update .gitignore**

Ensure sensitive files are NOT committed:

```bash
# Add to .gitignore if not present
.env
*.env
node_modules/
__pycache__/
*.pyc
.pytest_cache/
runs/
checkpoints/
test_results/
comparison_results/
```

#### **2. Create Production-Ready Files**

**Create `Procfile`** (for Railway/Heroku):
```
web: uvicorn tiannara_api.main:app --host 0.0.0.0 --port $PORT
```

**Create `runtime.txt`** (specify Python version):
```
python-3.11.0
```

**Update `requirements.txt`** (ensure all dependencies listed):
```txt
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
stripe>=7.5.0
requests>=2.31.0
sqlalchemy>=2.0.0
psycopg2-binary>=2.9.0
python-dotenv>=1.0.0
pydantic>=2.5.0
python-jose[cryptography]>=3.3.0
passlib[bcrypt]>=1.7.4
python-multipart>=0.0.6
alembic>=1.12.0
httpx>=0.25.0
```

#### **3. Commit and Push**

```bash
git add .
git commit -m "Prepare for deployment"
git push origin main
```

---

### **Phase 2: Deploy Backend to Railway**

#### **1. Sign Up for Railway**

1. Go to https://railway.app
2. Sign up with GitHub
3. Click "New Project"

#### **2. Create PostgreSQL Database**

1. Click "+ New" → "Database" → "PostgreSQL"
2. Railway automatically creates database
3. Copy connection details (you'll need these)

Click on the PostgreSQL service → Variables tab:
```
DATABASE_URL=postgresql://user:password@host:5432/railway
```

#### **3. Deploy Backend Service**

1. Click "+ New" → "GitHub Repo"
2. Select your Tiannara repository
3. Railway auto-detects Python/FastAPI
4. Click "Deploy"

#### **4. Configure Environment Variables**

In Railway dashboard → Backend Service → Variables:

**Add these variables:**

```bash
# Application Settings
APP_NAME=Tiannara MindCache SaaS
APP_ENV=production
DEBUG=false
SECRET_KEY=generate-a-random-secret-key-here
ALLOWED_HOSTS=your-railway-domain.railway.app,localhost

# Database (Railway auto-provides this)
DATABASE_URL=postgresql://... (from PostgreSQL service)

# Payment Provider Configuration
PAYMENT_PROVIDER=lemon_squeezy

# Lemon Squeezy
LEMON_SQUEEZY_API_KEY=eyJwcm9kdWN0aW9uIjoi...
LEMON_SQUEEZY_STORE_ID=12345
LEMON_SQUEEZY_WEBHOOK_SECRET=whsec_xxxxxx
LEMON_SQUEEZY_TEST_MODE=true

LS_STARTER_VARIANT_ID=123456
LS_PRO_VARIANT_ID=123457
LS_ENTERPRISE_VARIANT_ID=123458

# Stripe
STRIPE_SECRET_KEY=sk_test_xxxxxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxx

STRIPE_STARTER_PRICE_ID=price_xxxxxx
STRIPE_PRO_PRICE_ID=price_xxxxxx
STRIPE_ENTERPRISE_PRICE_ID=price_xxxxxx

# Authentication
JWT_SECRET_KEY=generate-another-random-key
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30

# Email (Resend recommended)
RESEND_API_KEY=re_xxxxxx
EMAIL_FROM=noreply@tiannara.com

# CORS
CORS_ORIGINS=https://your-frontend-domain.vercel.app

# API Configuration
API_V1_PREFIX=/api/v1

# Logging
LOG_LEVEL=INFO
```

**Generate secure keys:**
```bash
# In terminal
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

#### **5. Get Your Backend URL**

Railway provides a domain like:
```
https://tiannara-backend-production.up.railway.app
```

Copy this URL - you'll need it for frontend configuration.

#### **6. Test Backend Deployment**

Visit: `https://your-backend.railway.app/docs`

You should see the FastAPI Swagger UI.

Test endpoint:
```bash
curl https://your-backend.railway.app/api/v1/payment/providers
```

Expected response:
```json
{
  "available_providers": ["lemon_squeezy", "stripe"],
  "default_provider": "lemon_squeezy",
  ...
}
```

---

### **Phase 3: Deploy Frontend to Vercel**

#### **1. Sign Up for Vercel**

1. Go to https://vercel.com
2. Sign up with GitHub
3. Click "Add New Project"

#### **2. Import Repository**

1. Select your Tiannara repository
2. Vercel auto-detects Next.js
3. Click "Deploy"

#### **3. Configure Environment Variables**

In Vercel dashboard → Settings → Environment Variables:

```bash
# Backend API URL
NEXT_PUBLIC_API_URL=https://your-backend.railway.app

# Authentication
NEXTAUTH_SECRET=generate-random-key
NEXTAUTH_URL=https://your-frontend.vercel.app

# Payment
NEXT_PUBLIC_PAYMENT_PROVIDER=lemon_squeezy
```

#### **4. Update Frontend API Configuration**

Create/update `tiannara_gui/src/lib/api.ts`:

```typescript
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export const api = {
  baseURL: API_BASE_URL,
  
  async request(endpoint: string, options: RequestInit = {}) {
    const url = `${API_BASE_URL}${endpoint}`;
    
    const response = await fetch(url, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
    });
    
    if (!response.ok) {
      throw new Error(`API error: ${response.statusText}`);
    }
    
    return response.json();
  },
  
  // Payment endpoints
  payment: {
    subscribe: (data: any) => 
      api.request('/api/v1/payment/subscribe', {
        method: 'POST',
        body: JSON.stringify(data),
      }),
    
    providers: () => 
      api.request('/api/v1/payment/providers'),
    
    plans: () => 
      api.request('/api/v1/payment/plans'),
  },
};
```

#### **5. Redeploy Frontend**

Vercel auto-redeploys on push, or trigger manually:
```bash
git push origin main
```

#### **6. Get Your Frontend URL**

Vercel provides:
```
https://tiannara-saas.vercel.app
```

---

### **Phase 4: Configure Webhooks**

#### **1. Lemon Squeezy Webhook**

1. Go to Lemon Squeezy Dashboard → Settings → Webhooks
2. Add endpoint:
   ```
   https://your-backend.railway.app/api/v1/payment/webhook
   ```
3. Select events:
   - ✅ subscription_created
   - ✅ subscription_updated
   - ✅ subscription_cancelled
   - ✅ order_created
4. Copy signing secret
5. Update Railway env var: `LEMON_SQUEEZY_WEBHOOK_SECRET`

#### **2. Stripe Webhook**

1. Go to Stripe Dashboard → Developers → Webhooks
2. Add endpoint:
   ```
   https://your-backend.railway.app/api/v1/payment/webhook
   ```
3. Select events:
   - ✅ checkout.session.completed
   - ✅ invoice.payment_succeeded
   - ✅ customer.subscription.deleted
4. Copy signing secret
5. Update Railway env var: `STRIPE_WEBHOOK_SECRET`

---

### **Phase 5: Update CORS Configuration**

In Railway backend environment variables:

```bash
CORS_ORIGINS=https://tiannara-saas.vercel.app,http://localhost:3001
```

This allows your frontend to communicate with the backend.

---

### **Phase 6: Test End-to-End**

#### **1. Visit Your Frontend**

Go to: `https://tiannara-saas.vercel.app`

#### **2. Test Signup/Login**

- Create a test account
- Verify OTP email works (check Resend dashboard)

#### **3. Test Payment Flow**

1. Navigate to billing page
2. Select a plan (Starter $49)
3. Choose provider (Lemon Squeezy or Stripe)
4. Complete checkout with test card:
   - Card: `4242 4242 4242 4242`
   - Expiry: Any future date
   - CVC: Any 3 digits

#### **4. Verify Subscription Activation**

- Check user tier updated in database
- Verify webhook received in Railway logs
- Confirm success page displayed

---

## 🔧 **Troubleshooting**

### **Issue 1: Backend won't start**

**Check Railway logs:**
```bash
# Railway Dashboard → Backend → Deployments → View Logs
```

**Common fixes:**
- Ensure `DATABASE_URL` is correct
- Check all required env vars are set
- Verify `requirements.txt` has all dependencies

### **Issue 2: CORS errors**

**Solution:**
Update `CORS_ORIGINS` in Railway to include your Vercel domain:
```bash
CORS_ORIGINS=https://tiannara-saas.vercel.app
```

### **Issue 3: Webhooks not working**

**Check:**
1. Webhook URL is correct (no typos)
2. Signing secrets match
3. Railway logs show webhook received
4. Use Railway's public URL (not localhost)

**Test webhook:**
```bash
curl -X POST https://your-backend.railway.app/api/v1/payment/webhook \
  -H "Content-Type: application/json" \
  -H "x-signature: test_signature" \
  -d '{"test": true}'
```

### **Issue 4: Database connection failed**

**Solution:**
1. Verify PostgreSQL service is running in Railway
2. Check `DATABASE_URL` format:
   ```
   postgresql://user:password@host:5432/database
   ```
3. Ensure database migrations ran

**Run migrations:**
```bash
# Railway Shell
alembic upgrade head
```

---

## 📊 **Monitoring & Logs**

### **Railway Backend Logs**

1. Railway Dashboard → Backend → Logs
2. Real-time log streaming
3. Filter by deployment

### **Vercel Frontend Logs**

1. Vercel Dashboard → Deployments
2. Click on deployment → Function Logs
3. View runtime errors

### **Payment Provider Dashboards**

- **Lemon Squeezy**: Check webhook delivery status
- **Stripe**: Monitor API requests and errors

---

## 🎯 **Testing Checklist**

After deployment, verify:

- [ ] Backend accessible at Railway URL
- [ ] Frontend accessible at Vercel URL
- [ ] Swagger docs work: `/docs`
- [ ] User signup works
- [ ] OTP emails sent (check Resend)
- [ ] Login works
- [ ] Dashboard loads
- [ ] Payment providers listed
- [ ] Checkout flow works (test mode)
- [ ] Webhooks received
- [ ] Subscription activated
- [ ] Tier updated in database
- [ ] No console errors
- [ ] Mobile responsive

---

## 💰 **Cost Estimate (Free Tier)**

| Service | Cost | Notes |
|---------|------|-------|
| Railway Backend | $0 | $5 free credit/month |
| Vercel Frontend | $0 | Free for hobby projects |
| PostgreSQL | $0 | Included with Railway |
| Resend (Email) | $0 | 100 emails/day free |
| Lemon Squeezy | $0 | Test mode free |
| Stripe | $0 | Test mode free |
| **Total** | **$0** | Perfect for testing! |

---

## 🌐 **Adding Custom Domain Later**

When you're ready for a custom domain:

### **Railway Backend**

1. Railway Dashboard → Settings → Domains
2. Add your domain: `api.tiannara.com`
3. Update DNS CNAME record
4. Railway auto-provisions SSL

### **Vercel Frontend**

1. Vercel Dashboard → Settings → Domains
2. Add your domain: `app.tiannara.com`
3. Follow DNS configuration instructions
4. Vercel auto-provisions SSL

### **Update Environment Variables**

```bash
# Railway
ALLOWED_HOSTS=api.tiannara.com,app.tiannara.com
CORS_ORIGINS=https://app.tiannara.com

# Vercel
NEXT_PUBLIC_API_URL=https://api.tiannara.com
NEXTAUTH_URL=https://app.tiannara.com
```

### **Update Webhook URLs**

```
Lemon Squeezy: https://api.tiannara.com/api/v1/payment/webhook
Stripe: https://api.tiannara.com/api/v1/payment/webhook
```

---

## 🚀 **Quick Commands Reference**

```bash
# Local testing before deployment
uvicorn tiannara_api.main:app --reload
npm run dev

# Check backend health
curl https://your-backend.railway.app/health

# List payment providers
curl https://your-backend.railway.app/api/v1/payment/providers

# Test subscription
curl -X POST https://your-backend.railway.app/api/v1/payment/subscribe \
  -H "Content-Type: application/json" \
  -d '{
    "plan": "starter",
    "success_url": "https://your-frontend.vercel.app/success",
    "cancel_url": "https://your-frontend.vercel.app/cancel",
    "customer_email": "test@example.com"
  }'
```

---

## 📞 **Support Resources**

- **Railway Docs**: https://docs.railway.app
- **Vercel Docs**: https://vercel.com/docs
- **Tiannara Payment Guide**: [COMPLETE_PAYMENT_INTEGRATION.md](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/docs/deployment/COMPLETE_PAYMENT_INTEGRATION.md)
- **Railway Discord**: https://discord.gg/railway
- **Vercel Discord**: https://vercel.com/discord

---

## ✅ **Deployment Summary**

✅ **Backend**: Deployed to Railway (Free)  
✅ **Frontend**: Deployed to Vercel (Free)  
✅ **Database**: PostgreSQL on Railway (Free)  
✅ **HTTPS**: Automatic on both platforms  
✅ **Webhooks**: Configured for both providers  
✅ **Custom Domain**: Can add anytime  

**Your Tiannara SaaS is now live and ready for testing!** 🎉🚀

---

**Next Steps**:
1. Complete deployment following steps above
2. Test all features end-to-end
3. Invite beta testers
4. Monitor logs and fix any issues
5. Add custom domain when ready
