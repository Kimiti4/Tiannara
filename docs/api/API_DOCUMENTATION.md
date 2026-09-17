# Tiannara MindCache API Documentation

## Overview

Tiannara MindCache API provides access to advanced AI reasoning capabilities across multiple domains with cross-domain skill transfer.

**Base URL**: `https://api.tiannara.ai/v1`  
**Authentication**: Bearer Token  
**Rate Limits**: See pricing tiers

---

## Authentication

All API requests require authentication via Bearer token:

```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
     https://api.tiannara.ai/v1/reason
```

Get your API key from the dashboard after signing up.

---

## Quick Start

### 1. Reasoning Request

```python
import requests

api_key = "your_api_key"
headers = {
    "Authorization": f"Bearer {api_key}",
    "Content-Type": "application/json"
}

payload = {
    "domain": "reverse_engineering",
    "task": {
        "type": "function_inference",
        "subtype": "polynomial",
        "inputs": {
            "examples": [
                {"input": 1, "output": 3},
                {"input": 2, "output": 7},
                {"input": 3, "output": 13}
            ]
        },
        "test_input": 4
    }
}

response = requests.post(
    "https://api.tiannara.ai/v1/reason",
    headers=headers,
    json=payload
)

result = response.json()
print(f"Prediction: {result['output']}")
print(f"Confidence: {result['confidence']}")
```

### 2. Check Status

```python
response = requests.get(
    "https://api.tiannara.ai/v1/status",
    headers=headers
)

print(response.json())
# {'status': 'healthy', 'domains_available': 4, 'skills_loaded': 183}
```

---

## Endpoints

### POST /v1/reason

Submit a reasoning task and get predictions.

**Request Body**:
```json
{
  "domain": "reverse_engineering",
  "task": {
    "type": "function_inference",
    "subtype": "polynomial",
    "inputs": {
      "examples": [
        {"input": 1, "output": 3},
        {"input": 2, "output": 7}
      ]
    },
    "test_input": 5
  },
  "options": {
    "use_skill_transfer": true,
    "confidence_threshold": 0.8
  }
}
```

**Response**:
```json
{
  "success": true,
  "output": 21,
  "confidence": 0.95,
  "strategy_used": "polynomial_fit",
  "skills_applied": ["pattern_recognition_42"],
  "execution_time_ms": 45
}
```

**Supported Domains**:
- `algorithm` - Algorithmic problem solving
- `logic` - Logical deduction and puzzles
- `reverse_engineering` - Function inference
- `causal` - Causal discovery and inference

---

### GET /v1/domains

List available reasoning domains.

**Response**:
```json
{
  "domains": [
    {
      "name": "reverse_engineering",
      "description": "Function inference from examples",
      "success_rate": 0.93,
      "skills_available": 183
    },
    {
      "name": "causal",
      "description": "Causal structure learning",
      "success_rate": 1.0,
      "skills_available": 0
    }
  ]
}
```

---

### POST /v1/train

Train custom skills on your data (Professional+ tiers).

**Request Body**:
```json
{
  "domain": "custom",
  "training_data": [
    {"input": {...}, "output": {...}},
    ...
  ],
  "episodes": 100
}
```

**Response**:
```json
{
  "success": true,
  "skills_extracted": 45,
  "training_time_seconds": 120,
  "model_id": "custom_model_abc123"
}
```

---

### GET /v1/skills

View extracted skills (Professional+ tiers).

**Query Parameters**:
- `domain` - Filter by domain
- `type` - Filter by skill type
- `min_confidence` - Minimum confidence threshold

**Response**:
```json
{
  "skills": [
    {
      "id": "re_polynomial_42",
      "type": "pattern_recognition",
      "abstraction_level": "abstract",
      "success_rate": 0.98,
      "transfer_probability": 0.95,
      "origin_domain": "reverse_engineering"
    }
  ],
  "total": 183
}
```

---

### GET /v1/analytics

View usage analytics (Professional+ tiers).

**Response**:
```json
{
  "period": "last_30_days",
  "total_requests": 15420,
  "success_rate": 0.92,
  "avg_confidence": 0.87,
  "domains_used": {
    "reverse_engineering": 8500,
    "causal": 4200,
    "algorithm": 2100,
    "logic": 620
  },
  "skills_transferred": 3200,
  "transfer_success_rate": 0.97
}
```

---

## Error Handling

### Error Response Format

