# 🚀 Tiannara MindCache - Quick Launch Guide

## ⏱️ 3-Hour Launch Plan

### Hour 1: Stripe Setup (30 min)

```bash
# 1. Create Stripe account
Visit: https://stripe.com → "Start now"

# 2. Get API keys
Dashboard → Developers → API keys
Copy: sk_test_=sk_test_51QTIzlAU1LDAUc9qbzLcfqzYSCqmSwAvJR0ocxErS3u9qEZAqXM5BwQ6Voo7snfjyC9nJoF8nA7DPSpu5CA0H3r9000DjttXIB
pk_test_=pk_test_51QTIzlAU1LDAUc9q4hbOA7CNjaxn13B1Pimy3xLmY9oKRmfzfceT5Z7Z4T5FaRflLOhqQybMw9pxkEK9X3sscHHW00snKGD5Zf

# 3. Create 3 products
Dashboard → Products → Add product

**Product 1: Starter Plan ($49/month)**
```
Name: Tiannara Starter
Description: Perfect for developers and small teams exploring cross-domain AI reasoning. Get 5,000 API requests/month with access to 4 reasoning domains (Algorithm, Logic, Reverse Engineering, Causal). Includes automatic skill transfer (>97% success rate) so knowledge learned in one domain automatically improves performance in others. Ideal for prototyping, research projects, and small-scale applications.
Price: $49/month (recurring)
Features:
- 5,000 API requests/month
- Access to 4 reasoning domains
- Cross-domain skill transfer enabled
- Stagnation detection & adaptive strategies
- Standard email support
- API documentation access
- Community forum access
```

**Product 2: Professional Plan ($199/month)**
```
Name: Tiannara Professional
Description: Built for growing businesses and production applications requiring reliable AI reasoning at scale. Get 50,000 API requests/month with priority processing, advanced analytics, and dedicated support. Perfect for companies integrating AI reasoning into customer-facing products, internal decision-making systems, or complex workflow automation. Includes all Starter features plus enhanced performance guarantees and faster response times.
Price: $199/month (recurring)
Features:
- 50,000 API requests/month
- Access to 10 reasoning domains
- Priority API processing (faster response times)
- Advanced analytics dashboard
- Custom domain configuration
- Priority email support (24-hour response)
- Webhook notifications
- SLA guarantee (99.5% uptime)
- Monthly performance reports
```

**Product 3: Enterprise Plan ($999/month)**
```
Name: Tiannara Enterprise
Description: Complete AI reasoning infrastructure for large organizations with mission-critical applications. Unlimited API requests, unlimited domains, custom model training, and white-glove support. Designed for enterprises building AI-powered products at scale, requiring regulatory compliance (EU AI Act), explainable AI decisions, and guaranteed performance. Includes dedicated account manager, custom integrations, and on-premise deployment options.
Price: $999/month (recurring)
Features:
- Unlimited API requests
- Unlimited reasoning domains
- Custom model training & fine-tuning
- Dedicated account manager
- 24/7 phone & email support
- Custom SLA (99.9% uptime)
- On-premise deployment option
- EU AI Act compliance tools
- Explainable AI reports
- Custom integrations & APIs
- Quarterly strategy reviews
- Early access to new features
Copy Price IDs (price_...)

# 4. Set up webhook
Dashboard → Developers → Webhooks
URL: https://your-domain.com/api/v1/payment/webhook
Events: checkout.session.completed, invoice.payment_succeeded
Copy: whsec_...
```

---

### Hour 2: Configure & Test (45 min)

```bash
# 1. Copy environment file
cp .env.example .env

# 2. Edit .env with your keys
nano .env  # or use any text editor

# Required values:
STRIPE_SECRET_KEY=sk_test_your_key
STRIPE_PUBLISHABLE_KEY=pk_test_your_key
STRIPE_WEBHOOK_SECRET=whsec_your_secret
STRIPE_STARTER_PRICE_ID=price_starter_id
STRIPE_PRO_PRICE_ID=price_pro_id
STRIPE_ENTERPRISE_PRICE_ID=price_enterprise_id
JWT_SECRET_KEY=<run: python -c "import secrets; print(secrets.token_urlsafe(32))">

# 3. Install dependencies
pip install -r requirements-production.txt

# 4. Run tests
python test_payment_integration.py

# Should see: ✅ All tests passed!
```

---

### Hour 3: Deploy (45 min)

#### Option A: Render (Recommended - Free)

```
1. Visit: https://render.com
2. Sign up with GitHub
3. New + → Web Service
4. Connect repository
5. Configure:
   - Name: tiannara-mindcache
   - Build Command: pip install -r requirements-production.txt
   - Start Command: uvicorn tiannara_api.main_production:app --host 0.0.0.0 --port $PORT
