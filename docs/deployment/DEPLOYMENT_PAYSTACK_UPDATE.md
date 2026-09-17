# Production Deployment - Paystack Integration Update

**Date**: May 1, 2026  
**Status**: ✅ **Configuration Added** | ⏳ **Implementation Pending**  
**Related**: [`PRODUCTION_DEPLOYMENT_GUIDE.md`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/PRODUCTION_DEPLOYMENT_GUIDE.md)

---

## 🎯 **Overview**

This document updates the production deployment guide to include Paystack payment gateway configuration and billing service deployment requirements.

---

## 🔧 **Environment Configuration Updates**

### **Production .env File**

Add these variables to your production `.env` file (or Kubernetes Secrets):

```bash
# Paystack Payment Gateway (Production)
PAYSTACK_PUBLIC_KEY=pk_live_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
PAYSTACK_SECRET_KEY=sk_live_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
PAYSTACK_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Paystack Plan Codes (Create in Paystack Dashboard first)
PAYSTACK_STARTER_PLAN=PLN_starter_plan_code
PAYSTACK_PROFESSIONAL_PLAN=PLN_professional_plan_code

# Billing Service Configuration
BILLING_SERVICE_URL=http://tiannara-api:8000/api/v1/billing
WEBHOOK_VERIFY_SIGNATURE=true
PAYMENT_TIMEOUT_SECONDS=300
```

### **Kubernetes Secrets**

Create a Kubernetes Secret for Paystack credentials:

```yaml
# kubernetes/secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: tiannara-secrets
  namespace: tiannara-production
type: Opaque
stringData:
  # ... existing secrets ...
  
  # Paystack Credentials
  PAYSTACK_PUBLIC_KEY: "pk_live_xxxxx"
  PAYSTACK_SECRET_KEY: "sk_live_xxxxx"
  PAYSTACK_WEBHOOK_SECRET: "whsec_xxxxx"
  PAYSTACK_STARTER_PLAN: "PLN_xxxxx"
  PAYSTACK_PROFESSIONAL_PLAN: "PLN_xxxxx"
```

Apply with:
```bash
kubectl apply -f kubernetes/secrets.yaml
```

---

## 🐳 **Docker Configuration Updates**

### **API Service Environment Variables**

Update `docker-compose.prod.yml` to include Paystack environment variables:

```yaml
tiannara-api:
  image: tiannara/api:${API_VERSION:-latest}
  environment:
    # ... existing env vars ...
    
    # Paystack Configuration
    PAYSTACK_PUBLIC_KEY: ${PAYSTACK_PUBLIC_KEY}
    PAYSTACK_SECRET_KEY: ${PAYSTACK_SECRET_KEY}
    PAYSTACK_WEBHOOK_SECRET: ${PAYSTACK_WEBHOOK_SECRET}
    PAYSTACK_STARTER_PLAN: ${PAYSTACK_STARTER_PLAN}
    PAYSTACK_PROFESSIONAL_PLAN: ${PAYSTACK_PROFESSIONAL_PLAN}
```

### **Kubernetes Deployment Update**

Update the API deployment to reference Paystack secrets:

```yaml
# kubernetes/deployments/api-deployment.yaml
spec:
  template:
    spec:
      containers:
      - name: api
        image: tiannara/api:latest
        envFrom:
        - configMapRef:
            name: tiannara-config
        - secretRef:
            name: tiannara-secrets  # Includes Paystack credentials
```

---

## 🌐 **Webhook Endpoint Configuration**

### **Nginx Configuration for Webhooks**

Add webhook endpoint to Nginx configuration:

```nginx
# docker/nginx/nginx.conf

# Webhook endpoint (no rate limiting, signature verification handles security)
location /api/v1/billing/webhook {
    proxy_pass http://api_backend;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # Increase timeout for webhook processing
    proxy_connect_timeout 30s;
    proxy_send_timeout 30s;
    proxy_read_timeout 30s;
}
```

### **Paystack Dashboard Setup**

1. **Login to Paystack Dashboard**: https://dashboard.paystack.com
2. **Navigate to**: Settings → API Keys & Webhooks
3. **Add Webhook URL**:
   - Staging: `https://api-staging.tiannara.com/api/v1/billing/webhook`
   - Production: `https://api.tiannara.com/api/v1/billing/webhook`
4. **Select Events to Receive**:
   - ✅ charge.success
   - ✅ charge.failed
   - ✅ subscription.create
   - ✅ subscription.disable
   - ✅ invoice.update
5. **Copy Webhook Secret** and add to `.env` or Kubernetes Secrets

---

## 📊 **Monitoring & Alerts**

### **Paystack-Specific Metrics**

Add these metrics to your monitoring stack:

