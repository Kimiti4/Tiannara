# Enhanced Workflow Templates System

**Date:** May 1, 2026  
**Status:** ✅ COMPLETE  
**Based on:** templates.md (comprehensive guide)

---

## 🎯 Overview

The workflow templates system has been significantly enhanced following the architecture outlined in `templates.md`. Templates are now **orchestration blueprints** that connect Tiannara Core's intelligence domains to solve specific business problems.

### Key Architectural Principles (from templates.md):

1. **Templates are NOT the intelligence** - They define orchestration, UI schemas, and automation logic
2. **Tiannara Core is the intelligence runtime** - Provides reasoning, hypothesis generation, analysis, optimization
3. **Multi-domain integration** - Templates combine multiple Core domains (prediction, causal, RE, NLP, temporal, memory)
4. **Explainable AI** - All predictions include reasoning traces, confidence scores, and causal factors
5. **Multi-hypothesis approach** - Instead of binary outputs, templates generate multiple hypotheses with probabilities

---

## 📊 Template Categories (6 Major Categories)

Following templates.md Section "Template Categories", we've organized templates into:

### 1. 📊 Analytics Templates
- Customer Segmentation Analysis
- Marketing Campaign Insights
- Business KPI Monitoring
- User Behavior Intelligence

**Use Cases:** Easy to adopt, immediate business value, broad appeal

---

### 2. 🛡️ Security & Fraud Templates
- Fraud Detection Pipeline
- Anomaly Detection
- Threat Intelligence
- Suspicious Activity Scoring

**Features:**
- Uncertainty scoring
- Multi-hypothesis analysis
- Explainability traces
- Real-time alerts

**Monetization:** Strong business ROI, enterprise appeal

---

### 3. 🔮 Prediction Templates ⭐ NEW (Major Addition)

Following templates.md Section 5: "Prediction Templates - Huge monetization potential"

#### Added 5 New Prediction Templates:

##### a) **Football Match Prediction Engine** (`sports_prediction`)
- **Tier:** Professional
- **Domains:** prediction_domain, temporal_engine, reverse_engineering, causal_engine
- **Outputs:** match_outcome_probabilities, score_predictions, confidence_scores, reasoning_traces
- **Dashboard Widgets:** prediction_accuracy, confidence_distribution, historical_performance, multi_hypothesis_view
- **Automation Rules:** auto_update_before_match, alert_on_high_confidence, log_predictions_for_learning
- **Key Feature:** Multi-hypothesis analysis with explainable reasoning traces

##### b) **Demand Forecasting System** (`demand_forecasting`)
- **Tier:** Starter
- **Domains:** prediction_domain, temporal_engine, nlp_engine
- **Outputs:** demand_forecasts, seasonal_patterns, trend_analysis, confidence_intervals
- **Dashboard Widgets:** forecast_chart, seasonality_view, trend_indicators, error_metrics
- **Automation Rules:** weekly_retrain, alert_on_drift, update_inventory_recommendations
- **Key Feature:** Seasonal adjustments with external factor integration

##### c) **Risk Assessment & Prediction** (`risk_prediction`)
- **Tier:** Professional
- **Domains:** prediction_domain, causal_engine, reverse_engineering, memory_system
- **Outputs:** risk_scores, risk_factors, mitigation_recommendations, confidence_levels
- **Dashboard Widgets:** risk_distribution, factor_importance, trend_over_time, alerts
- **Automation Rules:** continuous_monitoring, alert_on_threshold, escalate_high_risk
- **Key Feature:** Causal risk factor identification with historical memory

##### d) **Market Trend Forecasting** (`trend_forecasting`)
- **Tier:** Enterprise
- **Domains:** prediction_domain, nlp_engine, temporal_engine, causal_engine, reverse_engineering
- **Outputs:** trend_predictions, confidence_scores, supporting_evidence, impact_assessment
- **Dashboard Widgets:** trend_timeline, confidence_heatmap, evidence_graph, impact_matrix
- **Automation Rules:** daily_trend_scan, alert_on_emerging_trends, weekly_report_generation
- **Key Feature:** Multi-domain intelligence combining NLP, temporal, and causal reasoning

##### e) **Customer Churn Prediction** (`churn_prediction`)
- **Tier:** Starter
- **Domains:** prediction_domain, reverse_engineering, causal_engine, memory_system
- **Outputs:** churn_probabilities, risk_factors, retention_strategies, customer_segments
- **Dashboard Widgets:** churn_risk_distribution, key_factors, segment_analysis, retention_roi
- **Automation Rules:** weekly_churn_scan, alert_high_risk_customers, trigger_retention_campaigns
- **Key Feature:** Personalized retention strategy generation

