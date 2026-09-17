# Phase 1-5 Implementation Plan: Sports Prediction System ✅

## Executive Summary

Successfully integrated **Feature Engineering** into Tiannara Core's PredictionEngine with **100% test pass rate**. This document outlines the complete implementation roadmap from current state through API monetization launch.

---

## ✅ COMPLETED: Feature Engineering Integration

### What Was Built

1. **[feature_engineering.py](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/tiannara_core/prediction/feature_engineering.py)** (576 lines)
   - All 5 formulas from realtime.md Sections 1.1-1.5
   - Momentum Index, Odds Velocity, News Impact Score, Chaos Index, Market Inefficiency
   - Production-ready with type hints and error handling

2. **[prediction.py Updated](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/tiannara_api/engines/prediction.py)** (+193 lines)
   - Integrated FeatureEngineer into PredictionEngine v2.1.0
   - Added `_predict_sports()` method with feature-based probability adjustment
   - Implemented confidence calculation, key drivers, risk assessment
   - Health check updated to show feature engineering status

3. **Test Results: 100% Pass Rate**
   ```
   ✅ Engine Initialization
   ✅ Basic Sports Prediction  
   ✅ Chaos Match Detection
   ✅ Value Opportunity Detection
   ✅ Health Check
   
   Total: 5/5 passed (100%)
   ```

### Key Capabilities Now Available

- **Real-time momentum tracking**: Detects which team is dominating RIGHT NOW
- **Chaos Index**: Identifies jackpot-friendly high-variance matches
- **Market inefficiency detection**: Finds bookmaker mispricing automatically
- **News impact scoring**: Quantifies how injuries/news affect outcomes
- **Explainable AI**: Every prediction includes key drivers and reasoning

---

## 📋 PHASE 1: Add Sports Prediction Templates (Week 1)

### Goal
Create user-facing workflow templates that leverage the new sports prediction capabilities.

### Tasks

#### 1.1 Create Sports Prediction Template Catalog

Add to `tiannara_saas/lib/workflow-templates.ts`:

```typescript
// Sports Prediction Templates (New Category)
{
  id: 'match_winner_prediction',
  name: 'Match Winner Prediction',
  description: 'Predict football match outcomes using real-time momentum, odds movements, and news impact.',
  category: 'prediction',
  difficulty: 'beginner',
  tierRequired: 'professional',  // Requires feature engineering
  domainsUsed: ['prediction_engine', 'feature_engineering'],
  outputs: ['win_probabilities', 'confidence_score', 'chaos_level', 'key_drivers'],
  dashboardWidgets: ['probability_gauge', 'momentum_chart', 'chaos_indicator', 'value_detector']
}

{
  id: 'jackpot_optimizer',
  name: 'Jackpot Match Optimizer',
  description: 'Identify high-variance matches perfect for jackpot betting systems using Chaos Index.',
  category: 'prediction',
  difficulty: 'intermediate',
  tierRequired: 'professional',
  domainsUsed: ['prediction_engine', 'feature_engineering'],
  outputs: ['chaos_score', 'jackpot_potential', 'risk_assessment', 'hedging_suggestions']
}

{
  id: 'live_bet_edge',
  name: 'Live Betting Edge Detector',
  description: 'Detect value bets in real-time by comparing model predictions vs market odds.',
  category: 'prediction',
  difficulty: 'advanced',
  tierRequired: 'enterprise',
  domainsUsed: ['prediction_engine', 'feature_engineering', 'real_time_streaming'],
  outputs: ['value_signals', 'mis_score', 'entry_timing', 'exit_strategy']
}
```

#### 1.2 Build Sports Prediction UI Components

Create in `tiannara_saas/components/sports/`:

- `MomentumChart.tsx` - Real-time momentum visualization
- `ChaosIndicator.tsx` - Chaos level gauge with jackpot potential
- `ValueDetector.tsx` - Market inefficiency alerts
- `OddsMovementChart.tsx` - Live odds velocity tracking
- `NewsImpactFeed.tsx` - Recent news affecting match

#### 1.3 Update Workflow Executor

Modify `tiannara_api/routes/workflow_executor.py`:

