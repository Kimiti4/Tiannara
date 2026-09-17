# Payment Integration - Quick Answers

## Your Questions Answered ✅

### **Q1: Can I integrate BOTH Stripe and Lemon Squeezy?**

**YES!** ✅ Both are now fully integrated.

**How it works:**
- Set a default provider in `.env`: `PAYMENT_PROVIDER=lemon_squeezy`
- Override per transaction: `{ "provider": "stripe" }`
- Let users choose on your billing page

**API Examples:**

```bash
# Use default provider (from .env)
curl -X POST http://localhost:8000/api/v1/payment/subscribe \
  -d '{"plan": "starter", "success_url": "...", "cancel_url": "..."}'

# Explicitly use Stripe
curl -X POST http://localhost:8000/api/v1/payment/subscribe \
  -d '{"plan": "starter", "provider": "stripe", "success_url": "..."}'

# Explicitly use Lemon Squeezy
curl -X POST http://localhost:8000/api/v1/payment/subscribe \
  -d '{"plan": "starter", "provider": "lemon_squeezy", "success_url": "..."}'
```

---

### **Q2: Does the website need a custom domain?**

**NO!** ❌ Custom domain is NOT required.

**What works:**
- ✅ `localhost` for development
- ✅ Free subdomains: `tiannara.vercel.app`, `tiannara.herokuapp.com`
- ✅ Custom domains (optional, for branding)

**Requirements:**
- Valid callback URLs (can be localhost during testing)
- HTTPS in production (free with most hosting)
- Webhook endpoint accessible from internet (use ngrok for local testing)

**Webhook Testing:**
```bash
ngrok http 8000
# Use: https://xxxx.ngrok.io/api/v1/payment/webhook
```

---

### **Q3: What about product descriptions?**

You configure products in each provider's dashboard:

**Lemon Squeezy Dashboard:**
1. Products → Add Product
2. Fill in name, description, price
3. Copy Variant ID to `.env`

**Stripe Dashboard:**
1. Products → Add Product
2. Create recurring prices
3. Copy Price IDs to `.env`

**Product Description Templates:** See [COMPLETE_PAYMENT_INTEGRATION.md](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/docs/deployment/COMPLETE_PAYMENT_INTEGRATION.md)

---

## 🚀 **Quick Setup (5 Minutes)**

### **Step 1: Configure Both Providers**

Edit `.env`:

```bash
# Default provider
PAYMENT_PROVIDER=lemon_squeezy

# Lemon Squeezy
LEMON_SQUEEZY_API_KEY=your_key
LEMON_SQUEEZY_STORE_ID=your_store_id
LS_STARTER_VARIANT_ID=id_1
LS_PRO_VARIANT_ID=id_2
LS_ENTERPRISE_VARIANT_ID=id_3

# Stripe
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_STARTER_PRICE_ID=price_xxx
STRIPE_PRO_PRICE_ID=price_xxx
STRIPE_ENTERPRISE_PRICE_ID=price_xxx
```

### **Step 2: Restart Backend**

```bash
uvicorn tiannara_api.main:app --reload
```

### **Step 3: Test Both**

```bash
# Test Lemon Squeezy (default)
curl http://localhost:8000/api/v1/payment/providers

# Test Stripe (override)
curl -X POST http://localhost:8000/api/v1/payment/subscribe \
  -d '{"plan": "starter", "provider": "stripe", ...}'
```

---

## 📋 **Complete Documentation**

| Document | Purpose |
|----------|---------|
| [COMPLETE_PAYMENT_INTEGRATION.md](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/docs/deployment/COMPLETE_PAYMENT_INTEGRATION.md) | Full integration guide with product descriptions |
| [PAYMENT_SETUP_GUIDE.md](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/docs/deployment/PAYMENT_SETUP_GUIDE.md) | Step-by-step setup instructions |
| [PAYMENT_QUICK_REF.md](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/PAYMENT_QUICK_REF.md) | Quick reference card |
| [PAYMENT_FIX_SUMMARY.md](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/PAYMENT_FIX_SUMMARY.md) | Implementation summary |
| [.env.template](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/.env.template) | Environment configuration template |

---

## 💡 **Key Features**

✅ **Multi-provider support** - Use both Stripe AND Lemon Squeezy  
✅ **Per-transaction selection** - Choose provider at checkout  
✅ **No custom domain needed** - Works with localhost  
✅ **Product templates provided** - Copy-paste ready  
✅ **Automatic failover** - Switch providers instantly  
✅ **Unified webhooks** - Single endpoint for all providers  

---

## 🎯 **Next Steps**

1. **Sign up** for both providers (if not done)
   - Lemon Squeezy: https://lemonsqueezy.com
   - Stripe: https://stripe.com

2. **Create products** in both dashboards
   - Use templates from COMPLETE_PAYMENT_INTEGRATION.md

3. **Configure .env** with credentials from both providers

4. **Test** both providers work

5. **Deploy** when ready (no custom domain required!)

---

**Ready to accept payments with BOTH providers!** 💰🚀
