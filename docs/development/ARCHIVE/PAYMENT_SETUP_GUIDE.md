# Payment Processing Setup Guide

## Overview

This guide walks through setting up payment processing for Tiannara MindCache services using Stripe (recommended) and PayPal (alternative).

---

## Option 1: Stripe Integration (Recommended)

### Why Stripe?
- ✅ Developer-friendly API
- ✅ Supports subscriptions (perfect for API tiers)
- ✅ One-time payments (consulting packages)
- ✅ Global coverage (135+ currencies)
- ✅ Built-in fraud protection
- ✅ Excellent documentation

### Setup Steps

#### 1. Create Stripe Account
1. Go to [stripe.com](https://stripe.com)
2. Click "Start now"
3. Fill in business details
4. Verify email and phone
5. Add bank account for payouts

**Time**: 15 minutes  
**Cost**: Free (2.9% + $0.30 per transaction)

---

#### 2. Get API Keys

1. Log into Stripe Dashboard
2. Go to Developers → API keys
3. Copy these keys:
   - **Publishable Key** (starts with `pk_test_` or `pk_live_`)
   - **Secret Key** (starts with `sk_test_` or `sk_live_`)

**Important**: 
- Use test keys during development
- Switch to live keys when ready to accept real payments
- Never expose secret keys in client-side code

---

#### 3. Install Stripe SDK

```bash
# Python backend
pip install stripe

# JavaScript frontend
npm install @stripe/stripe-js
```

---

#### 4. Create Products & Prices

Run this script to set up your products:

```python
import stripe

stripe.api_key = "sk_test_YOUR_SECRET_KEY"

# Product 1: Developer API Tier
developer_product = stripe.Product.create(
    name="Tiannara API - Developer",
    description="10,000 API calls/month with basic domains",
    type="service"
)

stripe.Price.create(
    product=developer_product.id,
    unit_amount=4900,  # $49.00 in cents
    currency="usd",
    recurring={"interval": "month"}
)

# Product 2: Professional API Tier
professional_product = stripe.Product.create(
    name="Tiannara API - Professional",
    description="100,000 API calls/month with all features",
    type="service"
)

stripe.Price.create(
    product=professional_product.id,
    unit_amount=19900,  # $199.00 in cents
    currency="usd",
    recurring={"interval": "month"}
)

# Product 3: Enterprise API Tier
enterprise_product = stripe.Product.create(
    name="Tiannara API - Enterprise",
    description="Unlimited calls with dedicated support",
    type="service"
)

stripe.Price.create(
    product=enterprise_product.id,
    unit_amount=99900,  # $999.00 in cents
    currency="usd",
    recurring={"interval": "month"}
)

# Product 4: Consulting Package (one-time)
consulting_product = stripe.Product.create(
    name="Strategic Consultation",
    description="1-week strategic AI reasoning consultation",
    type="service"
)

stripe.Price.create(
    product=consulting_product.id,
    unit_amount=300000,  # $3,000.00 in cents
    currency="usd"
)

print("Products created successfully!")
print(f"Developer Product ID: {developer_product.id}")
print(f"Professional Product ID: {professional_product.id}")
print(f"Enterprise Product ID: {enterprise_product.id}")
print(f"Consulting Product ID: {consulting_product.id}")
```

Save the product IDs for later use.

---

#### 5. Create Payment Endpoint

Create `tiannara_api/routes/payments.py`:

```python
from fastapi import APIRouter, HTTPException, Request
import stripe
import os

router = APIRouter()

stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
YOUR_DOMAIN = os.getenv("YOUR_DOMAIN", "http://localhost:8000")

@router.post("/create-checkout-session")
async def create_checkout_session(request: Request):
    """Create Stripe checkout session for one-time payments."""
    
    try:
        data = await request.json()
        price_id = data.get("price_id")
        
        if not price_id:
            raise HTTPException(status_code=400, detail="Price ID required")
        
        session = stripe.checkout.Session.create(
            payment_method_types=["card"],
            line_items=[{
                "price": price_id,
                "quantity": 1,
            }],
            mode="payment",
            success_url=f"{YOUR_DOMAIN}/success?session_id={{CHECKOUT_SESSION_ID}}",
            cancel_url=f"{YOUR_DOMAIN}/cancel",
        )
        
        return {"sessionId": session.id, "url": session.url}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/create-subscription")
async def create_subscription(request: Request):
    """Create Stripe subscription for API tiers."""
    
    try:
        data = await request.json()
        price_id = data.get("price_id")
        customer_email = data.get("email")
        
        if not price_id or not customer_email:
            raise HTTPException(status_code=400, detail="Price ID and email required")
        
        # Create or retrieve customer
        customers = stripe.Customer.list(email=customer_email)
        if customers.data:
            customer = customers.data[0]
        else:
            customer = stripe.Customer.create(email=customer_email)
        
        # Create subscription
        subscription = stripe.Subscription.create(
            customer=customer.id,
            items=[{"price": price_id}],
            payment_behavior="default_incomplete",
            expand=["latest_invoice.payment_intent"],
        )
        
        return {
            "subscriptionId": subscription.id,
            "clientSecret": subscription.latest_invoice.payment_intent.client_secret,
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/webhook")
async def stripe_webhook(request: Request):
    """Handle Stripe webhook events."""
    
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature")
    endpoint_secret = os.getenv("STRIPE_WEBHOOK_SECRET")
    
    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, endpoint_secret
        )
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.error.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Invalid signature")
    
    # Handle the event
    if event.type == "checkout.session.completed":
        session = event.data.object
        # Fulfill purchase (e.g., activate API key)
        print(f"Payment completed for session: {session.id}")
        
    elif event.type == "invoice.payment_succeeded":
        invoice = event.data.object
        # Subscription payment succeeded
        print(f"Subscription payment succeeded: {invoice.subscription}")
        
    elif event.type == "customer.subscription.deleted":
        subscription = event.data.object
        # Cancel API access
        print(f"Subscription cancelled: {subscription.id}")
    
    return {"status": "success"}
```

---

#### 6. Add Routes to Main App

Update `tiannara_api/main.py`:

```python
from tiannara_api.routes import payments

app.include_router(payments.router, prefix="/api/v1/payments", tags=["payments"])
```

---

#### 7. Set Environment Variables

Create `.env` file:

```bash
STRIPE_SECRET_KEY=sk_test_YOUR_SECRET_KEY
STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_PUBLISHABLE_KEY
STRIPE_WEBHOOK_SECRET=whsec_YOUR_WEBHOOK_SECRET
YOUR_DOMAIN=https://your-domain.com
```

---

#### 8. Test Integration

1. Use Stripe test cards:
   - Success: `4242 4242 4242 4242`
   - Decline: `4000 0000 0000 0002`
   
2. Make test payment:
```bash
curl -X POST http://localhost:8000/api/v1/payments/create-checkout-session \
  -H "Content-Type: application/json" \
  -d '{"price_id": "price_TEST_ID"}'
```

3. Verify webhook receives events

---

#### 9. Go Live

1. Switch to live API keys
2. Update domain to production URL
3. Test with real card (small amount)
4. Monitor dashboard for issues

---

## Option 2: PayPal Integration (Alternative)

### Why PayPal?
- ✅ Widely recognized
- ✅ No coding required (hosted buttons)
- ✅ Good for international clients
- ❌ Higher fees (3.49% + fixed fee)
- ❌ Less flexible than Stripe

### Quick Setup

#### 1. Create Business Account
1. Go to [paypal.com/business](https://paypal.com/business)
2. Sign up for business account
3. Verify email and link bank account

#### 2. Create Payment Buttons

1. Log into PayPal Business
2. Go to Tools → All Tools → PayPal Buttons
3. Create button for each service:
   - Consulting packages (one-time)
   - API subscriptions (recurring)

#### 3. Embed on Website

Copy generated HTML code and paste into landing page.

Example:
```html
<form action="https://www.paypal.com/cgi-bin/webscr" method="post">
  <input type="hidden" name="cmd" value="_xclick">
  <input type="hidden" name="business" value="your-email@example.com">
  <input type="hidden" name="item_name" value="Strategic Consultation">
  <input type="hidden" name="amount" value="3000.00">
  <input type="hidden" name="currency_code" value="USD">
  <input type="image" src="https://www.paypalobjects.com/en_US/i/btn/btn_buynow_LG.gif" border="0" name="submit" alt="PayPal - The safer, easier way to pay online!">
</form>
```

---

## Recommendation

**Use Stripe** for:
- API subscriptions (automated billing)
- Recurring revenue
- Better developer experience
- Lower fees for high volume

**Use PayPal** for:
- One-time consulting payments
- International clients who prefer PayPal
- Backup payment option

**Best Practice**: Offer both, default to Stripe.

---

## Cost Comparison

| Provider | Transaction Fee | Monthly Fee | Best For |
|----------|----------------|-------------|----------|
| Stripe | 2.9% + $0.30 | $0 | Subscriptions, APIs |
| PayPal | 3.49% + fixed | $0 | One-time payments |
| Square | 2.9% + $0.30 | $0 | In-person + online |

For $10K/month revenue:
- Stripe: ~$320 in fees
- PayPal: ~$380 in fees
- **Savings with Stripe**: $60/month ($720/year)

---

## Next Steps

1. ✅ Choose payment provider (Stripe recommended)
2. ✅ Create account and get API keys
3. ✅ Set up products and pricing
4. ✅ Integrate into API/backend
5. ✅ Test with test cards
6. ✅ Deploy to production
7. ✅ Monitor transactions

**Estimated Time**: 2-3 hours  
**Cost**: Free to set up, only pay per transaction

---

## Resources

- [Stripe Documentation](https://stripe.com/docs)
- [Stripe Test Cards](https://stripe.com/docs/testing)
- [PayPal Developer](https://developer.paypal.com/)
- [Payment Security Best Practices](https://stripe.com/docs/security)

---

**Ready to accept payments?** Start with Stripe setup above!
