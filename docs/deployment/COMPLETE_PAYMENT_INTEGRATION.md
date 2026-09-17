# Complete Payment Integration Guide

**Date**: May 1, 2026  
**Status**: ✅ **FULLY IMPLEMENTED**  
**Providers**: Lemon Squeezy + Stripe (Both Integrated!)

---

## 🎯 **Your Questions Answered**

### **Q1: Can I integrate BOTH Stripe and Lemon Squeezy?**

✅ **YES!** You can use both simultaneously. The system now supports:

1. **Default Provider**: Set in `.env` (`PAYMENT_PROVIDER=lemon_squeezy`)
2. **Per-Transaction Override**: Choose provider at checkout time
3. **Customer Choice**: Let users pick their preferred provider

### **Q2: Does the website need a custom domain?**

❌ **NO!** You can use:
- ✅ `localhost` for development
- ✅ Free subdomains (e.g., `tiannara.vercel.app`, `tiannara.herokuapp.com`)
- ✅ Custom domains (optional, for branding)

**However**, payment providers require:
- ✅ A valid callback/success URL (can be localhost during testing)
- ✅ HTTPS in production (most hosting provides this free)
- ✅ Webhook endpoint accessible from internet (use ngrok for local testing)

### **Q3: What about product descriptions?**

Each provider needs product information:

**Lemon Squeezy:**
- Product name and description
- Pricing tiers
- Variant IDs (for each plan)

**Stripe:**
- Product objects with descriptions
- Price objects (recurring subscriptions)
- Price IDs

**You configure these in each provider's dashboard**, not in code.

---

## 🚀 **Complete Integration Steps**

### **Step 1: Configure Both Providers**

#### **A. Lemon Squeezy Setup**

1. **Sign In**: https://app.lemonsqueezy.com
2. **Create Store** (if not done):
   - Store name: "Tiannara MindCache"
   - Description: "AI-powered reasoning and cognitive prosthetic platform"
   - Website URL: Your site URL (can be localhost for testing)

3. **Create Products**:
   
   **Product 1: Tiannara Starter**
   ```
   Name: Tiannara Starter
   Description: Perfect for individuals and small teams getting started with AI reasoning
   Price: $49/month
   Features:
   - 5,000 API requests/month
   - Core reasoning engine
   - Basic analytics
   - Email support
   ```
   → Copy **Variant ID** (e.g., `123456`)

   **Product 2: Tiannara Professional**
   ```
   Name: Tiannara Professional
   Description: Advanced features for growing teams and businesses
   Price: $199/month
   Features:
   - 50,000 API requests/month
   - Advanced workflows
   - Team collaboration
   - Priority support
   - Webhooks & integrations
   ```
   → Copy **Variant ID** (e.g., `123457`)

   **Product 3: Tiannara Enterprise**
   ```
   Name: Tiannara Enterprise
   Description: Unlimited access for large organizations
   Price: $999/month
   Features:
   - Unlimited API requests
   - Dedicated support
   - Custom integrations
   - SLA guarantee
   - Private deployment options
   ```
   → Copy **Variant ID** (e.g., `123458`)

4. **Get API Credentials**:
   - Settings → API → Create API Key
   - Copy: **API Key** (starts with `eyJ...`)
   - Copy: **Store ID** (numeric)

5. **Configure Webhooks**:
   - Settings → Webhooks → Add Endpoint
   - URL: `https://your-domain.com/api/v1/payment/webhook`
   - Events to subscribe:
     - ✅ `subscription_created`
     - ✅ `subscription_updated`
     - ✅ `subscription_cancelled`
     - ✅ `order_created`
   - Copy: **Signing Secret**

#### **B. Stripe Setup**

1. **Sign In**: https://dashboard.stripe.com
2. **Create Products**:
   
   Go to **Products → Add Product**

   **Product: Tiannara Subscriptions**
   ```
   Name: Tiannara MindCache
   Description: AI-powered reasoning and cognitive prosthetic platform
   
   Pricing:
   - Starter: $49/month (recurring)
   - Professional: $199/month (recurring)
   - Enterprise: $999/month (recurring)
   ```

