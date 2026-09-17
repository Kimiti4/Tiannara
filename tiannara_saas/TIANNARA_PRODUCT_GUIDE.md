# Tiannara SaaS - Complete Product Guide

## 🚀 Overview

**Tiannara SaaS** is an intelligent automation platform that helps businesses build, deploy, and scale AI-powered workflows without needing to build AI infrastructure from scratch. Think of it as your team's AI assistant that can analyze data, make predictions, automate repetitive tasks, and provide actionable insights—all through a simple dashboard or API.

Whether you're a solo developer building your first MVP, a growing startup scaling your operations, or an enterprise managing mission-critical systems, Tiannara adapts to your needs with three flexible subscription tiers.

---

## 📊 Quick Comparison

| Feature | Starter ($49/mo) | Professional ($199/mo) | Enterprise ($999+/mo) |
|---------|------------------|------------------------|---------------------|
| **Best For** | Individuals & small projects | Growing teams & production apps | Large organizations & compliance |
| **API Requests** | 5,000/month | 50,000/month | Unlimited |
| **AI Workflows** | ✅ Core workflows | ✅ Advanced orchestration | ✅ Custom deployment |
| **Analytics** | Basic dashboards | Real-time + custom | Enterprise-grade |
| **Team Features** | ❌ Single user | ✅ Up to 10 members | ✅ Unlimited members |
| **Support** | Email (48hr) | Priority (24hr) | 24/7 Dedicated |
| **Integrations** | Manual setup | Webhooks + APIs | Custom integrations |
| **Compliance** | ❌ | ❌ | ✅ Full suite |
| **Deployment** | Cloud only | Cloud only | Private/On-premise |

---

# 🎯 Tier 1: Starter — $49/month

### **Perfect for:** Solo developers, researchers, students, and small projects exploring AI automation

---

## 💡 What You Get

### **Core Capabilities**

#### 1. **Build AI Workflows Without Coding AI Systems**
Instead of spending months building machine learning models and AI pipelines, you get pre-built intelligent workflows ready to use.

**Real-World Example:**
> *Sarah runs a small e-commerce store. She wants to understand which customers are most likely to buy again. Instead of hiring a data scientist, she uses Tiannara's "Customer Segmentation" workflow. She uploads her customer data, and within minutes, Tiannara identifies her top 20% high-value customers automatically.*

**What This Means for You:**
- No need to learn TensorFlow, PyTorch, or complex ML frameworks
- Drag-and-drop workflow builder (or use pre-built templates)
- Get results in minutes, not weeks

---

#### 2. **Automate Repetitive Analysis Tasks**
Stop manually analyzing spreadsheets, reports, and data. Tiannara does the heavy lifting.

**Real-World Example:**
> *Mike is a marketing consultant. Every week, he spends 6 hours analyzing social media sentiment for his clients. With Tiannara, he sets up an automated workflow that pulls data from Twitter, Facebook, and Instagram, analyzes sentiment, and generates a report. Now it takes 10 minutes instead of 6 hours.*

**What This Means for You:**
- Save 10+ hours per week on manual analysis
- Consistent, error-free results every time
- Set it once, run it forever

---

#### 3. **Get Explainable AI Insights**
Unlike black-box AI systems, Tiannara shows you WHY it made certain decisions.

**Real-World Example:**
> *Lisa's startup built a loan approval system. When a loan application is rejected, Tiannara doesn't just say "Denied." It explains: "Rejected because debt-to-income ratio exceeds 40% AND credit score below 650. If credit score improves to 700, approval probability increases to 85%."*

**What This Means for You:**
- Understand AI decisions (critical for regulated industries)
- Build trust with customers and stakeholders
- Debug and improve your workflows easily

---

#### 4. **Basic Analytics Dashboard**
See how your workflows are performing at a glance.

**Includes:**
- Total API requests used this month
- Workflow success rate
- Average response time
- Error tracking
- Usage trends over time

---

### **Technical Specifications**