```python
# Add sports prediction node handler
async def _execute_sports_prediction(self, config: Dict):
    """Execute sports prediction using feature engineering."""
    
    # Extract match data from config
    match_stats = config.get('match_stats', {})
    odds_history = config.get('odds_history', [])
    news_events = config.get('news_events', [])
    
    # Call PredictionEngine with sports_prediction task
    result = self.prediction_engine.process({
        "task": "sports_prediction",
        "match_stats": match_stats,
        "odds_history": odds_history,
        "news_events": news_events,
        "model_probs": config.get('model_probs'),
        "market_probs": config.get('market_probs')
    })
    
    return result
```

#### 1.4 Create Demo Data Generator

Build `tiannara_api/utils/sports_demo_data.py`:

```python
def generate_demo_match(team_a="Arsenal", team_b="Chelsea"):
    """Generate realistic demo match data for testing."""
    return {
        "match_stats": {...},
        "odds_history": [...],
        "news_events": [...]
    }
```

### Success Criteria
- ✅ 3 sports prediction templates added to catalog
- ✅ UI components render correctly in workflow builder
- ✅ Demo data generates valid predictions
- ✅ End-to-end workflow execution works

---

## 📋 PHASE 2: Integrate Real-Time Data Sources (Week 2-3)

### Goal
Connect live data feeds for real-time feature updates during matches.

### Tasks

#### 2.1 Sports Data API Integration

Choose and integrate one:
- **API-Football** (api-football.com) - Comprehensive football data
- **SportRadar** - Professional-grade sports data
- **TheSportsDB** - Free tier available

Create `tiannara_api/integrations/sports_api.py`:

```python
class SportsDataClient:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base_url = "https://v3.football.api-sports.io"
    
    async def get_live_match(self, match_id: str):
        """Fetch live match statistics."""
        # API call to get shots, possession, attacks, etc.
        
    async def get_odds_history(self, match_id: str):
        """Fetch historical odds data."""
        
    async def get_team_news(self, team_id: str):
        """Fetch recent news/injuries."""
```

#### 2.2 News Stream Integration

Integrate news APIs:
- **NewsAPI.org** - General sports news
- **Twitter/X API** - Real-time breaking news
- **RSS feeds** - BBC Sport, ESPN, etc.

Create `tiannara_api/integrations/news_stream.py`:

```python
class NewsStreamProcessor:
    def __init__(self):
        self.nlp_processor = None  # For sentiment analysis
    
    async def fetch_sports_news(self, teams: List[str]):
        """Fetch and analyze news for specific teams."""
        # Fetch news
        # Analyze sentiment
        # Calculate impact weight
        return news_events
```

#### 2.3 Real-Time Update Mechanism

Implement polling or webhook system:

```python
# Background task for live match updates
async def update_live_features(match_id: str):
    while match_is_live:
        # Fetch latest data
        match_stats = await sports_api.get_live_match(match_id)
        odds = await sports_api.get_odds_history(match_id)
        news = await news_stream.fetch_sports_news(teams)
        
        # Recalculate features
        features = engineer_features(...)
        
        # Cache in Redis
        await redis.set(f"match:{match_id}:features", features)
        
        # WebSocket update to frontend
        await websocket.broadcast(f"match:{match_id}", features)
        
        await asyncio.sleep(30)  # Update every 30 seconds
```

#### 2.4 Redis Caching Layer

Set up Redis for feature caching:

```python
import redis.asyncio as redis

class FeatureCache:
    def __init__(self):
        self.redis = redis.Redis(host='localhost', port=6379)
    
    async def cache_features(self, match_id: str, features: Dict):
        """Cache feature vector with TTL."""
        await self.redis.setex(
            f"match:{match_id}:features",
            ttl=300,  # 5 minutes
            value=json.dumps(features)
        )
    
    async def get_features(self, match_id: str) -> Optional[Dict]:
        """Retrieve cached features."""
        data = await self.redis.get(f"match:{match_id}:features")
        return json.loads(data) if data else None
```