3. **Get Price IDs**:
   - Click on each price
   - Copy **Price ID** (starts with `price_`)
   - Example: `price_1ABC123DEF456`

4. **Get API Keys**:
   - Developers → API keys
   - Copy **Secret Key** (starts with `sk_test_`)
   - Copy **Publishable Key** (starts with `pk_test_`)

5. **Configure Webhooks**:
   - Developers → Webhooks → Add endpoint
   - URL: `https://your-domain.com/api/v1/payment/webhook`
   - Events:
     - ✅ `checkout.session.completed`
     - ✅ `invoice.payment_succeeded`
     - ✅ `customer.subscription.deleted`
   - Copy: **Signing Secret** (starts with `whsec_`)

---

### **Step 2: Update .env File**

```bash
# ==================== Payment Configuration ====================

# Default provider (used when no provider specified)
PAYMENT_PROVIDER=lemon_squeezy

# --- Lemon Squeezy Configuration ---
LEMON_SQUEEZY_API_KEY=eyJwcm9kdWN0aW9uIjoi...
LEMON_SQUEEZY_STORE_ID=12345
LEMON_SQUEEZY_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxx
LEMON_SQUEEZY_TEST_MODE=true  # Set to false in production

# Lemon Squeezy Variant IDs
LS_STARTER_VARIANT_ID=123456
LS_PRO_VARIANT_ID=123457
LS_ENTERPRISE_VARIANT_ID=123458

# --- Stripe Configuration ---
STRIPE_SECRET_KEY=sk_test_xxxxxxxxxxxxxxxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxx

# Stripe Price IDs
STRIPE_STARTER_PRICE_ID=price_1ABC...
STRIPE_PRO_PRICE_ID=price_2DEF...
STRIPE_ENTERPRISE_PRICE_ID=price_3GHI...
```

---

### **Step 3: Test Both Providers**

#### **Test Lemon Squeezy**

```bash
# Start backend
uvicorn tiannara_api.main:app --reload

# Create checkout session (uses default provider)
curl -X POST http://localhost:8000/api/v1/payment/subscribe \
  -H "Content-Type: application/json" \
  -d '{
    "plan": "starter",
    "success_url": "http://localhost:3001/billing/success",
    "cancel_url": "http://localhost:3001/billing/cancel",
    "customer_email": "test@example.com"
  }'
```

Expected response:
```json
{
  "session_id": "chk_xxxxxxxx",
  "checkout_url": "https://tiannara.lemonsqueezy.com/checkout/...",
  "provider": "lemon_squeezy"
}
```

#### **Test Stripe**

```bash
# Explicitly request Stripe
curl -X POST http://localhost:8000/api/v1/payment/subscribe \
  -H "Content-Type: application/json" \
  -d '{
    "plan": "professional",
    "success_url": "http://localhost:3001/billing/success",
    "cancel_url": "http://localhost:3001/billing/cancel",
    "customer_email": "test@example.com",
    "provider": "stripe"
  }'
```

Expected response:
```json
{
  "session_id": "cs_test_xxxxxxxx",
  "checkout_url": "https://checkout.stripe.com/...",
  "provider": "stripe"
}
```

#### **List Available Providers**

```bash
curl http://localhost:8000/api/v1/payment/providers
```

Response:
```json
{
  "available_providers": ["lemon_squeezy", "stripe"],
  "default_provider": "lemon_squeezy",
  "provider_info": {
    "lemon_squeezy": {
      "name": "Lemon Squeezy",
      "description": "No business registration required, handles taxes/VAT",
      "fees": "5% + $0.50 per transaction",
      "best_for": "Unregistered businesses, global SaaS"
    },
    "stripe": {
      "name": "Stripe",
      "description": "Individual accounts allowed, lower fees",
      "fees": "2.9% + $0.30 per transaction",
      "best_for": "Developers familiar with Stripe"
    }
  }
}
```

---

## 💻 **Frontend Integration**

### **Option 1: Use Default Provider**

