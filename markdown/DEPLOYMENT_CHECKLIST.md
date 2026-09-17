# Tiannara SaaS Deployment Checklist

**Use this checklist to ensure successful deployment**

---

## 📋 **Pre-Deployment Preparation**

### **Code & Repository**
- [ ] All code committed to Git
- [ ] Latest changes pushed to GitHub
- [ ] `.gitignore` includes `.env`, `node_modules`, caches
- [ ] `Procfile` created (for Railway/Heroku)
- [ ] `runtime.txt` created (Python version specified)
- [ ] `requirements.txt` updated with all dependencies
- [ ] No hardcoded secrets in code

### **Payment Providers**
- [ ] Lemon Squeezy account created
- [ ] 3 products created (Starter, Professional, Enterprise)
- [ ] Variant IDs copied
- [ ] API key generated
- [ ] Store ID noted
- [ ] Stripe account created
- [ ] Products and prices created
- [ ] Price IDs copied
- [ ] API keys (secret + publishable) obtained

### **Email Service**
- [ ] Resend account created (or SendGrid/SMTP configured)
- [ ] API key obtained
- [ ] Verified sender email address

---

## 🚀 **Railway Backend Deployment**

### **1. Create Project**
- [ ] Signed up at railway.app
- [ ] Created new project
- [ ] Connected GitHub repository

### **2. Database Setup**
- [ ] Added PostgreSQL database service
- [ ] Copied DATABASE_URL
- [ ] Verified database is running

### **3. Deploy Backend**
- [ ] Selected GitHub repo for deployment
- [ ] Railway detected Python/FastAPI
- [ ] Deployment started

### **4. Environment Variables**
Add these in Railway → Backend → Variables:

**Application:**
- [ ] `APP_NAME=Tiannara MindCache SaaS`
- [ ] `APP_ENV=production`
- [ ] `DEBUG=false`
- [ ] `SECRET_KEY=<generated>`
- [ ] `ALLOWED_HOSTS=<your-railway-domain>.railway.app`

**Database:**
- [ ] `DATABASE_URL=<from PostgreSQL service>`

**Payment - Default Provider:**
- [ ] `PAYMENT_PROVIDER=lemon_squeezy`

**Payment - Lemon Squeezy:**
- [ ] `LEMON_SQUEEZY_API_KEY=<your-key>`
- [ ] `LEMON_SQUEEZY_STORE_ID=<your-store-id>`
- [ ] `LEMON_SQUEEZY_WEBHOOK_SECRET=<will-update-after-webhook-setup>`
- [ ] `LEMON_SQUEEZY_TEST_MODE=true`
- [ ] `LS_STARTER_VARIANT_ID=<variant-id>`
- [ ] `LS_PRO_VARIANT_ID=<variant-id>`
- [ ] `LS_ENTERPRISE_VARIANT_ID=<variant-id>`

**Payment - Stripe:**
- [ ] `STRIPE_SECRET_KEY=sk_test_<your-key>`
- [ ] `STRIPE_PUBLISHABLE_KEY=pk_test_<your-key>`
- [ ] `STRIPE_WEBHOOK_SECRET=<will-update-after-webhook-setup>`
- [ ] `STRIPE_STARTER_PRICE_ID=price_<id>`
- [ ] `STRIPE_PRO_PRICE_ID=price_<id>`
- [ ] `STRIPE_ENTERPRISE_PRICE_ID=price_<id>`

**Authentication:**
- [ ] `JWT_SECRET_KEY=<generated>`
- [ ] `JWT_ALGORITHM=HS256`
- [ ] `JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30`

**Email:**
- [ ] `RESEND_API_KEY=re_<your-key>`
- [ ] `EMAIL_FROM=noreply@tiannara.com`

**CORS:**
- [ ] `CORS_ORIGINS=https://<your-frontend>.vercel.app,http://localhost:3001`

**API:**
- [ ] `API_V1_PREFIX=/api/v1`

**Logging:**
- [ ] `LOG_LEVEL=INFO`

### **5. Verify Backend**
- [ ] Deployment successful (green checkmark)
- [ ] Backend URL noted: `https://<your-app>.up.railway.app`
- [ ] Visit `/docs` endpoint - Swagger UI loads
- [ ] Test `/api/v1/payment/providers` - Returns JSON
- [ ] Check logs for errors

---

## 🎨 **Vercel Frontend Deployment**

### **1. Create Project**
- [ ] Signed up at vercel.com
- [ ] Clicked "Add New Project"
- [ ] Imported GitHub repository

### **2. Configure Build Settings**
- [ ] Framework preset: Next.js
- [ ] Root directory: `tiannara_gui` (if applicable)
- [ ] Build command: `npm run build`
- [ ] Output directory: `.next`

### **3. Environment Variables**
Add in Vercel → Settings → Environment Variables:

- [ ] `NEXT_PUBLIC_API_URL=https://<your-backend>.railway.app`
- [ ] `NEXTAUTH_SECRET=<generated>`
- [ ] `NEXTAUTH_URL=https://<your-frontend>.vercel.app`
- [ ] `NEXT_PUBLIC_PAYMENT_PROVIDER=lemon_squeezy`

### **4. Deploy**
- [ ] Deployment triggered
- [ ] Build successful
- [ ] Frontend URL noted: `https://<your-app>.vercel.app`
- [ ] Site loads without errors

### **5. Update CORS**
- [ ] Go back to Railway
- [ ] Update `CORS_ORIGINS` to include Vercel domain
- [ ] Redeploy backend (auto-triggered on env change)

---

## 🔗 **Webhook Configuration**

