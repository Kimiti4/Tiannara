# Tiannara SaaS - Tier Subscription System Analysis & Implementation Plan

## 📊 Current Status Assessment

### ✅ What's Already Implemented

#### 1. **Pricing Plans Configuration** (`tiannara_api/payment.py`)
The system has complete pricing tier definitions:

```python
PRICING_PLANS = {
    "starter": {
        "requests_per_month": 5000,      # ✅ Defined
        "max_domains": 4,                 # ✅ Defined
        "skill_transfer": True,           # ✅ Defined
        "amount_cents": 4900              # $49/month ✅
    },
    "professional": {
        "requests_per_month": 50000,     # ✅ Defined
        "max_domains": 10,                # ✅ Defined
        "skill_transfer": True,           # ✅ Defined
        "priority_support": True,         # ✅ Defined
        "amount_cents": 19900             # $199/month ✅
    },
    "enterprise": {
        "requests_per_month": -1,         # Unlimited ✅
        "max_domains": -1,                # Unlimited ✅
        "skill_transfer": True,           # ✅ Defined
        "priority_support": True,         # ✅ Defined
        "custom_domains": True,           # ✅ Defined
        "amount_cents": 99900             # $999/month ✅
    }
}
```

#### 2. **Payment Processing** ✅
- Stripe integration (complete)
- Lemon Squeezy integration (complete)
- Webhook handlers for subscription events
- Checkout session creation

#### 3. **Usage Tracking** ⚠️ Partial
- `/api/v1/usage/metrics` endpoint exists
- Returns usage statistics
- **BUT:** Currently uses mock data, not tied to user tiers

---

## ❌ Critical Gaps Identified

### **Gap 1: No Tier Enforcement Middleware**
**Problem:** Users can make unlimited API calls regardless of their subscription tier.

**Current State:**
- Pricing plans defined in `payment.py`
- No middleware checking user's tier before allowing requests
- No quota tracking per user

**Impact:** 
- Starter users ($49/mo) could use Professional features (50k requests)
- No way to enforce 5,000 request limit for Starter tier
- No blocking when quota exceeded

---

### **Gap 2: No User Subscription Status in Database**
**Problem:** User model doesn't track active subscription tier.

**Current State:**
- User model has `tier` field (string)
- No automatic updates from payment webhooks
- No subscription expiration tracking
- No downgrade logic when payment fails

**Impact:**
- Can't determine if user is Starter/Professional/Enterprise
- Can't enforce feature access based on tier
- Manual tier assignment required

---

### **Gap 3: Feature Access Not Enforced**
**Problem:** All users have access to all features regardless of tier.

**Architecture.md Specifies:**

| Feature | Starter | Professional | Enterprise |
|---------|---------|--------------|------------|
| Team Collaboration | ❌ | ✅ | ✅ |
| Priority Processing | ❌ | ✅ | ✅ |
| Monitoring & Alerts | ❌ | ✅ | ✅ |
| Advanced Automation | Basic | Advanced | Custom |
| SLA Guarantee | ❌ | 99.5% | Custom |
| Compliance Tooling | ❌ | ❌ | ✅ |

**Current State:**
- All dashboard pages accessible to all users
- No role-based feature gating
- No team management restrictions for Starter tier

**Impact:**
- Starter users can access team features (should be blocked)
- No priority processing differentiation
- All users get same response times

---

### **Gap 4: No Quota Tracking & Throttling**
**Problem:** No mechanism to count API requests per user per month.

**Required:**
- Track each API call against user's monthly quota
- Block requests when quota exceeded
- Show remaining quota in dashboard
- Reset quota at billing cycle start

**Current State:**
- Usage metrics endpoint returns mock data
- No real-time quota checking
- No throttling when limit reached

---

### **Gap 5: No Tier Upgrade/Downgrade Flow**
**Problem:** Users can't easily switch between tiers.

