# Payment Provider Update: Flutterwave → Paystack

**Date**: May 1, 2026  
**Change**: Switched payment provider from Flutterwave to Paystack  
**Reason**: Better African market support, lower fees, superior developer experience

---

## 🎯 **Why Paystack?**

### **Key Advantages:**

✅ **African Market Leadership**
- Dominant in Nigeria, Ghana, Kenya, South Africa
- Local payment methods (USSD, bank transfer, mobile money)
- Trusted by 60,000+ businesses in Africa

✅ **Lower Transaction Fees**
- Nigeria: 1.5% + ₦100 per transaction
- International cards: 3.9% + fixed fee
- No monthly fees or setup costs
- vs. Flutterwave: 1.4% but higher international fees

✅ **Superior Developer Experience**
- Excellent API documentation
- Python SDK (`paystackapi`) ready to use
- Comprehensive webhook system
- Test mode with test cards
- React/Next.js integration examples

✅ **Built-in Subscription Management**
- Automatic recurring billing
- Customer portal for self-service
- Invoice generation & email delivery
- Dunning management (failed payment retries)
- Proration support for tier changes

✅ **International Support**
- Accepts Visa, Mastercard, American Express
- Multiple currencies: NGN, USD, GBP, EUR, GHS, KES, ZAR
- Global payout options
- PCI DSS Level 1 compliant

---

## 📋 **Updated Documents**

### **Documents Modified:**

1. ✅ [`COMPLETE_ROADMAP_2026.md`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/COMPLETE_ROADMAP_2026.md)
   - Line 246: "Flutterwave not integrated" → "Paystack not integrated"
   - Line 258: "Flutterwave payment integration" → "Paystack payment integration"
   - Line 337: "Flutterwave not integrated" → "Paystack not integrated"
   - Line 416: "Flutterwave integration" → "Paystack SDK integration"
   - Line 513: "Flutterwave SDK integration" → "Paystack SDK integration"

2. ✅ [`PROGRESS_DASHBOARD.md`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/PROGRESS_DASHBOARD.md)
   - Updated billing section to reference Paystack
   - Added "Why Paystack?" explanation
   - Updated implementation timeline

3. ✅ [`PAYSTACK_INTEGRATION_GUIDE.md`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/PAYSTACK_INTEGRATION_GUIDE.md)
   - Complete implementation guide (created)
   - Backend integration steps
   - Frontend integration steps
   - Webhook handling
   - Testing procedures

4. ✅ [`PAYSTACK_SWITCH_SUMMARY.md`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/PAYSTACK_SWITCH_SUMMARY.md)
   - Quick reference document (created)
   - Migration checklist
   - Code examples

---

## 🔧 **Implementation Plan**

### **Phase 1: Backend Integration** (Week 1)

#### **Step 1: Install Dependencies**
```bash
pip install paystackapi
```

#### **Step 2: Create Paystack Service**
File: `tiannara_api/services/paystack_service.py`

```python
from paystackapi.paystack import Paystack
import os

class PaystackService:
    def __init__(self):
        self.paystack = Paystack(secret_key=os.getenv('PAYSTACK_SECRET_KEY'))
    
    def create_customer(self, email, name, phone=None):
        """Create customer in Paystack"""
        response = self.paystack.customer.create(
            email=email,
            first_name=name.split()[0] if name else '',
            last_name=' '.join(name.split()[1:]) if name and len(name.split()) > 1 else '',
            phone=phone
        )
        return response
    
    def create_subscription(self, customer_code, plan_code):
        """Create subscription for customer"""
        response = self.paystack.subscription.create(
            customer=customer_code,
            plan=plan_code
        )
        return response
    
    def verify_transaction(self, reference):
        """Verify transaction status"""
        response = self.paystack.transaction.verify(reference=reference)
        return response
    
    def handle_webhook(self, event_data):
        """Process webhook events"""
        event_type = event_data.get('event')
        
        if event_type == 'charge.success':
            # Handle successful payment
            pass
        elif event_type == 'subscription.create':
            # Activate user tier
            pass
        elif event_type == 'subscription.disable':
            # Downgrade user tier
            pass
        
        return {'status': 'success'}
```

#### **Step 3: Create Billing Routes**
File: `tiannara_api/routes/billing.py`

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from tiannara_api.database.session import get_db
from tiannara_api.services.paystack_service import PaystackService
from tiannara_api.routes.auth import get_current_user

router = APIRouter(prefix="/api/v1/billing", tags=["billing"])
paystack = PaystackService()

