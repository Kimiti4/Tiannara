# Deploy Tiannara SaaS - Quick Start Guide

**Goal**: Deploy Tiannara SaaS for testing in under 30 minutes  
**Cost**: $0 (free tiers)  
**Custom Domain**: Not required (add later)

---

## 🚀 **5-Step Deployment**

### **Step 1: Prepare Repository** (2 min)

Files already created:
- ✅ `Procfile` - Railway deployment config
- ✅ `runtime.txt` - Python version
- ✅ `requirements.txt` - Updated with all dependencies

Just commit and push:
```bash
git add .
git commit -m "Prepare for deployment"
git push origin main
```

---

### **Step 2: Deploy Backend to Railway** (10 min)

1. **Sign up**: https://railway.app (use GitHub)

2. **Create PostgreSQL**:
   - New Project → + New → Database → PostgreSQL
   - Copy DATABASE_URL

3. **Deploy Backend**:
   - + New → GitHub Repo → Select Tiannara repo
   - Click Deploy

4. **Add Environment Variables** (Railway → Backend → Variables):

**Copy-paste this template** (replace values):

```bash
APP_NAME=Tiannara MindCache SaaS
APP_ENV=production
DEBUG=false
SECRET_KEY=<run: python3 -c "import secrets; print(secrets.token_urlsafe(32))">
ALLOWED_HOSTS=<your-app>.up.railway.app

DATABASE_URL=<from PostgreSQL service>

PAYMENT_PROVIDER=lemon_squeezy

LEMON_SQUEEZY_API_KEY=eyJwcm9kdWN0aW9uIjoi...
LEMON_SQUEEZY_STORE_ID=12345
LEMON_SQUEEZY_WEBHOOK_SECRET=whsec_xxxxxx
LEMON_SQUEEZY_TEST_MODE=true
LS_STARTER_VARIANT_ID=123456
LS_PRO_VARIANT_ID=123457
LS_ENTERPRISE_VARIANT_ID=123458

STRIPE_SECRET_KEY=sk_test_xxxxxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxx
STRIPE_STARTER_PRICE_ID=price_xxxxxx
STRIPE_PRO_PRICE_ID=price_xxxxxx
STRIPE_ENTERPRISE_PRICE_ID=price_xxxxxx

JWT_SECRET_KEY=<run: python3 -c "import secrets; print(secrets.token_urlsafe(32))">
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30

RESEND_API_KEY=re_xxxxxx
EMAIL_FROM=noreply@tiannara.com

CORS_ORIGINS=https://<your-frontend>.vercel.app,http://localhost:3001

API_V1_PREFIX=/api/v1
LOG_LEVEL=INFO
```

5. **Get Backend URL**: Note it (e.g., `https://tiannara-backend.up.railway.app`)

6. **Test**: Visit `https://<your-backend>.railway.app/docs`

---

### **Step 3: Deploy Frontend to Vercel** (8 min)

1. **Sign up**: https://vercel.com (use GitHub)

2. **Import Project**:
   - Add New Project → Import Tiannara repo
   - Root directory: `tiannara_gui` (if needed)
   - Click Deploy

3. **Add Environment Variables** (Vercel → Settings → Env Vars):

```bash
NEXT_PUBLIC_API_URL=https://<your-backend>.railway.app
NEXTAUTH_SECRET=<run: python3 -c "import secrets; print(secrets.token_urlsafe(32))">
NEXTAUTH_URL=https://<your-frontend>.vercel.app
NEXT_PUBLIC_PAYMENT_PROVIDER=lemon_squeezy
```

4. **Get Frontend URL**: Note it (e.g., `https://tiannara-saas.vercel.app`)

5. **Update Railway CORS**:
   - Go back to Railway
   - Update `CORS_ORIGINS` to include Vercel domain
   - Backend auto-redeploys

---

### **Step 4: Configure Webhooks** (5 min)

**Lemon Squeezy**:
1. Dashboard → Settings → Webhooks
2. Add: `https://<backend>.railway.app/api/v1/payment/webhook`
3. Select events: subscription_created, subscription_updated, subscription_cancelled, order_created
4. Copy signing secret → Update Railway `LEMON_SQUEEZY_WEBHOOK_SECRET`

**Stripe**:
1. Dashboard → Developers → Webhooks
2. Add: `https://<backend>.railway.app/api/v1/payment/webhook`
3. Select events: checkout.session.completed, invoice.payment_succeeded, customer.subscription.deleted
4. Copy signing secret → Update Railway `STRIPE_WEBHOOK_SECRET`

---

### **Step 5: Test Everything** (5 min)

1. **Visit Frontend**: `https://<your-frontend>.vercel.app`

2. **Test Signup**:
   - Create account
   - Verify OTP email (check Resend dashboard)
   - Login

3. **Test Payment**:
   - Go to billing page
   - Select Starter plan ($49)
   - Checkout with test card: `4242 4242 4242 4242`
   - Any future expiry, any CVC
   - Complete payment

4. **Verify**:
   - Success page shows
   - User tier updated
   - Check Railway logs for webhook

---

## ✅ **Quick Verification Checklist**

- [ ] Backend accessible at Railway URL
- [ ] Swagger docs load: `/docs`
- [ ] Frontend loads at Vercel URL
- [ ] User can signup/login
- [ ] OTP emails work
- [ ] Payment checkout works (test mode)
- [ ] Webhooks received (check Railway logs)
- [ ] No console errors

---

## 🔧 **Common Issues & Fixes**

| Problem | Solution |
|---------|----------|
| Backend won't start | Check Railway logs, verify DATABASE_URL |
| CORS errors | Update CORS_ORIGINS in Railway with Vercel domain |
| Webhooks fail | Verify webhook URL and signing secrets |
| Email not sending | Check RESEND_API_KEY and verified sender |
| Database migration failed | Run `alembic upgrade head` in Railway shell |

---

## 📚 **Full Documentation**

For detailed instructions:
- 📘 [DEPLOYMENT_QUICK_START.md](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/docs/deployment/DEPLOYMENT_QUICK_START.md) - Complete guide (587 lines)
- ✅ [DEPLOYMENT_CHECKLIST.md](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/DEPLOYMENT_CHECKLIST.md) - Step-by-step checklist
- 💳 [COMPLETE_PAYMENT_INTEGRATION.md](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/docs/deployment/COMPLETE_PAYMENT_INTEGRATION.md) - Payment setup

---

## 💰 **Cost Breakdown**

| Service | Cost |
|---------|------|
| Railway Backend | $0 (free $5 credit) |
| Vercel Frontend | $0 (free tier) |
| PostgreSQL | $0 (included) |
| Resend Email | $0 (100/day free) |
| Lemon Squeezy | $0 (test mode) |
| Stripe | $0 (test mode) |
| **Total** | **$0/month** |

---

## 🎯 **Next Steps After Testing**

1. Invite beta testers
2. Monitor logs for 24 hours
3. Fix any issues
4. Add custom domain (optional)
5. Switch to production API keys
6. Launch!

---

## 📞 **Need Help?**

- Railway Discord: https://discord.gg/railway
- Vercel Discord: https://vercel.com/discord
- Tiannara Docs: See docs/deployment/ folder

---

**Ready to deploy? Start with Step 1!** 🚀