**Required:**
- Upgrade from Starter → Professional (immediate)
- Downgrade from Professional → Starter (end of billing cycle)
- Proration handling
- Feature access changes immediately on upgrade

**Current State:**
- Payment routes exist but no upgrade/downgrade logic
- No UI for changing plans
- No proration calculation

---

## 🎯 Implementation Plan

### **Phase 1: Core Infrastructure (Week 1)**

#### 1.1 Database Schema Updates
Add subscription tracking to user model:

```python
# tiannara_api/database/models.py
class User(Base):
    # ... existing fields ...
    
    # Subscription fields
    tier = Column(String, default="free")  # free, starter, professional, enterprise
    subscription_id = Column(String, nullable=True)  # Stripe/LemonSqueezy ID
    subscription_status = Column(String, default="inactive")  # active, cancelled, past_due
    current_period_start = Column(DateTime, nullable=True)
    current_period_end = Column(DateTime, nullable=True)
    cancel_at_period_end = Column(Boolean, default=False)
    
    # Usage tracking
    monthly_request_count = Column(Integer, default=0)
    last_quota_reset = Column(DateTime, nullable=True)
```

#### 1.2 Quota Tracking Middleware
Create middleware to check and enforce quotas:

```python
# tiannara_api/middleware/quota_enforcer.py
from fastapi import Request, HTTPException
from tiannara_api.database.models import User
from tiannara_api.payment import PRICING_PLANS

async def check_quota(request: Request, user: User):
    """Check if user has remaining API quota."""
    
    # Get user's tier limits
    tier_limits = PRICING_PLANS.get(user.tier, PRICING_PLANS["free"])
    max_requests = tier_limits["requests_per_month"]
    
    # Unlimited for enterprise
    if max_requests == -1:
        return
    
    # Check if quota reset needed (new billing cycle)
    if should_reset_quota(user):
        reset_user_quota(user)
        return
    
    # Check current usage
    if user.monthly_request_count >= max_requests:
        raise HTTPException(
            status_code=429,
            detail={
                "error": "quota_exceeded",
                "message": f"You've reached your {user.tier} tier limit of {max_requests:,} requests/month",
                "upgrade_url": "/dashboard/billing/upgrade"
            }
        )
    
    # Increment counter
    increment_user_usage(user)
```

#### 1.3 Webhook Handler Updates
Update webhook handlers to update user subscription status:

```python
# tiannara_api/routes/payment.py
@router.post("/webhook")
async def handle_webhook(request: Request):
    """Handle payment provider webhooks."""
    
    event = await payment_processor.handle_webhook(...)
    
    if event["status"] == "subscription_created":
        # Update user's tier
        user = db.query(User).filter(User.email == event["customer_email"]).first()
        user.tier = event["plan"]  # starter, professional, enterprise
        user.subscription_status = "active"
        user.current_period_start = datetime.utcnow()
        user.current_period_end = datetime.utcnow() + timedelta(days=30)
        db.commit()
        
    elif event["status"] == "subscription_cancelled":
        # Schedule downgrade at period end
        user.cancel_at_period_end = True
        db.commit()
```

---

### **Phase 2: Feature Access Control (Week 2)**

#### 2.1 Tier-Based Route Protection
Add decorators to protect tier-specific features:

```python
# tiannara_api/middleware/tier_guard.py
from functools import wraps
from fastapi import HTTPException

def require_tier(*allowed_tiers):
    """Decorator to restrict access by subscription tier."""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Get current user from request
            user = kwargs.get("current_user")
            
            if user.tier not in allowed_tiers:
                raise HTTPException(
                    status_code=403,
                    detail={
                        "error": "insufficient_tier",
                        "message": f"This feature requires {', '.join(allowed_tiers)} tier",
                        "current_tier": user.tier,
                        "upgrade_url": "/dashboard/billing"
                    }
                )
            
            return await func(*args, **kwargs)
        return wrapper
    return decorator

# Usage example:
@router.get("/team/members")
@require_tier("professional", "enterprise")
async def get_team_members(current_user: dict = Depends(get_current_user)):
    """Only Professional and Enterprise can access team features."""
    ...
```