6. Add environment variables (from .env)
7. Click "Create Web Service"
8. Wait 3-5 minutes for deployment
9. Note URL: https://tiannara-mindcache.onrender.com
```

#### Option B: Railway ($5/month)

```bash
npm i -g @railway/cli
railway login
railway up
```

#### Deploy Landing Page

```
Option 1: GitHub Pages (Free)
git checkout --orphan gh-pages
cp landing-page.html index.html
git add index.html
git commit -m "Launch landing page"
git push origin gh-pages
Settings → Pages → Enable from gh-pages branch

Option 2: Netlify (Free - Easiest)
Visit: https://netlify.com
Drag folder containing landing-page.html
Get instant URL
```

---

## ✅ Verify Everything Works

```bash
# Test deployed API
curl https://your-app.onrender.com/api/v1/payment/plans

# Should return JSON with pricing plans

# Test landing page
open https://your-site.netlify.app

# Test Stripe webhook
# In Stripe Dashboard → Webhooks → Send test webhook
```

---

## 📧 Start Outreach (Day 2)

### Morning: Prepare (2 hours)

1. **Customize email templates** (see CLIENT_OUTREACH_PLAN.md)
2. **Record 5-min demo video** showing skill transfer
3. **Research 20 prospects** (see target list in CLIENT_OUTREACH_PLAN.md)

### Afternoon: Send Emails (2 hours)

```
Send 10 emails using this template:

Subject: AI reasoning that transfers skills across domains (92% success rate)

Hi [Name],

I noticed [Company] is working on [specific problem].

I've built an AI system that solves problems current AI can't:

✅ Cross-domain skill transfer (>97% success)
✅ Learns from failures automatically
✅ Explains reasoning (EU AI Act compliant)
✅ 92% success rate across 4 domains

Would you be open to a 15-minute demo?

Best,
[Your Name]
```

---

## 🎯 Expected Results

| Timeline | Goal | Metric |
|----------|------|--------|
| Week 1 | Launch complete | API live, 20 emails sent |
| Week 2 | First interest | 5 responses, 2 demos |
| Week 3 | First customer | 1 consulting client signed |
| Month 1 | Traction | 3 customers, $5K MRR |
| Month 3 | Growth | 10 customers, $15K MRR |

---

## 🔗 Quick Links

- **Full Launch Guide**: `LAUNCH_CHECKLIST.md`
- **Payment Setup**: `PAYMENT_SETUP_GUIDE.md`
- **API Docs**: `API_DOCUMENTATION.md`
- **Consulting Packages**: `CONSULTING_SERVICES.md`
- **Client List**: `CLIENT_OUTREACH_PLAN.md`
- **Value Proposition**: `PROBLEMS_TIANNARA_SOLVES.md`

---

## 🆘 Troubleshooting

### Stripe Issues

**Error: Invalid API key**
```
Solution: Make sure you're using sk_test_ (test mode) not sk_live_
```

**Webhook not receiving events**
```
Solution: 
1. Check URL is correct (https://.../api/v1/payment/webhook)
2. Verify signature in .env matches Stripe dashboard
3. Test locally: stripe listen --forward-to localhost:8000/api/v1/payment/webhook
```

### Deployment Issues

**App crashes on startup**
```bash
# Check logs
render logs  # or heroku logs --tail

# Common fixes:
# 1. Verify all env vars are set
# 2. Check requirements-production.txt has all dependencies
# 3. Ensure Procfile is correct
```

**CORS errors**
```
Solution: Update CORS_ORIGINS in .env to include your frontend domain
```

---

## 💰 Revenue Calculator

### Conservative Estimate (Month 1)
```
2 Starter customers × $49 = $98
1 Professional customer × $199 = $199
1 Consulting project × $5,000 = $5,000
Total: $5,297
```

### Moderate Estimate (Month 3)
```
5 Starter customers × $49 = $245
3 Professional customers × $199 = $597
1 Enterprise customer × $999 = $999
2 Consulting projects × $7,500 = $15,000
Total: $16,841/month
```

### Aggressive Estimate (Month 6)
```
15 Starter customers × $49 = $735
8 Professional customers × $199 = $1,592
3 Enterprise customers × $999 = $2,997
4 Consulting projects × $10,000 = $40,000
Total: $45,324/month
```

---

## 🚀 You're Ready!

**Next Step:** Open `LAUNCH_CHECKLIST.md` and start at Step 1.

**Time to Launch:** 2-3 hours  
**Time to First Dollar:** 24-48 hours  

Good luck! 🎉