| Specification | Details |
|---------------|---------|
| **API Requests** | 5,000 per month (~166 per day) |
| **Workspaces** | 1 workspace |
| **API Keys** | 1 key |
| **Data Retention** | 30 days |
| **Max Workflow Complexity** | 20 nodes per workflow |
| **Response Time** | Standard priority (1-3 seconds avg) |
| **Uptime SLA** | Best effort (no guarantee) |

---

## 🛠️ How to Integrate (Step-by-Step)

### **For Developers: API Integration**

**Step 1: Get Your API Key**
1. Sign up at tiannara.com
2. Go to Dashboard → Settings → API Keys
3. Click "Generate New Key"
4. Copy your key (starts with `tk_...`)

**Step 2: Install SDK (Optional)**
```bash
# Python
pip install tiannara-sdk

# JavaScript
npm install @tiannara/sdk
```

**Step 3: Make Your First API Call**

**Python Example:**
```python
from tiannara import TiannaraClient

client = TiannaraClient(api_key="tk_your_key_here")

# Run a customer segmentation workflow
result = client.run_workflow(
    workflow_id="customer_segmentation_v1",
    data={
        "customers": [
            {"id": 1, "total_spent": 1500, "last_purchase": "2024-01-15"},
            {"id": 2, "total_spent": 200, "last_purchase": "2023-06-20"}
        ]
    }
)

print(result.segments)
# Output: {
#   "high_value": [{"id": 1, "score": 0.92}],
#   "at_risk": [{"id": 2, "score": 0.78}]
# }
```

**JavaScript Example:**
```javascript
const { TiannaraClient } = require('@tiannara/sdk');

const client = new TiannaraClient({ apiKey: 'tk_your_key_here' });

// Analyze sentiment from customer reviews
const result = await client.runWorkflow({
  workflowId: 'sentiment_analysis',
  data: {
    reviews: [
      "Great product, fast shipping!",
      "Terrible customer service, very disappointed"
    ]
  }
});

console.log(result.sentiments);
```

---

### **For Non-Developers: No-Code Integration**

**Step 1: Use Pre-Built Templates**
1. Log into your Tiannara dashboard
2. Go to Workflows → Templates
3. Choose a template (e.g., "Email Sentiment Analyzer")
4. Click "Use Template"

**Step 2: Connect Your Data Sources**
1. Click "Connect Data Source"
2. Choose from: Upload CSV, Google Sheets, Dropbox, Manual input
3. Map your columns to workflow inputs

**Step 3: Configure & Run**
1. Adjust settings (optional)
2. Click "Test Run" to verify
3. Click "Activate" to run on schedule

---

**Projected Benefits for Starter Users**

### **Time Savings (Projected)**
- **Before:** 10 hours/week on manual data analysis
- **After:** 30 minutes/week with automated workflows (based on pilot architecture)
- **Projected Savings:** 9.5 hours/week = **$19,000/year** (projected ROI at $40/hr)

### **Cost Avoidance (Projected)**
- **Hire Data Scientist:** $120,000/year salary
- **Build AI Infrastructure:** $50,000 one-time + $5,000/month cloud costs
- **Tiannara Starter:** $588/year
- **Projected First-Year Savings:** **$175,000+** (projected ROI)

### **Speed to Market (Target)**
- **Traditional approach:** 3-6 months to build AI features
- **With Tiannara:** 1-2 days to deploy working prototypes (prototype validation)
- **Target Advantage:** Launch 50x faster

---

## 🎬 Demo Scenarios

### **Demo 1: E-Commerce Customer Segmentation**

**Scenario:** Online store owner wants to identify VIP customers for special promotions.

**Steps:**
1. Upload customer database (CSV with purchase history)
2. Select "Customer Segmentation" workflow
3. Run analysis (takes 30 seconds)
4. View results:
   - **VIP Customers (top 10%):** 150 customers, avg spend $2,500
   - **Regular Customers (middle 60%):** 900 customers, avg spend $400
   - **At-Risk Customers (bottom 30%):** 450 customers, haven't purchased in 6+ months

**Action Taken:**
- Send exclusive 20% discount to VIP customers
- Create re-engagement campaign for at-risk customers
- Result: 35% increase in repeat purchases

---

### **Demo 2: Social Media Sentiment Monitoring**

**Scenario:** Marketing agency monitors brand sentiment across platforms.