---

### 4. 🔬 Research & Discovery Templates
- Root Cause Investigation
- Historical Reconstruction (future)
- Scientific Hypothesis Generation (future)
- Causal Inference Pipelines (future)

**Unique Value:** This is where Tiannara becomes unique - very few SaaS products can do this

---

### 5. ⚙️ Automation Templates
- Business Health Monitor
- Support Ticket Triage (future)
- Workflow Orchestration (future)
- Report Generation (future)

**Appeal:** Most businesses want automation first

---

### 6. 🏢 Organization Templates (Future)
- Executive Intelligence Dashboard
- Multi-team Analytics
- Operations Command Center
- Compliance Monitoring

**Enterprise Focus:** Teams love structured organizational tools

---

## 🏗️ Template Architecture (Enhanced)

Each template now includes comprehensive metadata:

```typescript
interface WorkflowTemplate {
  id: string
  name: string
  description: string
  category: 'analytics' | 'fraud' | 'research' | 'automation' | 'prediction' | 'organization'
  difficulty: 'beginner' | 'intermediate' | 'advanced'
  estimatedTime: string
  
  // NEW: Template metadata from templates.md
  tierRequired?: 'starter' | 'professional' | 'enterprise'
  domainsUsed?: string[]           // Required Tiannara Core domains
  outputs?: string[]               // Expected outputs
  dashboardWidgets?: string[]      // Auto-generated dashboard components
  automationRules?: string[]       // Built-in automation triggers
  
  nodes: WorkflowNode[]
  edges: WorkflowEdge[]
  tags: string[]
  recommendedFor: 'starter' | 'professional' | 'enterprise'
  icon: string
  color: string
}
```

---

## 🔥 How Templates Work (Runtime Flow)

From templates.md "What Happens When User Uses a Template":

```
User selects template (e.g., "Fraud Detection")
         ↓
Template sends orchestration config to Core:
{
  "workflow": "fraud_detection",
  "domains": ["causal", "reverse_engineering", "temporal"],
  "inputs": { "transactions": [...] }
}
         ↓
Tiannara Core Workflow Engine:
  - Loads template definition
  - Validates dependencies
  - Calls required domains
  - Orchestrates execution
  - Collects outputs
  - Generates reasoning traces
         ↓
Core returns intelligent output:
{
  "hypotheses": [
    { "type": "account_takeover", "confidence": 0.81 },
    { "type": "synthetic_identity", "confidence": 0.62 }
  ],
  "decision_trace": [...],
  "causal_factors": [...],
  "uncertainties": [...],
  "recommended_actions": [...]
}
         ↓
SaaS Dashboard visualizes results
```

**Key Point:** Templates NEVER directly call domains. Everything goes through the Workflow Engine for future flexibility.

---

## 💰 Monetization Strategy (from templates.md)

### Base SaaS Pricing
- Starter: $49/month
- Professional: $199/month
- Enterprise: $999/month

### Add-On Packs (Future)
```
Fraud Detection Pack → +$39/month
Prediction Engine → +$79/month
Research Discovery Pack → +$149/month
Compliance Pack → +$199/month
```

### Tier-Based Template Access
- **Starter:** Basic analytics, simple predictions, monitoring
- **Professional:** Advanced fraud detection, sports prediction, risk assessment
- **Enterprise:** Market trend forecasting, multi-domain research, custom templates

---

## 🧠 Long-Term Vision (from templates.md)

Eventually Tiannara becomes:

```
Core AI Infrastructure
        +
Workflow Marketplace
        +
Domain Intelligence Packs
        +
Autonomous Optimization
```

This is much more defensible than "just another AI SaaS."

### Self-Improving Workflows (Future)

Templates become smarter over time because **Core learns**, not because frontend changes.

**Example:**
- Month 1: Fraud template uses standard detection
- Month 6: Core learned better patterns, reduced false positives
- Result: ALL users improve automatically → **compounding intelligence infrastructure**

---

## 🖥️ Frontend Enhancements

### Updated Template Card Display

Each template card now shows:

1. **Tier Badge** - Visual indicator of required subscription tier
2. **Core Domains** - Lists which Tiannara Core domains are used
3. **Tags** - Quick filtering by use case
4. **Setup Time** - Estimated deployment time
5. **Node Count** - Complexity indicator
6. **Outputs** - What the template produces
7. **Recommended For** - Target user tier

### Enhanced "How Templates Work" Section

