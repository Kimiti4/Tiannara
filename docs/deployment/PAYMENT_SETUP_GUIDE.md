# Payment Provider Setup Guide for Tiannara SaaS

**Date**: May 1, 2026  
**Status**: ✅ **IMPLEMENTED**  
**Recommended Provider**: Lemon Squeezy (no business registration required)

---

## 🎯 **Payment Provider Comparison**

| Provider | Business Registration | Best For | Fees | Setup Time |
|----------|----------------------|----------|------|------------|
| **Lemon Squeezy** ⭐ | ❌ Not Required | Global SaaS, unregistered businesses | 5% + $0.50 | 1-2 hours |
| **Stripe** | ❌ Not Required (individual) | Developers familiar with Stripe | 2.9% + $0.30 | 30 min |
| **Paystack** | ✅ Required | African markets (Nigeria, Ghana, Kenya) | 1.5% + ₦100 | 2-3 days |
| **Paddle** | ❌ Not Required | Software products, global sales | 5% + $0.50 | 1-2 hours |
| **Flutterwave** | ✅ Required | African markets | Varies | 2-3 days |

---

## 🚀 **Quick Start: Lemon Squeezy (RECOMMENDED)**

### **Why Lemon Squeezy?**

✅ **No business registration required** - Acts as Merchant of Record  
✅ **Handles global taxes/VAT automatically** - No compliance headaches  
✅ **Built-in subscription management** - Less code to maintain  
✅ **Developer-friendly API** - Simple integration  
✅ **Supports 135+ currencies** - Accept payments globally  
✅ **Test mode available** - Develop without real charges  

### **Step 1: Create Lemon Squeezy Account**

