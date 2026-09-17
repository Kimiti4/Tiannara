# Tiannara API - Deployment Guide

## Quick Start: Deploy in 15 Minutes

This guide shows how to deploy Tiannara API to cloud platforms. Choose one:

1. **Render** (Easiest, Free Tier) ⭐ RECOMMENDED
2. **Railway** (Simple, $5/month)
3. **Heroku** (Classic, $7/month)
4. **AWS/GCP/Azure** (Enterprise, Complex)

---

## Option 1: Render (Recommended)

### Why Render?
- ✅ Free tier available
- ✅ Auto-deploy from GitHub
- ✅ Zero configuration needed
- ✅ Automatic HTTPS
- ✅ Built-in database support

### Deployment Steps

#### 1. Prepare Repository

Ensure your repo has these files:

**`requirements.txt`**:
```
fastapi==0.104.1
uvicorn==0.24.0
stripe==7.5.0
numpy==1.26.0
# Add all dependencies from tiannara_core
```

**`Procfile`** (for web process):
```
web: uvicorn tiannara_api.main:app --host 0.0.0.0 --port $PORT
```

**`.renderignore`**:
```
__pycache__/
*.pyc
.env
runs/
node_modules/
```

---

#### 2. Create Render Account

1. Go to [render.com](https://render.com)
2. Sign up with GitHub
3. Authorize GitHub access

---

#### 3. Create Web Service

1. Click "New +" → "Web Service"
2. Connect your GitHub repository
3. Configure:
   - **Name**: `tiannara-api`
   - **Region**: Choose closest to users
   - **Branch**: `main`
   - **Root Directory**: Leave blank
   - **Runtime**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn tiannara_api.main:app --host 0.0.0.0 --port $PORT`

4. Click "Advanced" and add environment variables:
   ```
   STRIPE_SECRET_KEY=sk_test_YOUR_KEY
   STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_KEY
   DATABASE_URL=postgresql://...
   ```

5. Click "Create Web Service"

**Time**: 5 minutes  
**Cost**: Free (750 hours/month), then $7/month

---

#### 4. Wait for Deployment

Render will:
1. Clone your repo
2. Install dependencies
3. Build the app
4. Start the server

You'll see logs in real-time.

---

#### 5. Get Your API URL

Once deployed, you'll get a URL like:
```
https://tiannara-api.onrender.com
```

Test it:
```bash
curl https://tiannara-api.onrender.com/api/v1/status
```

---

#### 6. Set Up Custom Domain (Optional)

1. Go to Settings → Domains
2. Add your domain (e.g., `api.tiannara.ai`)
3. Update DNS records as instructed
4. Wait for SSL certificate (automatic)

---

## Option 2: Railway

### Why Railway?
- ✅ Simple deployment
- ✅ $5 credit/month free
- ✅ Automatic scaling
- ✅ Great dashboard

### Deployment Steps

#### 1. Create Railway Account

1. Go to [railway.app](https://railway.app)
2. Sign up with GitHub
3. Install Railway CLI (optional):
   ```bash
   npm i -g @railway/cli
   ```

---

#### 2. Deploy from GitHub

1. Click "New Project"
2. Select "Deploy from GitHub repo"
3. Choose your repository
4. Railway auto-detects Python app

---

#### 3. Configure Environment

1. Go to Variables tab
2. Add environment variables:
   ```
   PORT=8000
   STRIPE_SECRET_KEY=sk_test_YOUR_KEY
   ```

---

#### 4. Deploy

Railway automatically builds and deploys.

Get your URL from "Settings" → "Domains":
```
https://tiannara-api.railway.app
```

**Cost**: $5 credit free, then usage-based (~$5-10/month)

---

## Option 3: Heroku

### Why Heroku?
- ✅ Mature platform
- ✅ Large ecosystem
- ❌ No longer free tier
- ❌ More expensive

### Deployment Steps

#### 1. Install Heroku CLI

```bash
# macOS
brew tap heroku/brew && brew install heroku

# Windows
# Download from https://devcenter.heroku.com/articles/heroku-cli
```

---

#### 2. Login and Create App

```bash
heroku login
heroku create tiannara-api
```

---

#### 3. Set Config Vars

```bash
heroku config:set STRIPE_SECRET_KEY=sk_test_YOUR_KEY
heroku config:set STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_KEY
```

---

#### 4. Deploy

```bash
git push heroku main
```

---

#### 5. Open App

```bash
heroku open
```

**Cost**: $7/month (Hobby dyno) + usage

---

## Option 4: AWS/GCP/Azure (Enterprise)

For production at scale, use cloud providers. This requires more setup but offers:
- Better performance
- More control
- Enterprise features
- Compliance certifications

See separate guides for each provider.

---

## Post-Deployment Checklist

### 1. Test API Endpoints

```bash
# Health check
curl https://your-api-url.com/api/v1/status

# Test reasoning endpoint
curl -X POST https://your-api-url.com/api/v1/reason \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "reverse_engineering",
    "task": {...}
  }'