#### 2.2 Frontend Feature Gating
Update frontend to hide/show features based on tier:

```typescript
// tiannara_saas/contexts/AuthContext.tsx
export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<UserProfile | null>(null)
  
  // Helper to check feature access
  const hasFeature = (feature: string): boolean => {
    if (!user) return false
    
    const tierFeatures = {
      starter: ['basic_workflows', 'basic_analytics'],
      professional: ['basic_workflows', 'basic_analytics', 'team_collaboration', 'priority_processing', 'monitoring'],
      enterprise: ['basic_workflows', 'basic_analytics', 'team_collaboration', 'priority_processing', 'monitoring', 'compliance', 'custom_deployment']
    }
    
    return tierFeatures[user.tier]?.includes(feature) || false
  }
  
  return (
    <AuthContext.Provider value={{ user, hasFeature, ... }}>
      {children}
    </AuthContext.Provider>
  )
}
```

```tsx
// tiannara_saas/app/dashboard/team/page.tsx
import { useAuth } from '@/contexts/AuthContext'

export default function TeamPage() {
  const { user, hasFeature } = useAuth()
  
  if (!hasFeature('team_collaboration')) {
    return (
      <UpgradePrompt
        title="Team Collaboration"
        description="Upgrade to Professional or Enterprise to manage team members"
        currentTier={user?.tier}
        requiredTier="professional"
      />
    )
  }
  
  // Render team page normally
  return <TeamManagement />
}
```

---

### **Phase 3: Billing UI & Upgrade Flow (Week 3)**

#### 3.1 Billing Page Enhancement
Create comprehensive billing page showing:

```tsx
// tiannara_saas/app/dashboard/billing/page.tsx
- Current plan details
- Usage meter (X of Y requests used)
- Upgrade/downgrade buttons
- Billing history
- Payment method management
- Invoice downloads
```

#### 3.2 Upgrade Flow
Implement seamless upgrade process:

```typescript
const handleUpgrade = async (newPlan: string) => {
  // 1. Create checkout session for new plan
  const response = await apiClient.createSubscription({
    plan: newPlan,
    success_url: `${window.location.origin}/dashboard/billing/success`,
    cancel_url: `${window.location.origin}/dashboard/billing`
  })
  
  // 2. Redirect to payment provider
  window.location.href = response.checkout_url
}

// After successful payment (webhook updates user tier automatically)
// User immediately gets access to new features
```

#### 3.3 Downgrade Flow
Handle downgrades gracefully:

```typescript
const handleDowngrade = async (newPlan: string) => {
  // 1. Cancel current subscription at period end
  await apiClient.cancelSubscription({
    cancel_at_period_end: true
  })
  
  // 2. Show confirmation message
  alert(`You'll be downgraded to ${newPlan} at the end of your billing cycle`)
  
  // 3. Update UI to show pending downgrade
  setPendingDowngrade(newPlan)
}
```

---

### **Phase 4: Usage Dashboard & Alerts (Week 4)**

#### 4.1 Real-Time Usage Meter
Show remaining quota prominently:

```tsx
// tiannara_saas/app/dashboard/page.tsx
<div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
  <h3 className="text-lg font-semibold text-white mb-4">API Usage</h3>
  
  <div className="mb-2 flex justify-between text-sm">
    <span className="text-slate-400">
      {metrics.api_usage.current.toLocaleString()} / 
      {metrics.api_usage.limit === -1 ? '∞' : metrics.api_usage.limit.toLocaleString()} requests
    </span>
    <span className="text-slate-400">
      {Math.round((metrics.api_usage.current / metrics.api_usage.limit) * 100)}%
    </span>
  </div>
  
  <div className="w-full bg-slate-700 rounded-full h-2">
    <div 
      className={`h-2 rounded-full transition-all ${
        usagePercentage > 90 ? 'bg-red-500' : 
        usagePercentage > 75 ? 'bg-yellow-500' : 
        'bg-green-500'
      }`}
      style={{ width: `${Math.min(usagePercentage, 100)}%` }}
    />
  </div>
  
  {usagePercentage > 80 && (
    <div className="mt-4 p-3 bg-yellow-500/10 border border-yellow-500/20 rounded-lg">
      <p className="text-sm text-yellow-400">
        ⚠️ You've used {usagePercentage}% of your monthly quota. 
        <a href="/dashboard/billing/upgrade" className="underline ml-1">
          Upgrade now
        </a>
      </p>
    </div>
  )}