Added comprehensive category overview showing all 6 template categories with descriptions:
- 📊 Analytics
- 🛡️ Security & Fraud
- 🔮 Prediction
- 🔬 Research & Discovery
- ⚙️ Automation
- 🏢 Organization

---

## 📁 Files Modified

### Backend/Library
1. **`tiannara_saas/lib/workflow-templates.ts`**
   - Enhanced interface with new metadata fields
   - Added 5 comprehensive prediction templates
   - Updated categories to match templates.md
   - Added domain usage, outputs, widgets, automation rules
   - Total: ~1000 lines with full template definitions

### Frontend
2. **`tiannara_saas/app/dashboard/workflows/templates/page.tsx`**
   - Added tier badge display
   - Added core domains visualization
   - Added outputs display
   - Enhanced "How Templates Work" section with category overview
   - Improved visual hierarchy and information density

---

## 🎯 Key Differentiators (Why This Matters)

### 1. Multi-Hypothesis Approach
Instead of: `Fraud = TRUE/FALSE`

Tiannara returns:
```json
{
  "hypotheses": [
    { "type": "account_takeover", "confidence": 0.81 },
    { "type": "synthetic_identity", "confidence": 0.62 }
  ]
}
```

This makes Tiannara feel:
- ✅ Intelligent
- ✅ Probabilistic
- ✅ Explainable
- ✅ Scientific

Instead of:
- ❌ Rigid
- ❌ Black-box
- ❌ Binary

### 2. Explainability Generation
Every template automatically generates:
```json
{
  "decision_trace": [...],
  "causal_factors": [...],
  "uncertainties": [...],
  "recommended_actions": [...]
}
```

The SaaS simply visualizes this - Core does the heavy lifting.

### 3. Memory Integration
Core stores:
- Past executions
- Learned patterns
- Anomalies
- Workflow outcomes

This enables:
- Personalization
- Optimization
- Adaptive behavior
- Future autonomous improvement

---

## 🚀 Recommended Launch Strategy (from templates.md)

Start with only 4–6 extremely polished templates:

### Initial Set (Now Implemented):
1. ✅ **Customer Intelligence** - Easy demo value
2. ✅ **Fraud Detection** - Strong business ROI
3. ✅ **Predictive Analytics** - Shows intelligence capabilities
4. ✅ **Root Cause Investigation** - Research showcase
5. ✅ **Football Match Prediction** - "Wow factor" (proves Tiannara reasons differently)
6. ✅ **Demand Forecasting** - Broad business appeal

### Future Additions:
- Historical Reconstruction (unique differentiator)
- Executive Intelligence Dashboard (enterprise)
- Compliance Monitoring (regulated industries)
- Support Ticket Triage (automation)

---

## 🧱 Internal Structure (Future Implementation)

Per templates.md, Core should have:

```
tiannara_core/
├── workflows/
│   ├── engine/          # Workflow Runtime Layer
│   ├── templates/       # Template Registry
│   ├── runners/         # Execution Runners
│   ├── orchestrators/   # Domain Orchestrator
│   └── executors/       # Task Executors
```

### Core Components Needed:
1. **Workflow Registry** - Stores available templates, configs, permissions
2. **Domain Orchestrator** - Routes tasks between RE, causal, NLP, temporal, etc.
3. **Execution Runtime** - Handles state, retries, queues, streaming
4. **Reasoning Trace Generator** - Creates explainability graphs
5. **Insight Engine** - Generates recommendations, anomalies, optimizations

---

## 💡 Biggest Architectural Insight (from templates.md)

**Your SaaS is NOT "the product."**

The SaaS is:
> A delivery interface for Tiannara Core cognition.

**Core is the actual product.**

The SaaS:
- Packages it
- Visualizes it
- Commercializes it
- Simplifies access

That distinction matters a lot for long-term strategy.

---

## ✅ Summary

The enhanced template system now:

1. ✅ Follows the comprehensive architecture from templates.md
2. ✅ Includes 5 new prediction templates with full metadata
3. ✅ Implements multi-domain orchestration patterns
4. ✅ Supports tier-based access control
5. ✅ Displays rich template information (domains, outputs, widgets)
6. ✅ Prepares for future marketplace and add-on packs
7. ✅ Aligns with long-term vision of compounding intelligence infrastructure

**Total Templates:** 11 (6 existing + 5 new prediction templates)

**Next Steps:**
- Implement backend workflow engine to execute templates
- Connect templates to real Tiannara Core domains
- Build template-specific dashboards with auto-generated widgets
- Add automation rule execution
- Create template marketplace UI
