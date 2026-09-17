# Quick Reference: Cognitive Analysis API

## Base URL
```
http://localhost:8004/api/v1
```

## Authentication
All endpoints require JWT token in header:
```
Authorization: Bearer YOUR_JWT_TOKEN
```

---

## Endpoints

### 1. Run Cognitive Analysis
**POST** `/cognitive/analyze`

**Request:**
```json
{
  "input_type": "image" | "text",
  "input_data": "<base64_encoded>",
  "domains": ["vision", "web", "nlp", "prediction"],
  "context": {}
}
```

**Response:**
```json
{
  "success": true,
  "analysis_id": "cog_123456",
  "processing_time_ms": 2345.67,
  "domains_activated": ["vision", "web"],
  "results": {
    "vision": { "objects": [], "description": "", "confidence": 0.94 },
    "web": { "related_info": [], "sources": [] },
    "nlp": { "summary": "", "entities": [], "sentiment": "positive" },
    "prediction": { "insights": [], "recommendations": [] }
  }
}
```

---

### 2. Analyze Uploaded Image
**POST** `/cognitive/analyze-image`

**Form Data:**
- `file`: Image file (PNG/JPEG/WebP, max 10MB)
- `domains`: Comma-separated list (default: "vision,web,nlp,prediction")
- `context`: JSON string (optional)

**Example cURL:**
```bash
curl -X POST http://localhost:8004/api/v1/cognitive/analyze-image \
  -H "Authorization: Bearer TOKEN" \
  -F "file=@photo.png" \
  -F "domains=vision,web"
```

---

### 3. Get Domain Status
**GET** `/cognitive/domains/status`

**Response:**
```json
{
  "success": true,
  "domains": {
    "vision": {
      "name": "Vision Intelligence",
      "status": "operational",
      "capabilities": ["object_detection", "scene_understanding"],
      "version": "1.0.0"
    }
  }
}
```

---

### 4. Get Templates
**GET** `/cognitive/templates`

**Response:**
```json
{
  "success": true,
  "templates": [
    {
      "id": "image_understanding",
      "name": "Image Understanding",
      "domains": ["vision", "web", "nlp"],
      "recommended_for": "starter"
    }
  ]
}
```

---

## Frontend Usage

### Import API Client
```typescript
import { apiClient } from '@/lib/api'
```

### Analyze Image
```typescript
const file = fileInput.files[0]
const response = await apiClient.analyzeImage(
  file,
  ['vision', 'web'],  // domains
  { language: 'en' }   // context
)

if (response.success) {
  console.log(response.data.results.vision)
}
```

### Analyze Text
```typescript
const text = "Your text here"
const base64Text = btoa(unescape(encodeURIComponent(text)))

const response = await apiClient.runCognitiveAnalysis(
  'text',
  base64Text,
  ['nlp', 'prediction']
)
```

### Get Domain Status
```typescript
const status = await apiClient.getCognitiveDomainsStatus()
console.log(status.data.domains)
```

### Get Templates
```typescript
const templates = await apiClient.getCognitiveTemplates()
console.log(templates.data.templates)
```

---

## Available Domains

| Domain | Purpose | Capabilities |
|--------|---------|--------------|
| `vision` | Image understanding | Object detection, OCR, scene analysis |
| `web` | Contextual research | Fact verification, trend analysis |
| `nlp` | Text analysis | Summarization, sentiment, entities |
| `prediction` | Insights & forecasts | Pattern recognition, recommendations |

---

## Error Handling

### Common Errors

**400 Bad Request:**
```json
{
  "detail": "At least one valid domain must be selected"
}
```

**413 Payload Too Large:**
```json
{
  "detail": "Image too large (max 10MB)"
}
```

**503 Service Unavailable:**
```json
{
  "detail": "Vision engine unavailable: Module not found"
}
```

**500 Internal Server Error:**
```json
{
  "detail": "Cognitive analysis orchestration failed: ..."
}
```

### Frontend Error Handling
```typescript
try {
  const response = await apiClient.analyzeImage(file, domains)
  
  if (!response.success) {
    setError(response.error || 'Analysis failed')
    return
  }
  
  // Process results
  setResult(response.data.results)
  
} catch (err) {
  setError('Network error. Please try again.')
}
```

---

## Testing Checklist

### Image Upload
- [ ] PNG image (< 10MB)
- [ ] JPEG image
- [ ] WebP image
- [ ] Drag & drop functionality
- [ ] File size validation (> 10MB rejected)
- [ ] Invalid format rejected (.gif, .bmp)

### Text Input
- [ ] Short text (< 100 chars)
- [ ] Long text (> 1000 chars)
- [ ] Special characters
- [ ] Unicode/emoji support
- [ ] Empty text validation

### Domain Selection
- [ ] Single domain selected
- [ ] Multiple domains selected
- [ ] All domains selected
- [ ] No domains selected (should show error)

### Results Display
- [ ] Vision results show objects/description
- [ ] Web results show sources/info
- [ ] NLP results show summary/entities
- [ ] Prediction results show insights
- [ ] Loading state during analysis
- [ ] Error state on failure

---

## Performance Targets

| Metric | Target | Current (Placeholder) |
|--------|--------|----------------------|
| Processing Time | < 2s (parallel) | ~2s (simulated) |
| Success Rate | > 99% | 100% (mock) |
| Max File Size | 10MB | 10MB enforced |
| Concurrent Users | 100+ | Not load tested |

---

## Swagger UI

Visit: **http://localhost:8004/docs**

Search for "Cognitive Analysis" to see all endpoints with interactive testing.

---

## Logs

Check backend logs for:
```
INFO: /api/v1/cognitive/analyze - User: usr_123 - Domains: [vision, web] - Time: 2345ms
ERROR: Vision engine unavailable - ModuleNotFoundError
```

Log file: `logs/tiannara.log`

---

## Quick Troubleshooting

**Problem:** Backend won't start
**Solution:** Check port 8004 is free, verify imports in main.py

**Problem:** 401 Unauthorized
**Solution:** Ensure JWT token is valid and included in headers

**Problem:** Domain returns empty results
**Solution:** Check domain engine is initialized (currently placeholders)

**Problem:** Image upload fails
**Solution:** Verify file size < 10MB and format is PNG/JPEG/WebP

**Problem:** CORS errors
**Solution:** Check ALLOWED_ORIGINS in .env includes your frontend URL

---

## Support

- **Documentation:** `WORKSPACE_AND_API_GATEWAY_SETUP.md`
- **Architecture:** `docs/architecture/architecture.md`
- **Implementation Details:** `IMPLEMENTATION_SUMMARY.md`
- **API Docs:** http://localhost:8004/docs