```

---

### 2. Set Up Monitoring

**Option A: Render/Railway Built-in**
- View logs in dashboard
- Monitor CPU/memory usage
- Set up alerts

**Option B: Sentry (Error Tracking)**
```bash
pip install sentry-sdk
```

Add to `tiannara_api/main.py`:
```python
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration

sentry_sdk.init(
    dsn="YOUR_SENTRY_DSN",
    integrations=[FastApiIntegration()],
    traces_sample_rate=1.0
)
```

**Option C: Datadog/New Relic**
- Full observability
- Custom dashboards
- Advanced alerting

---

### 3. Enable Rate Limiting

Add to `tiannara_api/main.py`:

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@app.post("/api/v1/reason")
@limiter.limit("10/minute")  # Adjust per tier
async def reason(request: Request):
    ...
```

Install:
```bash
pip install slowapi
```

---

### 4. Set Up Database (If Needed)

For user management, API keys, etc.

**Render PostgreSQL**:
1. New+ → PostgreSQL
2. Link to your web service
3. Use provided DATABASE_URL

**Railway PostgreSQL**:
1. New → Database → PostgreSQL
2. Copy connection string
3. Add to environment variables

---

### 5. Configure CORS

Update `tiannara_api/main.py`:

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://your-frontend.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

### 6. Add API Key Authentication

Create `tiannara_api/auth.py`:

```python
from fastapi import Depends, HTTPException, Header

VALID_API_KEYS = {
    "test_key_123": {"tier": "developer", "user_id": "user_1"},
    # Load from database in production
}

def verify_api_key(x_api_key: str = Header(...)):
    if x_api_key not in VALID_API_KEYS:
        raise HTTPException(status_code=401, detail="Invalid API key")
    return VALID_API_KEYS[x_api_key]
```

Use in routes:
```python
@app.post("/api/v1/reason")
async def reason(user: dict = Depends(verify_api_key)):
    # user contains tier and user_id
    ...
```

---

## Cost Comparison

| Platform | Free Tier | Paid Starting | Best For |
|----------|-----------|---------------|----------|
| Render | 750 hrs/mo | $7/month | Startups, MVPs |
| Railway | $5 credit | ~$5/month | Developers |
| Heroku | None | $7/month | Legacy apps |
| AWS | 12 months free | Variable | Enterprise |
| GCP | $300 credit | Variable | Enterprise |

**Recommendation**: Start with Render (free), upgrade as you grow.

---

## Scaling Considerations

### When to Upgrade:
- >100 requests/minute consistently
- Need 99.9% uptime SLA
- Require custom domains
- Need dedicated resources

### Upgrade Path:
1. **Render**: Free → Starter ($7) → Pro ($25+)
2. **Railway**: Free credit → Usage-based
3. **AWS**: EC2 → ECS → EKS (Kubernetes)

---

## Security Best Practices

1. ✅ Use environment variables for secrets
2. ✅ Enable HTTPS (automatic on Render/Railway)
3. ✅ Implement rate limiting
4. ✅ Validate all inputs
5. ✅ Use API key authentication
6. ✅ Set up CORS properly
7. ✅ Monitor for suspicious activity
8. ✅ Regular security updates

---

## Troubleshooting

### Issue: Build Fails
**Solution**: Check build logs, ensure `requirements.txt` is complete

### Issue: App Crashes on Start
**Solution**: Check runtime logs, verify start command

### Issue: Slow Response Times
**Solution**: Upgrade plan, optimize code, add caching

### Issue: Database Connection Errors
**Solution**: Verify DATABASE_URL, check network settings

---

## Next Steps

1. ✅ Choose deployment platform
2. ✅ Deploy API
3. ✅ Test endpoints
4. ✅ Set up monitoring
5. ✅ Configure authentication
6. ✅ Add rate limiting
7. ✅ Launch to users!

**Total Time**: 15-30 minutes  
**Cost**: $0-7/month to start

---

**Ready to deploy?** Follow Render steps above for fastest launch! 🚀