**Results:**
- Today's mentions: 247
- Positive: 68% (↑ 5% from yesterday)
- Negative: 12% (↓ 3% from yesterday)
- Top complaint: "Shipping delays" (mentioned 45 times)

**Action Taken:**
- Alert logistics team about shipping complaints
- Respond to negative mentions within 1 hour
- Result: Improved customer satisfaction from 3.8 to 4.5 stars

---

### **Demo 3: Document Classification**

**Scenario:** Law firm needs to organize thousands of legal documents.

**Results:**
- Processed 5,000 PDFs in 15 minutes
- Auto-sorted into: Contracts (1,200), Invoices (800), Court Filings (2,100), Correspondence (750)
- Flagged contracts expiring within 90 days
- Result: 40 hours saved on manual filing, zero misfiled documents

---

# ⚡ Tier 2: Professional — $199/month

### **Perfect for:** Growing startups, SaaS companies, analytics platforms, and teams deploying AI in production

---

## 💡 What You Get (Everything in Starter, Plus:)

### **Advanced Capabilities**

#### 1. **10x More API Capacity (50,000 requests/month)**
Handle production workloads without worrying about limits.

**Real-World Example:**
> *TechStartup Inc. has 5,000 active users. Each user triggers 2-3 AI analyses per day. That's 10,000-15,000 API calls daily. Starter tier (5,000/month) would hit limits in 12 hours. Professional tier handles it comfortably with room to grow.*

---

#### 2. **Team Collaboration (Up to 10 Members)**
Work together with role-based access control.

**Features:**
- Invite team members (Admin, Member, Viewer roles)
- Shared workspaces and workflows
- Activity feed showing who did what
- Collaborative workflow building
- Centralized billing

---

#### 3. **Real-Time Analytics Dashboard**
Monitor your AI systems live with customizable dashboards.

**Includes:**
- Live request volume (updates every 5 seconds)
- Real-time error rate tracking
- Custom metric widgets
- Automated alerts (email/Slack/webhook)
- Historical trend analysis (up to 1 year)
- Export data to CSV/JSON

---

#### 4. **Webhooks & Integrations**
Connect Tiannara to your existing tools automatically.

**Supported Integrations:**
- **Communication:** Slack, Microsoft Teams, Discord
- **Project Management:** Jira, Asana, Trello
- **CRM:** Salesforce, HubSpot, Pipedrive
- **Databases:** PostgreSQL, MySQL, MongoDB
- **Cloud Storage:** AWS S3, Google Cloud Storage, Azure Blob
- **Custom:** Any HTTP endpoint

---

#### 5. **Priority Processing & Faster Response Times**
Your requests get priority in the queue.

**Performance Comparison:**
| Metric | Starter | Professional |
|--------|---------|--------------|
| Avg Response Time | 1-3 seconds | 200-800ms |
| Peak Hour Performance | May slow down | Consistent speed |
| Queue Priority | Standard | High priority |

---

#### 6. **Advanced Monitoring & Alerts**
Proactive monitoring prevents downtime.

**Alert Types:**
- Error Rate Spike
- Quota Warning (80%, 90%, 100%)
- Latency Increase
- Workflow Failure
- Anomaly Detection

**Delivery Methods:** Email, Slack, SMS, PagerDuty

---

#### 7. **99.5% Uptime SLA**
Guaranteed reliability for production systems.

**SLA Details:**
- **Uptime Guarantee:** 99.5% monthly (max 3.6 hours downtime/month)
- **Credits if SLA Missed:** 10-50% based on severity
- **Status Page:** status.tiannara.com

---

#### 8. **Priority Email Support (24-Hour Response)**
Get help when you need it.

**Support Includes:**
- Technical questions about API/workflows
- Debugging assistance
- Best practices guidance
- Feature requests consideration

---

### **Technical Specifications**

| Specification | Details |
|---------------|---------||
| **API Requests** | 50,000 per month (~1,666 per day) |
| **Workspaces** | Up to 5 workspaces |
| **API Keys** | 5 keys |
| **Team Members** | Up to 10 members |
| **Data Retention** | 90 days |
| **Max Workflow Complexity** | 100 nodes per workflow |
| **Response Time** | Priority (200-800ms avg) |
| **Uptime SLA** | 99.5% guaranteed |
| **Webhooks** | Unlimited |