</div>
```

#### 4.2 Email Alerts
Send warnings at thresholds:

```python
# tiannara_api/services/quota_alerts.py
def check_and_send_quota_alerts(user: User):
    """Send email alerts when user approaches quota limits."""
    
    tier_limits = PRICING_PLANS[user.tier]
    usage_percentage = (user.monthly_request_count / tier_limits["requests_per_month"]) * 100
    
    if usage_percentage >= 90:
        send_email(
            to=user.email,
            subject="⚠️ You've used 90% of your API quota",
            template="quota_warning_90",
            context={
                "used": user.monthly_request_count,
                "limit": tier_limits["requests_per_month"],
                "upgrade_url": "https://tiannara.com/dashboard/billing/upgrade"
            }
        )
    
    elif usage_percentage >= 100:
        send_email(
            to=user.email,
            subject="🚫 You've reached your API quota limit",
            template="quota_exceeded",
            context={
                "upgrade_url": "https://tiannara.com/dashboard/billing/upgrade"
            }
        )
```

---

## 📋 Feature Access Matrix

Based on architecture.md, here's what each tier should access:

### **Starter ($49/mo)**
✅ **Allowed:**
- 5,000 API requests/month
- Core reasoning & workflow engine
- AI-assisted analytics and insights
- Explainable outputs
- Basic automation modules
- Basic dashboard analytics
- API access
- Community support

❌ **Blocked:**
- Team collaboration features
- Priority processing
- Advanced monitoring & alerts
- Webhooks & integrations
- SLA guarantee
- Advanced automation workflows

---

### **Professional ($199/mo)**
✅ **Everything in Starter, plus:**
- 50,000 API requests/month
- Priority processing & faster response
- Advanced workflow orchestration
- Real-time analytics dashboard
- Team collaboration tools (up to 10 members)
- Webhooks & integrations
- Advanced monitoring & alerts
- Usage analytics & reporting
- 99.5% SLA uptime guarantee
- Priority email support (24-hour)
- Enhanced automation workflows
- Project versioning

❌ **Blocked:**
- Unlimited API access
- Dedicated infrastructure
- Custom AI workflow deployment
- Compliance tooling
- Private/on-premise deployment
- Dedicated account manager
- 24/7 support

---

### **Enterprise ($999/mo or Custom)**
✅ **Everything in Professional, plus:**
- Unlimited API requests
- Dedicated infrastructure options
- Custom AI workflow deployment
- Explainability & audit reporting
- Compliance tooling & governance
- Dedicated account manager
- 24/7 priority support
- Custom SLA agreements
- Advanced security controls
- Private/on-premise deployment
- Custom integrations & onboarding
- Strategic architecture reviews
- Multi-region deployment

---

## 🚀 Integration Ease for Businesses

### **How Businesses Will Integrate Tiannara:**

#### 1. **Quick Start (5 minutes)**
```bash
# 1. Sign up for Starter tier
# 2. Generate API key from dashboard
# 3. Install SDK
pip install tiannara-sdk

# 4. Make first API call
from tiannara import TiannaraClient

client = TiannaraClient(api_key="your_key_here")
result = client.analyze("Customer sentiment analysis", data=sales_data)
print(result.insights)
```

#### 2. **Workflow Builder (No Code)**
- Visual drag-and-drop interface
- Pre-built templates for common use cases
- Connect to existing data sources
- Deploy with one click

#### 3. **API Integration (Developers)**
```python
# Example: Automate repetitive analysis
from tiannara import Workflow