### **Lemon Squeezy Webhook**
- [ ] Railway backend URL copied
- [ ] Lemon Squeezy Dashboard → Settings → Webhooks
- [ ] Added endpoint: `https://<backend>.railway.app/api/v1/payment/webhook`
- [ ] Selected events:
  - [ ] subscription_created
  - [ ] subscription_updated
  - [ ] subscription_cancelled
  - [ ] order_created
- [ ] Signing secret copied
- [ ] Updated Railway: `LEMON_SQUEEZY_WEBHOOK_SECRET`
- [ ] Backend redeployed

### **Stripe Webhook**
- [ ] Stripe Dashboard → Developers → Webhooks
- [ ] Added endpoint: `https://<backend>.railway.app/api/v1/payment/webhook`
- [ ] Selected events:
  - [ ] checkout.session.completed
  - [ ] invoice.payment_succeeded
  - [ ] customer.subscription.deleted
- [ ] Signing secret copied
- [ ] Updated Railway: `STRIPE_WEBHOOK_SECRET`
- [ ] Backend redeployed

---

## 🧪 **End-to-End Testing**

### **Backend Tests**
- [ ] `GET /docs` - Swagger UI loads
- [ ] `GET /api/v1/payment/providers` - Returns providers list
- [ ] `GET /api/v1/payment/plans` - Returns pricing plans
- [ ] Health check passes

### **Frontend Tests**
- [ ] Homepage loads
- [ ] Signup page accessible
- [ ] Login page accessible
- [ ] No console errors

### **Authentication Flow**
- [ ] User can sign up
- [ ] OTP email received (check Resend dashboard)
- [ ] OTP verification works
- [ ] User can login
- [ ] Session persists
- [ ] Logout works

### **Dashboard Tests**
- [ ] Dashboard loads after login
- [ ] User profile displays
- [ ] Usage metrics show (may be zero initially)
- [ ] Navigation works

### **Payment Flow**
- [ ] Navigate to billing page
- [ ] Pricing plans display correctly
- [ ] Provider selection works (if implemented)
- [ ] Click "Subscribe" redirects to payment provider
- [ ] Test card accepted: `4242 4242 4242 4242`
- [ ] Payment completes successfully
- [ ] Redirect to success page
- [ ] User tier updated in database
- [ ] Webhook received (check Railway logs)

### **Admin Dashboard** (if admin user)
- [ ] Admin view accessible
- [ ] System metrics display
- [ ] Real-time updates work

---

## 📊 **Monitoring Setup**

### **Railway Monitoring**
- [ ] Backend logs accessible
- [ ] No error spikes
- [ ] Database connection stable
- [ ] Memory/CPU usage normal

### **Vercel Monitoring**
- [ ] Deployment logs clean
- [ ] Function logs accessible
- [ ] No runtime errors

### **Payment Provider Monitoring**
- [ ] Lemon Squeezy webhook delivery successful
- [ ] Stripe webhook delivery successful
- [ ] No failed payments in test mode

### **Email Service Monitoring**
- [ ] Resend dashboard shows emails sent
- [ ] No bouncebacks
- [ ] Delivery rate 100%

---

## 🔒 **Security Checks**

- [ ] No `.env` file committed to Git
- [ ] All API keys stored in platform env vars
- [ ] DEBUG=false in production
- [ ] SECRET_KEY is strong random string
- [ ] JWT_SECRET_KEY is strong random string
- [ ] CORS restricted to your domains only
- [ ] HTTPS enforced (automatic on Railway/Vercel)
- [ ] Database credentials not hardcoded

---

## 📱 **Mobile Responsiveness**

- [ ] Test on iPhone Safari
- [ ] Test on Android Chrome
- [ ] Test on iPad
- [ ] All pages responsive
- [ ] Touch interactions work
- [ ] Forms usable on mobile

---

## 🐛 **Bug Fixes**

Common issues and fixes:

**Issue**: Backend won't start
- [ ] Check Railway logs for errors
- [ ] Verify DATABASE_URL format
- [ ] Ensure all required env vars set
- [ ] Check requirements.txt has all deps

**Issue**: CORS errors
- [ ] Update CORS_ORIGINS in Railway
- [ ] Include both Vercel domain and localhost
- [ ] Redeploy backend

**Issue**: Webhooks not working
- [ ] Verify webhook URL is correct
- [ ] Check signing secrets match
- [ ] Review Railway logs for webhook receipt
- [ ] Test with provider's webhook test tool

**Issue**: Database migration failed
- [ ] Run migrations manually in Railway shell
- [ ] Check migration files exist
- [ ] Verify database permissions

**Issue**: Email not sending
- [ ] Verify RESEND_API_KEY is correct
- [ ] Check sender email is verified in Resend
- [ ] Review Railway logs for email errors

---

## ✅ **Final Verification**

Before announcing deployment:

- [ ] All critical features tested
- [ ] No console errors in browser
- [ ] No server errors in logs
- [ ] Payment flow works end-to-end
- [ ] Webhooks processing correctly
- [ ] Mobile experience acceptable
- [ ] Performance acceptable (<2s page loads)
- [ ] Security checklist complete
- [ ] Documentation updated

---

## 🎉 **Deployment Complete!**

Once all items checked:

1. **Share with beta testers**
2. **Monitor logs closely first 24 hours**
3. **Collect feedback**
4. **Fix any issues reported**
5. **Plan custom domain setup**

---

## 📞 **Support Resources**

- **Railway Support**: https://railway.app/support
- **Vercel Support**: https://vercel.com/support
- **Tiannara Docs**: See docs/deployment/ folder
- **Payment Guide**: COMPLETE_PAYMENT_INTEGRATION.md

---

**Good luck with your deployment!** 🚀💪