```python
# tiannara_api/metrics/paystack_metrics.py
from prometheus_client import Counter, Histogram, Gauge

# Payment metrics
payment_initiated = Counter(
    'paystack_payment_initiated_total',
    'Total payments initiated',
    ['plan']
)

payment_success = Counter(
    'paystack_payment_success_total',
    'Total successful payments',
    ['plan']
)

payment_failed = Counter(
    'paystack_payment_failed_total',
    'Total failed payments',
    ['plan', 'reason']
)

payment_latency = Histogram(
    'paystack_payment_latency_seconds',
    'Payment processing latency',
    ['plan']
)

webhook_received = Counter(
    'paystack_webhook_received_total',
    'Total webhooks received',
    ['event_type']
)

active_subscriptions = Gauge(
    'paystack_active_subscriptions',
    'Number of active subscriptions',
    ['plan']
)
```

### **Grafana Dashboard Panels**

Create dashboard panels for:

1. **Payment Success Rate**
   - Query: `rate(paystack_payment_success_total[5m]) / rate(paystack_payment_initiated_total[5m])`
   - Alert if < 95%

2. **Payment Latency (p95)**
   - Query: `histogram_quantile(0.95, rate(paystack_payment_latency_seconds_bucket[5m]))`
   - Alert if > 10s

3. **Failed Payments by Reason**
   - Query: `sum by (reason) (rate(paystack_payment_failed_total[1h]))`
   - Alert on spike in failures

4. **Active Subscriptions**
   - Query: `paystack_active_subscriptions`
   - Track growth over time

5. **Webhook Delivery Rate**
   - Query: `rate(paystack_webhook_received_total[5m])`
   - Alert if drops to 0

---

## 🔒 **Security Considerations**

### **Webhook Signature Verification**

Implement signature verification in your webhook handler:

```python
import hmac
import hashlib
from fastapi import HTTPException, Request

def verify_paystack_signature(payload: bytes, signature: str, secret: str) -> bool:
    """Verify Paystack webhook signature"""
    expected_signature = hmac.new(
        secret.encode('utf-8'),
        payload,
        hashlib.sha512
    ).hexdigest()
    
    return hmac.compare_digest(expected_signature, signature)

@router.post("/webhook")
async def paystack_webhook(request: Request):
    body = await request.body()
    signature = request.headers.get('x-paystack-signature')
    
    if not signature:
        raise HTTPException(status_code=401, detail="Missing signature")
    
    webhook_secret = os.getenv('PAYSTACK_WEBHOOK_SECRET')
    if not verify_paystack_signature(body, signature, webhook_secret):
        raise HTTPException(status_code=401, detail="Invalid signature")
    
    # Process webhook...
```

### **Network Security**

1. **Restrict Webhook Source IPs** (optional):
   ```nginx
   # Allow only Paystack IPs
   allow 52.31.139.75;
   allow 52.49.173.169;
   allow 52.214.14.220;
   deny all;
   ```

2. **Use HTTPS Only**: Ensure webhook endpoint is only accessible via HTTPS

3. **Rate Limiting**: Apply strict rate limiting to prevent abuse

---

## 🧪 **Testing Strategy**

### **Staging Environment Testing**

1. **Use Test Keys**:
   ```bash
   PAYSTACK_PUBLIC_KEY=pk_test_xxxxx
   PAYSTACK_SECRET_KEY=sk_test_xxxxx
   ```

2. **Test Cards**:
   ```
   Success: 4084 0840 8408 4081
   Failure: 4084 0840 8408 4082
   ```

3. **Test Scenarios**:
   - ✅ Successful subscription creation
   - ❌ Failed payment handling
   - 🔄 Subscription renewal
   - 🚫 Subscription cancellation
   - 📧 Webhook delivery and processing

### **Load Testing**

Simulate payment traffic:

```bash
# Using k6
k6 run scripts/payment-load-test.js \
  --vus 50 \
  --duration 10m \
  --tag test_type=payment_flow
```

Example test script:
```javascript
// scripts/payment-load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 50,
  duration: '10m',
};

export default function () {
  // Initialize payment
  const initRes = http.post('https://api-staging.tiannara.com/api/v1/billing/initialize-payment', 
    JSON.stringify({ plan: 'starter' }),
    { headers: { 'Content-Type': 'application/json' } }
  );
  
  check(initRes, {
    'payment initialized': (r) => r.status === 200,
  });
  
  sleep(1);
}
```

---

## 📋 **Deployment Checklist**

### **Pre-Deployment:**

- [ ] Create Paystack business account
- [ ] Complete KYC verification
- [ ] Get live API keys
- [ ] Create pricing plans in Paystack dashboard
- [ ] Configure webhook URL in Paystack dashboard
- [ ] Copy webhook secret
- [ ] Test with test keys in staging
- [ ] Verify webhook signature implementation
- [ ] Set up monitoring alerts

