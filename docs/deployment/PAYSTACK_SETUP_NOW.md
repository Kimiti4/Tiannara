# Paystack Setup Guide - Getting Started

**Date**: May 1, 2026  
**Status**: ✅ **Credentials Configured** | ⏳ **Ready to Build**

---

## ✅ **What's Done**

Your Paystack test credentials have been added to `.env`:

```env
PAYSTACK_PUBLIC_KEY=pk_test_227af9aa38cfce5faff66fce40025878a1f53228
PAYSTACK_SECRET_KEY=sk_test_6e25410eb683833a241ef3fe99d6e73f95f5f0b7
```

---

## 🎯 **Next Steps**

### **Step 1: Install Paystack Python SDK**

```bash
pip install paystackapi
```

Add to `requirements.txt`:
```
paystackapi==2.2.2
```

---

### **Step 2: Create Paystack Plans in Dashboard**

1. **Login to Paystack Dashboard**: https://dashboard.paystack.com
2. **Navigate to**: Products → Plans
3. **Create Starter Plan**:
   - Name: "Tiannara Starter"
   - Amount: $49 USD (or ₦49,000 NGN)
   - Interval: Monthly
   - Note down the Plan Code (e.g., `PLN_xxxxx`)

4. **Create Professional Plan**:
   - Name: "Tiannara Professional"
   - Amount: $199 USD (or ₦199,000 NGN)
   - Interval: Monthly
   - Note down the Plan Code (e.g., `PLN_yyyyy`)

5. **Update `.env` with actual plan codes**:
   ```env
   PAYSTACK_STARTER_PLAN=PLN_actual_starter_code
   PAYSTACK_PROFESSIONAL_PLAN=PLN_actual_professional_code
   ```

---

### **Step 3: Configure Webhook Endpoint**

1. **In Paystack Dashboard**: Settings → API Keys & Webhooks
2. **Add Webhook URL**: 
   - For local testing: Use ngrok or similar
   - For production: `https://api.tiannara.com/api/v1/billing/webhook`
3. **Copy Webhook Secret** and update `.env`:
   ```env
   PAYSTACK_WEBHOOK_SECRET=whsec_actual_webhook_secret
   ```

---

### **Step 4: Build Backend Service**

Create file: `tiannara_api/services/paystack_service.py`

```python
from paystackapi.paystack import Paystack
import os
from typing import Dict, Any

class PaystackService:
    def __init__(self):
        self.paystack = Paystack(secret_key=os.getenv('PAYSTACK_SECRET_KEY'))
    
    def initialize_transaction(self, email: str, amount: int, reference: str, metadata: dict = None) -> Dict[str, Any]:
        """Initialize a payment transaction"""
        response = self.paystack.transaction.initialize(
            email=email,
            amount=amount * 100,  # Convert to kobo/cents
            reference=reference,
            metadata=metadata or {}
        )
        return response
    
    def verify_transaction(self, reference: str) -> Dict[str, Any]:
        """Verify transaction status"""
        response = self.paystack.transaction.verify(reference=reference)
        return response
    
    def create_customer(self, email: str, first_name: str = '', last_name: str = '') -> Dict[str, Any]:
        """Create customer in Paystack"""
        response = self.paystack.customer.create(
            email=email,
            first_name=first_name,
            last_name=last_name
        )
        return response
    
    def create_subscription(self, customer_code: str, plan_code: str) -> Dict[str, Any]:
        """Create subscription for customer"""
        response = self.paystack.subscription.create(
            customer=customer_code,
            plan=plan_code
        )
        return response
    
    def handle_webhook(self, event_data: dict) -> Dict[str, Any]:
        """Process webhook events"""
        event_type = event_data.get('event')
        
        if event_type == 'charge.success':
            return self._handle_charge_success(event_data)
        elif event_type == 'subscription.create':
            return self._handle_subscription_create(event_data)
        elif event_type == 'subscription.disable':
            return self._handle_subscription_disable(event_data)
        
        return {'status': 'ignored', 'event': event_type}
    
    def _handle_charge_success(self, event_data: dict) -> Dict[str, Any]:
        """Handle successful charge"""
        # Extract customer email and reference
        # Update user tier in database
        # Send confirmation email
        pass
    
    def _handle_subscription_create(self, event_data: dict) -> Dict[str, Any]:
        """Handle new subscription"""
        # Activate user subscription
        # Update database
        pass
    
    def _handle_subscription_disable(self, event_data: dict) -> Dict[str, Any]:
        """Handle subscription cancellation"""
        # Deactivate user subscription
        # Downgrade to free tier
        pass
```