### Success Criteria
- ✅ Live match data fetched from API
- ✅ News stream processed with sentiment analysis
- ✅ Features recalculated every 30 seconds during live matches
- ✅ Redis caching reduces API calls by 80%
- ✅ WebSocket updates push to frontend in real-time

---

## 📋 PHASE 3: Build Feature Engineering Layer (Week 4)

### Goal
Optimize feature engineering for production scale (thousands of matches).

### Tasks

#### 3.1 Batch Feature Computation

Optimize for multiple matches:

```python
async def compute_features_batch(match_ids: List[str]) -> Dict[str, Dict]:
    """Compute features for multiple matches efficiently."""
    
    # Parallel API calls
    tasks = [fetch_match_data(mid) for mid in match_ids]
    results = await asyncio.gather(*tasks)
    
    # Batch feature computation
    features = {}
    for match_id, data in zip(match_ids, results):
        features[match_id] = engineer_features(**data)
    
    return features
```

#### 3.2 Feature Store Implementation

Build persistent feature storage:

```python
class FeatureStore:
    def __init__(self):
        self.postgres = AsyncSession()  # Historical features
        self.redis = Redis()  # Live features
    
    async def store_feature_snapshot(self, match_id: str, features: Dict):
        """Store feature snapshot for training data."""
        await self.postgres.execute(
            insert(FeatureHistory).values({
                "match_id": match_id,
                "timestamp": datetime.now(),
                "features": features
            })
        )
```

#### 3.3 Performance Optimization

Profile and optimize hot paths:

```python
# Use numpy for vectorized operations
import numpy as np

def calculate_momentum_vectorized(stats_array: np.ndarray) -> np.ndarray:
    """Vectorized momentum calculation for batch processing."""
    # Process 1000 matches simultaneously
    momentum = (
        0.4 * stats_array[:, 0] +  # shots on target
        0.3 * stats_array[:, 1] +  # dangerous attacks
        0.2 * stats_array[:, 2] +  # total shots
        0.1 * stats_array[:, 3]    # possession
    )
    return momentum
```

#### 3.4 Monitoring & Alerting

Add feature quality monitoring:

```python
class FeatureQualityMonitor:
    def check_feature_health(self, features: Dict):
        """Validate feature values are within expected ranges."""
        alerts = []
        
        if abs(features['momentum_diff']) > 1.0:
            alerts.append("Momentum diff out of range")
        
        if features['chaos_index'] < 0 or features['chaos_index'] > 1:
            alerts.append("Chaos index invalid")
        
        return alerts
```

### Success Criteria
- ✅ Batch processing handles 100+ matches/second
- ✅ Feature store persists historical data for model training
- ✅ Latency <50ms per match feature computation
- ✅ Quality monitoring catches anomalous features

---

## 📋 PHASE 4: Deploy v2 ML Models (Month 2)

### Goal
Upgrade from formula-based v1 to deep learning v2 models (PyTorch Transformers).

### Tasks

#### 4.1 PyTorch Model Implementation

Build transformer-based model from realtime.md:

```python
import torch
import torch.nn as nn

class TiannaraCoreV2(nn.Module):
    def __init__(self):
        super().__init__()
        self.news_encoder = NewsEncoder(input_dim=128, hidden=256)
        self.odds_encoder = OddsEncoder(hidden_size=128)
        self.fusion_transformer = nn.TransformerEncoder(
            nn.TransformerEncoderLayer(d_model=256, nhead=8),
            num_layers=4
        )
        self.chaos_head = ChaosHead(dim=256)
        self.prediction_head = PredictionHead(dim=256)
    
    def forward(self, news_embed, odds_seq, match_state):
        n = self.news_encoder(news_embed)
        o = self.odds_encoder(odds_seq)
        m = match_state
        
        x = torch.stack([n, o, m], dim=0)
        x = self.fusion_transformer(x)
        
        chaos = self.chaos_head(x.mean(dim=0))
        prediction = self.prediction_head(x.mean(dim=0))
        
        return prediction, chaos
```

#### 4.2 Training Pipeline

Build end-to-end training system:

```python
class TrainingPipeline:
    def __init__(self):
        self.model = TiannaraCoreV2()
        self.optimizer = torch.optim.Adam(self.model.parameters(), lr=0.001)
    
    def train_epoch(self, dataloader):
        for batch in dataloader:
            self.optimizer.zero_grad()
            
            pred, chaos = self.model(
                batch.news_embeddings,
                batch.odds_sequences,
                batch.match_states
            )
            
            loss = self.compute_loss(pred, chaos, batch.labels)
            loss.backward()
            self.optimizer.step()
```

#### 4.3 Model Registry & Versioning

Track model versions:

```python
class ModelRegistry:
    def save_model(self, model: nn.Module, version: str, metrics: Dict):
        """Save model with metadata."""
        torch.save({
            'model_state': model.state_dict(),
            'version': version,
            'metrics': metrics,
            'timestamp': datetime.now()
        }, f"models/v{version}.pt")
    
    def load_best_model(self) -> nn.Module:
        """Load best performing model."""
        checkpoint = torch.load("models/best.pt")
        model = TiannaraCoreV2()
        model.load_state_dict(checkpoint['model_state'])
        return model
```

#### 4.4 A/B Testing Framework

Compare v1 vs v2 performance:

```python
class ABTestManager:
    def route_prediction(self, match_id: str) -> str:
        """Route 50% traffic to v1, 50% to v2."""
        if hash(match_id) % 2 == 0:
            return "v1_formula"
        else:
            return "v2_transformer"
    
    def track_performance(self, model_version: str, prediction: Dict, actual: str):
        """Track accuracy by model version."""
        correct = 1 if prediction['predicted_outcome'] == actual else 0
        self.metrics[model_version].append(correct)
```

### Success Criteria
- ✅ Transformer model achieves >5% better accuracy than v1
- ✅ Training pipeline processes 10,000+ historical matches
- ✅ Model registry tracks 10+ versions with metrics
- ✅ A/B testing shows v2 outperforms v1 consistently

---

## 📋 PHASE 5: Launch API Monetization (Month 3)

### Goal
Launch paid API tiers leveraging sports prediction intelligence.

### Tasks

#### 5.1 API Endpoint Design

Create premium endpoints:

```python
# tiannara_api/routes/sports_intelligence.py

@router.get("/v1/match/momentum/{match_id}")
async def get_momentum(match_id: str, api_key: str):
    """Get real-time momentum index."""
    verify_api_key(api_key, min_tier="starter")
    features = await feature_cache.get_features(match_id)
    return features['momentum_features']

@router.get("/v1/match/chaos-score/{match_id}")
async def get_chaos_score(match_id: str, api_key: str):
    """Get Chaos Index (premium feature)."""
    verify_api_key(api_key, min_tier="professional")
    features = await feature_cache.get_features(match_id)
    return features['chaos_features']

@router.get("/v1/value-detector/{match_id}")
async def detect_value(match_id: str, api_key: str):
    """Detect market inefficiencies (elite feature)."""
    verify_api_key(api_key, min_tier="enterprise")
    features = await feature_cache.get_features(match_id)
    return features['market_features']

@router.post("/v1/predict/match")
async def predict_match(request: PredictionRequest, api_key: str):
    """Full sports prediction with all features."""
    verify_api_key(api_key, min_tier="professional")
    result = prediction_engine.process({
        "task": "sports_prediction",
        **request.dict()
    })
    return result
```

#### 5.2 Pricing Tiers

Define API pricing:

| Tier | Price/Month | Features | Rate Limit |
|------|-------------|----------|------------|
| **Free** | $0 | Basic momentum | 50 requests/day |
| **Starter** | $29 | Momentum + basic predictions | 1,000 requests/day |
| **Professional** | $99 | Full features + Chaos Index | 10,000 requests/day |
| **Enterprise** | $499 | Real-time streaming + custom models | Unlimited |

#### 5.3 Usage Tracking & Billing

Implement usage metering:

```python
class UsageTracker:
    async def record_usage(self, api_key: str, endpoint: str, cost: float):
        """Record API usage for billing."""
        await self.postgres.execute(
            insert(APIUsage).values({
                "api_key": api_key,
                "endpoint": endpoint,
                "cost": cost,
                "timestamp": datetime.now()
            })
        )
    
    async def check_quota(self, api_key: str) -> bool:
        """Check if user has remaining quota."""
        usage = await self.get_monthly_usage(api_key)
        plan = await self.get_user_plan(api_key)
        return usage < plan.monthly_limit
```