```typescript
// Frontend (React/Next.js)
const handleSubscribe = async (plan: string) => {
  const response = await fetch('/api/v1/payment/subscribe', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      plan: plan,
      success_url: window.location.origin + '/billing/success',
      cancel_url: window.location.origin + '/billing/cancel',
      customer_email: user.email
      // No provider specified - uses default from .env
    })
  });
  
  const data = await response.json();
  window.location.href = data.checkout_url;
};
```

### **Option 2: Let User Choose Provider**

```typescript
// Billing page with provider selection
const [selectedProvider, setSelectedProvider] = useState('lemon_squeezy');

const handleSubscribe = async (plan: string) => {
  const response = await fetch('/api/v1/payment/subscribe', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      plan: plan,
      success_url: window.location.origin + '/billing/success',
      cancel_url: window.location.origin + '/billing/cancel',
      customer_email: user.email,
      provider: selectedProvider  // User's choice
    })
  });
  
  const data = await response.json();
  window.location.href = data.checkout_url;
};

// UI
<div className="provider-selection">
  <label>
    <input 
      type="radio" 
      value="lemon_squeezy"
      checked={selectedProvider === 'lemon_squeezy'}
      onChange={(e) => setSelectedProvider(e.target.value)}
    />
    Lemon Squeezy (Recommended)
  </label>
  <label>
    <input 
      type="radio" 
      value="stripe"
      checked={selectedProvider === 'stripe'}
      onChange={(e) => setSelectedProvider(e.target.value)}
    />
    Stripe
  </label>
</div>
```

### **Option 3: Fetch Available Providers**

```typescript
// Load available providers on page load
useEffect(() => {
  fetch('/api/v1/payment/providers')
    .then(res => res.json())
    .then(data => {
      setProviders(data.available_providers);
      setDefaultProvider(data.default_provider);
    });
}, []);
```

---

## 🌐 **Domain Requirements**

### **Development (Localhost)**

✅ **Works perfectly with localhost**

```bash
# Backend
uvicorn tiannara_api.main:app --reload
# Runs on: http://localhost:8000

# Frontend
npm run dev
# Runs on: http://localhost:3001
```

**Webhook Testing**:
```bash
# Install ngrok
npm install -g ngrok

# Expose local server
ngrok http 8000

# Use the ngrok URL in provider dashboards:
# https://xxxx.ngrok.io/api/v1/payment/webhook
```

### **Production (Free Hosting Options)**

✅ **No custom domain required!**

**Option 1: Vercel (Frontend)**
- Free subdomain: `tiannara.vercel.app`
- Automatic HTTPS
- Easy deployment from GitHub

**Option 2: Railway/Render (Backend)**
- Free subdomain: `tiannara-api.railway.app`
- Automatic HTTPS
- PostgreSQL included

**Option 3: Heroku**
- Free subdomain: `tiannara.herokuapp.com`
- Automatic HTTPS

**Webhook URLs in Production**:
```
Lemon Squeezy: https://tiannara-api.railway.app/api/v1/payment/webhook
Stripe: https://tiannara-api.railway.app/api/v1/payment/webhook
```

### **Custom Domain (Optional)**

If you want a custom domain later:
1. Buy domain (e.g., `tiannara.com`)
2. Point DNS to your hosting provider
3. Update webhook URLs in provider dashboards
4. Update CORS settings in `.env`

---

## 📝 **Product Descriptions Template**

Use these descriptions in both Lemon Squeezy and Stripe:

### **Starter Plan ($49/month)**
```
Name: Tiannara Starter
Description: Perfect for individuals and small teams getting started with AI-powered reasoning and cognitive assistance.

Features:
• 5,000 API requests per month
• Access to core reasoning engine
• Basic analytics dashboard
• Email support (48-hour response)
• 2 domain engines
• Standard skill transfer

Best for: Solo developers, students, small projects
```

### **Professional Plan ($199/month)**
```
Name: Tiannara Professional
Description: Advanced features for growing teams and businesses that need powerful AI reasoning at scale.

Features:
• 50,000 API requests per month
• Advanced workflow automation
• Team collaboration tools
• Priority support (24-hour response)
• 10 domain engines
• Full skill transfer capabilities
• Webhooks & API integrations
• Advanced analytics & reporting

Best for: Startups, growing teams, production applications
```