@router.post("/create-subscription")
async def create_subscription(
    plan: str,  # 'starter' or 'professional'
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create Paystack subscription for user"""
    # Map plan to Paystack plan code
    plan_codes = {
        'starter': 'PLN_xxxxx',      # Replace with actual plan codes
        'professional': 'PLN_yyyyy'
    }
    
    if plan not in plan_codes:
        raise HTTPException(status_code=400, detail="Invalid plan")
    
    # Get or create Paystack customer
    customer_response = paystack.create_customer(
        email=current_user['email'],
        name=current_user.get('full_name', '')
    )
    
    # Create subscription
    subscription_response = paystack.create_subscription(
        customer_code=customer_response['data']['customer_code'],
        plan_code=plan_codes[plan]
    )
    
    return {
        'authorization_url': subscription_response['data']['authorization_url'],
        'access_code': subscription_response['data']['access_code']
    }

@router.post("/webhook")
async def paystack_webhook(request: Request):
    """Handle Paystack webhook events"""
    event_data = await request.json()
    
    # Verify webhook signature
    signature = request.headers.get('x-paystack-signature')
    if not verify_signature(event_data, signature):
        raise HTTPException(status_code=401, detail="Invalid signature")
    
    # Process event
    result = paystack.handle_webhook(event_data)
    
    return result
```

#### **Step 4: Add Environment Variables**
File: `.env`

```env
# Paystack Configuration
PAYSTACK_PUBLIC_KEY=pk_live_xxxxxxxxxxxxxxxx
PAYSTACK_SECRET_KEY=sk_live_xxxxxxxxxxxxxxxx
PAYSTACK_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxx

# Paystack Plan Codes
PAYSTACK_STARTER_PLAN=PLN_xxxxx
PAYSTACK_PROFESSIONAL_PLAN=PLN_yyyyy
```

---

### **Phase 2: Frontend Integration** (Week 2)

#### **Step 1: Install Paystack React SDK**
```bash
cd tiannara_gui
npm install react-paystack
```

#### **Step 2: Create Payment Component**
File: `tiannara_gui/src/components/Billing/PaystackPayment.tsx`

```tsx
import React from 'react';
import { usePaystackPayment } from 'react-paystack';

interface PaystackPaymentProps {
  plan: 'starter' | 'professional';
  userEmail: string;
  userName: string;
  onSuccess: (reference: any) => void;
  onClose: () => void;
}

const PaystackPayment: React.FC<PaystackPaymentProps> = ({
  plan,
  userEmail,
  userName,
  onSuccess,
  onClose
}) => {
  const config = {
    reference: new Date().getTime().toString(),
    email: userEmail,
    amount: plan === 'starter' ? 4900 : 19900, // Amount in kobo/cents
    publicKey: process.env.NEXT_PUBLIC_PAYSTACK_PUBLIC_KEY || '',
    metadata: {
      custom_fields: [
        {
          display_name: "Plan",
          variable_name: "plan",
          value: plan
        },
        {
          display_name: "Customer Name",
          variable_name: "customer_name",
          value: userName
        }
      ]
    }
  };

  const initializePayment = usePaystackPayment(config);

  return (
    <button
      onClick={() => initializePayment(onSuccess, onClose)}
      className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition"
    >
      Subscribe to {plan === 'starter' ? 'Starter' : 'Professional'} - ${plan === 'starter' ? '49' : '199'}/month
    </button>
  );
};

export default PaystackPayment;
```

#### **Step 3: Update Billing Page**
File: `tiannara_gui/src/app/dashboard/billing/page.tsx`

```tsx
import { useState } from 'react';
import PaystackPayment from '@/components/Billing/PaystackPayment';

export default function BillingPage() {
  const [selectedPlan, setSelectedPlan] = useState<'starter' | 'professional'>('starter');
  const user = useAuth(); // Get current user from auth context

  const handlePaymentSuccess = async (reference: any) => {
    // Verify payment on backend
    const response = await fetch('/api/v1/billing/verify-payment', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ reference: reference.reference })
    });
    
    if (response.ok) {
      // Show success message
      alert('Subscription activated successfully!');
      // Refresh user data
    }
  };

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-6">Billing & Subscription</h1>
      
      {/* Current Plan */}
      <div className="mb-8">
        <h2 className="text-lg font-semibold mb-4">Current Plan</h2>
        <div className="bg-gray-100 p-4 rounded-lg">
          <p>Plan: {user.tier || 'Free'}</p>
          <p>Status: {user.subscription_status || 'Inactive'}</p>
        </div>
      </div>

      {/* Upgrade Options */}
      <div className="grid md:grid-cols-2 gap-6">
        {/* Starter Plan */}
        <div className="border p-6 rounded-lg">
          <h3 className="text-xl font-bold">Starter</h3>
          <p className="text-3xl font-bold my-4">$49<span className="text-sm font-normal">/month</span></p>
          <ul className="mb-6 space-y-2">
            <li>✓ 5,000 API requests/month</li>
            <li>✓ Core AI workflows</li>
            <li>✓ Basic analytics</li>
          </ul>
          
          <PaystackPayment
            plan="starter"
            userEmail={user.email}
            userName={user.full_name}
            onSuccess={handlePaymentSuccess}
            onClose={() => console.log('Payment cancelled')}
          />
        </div>

        {/* Professional Plan */}
        <div className="border p-6 rounded-lg">
          <h3 className="text-xl font-bold">Professional</h3>
          <p className="text-3xl font-bold my-4">$199<span className="text-sm font-normal">/month</span></p>
          <ul className="mb-6 space-y-2">
            <li>✓ 50,000 API requests/month</li>
            <li>✓ Advanced orchestration</li>
            <li>✓ Priority processing</li>
            <li>✓ Team collaboration</li>
          </ul>
          
          <PaystackPayment
            plan="professional"
            userEmail={user.email}
            userName={user.full_name}
            onSuccess={handlePaymentSuccess}
            onClose={() => console.log('Payment cancelled')}
          />
        </div>
      </div>
    </div>
  );
}
```

---

### **Phase 3: Webhook Handling** (Week 2)

#### **Step 1: Create Webhook Endpoint**
Already shown in Phase 1, Step 3 above.

#### **Step 2: Implement Tier Activation Logic**
File: `tiannara_api/services/subscription_service.py`

```python
from sqlalchemy.orm import Session
from datetime import datetime, timedelta

def activate_subscription(db: Session, user_id: str, plan: str, paystack_reference: str):
    """Activate user subscription after successful payment"""
    
    # Determine tier based on plan
    tier_map = {
        'starter': 'starter',
        'professional': 'professional'
    }
    
    tier = tier_map.get(plan)
    if not tier:
        raise ValueError(f"Invalid plan: {plan}")
    
    # Update user tier
    user = db.query(User).filter(User.id == user_id).first()
    if user:
        user.tier = tier
        user.subscription_status = 'active'
        user.subscription_start_date = datetime.utcnow()
        user.subscription_end_date = datetime.utcnow() + timedelta(days=30)
        user.paystack_customer_reference = paystack_reference
        db.commit()
    
    return user

def deactivate_subscription(db: Session, user_id: str):
    """Deactivate user subscription (payment failed/cancelled)"""
    user = db.query(User).filter(User.id == user_id).first()
    if user:
        user.tier = 'free'
        user.subscription_status = 'inactive'
        user.subscription_end_date = datetime.utcnow()
        db.commit()
    
    return user
```

---

## 🧪 **Testing Plan**

### **Test Mode Setup**

1. **Get Test Keys from Paystack Dashboard**
   - Public Key: `pk_test_xxxxxxxxxxxxxxxx`
   - Secret Key: `sk_test_xxxxxxxxxxxxxxxx`

2. **Use Test Cards**
   ```
   Card Number: 4084 0840 8408 4081
   CVV: 408
   Expiry: Any future date
   PIN: 40840
   OTP: 12345
   ```

3. **Test Scenarios**
   - ✅ Successful subscription creation
   - ✅ Failed payment handling
   - ✅ Webhook event processing
   - ✅ Tier upgrade/downgrade
   - ✅ Subscription cancellation
   - ✅ Invoice generation

---

## 📊 **Cost Comparison**

| Feature | Flutterwave | Paystack | Winner |
|---------|-------------|----------|--------|
| **Nigeria Fee** | 1.4% | 1.5% + ₦100 | Flutterwave (slightly) |
| **International Fee** | 3.8% | 3.9% | Flutterwave (slightly) |
| **Monthly Fee** | $0 | $0 | Tie |
| **Setup Fee** | $0 | $0 | Tie |
| **Developer Docs** | Good | Excellent | **Paystack** |
| **African Coverage** | 10 countries | 4 countries (deeper) | **Paystack** |
| **Subscription Mgmt** | Basic | Advanced | **Paystack** |
| **Webhook Reliability** | Good | Excellent | **Paystack** |
| **React Integration** | Limited | Well-documented | **Paystack** |

**Verdict**: Paystack wins on developer experience, subscription management, and reliability despite slightly higher fees.

---

## ✅ **Migration Checklist**

### **Before Launch:**

- [ ] Sign up for Paystack account
- [ ] Complete business verification
- [ ] Get live API keys
- [ ] Create pricing plans in Paystack dashboard
- [ ] Configure webhook endpoint URL
- [ ] Test with test cards
- [ ] Deploy webhook endpoint to production
- [ ] Update environment variables
- [ ] Test end-to-end subscription flow
- [ ] Monitor first live transactions

### **Post-Launch:**

- [ ] Set up Paystack dashboard alerts
- [ ] Configure email notifications
- [ ] Monitor webhook delivery rates
- [ ] Track failed payment patterns
- [ ] Optimize dunning settings
- [ ] Review monthly payouts

---

## 🚀 **Next Steps**

1. **Immediate (This Week)**
   - Create Paystack account
   - Install `paystackapi` Python package
   - Create backend service layer
   - Set up test environment

2. **Short-term (Next 2 Weeks)**
   - Build frontend payment components
   - Implement webhook handling
   - Test subscription flows
   - Deploy to staging

3. **Medium-term (Month 2)**
   - Go live with Paystack
   - Monitor transactions
   - Optimize conversion rates
   - Add invoice features

---

## 📞 **Support Resources**

- **Paystack Documentation**: https://paystack.com/docs
- **API Reference**: https://paystack.com/docs/api
- **Python SDK**: https://github.com/PaystackOSS/paystack-python
- **React SDK**: https://github.com/paystack/react-paystack
- **Support Email**: support@paystack.com
- **Developer Slack**: Available upon request

---

**Status**: ✅ **Ready to implement**  
**Priority**: HIGH (blocks beta launch)  
**Estimated Timeline**: 2-3 weeks for full integration