---

### **Step 5: Create Billing Routes**

Create file: `tiannara_api/routes/billing.py`

```python
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from tiannara_api.database.session import get_db
from tiannara_api.services.paystack_service import PaystackService
from tiannara_api.routes.auth import get_current_user
import uuid

router = APIRouter(prefix="/api/v1/billing", tags=["billing"])
paystack = PaystackService()

@router.post("/initialize-payment")
async def initialize_payment(
    plan: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Initialize Paystack payment for subscription"""
    
    # Map plan to amount
    plan_amounts = {
        'starter': 4900,      # $49.00 in cents
        'professional': 19900  # $199.00 in cents
    }
    
    if plan not in plan_amounts:
        raise HTTPException(status_code=400, detail="Invalid plan")
    
    # Generate unique reference
    reference = f"txn_{uuid.uuid4().hex[:12]}"
    
    # Initialize transaction
    response = paystack.initialize_transaction(
        email=current_user['email'],
        amount=plan_amounts[plan],
        reference=reference,
        metadata={
            'user_id': current_user['id'],
            'plan': plan
        }
    )
    
    if response['status']:
        return {
            'authorization_url': response['data']['authorization_url'],
            'access_code': response['data']['access_code'],
            'reference': reference
        }
    else:
        raise HTTPException(status_code=500, detail="Payment initialization failed")

@router.post("/verify-payment/{reference}")
async def verify_payment(
    reference: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Verify payment and activate subscription"""
    
    response = paystack.verify_transaction(reference)
    
    if response['status'] and response['data']['status'] == 'success':
        # Activate user subscription
        # Update database
        return {'status': 'success', 'message': 'Subscription activated'}
    else:
        raise HTTPException(status_code=400, detail="Payment verification failed")

@router.post("/webhook")
async def paystack_webhook(request: Request):
    """Handle Paystack webhook events"""
    
    # Get raw body for signature verification
    body = await request.body()
    signature = request.headers.get('x-paystack-signature')
    
    # Verify webhook signature (implement this)
    # if not verify_signature(body, signature):
    #     raise HTTPException(status_code=401, detail="Invalid signature")
    
    # Parse event data
    import json
    event_data = json.loads(body)
    
    # Process event
    result = paystack.handle_webhook(event_data)
    
    return {'status': 'success'}
```

---

### **Step 6: Register Route in main.py**

Update `tiannara_api/main.py`:

```python
from tiannara_api.routes.billing import router as billing_router

app.include_router(billing_router)
```

---

### **Step 7: Test with Test Cards**

Use these test cards in development:

```
Card Number: 4084 0840 8408 4081
CVV: 408
Expiry: Any future date (e.g., 12/25)
PIN: 40840
OTP: 12345
```

**Test Scenarios:**
1. ✅ Successful payment
2. ❌ Failed payment (use card: `4084 0840 8408 4082`)
3. ⏸️ Pending payment
4. 🔄 Subscription renewal

---

## 🧪 **Testing Checklist**

- [ ] Install `paystackapi` package
- [ ] Create Paystack plans in dashboard
- [ ] Update plan codes in `.env`
- [ ] Build `paystack_service.py`
- [ ] Build `billing.py` routes
- [ ] Register routes in `main.py`
- [ ] Test payment initialization
- [ ] Test payment verification
- [ ] Test webhook handling
- [ ] Test subscription activation
- [ ] Test with multiple scenarios

---

## 📚 **Reference Documentation**

- **Full Integration Guide**: [`PAYSTACK_INTEGRATION_GUIDE.md`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/PAYSTACK_INTEGRATION_GUIDE.md)
- **Complete Implementation**: [`PAYSTACK_UPDATE_COMPLETE.md`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/PAYSTACK_UPDATE_COMPLETE.md)
- **Quick Reference**: [`PAYSTACK_QUICK_REF.md`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/PAYSTACK_QUICK_REF.md)
- **Paystack API Docs**: https://paystack.com/docs/api
- **Python SDK**: https://github.com/PaystackOSS/paystack-python

---

## 🚀 **Ready to Start?**

Your credentials are configured. Next action:

```bash
# 1. Install SDK
pip install paystackapi

# 2. Create backend service
# See Step 4 above

# 3. Start building!
```

---

**Status**: ✅ **Credentials Ready** | ⏳ **Implementation Next**