### **Enterprise Plan ($999/month)**
```
Name: Tiannara Enterprise
Description: Unlimited access and dedicated support for large organizations requiring maximum performance and customization.

Features:
• Unlimited API requests
• Unlimited domain engines
• Dedicated account manager
• 24/7 priority support (1-hour response)
• Custom integrations & APIs
• SLA guarantee (99.9% uptime)
• Private deployment options
• Custom training & onboarding
• Advanced security features
• White-label options

Best for: Large enterprises, mission-critical applications
```

---

## 🔧 **Website/Product URL Requirements**

### **What Payment Providers Ask For**

Both Lemon Squeezy and Stripe will ask for:

1. **Company/Business Name**: "Tiannara MindCache" or your name
2. **Website URL**: 
   - Development: `http://localhost:3001` ✅
   - Staging: `https://tiannara-staging.vercel.app` ✅
   - Production: `https://tiannara.com` or `https://tiannara.vercel.app` ✅
3. **Product Description**: Use templates above
4. **Support Email**: Your email address
5. **Terms of Service**: Can link to a simple page or GitHub README
6. **Privacy Policy**: Can use a template generator

### **Do You Need a Live Website?**

**For Testing**: ❌ NO
- Use localhost
- Use test mode in providers

**For Going Live**: ✅ YES (but doesn't need to be fancy)
- Minimum viable site with:
  - Landing page explaining Tiannara
  - Pricing page
  - Contact/support info
  - Terms of Service
  - Privacy Policy

**Quick Solution**: Use a simple landing page builder:
- Carrd.co ($19/year)
- Notion + Super.so (free tier)
- GitHub Pages (free)
- Vercel deploy from template (free)

---

## ✅ **Integration Checklist**

### **Lemon Squeezy**
- [ ] Create account at lemonsqueezy.com
- [ ] Create store with product descriptions
- [ ] Create 3 pricing variants (Starter, Pro, Enterprise)
- [ ] Get API key and Store ID
- [ ] Configure webhooks
- [ ] Add credentials to .env
- [ ] Test checkout flow
- [ ] Verify webhook delivery

### **Stripe**
- [ ] Create account at stripe.com
- [ ] Create products and prices
- [ ] Get API keys (secret + publishable)
- [ ] Configure webhooks
- [ ] Add credentials to .env
- [ ] Test checkout flow
- [ ] Verify webhook delivery

### **Backend**
- [ ] Both providers configured in .env
- [ ] Backend running on port 8000
- [ ] Test `/api/v1/payment/providers` endpoint
- [ ] Test Lemon Squeezy checkout
- [ ] Test Stripe checkout
- [ ] Test webhook handling

### **Frontend**
- [ ] Billing page created
- [ ] Provider selection UI (optional)
- [ ] Subscribe button working
- [ ] Success/cancel pages created
- [ ] Test end-to-end flow

### **Production Readiness**
- [ ] Switch to live API keys
- [ ] Update webhook URLs to production domain
- [ ] Set `LEMON_SQUEEZY_TEST_MODE=false`
- [ ] Test with real card (small amount)
- [ ] Monitor first transactions
- [ ] Set up error alerts

---

## 🎉 **Summary**

✅ **Both Stripe AND Lemon Squeezy integrated**  
✅ **No custom domain required** (localhost works for testing)  
✅ **Product descriptions provided** (copy-paste ready)  
✅ **Per-transaction provider selection** supported  
✅ **Complete documentation** created  

**You're ready to accept payments!** 💰🚀

---

## 📞 **Need Help?**

- **Setup Guide**: [docs/deployment/PAYMENT_SETUP_GUIDE.md](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/docs/deployment/PAYMENT_SETUP_GUIDE.md)
- **Quick Reference**: [PAYMENT_QUICK_REF.md](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/PAYMENT_QUICK_REF.md)
- **Fix Summary**: [PAYMENT_FIX_SUMMARY.md](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/PAYMENT_FIX_SUMMARY.md)

**Lemon Squeezy Support**: help@lemonsqueezy.com  
**Stripe Support**: https://support.stripe.com
