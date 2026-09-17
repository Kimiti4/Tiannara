# Paystack Integration Guide for Tiannara SaaS

**Date**: May 1, 2026  
**Status**: 📋 **IMPLEMENTATION PLAN**  
**Payment Provider**: [Paystack](https://paystack.com)

---

## 🎯 **Why Paystack?**

### **Advantages for Tiannara:**

✅ **African Market Focus**
- Excellent support for Nigeria, Ghana, Kenya, South Africa
- Local payment methods (bank transfer, USSD, mobile money)
- Lower fees than international competitors

✅ **International Support**
- Accepts Visa, Mastercard, American Express
- USD, GBP, EUR, GHS, KES, ZAR currencies
- Global payout options

✅ **Developer-Friendly**
- Comprehensive API documentation
- SDKs for Python, JavaScript, PHP, Ruby, Go
- Webhook system for real-time updates
- Test mode for development

✅ **Built-in Features**
- Subscription management
- Invoice generation
- Customer portal
- Fraud detection
- Analytics dashboard

✅ **Cost-Effective**
- Transaction fee: 1.5% + ₦100 (Nigeria)
- No monthly fees
- No setup costs
- Free test mode

---

## 📋 **Prerequisites**

### **1. Create Paystack Account**

1. Sign up at [https://paystack.com](https://paystack.com)
2. Complete business verification
3. Get API keys from Dashboard → Settings → API Keys

### **2. API Keys You'll Need**

```bash
# Test Mode (Development)
PAYSTACK_SECRET_KEY=sk_test_xxxxxxxxxxxxxxxx
PAYSTACK_PUBLIC_KEY=pk_test_xxxxxxxxxxxxxxxx

# Live Mode (Production)
PAYSTACK_SECRET_KEY=sk_live_xxxxxxxxxxxxxxxx
PAYSTACK_PUBLIC_KEY=pk_live_xxxxxxxxxxxxxxxx
```

**Important:**
- Use **test keys** during development
- Switch to **live keys** only when ready for production
- Never commit API keys to version control

### **3. Install Paystack SDK**

```bash
pip install paystackapi
```

Or use direct HTTP requests with `requests` library (already in requirements.txt).

---

## 🔧 **Backend Implementation**

### **Step 1: Create Billing Routes**

Create `tiannara_api/routes/billing.py`:

```python
"""
Paystack Billing Integration for Tiannara SaaS

Handles:
- Subscription creation
- Payment verification
- Webhook processing
- Invoice management
"""

from fastapi import APIRouter, Depends, HTTPException, status, Request, Header
from sqlalchemy.orm import Session
import httpx
import os
import hmac
import hashlib
import json
from datetime import datetime, timezone

from tiannara_api.database import get_db
from tiannara_api.routes.auth import get_current_user
from tiannara_api.database.models import User, Subscription, Invoice

router = APIRouter(prefix="/billing", tags=["Billing"])

# Paystack configuration
PAYSTACK_SECRET_KEY = os.getenv("PAYSTACK_SECRET_KEY")
PAYSTACK_PUBLIC_KEY = os.getenv("PAYSTACK_PUBLIC_KEY")
PAYSTACK_WEBHOOK_SECRET = os.getenv("PAYSTACK_WEBHOOK_SECRET")

PAYSTACK_BASE_URL = "https://api.paystack.co"


# ==================== Subscription Plans ====================

PLANS = {
    "starter": {
        "name": "Tiannara Starter",
        "amount": 4900,  # In kobo/cents (₦49.00 or $49.00)
        "interval": "monthly",
        "api_requests": 5000,
        "features": ["core_reasoning", "basic_analytics", "email_support"]
    },
    "professional": {
        "name": "Tiannara Professional",
        "amount": 19900,  # ₦199.00 or $199.00
        "interval": "monthly",
        "api_requests": 50000,
        "features": ["advanced_workflows", "team_collab", "priority_support", "webhooks"]
    },
    "enterprise": {
        "name": "Tiannara Enterprise",
        "amount": 0,  # Custom pricing
        "interval": "custom",
        "api_requests": -1,  # Unlimited
        "features": ["unlimited_everything", "dedicated_support", "private_deployment"]
    }
}


# ==================== Initialize Transaction ====================

@router.post("/initialize")
async def initialize_subscription(
    plan_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Initialize a Paystack transaction for subscription.
    
    Returns authorization URL for checkout.
    """
    if plan_id not in PLANS:
        raise HTTPException(status_code=404, detail="Plan not found")
    
    plan = PLANS[plan_id]
    user_email = current_user.get("user", {}).get("email")
    user_id = current_user.get("user", {}).get("id")
    
    # Prepare transaction data
    transaction_data = {
        "email": user_email,
        "amount": plan["amount"],
        "currency": "NGN",  # Change to USD for international
        "callback_url": f"https://app.tiannara.com/billing/success?plan={plan_id}",
        "metadata": {
            "user_id": user_id,
            "plan_id": plan_id,
            "plan_name": plan["name"]
        }
    }
    
    # Call Paystack API
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{PAYSTACK_BASE_URL}/transaction/initialize",
            headers={
                "Authorization": f"Bearer {PAYSTACK_SECRET_KEY}",
                "Content-Type": "application/json"
            },
            json=transaction_data
        )
        
        if response.status_code != 200:
            raise HTTPException(
                status_code=500,
                detail=f"Paystack error: {response.text}"
            )
        
        result = response.json()
        
        if not result.get("status"):
            raise HTTPException(
                status_code=500,
                detail=result.get("message", "Transaction initialization failed")
            )
        
        return {
            "status": "success",
            "authorization_url": result["data"]["authorization_url"],
            "access_code": result["data"]["access_code"],
            "reference": result["data"]["reference"]
        }


# ==================== Verify Payment ====================

@router.get("/verify/{reference}")
async def verify_payment(
    reference: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Verify a Paystack transaction after callback.
    """
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{PAYSTACK_BASE_URL}/transaction/verify/{reference}",
            headers={"Authorization": f"Bearer {PAYSTACK_SECRET_KEY}"}
        )
        
        if response.status_code != 200:
            raise HTTPException(status_code=500, detail="Verification failed")
        
        result = response.json()
        
        if not result.get("status"):
            raise HTTPException(status_code=400, detail="Transaction not found")
        
        transaction = result["data"]
        
        if transaction["status"] == "success":
            # Activate subscription
            user_id = transaction["metadata"].get("user_id")
            plan_id = transaction["metadata"].get("plan_id")
            
            # Update user tier
            user = db.query(User).filter(User.id == user_id).first()
            if user:
                user.tier = plan_id
                user.subscription_status = "active"
                user.subscription_start = datetime.now(timezone.utc)
                db.commit()
            
            # Create invoice record
            invoice = Invoice(
                user_id=user_id,
                amount=transaction["amount"] / 100,  # Convert from kobo
                currency=transaction["currency"],
                status="paid",
                paystack_reference=reference,
                paid_at=datetime.now(timezone.utc)
            )
            db.add(invoice)
            db.commit()
            
            return {
                "status": "success",
                "message": "Subscription activated successfully",
                "tier": plan_id,
                "invoice_id": invoice.id
            }
        else:
            raise HTTPException(
                status_code=400,
                detail=f"Payment failed: {transaction['gateway_response']}"
            )


# ==================== Webhook Handler ====================

@router.post("/webhook")
async def handle_webhook(
    request: Request,
    x_paystack_signature: str = Header(None),
    db: Session = Depends(get_db)
):
    """
    Handle Paystack webhook events.
    
    Verifies signature and processes events:
    - charge.success
    - subscription.create
    - subscription.disable
    """
    # Verify webhook signature
    payload = await request.body()
    
    if x_paystack_signature:
        computed_signature = hmac.new(
            PAYSTACK_WEBHOOK_SECRET.encode(),
            payload,
            hashlib.sha512
        ).hexdigest()
        
        if computed_signature != x_paystack_signature:
            raise HTTPException(status_code=400, detail="Invalid signature")
    
    event = json.loads(payload)
    event_type = event.get("event")
    
    # Process different event types
    if event_type == "charge.success":
        await handle_charge_success(event, db)
    
    elif event_type == "subscription.create":
        await handle_subscription_create(event, db)
    
    elif event_type == "subscription.disable":
        await handle_subscription_disable(event, db)
    
    return {"status": "success"}


async def handle_charge_success(event: dict, db: Session):
    """Handle successful charge event."""
    data = event["data"]
    user_id = data["metadata"].get("user_id")
    
    # Update user subscription
    user = db.query(User).filter(User.id == user_id).first()
    if user:
        user.last_payment_date = datetime.now(timezone.utc)
        db.commit()


async def handle_subscription_create(event: dict, db: Session):
    """Handle new subscription event."""
    data = event["data"]
    customer_email = data["customer"]["email"]
    
    # Find user by email
    user = db.query(User).filter(User.email == customer_email).first()
    if user:
        user.subscription_status = "active"
        db.commit()


async def handle_subscription_disable(event: dict, db: Session):
    """Handle subscription cancellation."""
    data = event["data"]
    customer_email = data["customer"]["email"]
    
    user = db.query(User).filter(User.email == customer_email).first()
    if user:
        user.subscription_status = "cancelled"
        db.commit()


# ==================== Cancel Subscription ====================

@router.post("/cancel")
async def cancel_subscription(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Cancel user's active subscription."""
    user_id = current_user.get("user", {}).get("id")
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user or user.subscription_status != "active":
        raise HTTPException(status_code=400, detail="No active subscription")
    
    # Downgrade to free tier
    user.tier = "free"
    user.subscription_status = "cancelled"
    user.subscription_end = datetime.now(timezone.utc)
    db.commit()
    
    return {
        "status": "success",
        "message": "Subscription cancelled",
        "new_tier": "free"
    }


# ==================== Get Invoices ====================

@router.get("/invoices")
async def get_invoices(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's invoice history."""
    user_id = current_user.get("user", {}).get("id")
    
    invoices = db.query(Invoice).filter(
        Invoice.user_id == user_id
    ).order_by(
        Invoice.created_at.desc()
    ).all()
    
    return {
        "count": len(invoices),
        "invoices": [
            {
                "id": inv.id,
                "amount": inv.amount,
                "currency": inv.currency,
                "status": inv.status,
                "created_at": inv.created_at.isoformat(),
                "paid_at": inv.paid_at.isoformat() if inv.paid_at else None
            }
            for inv in invoices
        ]
    }
```

---

### **Step 2: Add Database Models**

Update `tiannara_api/database/models.py`:

```python
from sqlalchemy import Column, String, Integer, Float, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
import uuid

class User(Base):
    __tablename__ = "users"
    
    # ... existing fields ...
    
    # Subscription fields
    tier = Column(String(50), default="free")  # free, starter, professional, enterprise
    subscription_status = Column(String(20), default="inactive")  # active, cancelled, past_due
    subscription_start = Column(DateTime, nullable=True)
    subscription_end = Column(DateTime, nullable=True)
    last_payment_date = Column(DateTime, nullable=True)


class Invoice(Base):
    __tablename__ = "invoices"
    
    id = Column(String, primary_key=True, default=lambda: f"inv_{uuid.uuid4().hex[:12]}")
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    amount = Column(Float, nullable=False)
    currency = Column(String(3), default="NGN")
    status = Column(String(20), default="pending")  # pending, paid, failed, refunded
    paystack_reference = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    paid_at = Column(DateTime, nullable=True)
    
    user = relationship("User", backref="invoices")
```

---

### **Step 3: Run Migration**

Create `migrate_billing.py`:

```python
"""Add billing tables to database."""

from sqlalchemy import create_engine, text
from tiannara_api.database import Base, engine
from tiannara_api.database.models import Invoice

def run_migration():
    print("Creating billing tables...")
    Invoice.__table__.create(engine, checkfirst=True)
    print("✅ Billing tables created successfully")

if __name__ == "__main__":
    run_migration()
```

Run it:
```bash
python migrate_billing.py
```

---

### **Step 4: Update Environment Variables**

Add to `.env`:

```bash
# Paystack Configuration
PAYSTACK_SECRET_KEY=sk_test_xxxxxxxxxxxxxxxx
PAYSTACK_PUBLIC_KEY=pk_test_xxxxxxxxxxxxxxxx
PAYSTACK_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxx

# Callback URLs
PAYSTACK_CALLBACK_URL=https://app.tiannara.com/billing/success
PAYSTACK_WEBHOOK_URL=https://api.tiannara.com/api/v1/billing/webhook
```

---

## 🎨 **Frontend Implementation**

### **Step 1: Install Paystack Inline JS**

In `tiannara_gui/src/app/dashboard/billing/page.tsx`:

```typescript
'use client'

import { useState, useEffect } from 'react'
import axios from 'axios'

export default function BillingPage() {
  const [currentTier, setCurrentTier] = useState('free')
  const [loading, setLoading] = useState(false)

  const plans = [
    {
      id: 'starter',
      name: 'Starter',
      price: 49,
      features: ['5,000 API requests/month', 'Core reasoning engine', 'Email support']
    },
    {
      id: 'professional',
      name: 'Professional',
      price: 199,
      features: ['50,000 API requests/month', 'Advanced workflows', 'Priority support', 'Webhooks']
    }
  ]

  const handleSubscribe = async (planId: string) => {
    setLoading(true)
    try {
      // Initialize Paystack transaction
      const response = await axios.post('/api/v1/billing/initialize', {
        plan_id: planId
      }, {
        headers: {
          Authorization: `Bearer ${localStorage.getItem('token')}`
        }
      })

      // Redirect to Paystack checkout
      window.location.href = response.data.authorization_url
      
    } catch (error) {
      console.error('Subscription error:', error)
      alert('Failed to start subscription. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-8">Billing & Subscription</h1>
      
      <div className="mb-8 p-6 bg-gray-50 rounded-lg">
        <h2 className="text-xl font-semibold mb-2">Current Plan</h2>
        <p className="text-gray-600">
          You are on the <span className="font-bold capitalize">{currentTier}</span> plan
        </p>
      </div>

      <div className="grid md:grid-cols-2 gap-6">
        {plans.map((plan) => (
          <div key={plan.id} className="border rounded-lg p-6 hover:shadow-lg transition">
            <h3 className="text-2xl font-bold mb-2">{plan.name}</h3>
            <p className="text-4xl font-bold mb-4">
              ${plan.price}<span className="text-lg text-gray-500">/month</span>
            </p>
            
            <ul className="mb-6 space-y-2">
              {plan.features.map((feature, idx) => (
                <li key={idx} className="flex items-center">
                  <span className="text-green-500 mr-2">✓</span>
                  {feature}
                </li>
              ))}
            </ul>

            <button
              onClick={() => handleSubscribe(plan.id)}
              disabled={loading || currentTier === plan.id}
              className="w-full py-3 px-4 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
            >
              {loading ? 'Processing...' : currentTier === plan.id ? 'Current Plan' : 'Subscribe'}
            </button>
          </div>
        ))}
      </div>
    </div>
  )
}
```

---

### **Step 2: Add Success Page**

Create `tiannara_gui/src/app/billing/success/page.tsx`:

```typescript
'use client'

import { useEffect, useState } from 'react'
import { useSearchParams } from 'next/navigation'
import axios from 'axios'

export default function BillingSuccessPage() {
  const searchParams = useSearchParams()
  const reference = searchParams.get('reference')
  const plan = searchParams.get('plan')
  const [status, setStatus] = useState('verifying')

  useEffect(() => {
    if (reference) {
      verifyPayment(reference)
    }
  }, [reference])

  const verifyPayment = async (ref: string) => {
    try {
      const response = await axios.get(`/api/v1/billing/verify/${ref}`, {
        headers: {
          Authorization: `Bearer ${localStorage.getItem('token')}`
        }
      })

      if (response.data.status === 'success') {
        setStatus('success')
      } else {
        setStatus('failed')
      }
    } catch (error) {
      setStatus('failed')
    }
  }

  if (status === 'verifying') {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-lg">Verifying your payment...</p>
        </div>
      </div>
    )
  }

  if (status === 'success') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-green-50">
        <div className="text-center">
          <div className="text-6xl mb-4">🎉</div>
          <h1 className="text-3xl font-bold text-green-600 mb-4">Payment Successful!</h1>
          <p className="text-lg mb-6">Your {plan} subscription is now active.</p>
          <a href="/dashboard" className="px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700">
            Go to Dashboard
          </a>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-red-50">
      <div className="text-center">
        <div className="text-6xl mb-4">❌</div>
        <h1 className="text-3xl font-bold text-red-600 mb-4">Payment Failed</h1>
        <p className="text-lg mb-6">Something went wrong. Please try again.</p>
        <a href="/dashboard/billing" className="px-6 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700">
          Try Again
        </a>
      </div>
    </div>
  )
}
```

---

## 🔐 **Webhook Configuration**

### **Step 1: Configure Webhook in Paystack Dashboard**

1. Go to Paystack Dashboard → Settings → Webhooks
2. Add webhook URL: `https://api.tiannara.com/api/v1/billing/webhook`
3. Select events to receive:
   - ✅ charge.success
   - ✅ subscription.create
   - ✅ subscription.disable
   - ✅ invoice.update
4. Copy webhook secret key
5. Add to `.env`: `PAYSTACK_WEBHOOK_SECRET=whsec_xxxx`

### **Step 2: Test Webhook Locally**

Use ngrok to expose local server:

```bash
ngrok http 8000
```

Update webhook URL in Paystack dashboard to: `https://xxxx.ngrok.io/api/v1/billing/webhook`

Test with Paystack's webhook test tool.

---

## 🧪 **Testing**

### **Test Cards (Paystack Test Mode)**

| Card Number | Result |
|-------------|--------|
| 4084084084084081 | Success |
| 4187427415564246 | Requires OTP |
| 5531886652142950 | Insufficient funds |
| 5060666666666666000 | Bank transfer |

### **Test Flow:**

1. Start backend: `uvicorn tiannara_api.main:app --reload`
2. Start frontend: `npm run dev`
3. Navigate to `/dashboard/billing`
4. Click "Subscribe" on Starter plan
5. Use test card: `4084084084084081`
6. Complete checkout
7. Verify redirect to success page
8. Check database for updated tier

---

## 🚀 **Deployment Checklist**

- [ ] Switch to Paystack live API keys
- [ ] Configure production webhook URL
- [ ] Test with real card (small amount)
- [ ] Verify webhook delivery in production
- [ ] Set up monitoring for failed payments
- [ ] Configure email notifications for payments
- [ ] Test subscription cancellation flow
- [ ] Verify invoice generation

---

## 📊 **Monitoring**

Track these metrics:

- Payment success rate
- Average transaction value
- Subscription churn rate
- Webhook delivery failures
- Revenue per user

Use Paystack Dashboard → Analytics for insights.

---

## 💡 **Best Practices**

1. **Always verify signatures** on webhooks
2. **Use idempotency keys** for retry logic
3. **Store Paystack references** for dispute resolution
4. **Handle edge cases** (failed payments, refunds)
5. **Log all payment events** for debugging
6. **Test thoroughly** in test mode before going live
7. **Monitor webhook failures** and set up alerts

---

## 📞 **Support Resources**

- **Paystack Documentation**: https://paystack.com/docs
- **API Reference**: https://paystack.com/docs/api
- **Developer Support**: developers@paystack.com
- **Community Forum**: https://paystack.community

---

**Ready to integrate Paystack? Start with Step 1: Create billing routes!** 💳🚀