workflow = Workflow(name="Daily Sales Analysis")
workflow.add_step("data_ingestion", source="sales_db")
workflow.add_step("sentiment_analysis", model="nlp_v2")
workflow.add_step("forecasting", horizon="7d")
workflow.add_step("report_generation", format="pdf")

workflow.schedule(cron="0 9 * * *")  # Run daily at 9 AM
workflow.deploy()
```

#### 4. **Team Collaboration (Professional+)**
- Invite team members via email
- Shared workspaces
- Collaborative workflow editing
- Role-based permissions (admin/member/viewer)

#### 5. **Enterprise Deployment**
- Private cloud or on-premise option
- Custom domain setup
- SSO integration (SAML/OAuth)
- Dedicated support channel
- Custom compliance configurations

---

## 📊 Success Metrics

After implementation, we should track:

1. **Conversion Rates:**
   - Free → Starter: Target 5%
   - Starter → Professional: Target 15%
   - Professional → Enterprise: Target 10%

2. **Quota Utilization:**
   - Average % of quota used per tier
   - Number of users hitting quota limits
   - Upgrade rate after quota warnings

3. **Feature Adoption:**
   - % of Professional users using team features
   - % using advanced monitoring
   - % using webhooks/integrations

4. **Churn Indicators:**
   - Users consistently under-utilizing quota
   - Failed payment attempts
   - Support tickets about pricing

---

## ✅ Implementation Checklist

### Phase 1: Infrastructure
- [ ] Add subscription fields to User model
- [ ] Create quota tracking middleware
- [ ] Implement quota reset logic (monthly)
- [ ] Update webhook handlers to sync subscription status
- [ ] Add database migrations

### Phase 2: Access Control
- [ ] Create tier-based route decorators
- [ ] Protect team management routes (Professional+)
- [ ] Protect monitoring routes (Professional+)
- [ ] Protect compliance routes (Enterprise only)
- [ ] Add frontend feature gating

### Phase 3: Billing UI
- [ ] Create billing page with plan comparison
- [ ] Add usage meter with visual progress bar
- [ ] Implement upgrade flow
- [ ] Implement downgrade flow
- [ ] Add billing history table
- [ ] Add invoice download functionality

### Phase 4: Monitoring & Alerts
- [ ] Real-time quota tracking
- [ ] Email alerts at 80%, 90%, 100% usage
- [ ] Dashboard notifications
- [ ] Usage breakdown by feature/domain
- [ ] Predictive alerts (based on usage trends)

### Testing
- [ ] Test quota enforcement (Starter limit)
- [ ] Test feature access control
- [ ] Test upgrade flow (immediate access)
- [ ] Test downgrade flow (end of period)
- [ ] Test webhook synchronization
- [ ] Test email alerts
- [ ] Load test with multiple tiers

---

## 🎯 Conclusion

**Current State:** Tiannara SaaS has the foundation (pricing plans, payment processing) but lacks enforcement mechanisms.

**What's Needed:** 
1. Quota tracking and enforcement
2. Tier-based feature access control
3. Subscription status synchronization
4. User-friendly upgrade/downgrade flows
5. Usage monitoring and alerts

**Timeline:** 4 weeks for complete implementation

**Result:** A fully functional multi-tier SaaS platform where:
- ✅ Starter users get exactly 5,000 requests/month with basic features
- ✅ Professional users get 50,000 requests with team collaboration and advanced features
- ✅ Enterprise users get unlimited access with custom deployment options
- ✅ Easy upgrades/downgrades with immediate feature access changes
- ✅ Automatic enforcement prevents abuse and ensures fair usage
- ✅ Businesses can integrate in minutes with clear upgrade paths

**This will make Tiannara SaaS production-ready for real customers!** 🚀