```json
{
  "error": {
    "code": "INVALID_DOMAIN",
    "message": "Domain 'quantum' is not supported",
    "details": "Supported domains: algorithm, logic, reverse_engineering, causal"
  }
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INVALID_DOMAIN` | 400 | Domain not supported |
| `INVALID_TASK` | 400 | Task format incorrect |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `AUTHENTICATION_FAILED` | 401 | Invalid API key |
| `INSUFFICIENT_CREDITS` | 402 | Plan limit reached |
| `INTERNAL_ERROR` | 500 | Server error |

---

## Rate Limits

| Tier | Requests/Month | Rate Limit |
|------|----------------|------------|
| Developer | 10,000 | 10 req/min |
| Professional | 100,000 | 60 req/min |
| Enterprise | Unlimited | 300 req/min |

Rate limit headers included in responses:
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1620000000
```

---

## SDKs

### Python SDK

```bash
pip install tiannara-sdk
```

```python
from tiannara import TiannaraClient

client = TiannaraClient(api_key="your_key")

result = client.reason(
    domain="reverse_engineering",
    task={...}
)

print(result.output)
```

### JavaScript SDK

```bash
npm install @tiannara/sdk
```

```javascript
const { TiannaraClient } = require('@tiannara/sdk');

const client = new TiannaraClient({ apiKey: 'your_key' });

const result = await client.reason({
  domain: 'reverse_engineering',
  task: {...}
});

console.log(result.output);
```

---

## Webhooks

Receive notifications for async operations (Enterprise tier).

**Setup**:
```json
POST /v1/webhooks
{
  "url": "https://your-server.com/webhook",
  "events": ["task.completed", "training.finished"],
  "secret": "webhook_secret"
}
```

**Payload**:
```json
{
  "event": "task.completed",
  "timestamp": "2026-05-06T16:00:00Z",
  "data": {
    "task_id": "task_abc123",
    "result": {...}
  }
}
```

---

## Best Practices

### 1. Use Skill Transfer

Enable cross-domain skill transfer for better results:

```json
{
  "options": {
    "use_skill_transfer": true,
    "min_confidence": 0.7
  }
}
```

### 2. Batch Requests

For multiple tasks, use batch endpoint (Professional+):

```json
POST /v1/reason/batch
{
  "tasks": [
    {"domain": "...", "task": {...}},
    {"domain": "...", "task": {...}}
  ]
}
```

### 3. Cache Results

Cache predictions for identical inputs to reduce costs.

### 4. Monitor Confidence

Low confidence indicates uncertain predictions:

```python
if result.confidence < 0.7:
    # Consider alternative approaches
    pass
```

---

## Pricing

### Starter - $49/month
Perfect for developers and small teams exploring cross-domain AI reasoning.
- **5,000 API requests/month**
- 4 reasoning domains (Algorithm, Logic, RE, Causal)
- Cross-domain skill transfer (>97% success rate)
- Stagnation detection & adaptive strategies
- Standard email support
- API documentation access
- Community forum access

### Professional - $199/month
Built for growing businesses requiring reliable AI reasoning at scale.
- **50,000 API requests/month**
- 10 reasoning domains
- Priority API processing (faster response times)
- Advanced analytics dashboard
- Custom domain configuration
- Priority email support (24-hour response)
- Webhook notifications
- SLA guarantee (99.5% uptime)
- Monthly performance reports

### Enterprise - $999/month
Complete AI reasoning infrastructure for mission-critical applications.
- **Unlimited API requests**
- Unlimited reasoning domains
- Custom model training & fine-tuning
- Dedicated account manager
- 24/7 phone & email support
- Custom SLA (99.9% uptime)
- On-premise deployment option
- EU AI Act compliance tools
- Explainable AI reports
- Quarterly strategy reviews
- Early access to new features

[View Full Pricing Details →](https://tiannara.ai/pricing)

---

## Support

- **Documentation**: https://docs.tiannara.ai
- **API Status**: https://status.tiannara.ai
- **Email**: api-support@tiannara.ai
- **Discord**: https://discord.gg/tiannara

---

## Changelog

### v1.2.0 (May 6, 2026)
- ✅ Added cross-domain skill transfer
- ✅ Improved confidence scoring
- ✅ New analytics endpoint

### v1.1.0 (April 15, 2026)
- ✅ Added causal domain
- ✅ Batch processing support
- ✅ Webhook notifications

### v1.0.0 (March 1, 2026)
- 🚀 Initial release
- ✅ 4 reasoning domains
- ✅ REST API

---

**Ready to build?** [Get Your API Key →](#)