---

## 🛠️ Production Integration Example

**Scenario:** SaaS company predicts customer churn and triggers retention campaigns.

**Workflow:**
```
Input: Customer activity data (last 30 days)
    ↓
Feature Engineering: Login frequency, usage depth, support tickets
    ↓
ML Model: Churn prediction (Random Forest)
    ↓
Output: Churn probability (0-100%)
    ↓
Decision Logic:
  - If > 80%: High risk → Trigger immediate intervention
  - If 50-80%: Medium risk → Add to watchlist
  - If < 50%: Low risk → No action
```

**Integration:**
1. Schedule workflow to run daily at 6 AM
2. Configure webhooks to send results to CRM
3. Set up monitoring dashboard with alerts
4. Integrate with email service for automated retention offers

**Demonstration Results:**
- **Before:** Manual churn analysis monthly, 15% churn rate (baseline)
- **After:** Daily automated predictions, proactive interventions, target 8% churn rate (projected improvement)
- **Projected Impact:** Retain 70 additional customers/year × $500 ARR = **$35,000 projected annual revenue** (projected ROI)

---

## 📈 Benefits for Professional Users

### **Projected ROI Calculation**

**For a SaaS Company with 1,000 Customers (Simulated Benchmark):**

**Without Tiannara (Baseline):**
- Hire 2 data analysts: $160,000/year
- Build custom ML infrastructure: $80,000 one-time + $8,000/month
- Manual analysis: $12,000/year
- **Total Year 1 Baseline Cost:** $348,000

**With Tiannara Professional (Projected):**
- Subscription: $2,388/year
- Integration time: $3,000 one-time
- Ongoing maintenance: $1,200/year
- **Total Year 1 Projected Cost:** $6,588

**Projected First-Year Savings:** **$341,412** (98% projected cost reduction)

**Plus Projected Revenue Impact:**
- Reduced churn = 70 retained customers × $500 ARR = **$35,000 projected additional revenue**
- **Total Projected Net Benefit:** $376,412 (projected ROI)

---

## 🎬 Demo Scenarios

### **Demo 1: Real-Time Fraud Detection**

**Scenario:** Payment processor detects fraudulent transactions instantly.

**Live Demo:**
```
Transaction: $2,500 purchase, new device, foreign IP
    ↓ (200ms processing)
Tiannara analysis:
  - Device fingerprint: Unknown
  - Location mismatch: Yes (US card, Nigerian IP)
  - Velocity check: 5 transactions in 10 minutes
  - Amount anomaly: 10x customer average
    ↓
Result: Fraud probability 94%
    ↓
Action: Block transaction, alert fraud team via Slack
```

**Demonstration Results:**
- **Detection rate:** 97% of fraudulent transactions caught (simulated benchmark)
- **False positive rate:** 1.8% (below 3% threshold in pilot testing)
- **Avg response time:** 245ms (target SLA: < 500ms)
- **Projected fraud loss prevention:** $450,000/year (based on pilot architecture)

---

### **Demo 2: Predictive Inventory Management**

**Scenario:** Retail chain optimizes stock levels across 50 stores.

**Pilot Validation Results:**
- **Forecast accuracy:** 92% (vs. 75% with previous system in prototype validation)
- **Stockout reduction:** From 12% to 2% of SKUs (demonstration results)
- **Waste reduction:** 35% less overstock (simulated benchmark)
- **Projected annual savings:** $280,000 in inventory optimization (projected ROI)

---

### **Demo 3: Customer Support Automation**

**Scenario:** SaaS company automates support ticket routing.

**Prototype Validation Results:**
- **Auto-categorization accuracy:** 94% (simulated benchmark)
- **Target response time:** Reduced from 4 hours to 45 minutes (designed for high-volume support)
- **Projected agent efficiency:** 40% more tickets handled per day (projected ROI)
- **Target customer satisfaction:** Increase from 3.9 to 4.6 stars (pilot architecture goal)

---
