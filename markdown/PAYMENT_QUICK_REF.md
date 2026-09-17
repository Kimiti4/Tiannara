# Payment Provider Quick Reference

## 🚀 **5-Minute Setup (Lemon Squeezy)**

### **1. Sign Up** (2 min)
- Go to https://lemonsqueezy.com
- Create account (no business registration needed!)

### **2. Create Products** (2 min)
- Products → Add Product
- Create 3 plans: Starter ($49), Professional ($199), Enterprise ($999)
- Copy variant IDs

### **3. Get API Keys** (1 min)
- Settings → API → Create Key
- Copy: API Key, Store ID

### **4. Configure .env**
```bash
cp .env.template .env
```

Edit `.env`:
```bash
PAYMENT_PROVIDER=lemon_squeezy
LEMON_SQUEEZY_API_KEY=your_key_here
LEMON_SQUEEZY_STORE_ID=your_store_id
LS_STARTER_VARIANT_ID=id_1
LS_PRO_VARIANT_ID=id_2
LS_ENTERPRISE_VARIANT_ID=id_3
LEMON_SQUEEZY_TEST_MODE=true
```

### **5. Test**
```bash
uvicorn tiannara_api.main:app --reload
```

Visit: http://localhost:8000/docs → Try `/api/v1/payment/subscribe`

---

## 🔄 **Switch Providers**

Just change ONE line in `.env`:

```bash
# Lemon Squeezy
PAYMENT_PROVIDER=lemon_squeezy

# Stripe
PAYMENT_PROVIDER=stripe
```

Restart backend. Done!

---

## 📋 **Environment Variables Checklist**

### **Lemon Squeezy**
- [ ] `PAYMENT_PROVIDER=lemon_squeezy`
- [ ] `LEMON_SQUEEZY_API_KEY=...`
- [ ] `LEMON_SQUEEZY_STORE_ID=...`
- [ ] `LEMON_SQUEEZY_WEBHOOK_SECRET=...`
- [ ] `LS_STARTER_VARIANT_ID=...`
- [ ] `LS_PRO_VARIANT_ID=...`
- [ ] `LS_ENTERPRISE_VARIANT_ID=...`
- [ ] `LEMON_SQUEEZY_TEST_MODE=true`

### **Stripe**
- [ ] `PAYMENT_PROVIDER=stripe`
- [ ] `STRIPE_SECRET_KEY=sk_test_...`
- [ ] `STRIPE_PUBLISHABLE_KEY=pk_test_...`
- [ ] `STRIPE_WEBHOOK_SECRET=whsec_...`
- [ ] `STRIPE_STARTER_PRICE_ID=price_...`
- [ ] `STRIPE_PRO_PRICE_ID=price_...`
- [ ] `STRIPE_ENTERPRISE_PRICE_ID=price_...`

---

## 🧪 **Test Cards**

### **Lemon Squeezy / Stripe**
- Success: `4242 4242 4242 4242`
- Requires auth: `4000 0025 0000 3155`
- Declined: `4000 0000 0000 0002`

Any future date, any CVC.

---

## 🔗 **Important URLs**

- **Lemon Squeezy Dashboard**: https://app.lemonsqueezy.com
- **Lemon Squeezy Docs**: https://docs.lemonsqueezy.com
- **Stripe Dashboard**: https://dashboard.stripe.com
- **Stripe Docs**: https://stripe.com/docs
- **Tiannara Setup Guide**: [docs/deployment/PAYMENT_SETUP_GUIDE.md](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/docs/deployment/PAYMENT_SETUP_GUIDE.md)

---

## ⚡ **Common Commands**

```bash
# Start backend
uvicorn tiannara_api.main:app --reload

# Test checkout endpoint
curl -X POST http://localhost:8000/api/v1/payment/subscribe \
  -H "Content-Type: application/json" \
  -d '{
    "plan": "starter",
    "success_url": "http://localhost:3001/success",
    "cancel_url": "http://localhost:3001/cancel",
    "customer_email": "test@example.com"
  }'

# List plans
curl http://localhost:8000/api/v1/payment/plans
```

---

## 🆘 **Troubleshooting**

| Problem | Solution |
|---------|----------|
| "Credentials not configured" | Check .env has all required keys |
| "Variant ID not configured" | Add LS_*_VARIANT_ID to .env |
| Webhook not working | Verify webhook URL in provider dashboard |
| Signature verification failed | Check webhook secret matches |
| Payment succeeds but tier not updated | Check webhook delivery logs |

---

## 📞 **Need Help?**

- **Full Guide**: [PAYMENT_SETUP_GUIDE.md](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/docs/deployment/PAYMENT_SETUP_GUIDE.md)
- **Summary**: [PAYMENT_FIX_SUMMARY.md](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/PAYMENT_FIX_SUMMARY.md)
- **Lemon Squeezy Support**: help@lemonsqueezy.com
- **Stripe Support**: https://support.stripe.com