### **Deployment:**

- [ ] Add Paystack credentials to Kubernetes Secrets
- [ ] Update API deployment with Paystack env vars
- [ ] Deploy updated API service
- [ ] Verify webhook endpoint is accessible
- [ ] Test webhook delivery from Paystack dashboard
- [ ] Monitor initial transactions
- [ ] Verify subscription activation works

### **Post-Deployment:**

- [ ] Monitor payment success rate
- [ ] Check webhook delivery logs
- [ ] Verify subscription database updates
- [ ] Test customer portal access
- [ ] Review error logs for payment issues
- [ ] Set up automated backup of payment records
- [ ] Configure dunning management settings

---

## 🚨 **Troubleshooting**

### **Common Issues:**

#### **1. Webhook Not Received**

**Symptoms**: Payments succeed but subscriptions not activated

**Check**:
```bash
# Check Nginx logs
kubectl logs -n tiannara-production deployment/nginx | grep webhook

# Check API logs
kubectl logs -n tiannara-production deployment/tiannara-api | grep paystack

# Verify webhook URL in Paystack dashboard
curl -X POST https://api.tiannara.com/api/v1/billing/webhook \
  -H "Content-Type: application/json" \
  -d '{"test": true}'
```

**Solutions**:
- Verify webhook URL is correct in Paystack dashboard
- Check firewall/Nginx allows POST requests to webhook endpoint
- Ensure webhook secret matches between Paystack and `.env`

#### **2. Signature Verification Fails**

**Symptoms**: 401 errors on webhook endpoint

**Check**:
```python
# Debug signature verification
print(f"Received signature: {signature}")
print(f"Expected signature: {expected_signature}")
print(f"Webhook secret: {webhook_secret[:10]}...")
```

**Solutions**:
- Verify webhook secret is correctly set in environment
- Ensure you're using the raw request body (not parsed JSON)
- Check encoding (should be UTF-8)

#### **3. Payment Initialization Fails**

**Symptoms**: 500 errors when creating payment

**Check**:
```bash
# Check API logs
kubectl logs -n tiannara-production deployment/tiannara-api | grep "initialize"

# Verify API keys
echo $PAYSTACK_SECRET_KEY | wc -c  # Should be ~40 chars
```

**Solutions**:
- Verify PAYSTACK_SECRET_KEY is set correctly
- Check network connectivity to Paystack API
- Verify plan codes exist in Paystack dashboard

---

## 📈 **Performance Optimization**

### **Caching Strategy**

Cache Paystack customer data to reduce API calls:

```python
from redis import Redis
import json

redis = Redis.from_url(os.getenv('REDIS_URL'))

def get_or_create_customer(email: str, name: str):
    """Get customer from cache or create in Paystack"""
    cache_key = f"paystack:customer:{email}"
    
    # Try cache first
    cached = redis.get(cache_key)
    if cached:
        return json.loads(cached)
    
    # Create in Paystack
    customer = paystack.create_customer(email=email, first_name=name)
    
    # Cache for 24 hours
    redis.setex(cache_key, 86400, json.dumps(customer))
    
    return customer
```

### **Async Processing**

Process webhooks asynchronously to avoid timeouts:

```python
from celery import Celery

celery_app = Celery('tasks', broker=os.getenv('REDIS_URL'))

@celery_app.task
def process_webhook_async(event_data: dict):
    """Process webhook in background"""
    # Activate subscription
    # Send confirmation email
    # Update analytics
    pass

@router.post("/webhook")
async def paystack_webhook(request: Request):
    # Quick signature verification
    # Acknowledge immediately
    # Queue for async processing
    process_webhook_async.delay(event_data)
    return {'status': 'received'}
```

---

## 📞 **Support Resources**

### **Paystack Support:**
- **Documentation**: https://paystack.com/docs
- **API Reference**: https://paystack.com/docs/api
- **Status Page**: https://status.paystack.com
- **Support Email**: support@paystack.com
- **Developer Community**: Available upon request

### **Internal Contacts:**
- **DevOps Lead**: [Contact Info]
- **Backend Lead**: [Contact Info]
- **On-Call Engineer**: PagerDuty rotation

---

## 🎯 **Next Steps**

1. **Immediate**:
   - [ ] Add Paystack credentials to production secrets
   - [ ] Configure webhook endpoint in Paystack dashboard
   - [ ] Test webhook delivery

2. **Short-term**:
   - [ ] Implement monitoring dashboards
   - [ ] Set up alert rules
   - [ ] Load test payment flow

3. **Long-term**:
   - [ ] Implement retry logic for failed webhooks
   - [ ] Add payment analytics to admin dashboard
   - [ ] Optimize caching strategy

---

**Status**: ✅ **Configuration Documented** | ⏳ **Ready for Implementation**