#### 5.4 SDK Development

Create developer-friendly SDKs:

**Python SDK:**
```python
from tiannara_sdk import TiannaraClient

client = TiannaraClient(api_key="your_key")

# Get match prediction
prediction = client.predict_match(
    match_id="12345",
    include_chaos=True,
    include_value_signals=True
)

print(f"Home Win: {prediction.home_win:.1%}")
print(f"Chaos Level: {prediction.chaos_level}")
```

**JavaScript SDK:**
```javascript
const Tiannara = require('tiannara-sdk');
const client = new Tiannara.Client('your_key');

const prediction = await client.predictMatch('12345');
console.log(`Home Win: ${(prediction.homeWin * 100).toFixed(1)}%`);
```

#### 5.5 Developer Portal

Build documentation site:
- API reference with examples
- Interactive playground
- SDK download links
- Pricing calculator
- Status page

### Success Criteria
- ✅ 4 API tiers launched with proper rate limiting
- ✅ Usage tracking accurate to $0.001
- ✅ Python and JavaScript SDKs published
- ✅ First 10 paying customers acquired
- ✅ API uptime >99.9%

---

## 🎯 Immediate Next Steps (This Week)

### Priority 1: Complete Phase 1 (Sports Templates)

1. **Add 3 sports templates to workflow-templates.ts**
   - Match Winner Prediction
   - Jackpot Optimizer
   - Live Bet Edge Detector

2. **Build 5 UI components in tiannara_saas/components/sports/**
   - MomentumChart.tsx
   - ChaosIndicator.tsx
   - ValueDetector.tsx
   - OddsMovementChart.tsx
   - NewsImpactFeed.tsx

3. **Update workflow executor to handle sports_prediction task**
   - Add node handler in workflow_executor.py
   - Test end-to-end workflow execution

4. **Create demo data generator**
   - Generate realistic match scenarios
   - Test with various chaos levels

### Priority 2: Prepare Phase 2 Infrastructure

1. **Sign up for sports data API** (API-Football recommended)
2. **Set up Redis instance** for feature caching
3. **Design database schema** for feature history

---

## 📊 Current Status Summary

| Phase | Status | Completion | ETA |
|-------|--------|------------|-----|
| **Feature Engineering** | ✅ Complete | 100% | Done |
| **Phase 1: Templates** | 🔄 In Progress | 20% | 1 week |
| **Phase 2: Real-Time Data** | ⏳ Pending | 0% | 2-3 weeks |
| **Phase 3: Feature Layer** | ⏳ Pending | 0% | 4 weeks |
| **Phase 4: v2 ML Models** | ⏳ Pending | 0% | 2 months |
| **Phase 5: API Monetization** | ⏳ Pending | 0% | 3 months |

---

## 🚀 Key Achievements So Far

✅ **All 5 realtime.md formulas implemented and tested**  
✅ **PredictionEngine v2.1.0 with sports prediction capability**  
✅ **100% integration test pass rate**  
✅ **Production-ready code with error handling**  
✅ **Explainable AI with key drivers identification**  
✅ **Chaos Index for jackpot detection**  
✅ **Market inefficiency detection for value bets**  

---

## 📚 Reference Documents

- **Feature Engineering Spec**: [realtime.md Sections 1.1-1.5](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/realtime.md#L1372-L1530)
- **Implementation**: [feature_engineering.py](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/tiannara_core/prediction/feature_engineering.py)
- **Integration Tests**: [test_prediction_integration.py](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/test_prediction_integration.py)
- **Complete Documentation**: [FEATURE_ENGINEERING_COMPLETE.md](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/FEATURE_ENGINEERING_COMPLETE.md)

---

**Status: READY FOR PHASE 1 IMPLEMENTATION** 🚀

The foundation is solid. Feature engineering is integrated, tested, and ready. Now we build the user-facing templates and real-time infrastructure to make this a production sports intelligence platform.