1. Sign up at [https://lemonsqueezy.com](https://lemonsqueezy.com)
2. Complete your profile (individual or business)
3. Navigate to **Settings → Stores**
4. Copy your **Store ID**

### **Step 2: Create Products & Variants**

1. Go to **Products → Add Product**
2. Create three products (or one product with three variants):

   **Starter Plan:**
   - Name: "Tiannara Starter"
   - Price: $49/month
   - Copy the **Variant ID**

   **Professional Plan:**
   - Name: "Tiannara Professional"
   - Price: $199/month
   - Copy the **Variant ID**

   **Enterprise Plan:**
   - Name: "Tiannara Enterprise"
   - Price: $999/month
   - Copy the **Variant ID**

### **Step 3: Get API Keys**

1. Go to **Settings → API**
2. Click **Create API Key**
3. Give it a name (e.g., "Tiannara SaaS")
4. Copy the **API Key** (starts with `eyJ...`)

### **Step 4: Configure Webhooks**

1. Go to **Settings → Webhooks**
2. Click **Add Endpoint**
3. URL: `https://api.tiannara.com/api/v1/payment/webhook`
4. Select events:
   - ✅ `subscription_created`
   - ✅ `subscription_updated`
   - ✅ `subscription_cancelled`
   - ✅ `order_created`
5. Copy the **Signing Secret**

### **Step 5: Update .env File**

```bash
# ==================== Payment Configuration ====================

# Select payment provider: lemon_squeezy, stripe
PAYMENT_PROVIDER=lemon_squeezy

# Lemon Squeezy Configuration
LEMON_SQUEEZY_API_KEY=eyJwcm9kdWN0aW9uIjoi...
LEMON_SQUEEZY_STORE_ID=12345
LEMON_SQUEEZY_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxx
LEMON_SQUEEZY_TEST_MODE=true  # Set to false in production

# Lemon Squeezy Variant IDs (from Products page)
LS_STARTER_VARIANT_ID=123456
LS_PRO_VARIANT_ID=123457
LS_ENTERPRISE_VARIANT_ID=123458

# Stripe Configuration (fallback/alternative)
STRIPE_SECRET_KEY=sk_test_your_key_here
STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxx
STRIPE_STARTER_PRICE_ID=price_starter_id
STRIPE_PRO_PRICE_ID=price_pro_id
STRIPE_ENTERPRISE_PRICE_ID=price_enterprise_id
```

### **Step 6: Test Integration**

```bash
# Start backend
uvicorn tiannara_api.main:app --reload

# Test creating checkout session
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

---

## 💳 **Alternative: Stripe Setup**

If you prefer Stripe (already integrated), follow these steps:

### **Step 1: Create Stripe Account**

1. Sign up at [https://stripe.com](https://stripe.com)
2. Individual accounts don't require business registration
3. Complete account verification

### **Step 2: Create Products & Prices**

1. Go to **Dashboard → Products**
2. Create three products with recurring prices:
   - Starter: $49/month
   - Professional: $199/month
   - Enterprise: $999/month
3. Copy each **Price ID** (starts with `price_`)

### **Step 3: Get API Keys**

1. Go to **Developers → API keys**
2. Copy **Secret Key** (starts with `sk_test_`)
3. Copy **Publishable Key** (starts with `pk_test_`)

### **Step 4: Configure Webhooks**

1. Go to **Developers → Webhooks**
2. Add endpoint: `https://api.tiannara.com/api/v1/payment/webhook`
3. Select events:
   - ✅ `checkout.session.completed`
   - ✅ `invoice.payment_succeeded`
   - ✅ `customer.subscription.deleted`
4. Copy **Signing Secret** (starts with `whsec_`)

### **Step 5: Update .env File**

```bash
# Switch to Stripe
PAYMENT_PROVIDER=stripe

# Stripe Configuration
STRIPE_SECRET_KEY=sk_test_xxxxxxxxxxxxxxxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxx
STRIPE_STARTER_PRICE_ID=price_1ABC...
STRIPE_PRO_PRICE_ID=price_2DEF...
STRIPE_ENTERPRISE_PRICE_ID=price_3GHI...
```

---

## 🔧 **Switching Between Providers**

To switch payment providers, simply update `.env`:

```bash
# Use Lemon Squeezy
PAYMENT_PROVIDER=lemon_squeezy

# OR use Stripe
PAYMENT_PROVIDER=stripe
```

Restart your backend:
```bash
uvicorn tiannara_api.main:app --reload
```

No code changes needed! The system auto-detects the provider.

---

## 🧪 **Testing**

### **Lemon Squeezy Test Mode**

1. Set `LEMON_SQUEEZY_TEST_MODE=true` in `.env`
2. Use test card numbers:
   - Success: `4242 4242 4242 4242`
   - Requires authentication: `4000 0025 0000 3155`
   - Declined: `4000 0000 0000 0002`

### **Stripe Test Mode**

1. Use test API keys (`sk_test_...`, `pk_test_...`)
2. Test cards:
   - Success: `4242 4242 4242 4242`
   - Requires 3D Secure: `4000 0025 0000 3155`
   - Insufficient funds: `4000 0000 0000 9995`

---

## 📊 **Webhook Testing**

### **Local Testing with ngrok**

```bash
# Install ngrok
npm install -g ngrok

# Expose local server
ngrok http 8000

# Update webhook URL in provider dashboard to:
# https://xxxx.ngrok.io/api/v1/payment/webhook
```

### **Verify Webhook Delivery**

Check backend logs for webhook events:
```
INFO: Received webhook from lemon_squeezy: subscription_created
INFO: Subscription activated for customer cus_xxxxxxxx
```

---

## 🚨 **Common Issues & Solutions**

### **Issue 1: "Lemon Squeezy credentials not configured"**

**Solution:**
```bash
# Verify .env has these lines:
LEMON_SQUEEZY_API_KEY=eyJwcm9kdWN0aW9uIjoi...
LEMON_SQUEEZY_STORE_ID=12345

# Restart backend after updating .env
```

### **Issue 2: "Variant ID not configured for plan"**

**Solution:**
```bash
# Add variant IDs to .env:
LS_STARTER_VARIANT_ID=123456
LS_PRO_VARIANT_ID=123457
LS_ENTERPRISE_VARIANT_ID=123458
```

### **Issue 3: Webhook signature verification failed**

**Solution:**
```bash
# Verify webhook secret matches provider dashboard:
LEMON_SQUEEZY_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxx
# OR
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxx
```

### **Issue 4: Payment succeeds but subscription not activated**

**Solution:**
- Check webhook delivery in provider dashboard
- Verify webhook endpoint is accessible (not blocked by firewall)
- Check backend logs for errors
- Ensure database models are migrated

---

## 📈 **Going Live**

### **Lemon Squeezy Production**

1. Set `LEMON_SQUEEZY_TEST_MODE=false`
2. Update webhook URL to production domain
3. Test with real card (small amount)
4. Monitor first few transactions

### **Stripe Production**

1. Switch to live API keys (`sk_live_...`, `pk_live_...`)
2. Update webhook URL to production domain
3. Enable Stripe Radar for fraud protection
4. Test with real card

---

## 💡 **Best Practices**

1. **Always use test mode during development**
2. **Never commit API keys to version control**
3. **Verify webhook signatures** (already implemented)
4. **Log all payment events** for debugging
5. **Monitor failed payments** and set up alerts
6. **Handle edge cases** (refunds, chargebacks, disputes)
7. **Test subscription cancellation flow**
8. **Use idempotency keys** for retry logic

---

## 📞 **Support Resources**

### **Lemon Squeezy**
- Documentation: https://docs.lemonsqueezy.com
- API Reference: https://docs.lemonsqueezy.com/api
- Support: help@lemonsqueezy.com
- Discord Community: https://discord.gg/lemonsqueezy

### **Stripe**
- Documentation: https://stripe.com/docs
- API Reference: https://stripe.com/docs/api
- Support: https://support.stripe.com
- Community Forum: https://stackoverflow.com/questions/tagged/stripe

---

## ✅ **Setup Checklist**

- [ ] Create Lemon Squeezy/Stripe account
- [ ] Create products and pricing plans
- [ ] Get API keys and store in .env
- [ ] Configure webhooks in provider dashboard
- [ ] Set PAYMENT_PROVIDER in .env
- [ ] Test checkout flow in test mode
- [ ] Verify webhook delivery
- [ ] Test subscription cancellation
- [ ] Switch to production keys
- [ ] Monitor first live transactions

---

**Ready to accept payments? Start with Lemon Squeezy - it's the easiest for unregistered businesses!** 💰🚀
