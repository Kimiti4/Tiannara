# Tiannara Moderation Service - JamiiLink Integration Guide

**Date**: May 1, 2026  
**Status**: ✅ **Service Ready** | 📋 **Integration Instructions**

---

## 🎯 **Overview**

The Tiannara Moderation Service is now live and ready for JamiiLink integration. This guide shows you how to integrate content moderation into your JamiiLink backend.

**Service URL**: `http://localhost:8000/api/v1/moderate` (development)  
**Production URL**: Will be configured when deployed

---

## 🚀 **Quick Start**

### **Step 1: Add Environment Variable**

In your JamiiLink backend (`iyf-s10-week-11-Kimiti4/.env`):

```env
# Tiannara Core Integration
TIANNARA_API_URL=http://localhost:8000
```

For production (when deployed):
```env
TIANNARA_API_URL=https://api.tiannara.com
```

---

### **Step 2: Create Tiannara Service**

Create file: `iyf-s10-week-11-Kimiti4/src/services/tiannaraService.js`

```javascript
const TIANNARA_API_URL = process.env.TIANNARA_API_URL || 'http://localhost:8000';

class TiannaraService {
  /**
   * Moderate content before publication
   * @param {string} content - Text content to analyze
   * @returns {Promise<Object>} Moderation result
   */
  async moderateContent(content) {
    try {
      const response = await fetch(`${TIANNARA_API_URL}/api/v1/moderate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ content })
      });

      if (!response.ok) {
        throw new Error(`Moderation API error: ${response.status}`);
      }

      const result = await response.json();
      return result;
    } catch (error) {
      console.error('Tiannara moderation failed:', error);
      
      // Graceful degradation: allow content if service is down
      // In production, you might want to queue for later review
      return {
        safe: true,
        toxicity_score: 0,
        spam_probability: 0,
        scam_probability: 0,
        categories_flagged: [],
        confidence: 0,
        explanation: 'Moderation service unavailable, using fallback'
      };
    }
  }

  /**
   * Check if content should be allowed based on moderation result
   * @param {Object} moderationResult - Result from moderateContent()
   * @returns {boolean} True if content is safe
   */
  isContentSafe(moderationResult) {
    return moderationResult.safe;
  }

  /**
   * Get human-readable reason why content was flagged
   * @param {Object} moderationResult - Result from moderateContent()
   * @returns {string} Explanation
   */
  getFlagReason(moderationResult) {
    if (moderationResult.safe) {
      return 'Content is safe';
    }
    return moderationResult.explanation;
  }
}

module.exports = new TiannaraService();
```

---

### **Step 3: Integrate into Post Creation**

Update: `iyf-s10-week-11-Kimiti4/src/controllers/posts.js`

Find the post creation function and add moderation:

```javascript
const tiannaraService = require('../services/tiannaraService');

// In your create post handler
exports.createPost = async (req, res) => {
  try {
    const { title, content, category, image } = req.body;
    const userId = req.user.id;

    // 🔹 STEP 1: Moderate content BEFORE saving
    const moderationResult = await tiannaraService.moderateContent(content);

    // 🔹 STEP 2: Check if content is safe
    if (!tiannaraService.isContentSafe(moderationResult)) {
      return res.status(400).json({
        success: false,
        message: 'Content violates community guidelines',
        reason: tiannaraService.getFlagReason(moderationResult),
        details: {
          toxicity: moderationResult.toxicity_score,
          spam: moderationResult.spam_probability,
          scam: moderationResult.scam_probability
        }
      });
    }

    // 🔹 STEP 3: Content is safe, proceed with creation
    const post = new Post({
      title,
      content,
      category,
      image,
      author: userId,
      // Optional: Store moderation metadata
      moderation: {
        checked: true,
        timestamp: new Date(),
        scores: {
          toxicity: moderationResult.toxicity_score,
          spam: moderationResult.spam_probability,
          scam: moderationResult.scam_probability
        }
      }
    });

    await post.save();

    res.status(201).json({
      success: true,
      data: post
    });

  } catch (error) {
    console.error('Error creating post:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};
```

---

### **Step 4: Test the Integration**

#### **Test 1: Safe Content**

```bash
curl -X POST http://localhost:4000/api/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "title": "Community Event",
    "content": "Join us for a neighborhood cleanup this Saturday!",
    "category": "mtaani"
  }'
```

**Expected**: Post created successfully ✅

---

#### **Test 2: Toxic Content**

```bash
curl -X POST http://localhost:4000/api/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "title": "Angry Post",
    "content": "You stupid idiot! This is trash and you should die!",
    "category": "mtaani"
  }'
```

**Expected**: Rejected with 400 error ❌
```json
{
  "success": false,
  "message": "Content violates community guidelines",
  "reason": "High toxicity detected (85.0%)",
  "details": {
    "toxicity": 0.85,
    "spam": 0.05,
    "scam": 0.02
  }
}
```

---

#### **Test 3: Spam Content**

```bash
curl -X POST http://localhost:4000/api/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "title": "Amazing Deal",
    "content": "CLICK HERE NOW! BUY NOW and earn FREE MONEY fast! Limited time offer!",
    "category": "farm"
  }'
```

**Expected**: Rejected as spam ❌

---

## 📊 **API Reference**

### **Endpoint**: `POST /api/v1/moderate`

**Request:**
```json
{
  "content": "Text to analyze"
}
```

**Response:**
```json
{
  "safe": true,
  "toxicity_score": 0.15,
  "spam_probability": 0.05,
  "scam_probability": 0.02,
  "categories_flagged": [],
  "confidence": 0.9,
  "explanation": "Content appears safe. No significant issues detected."
}
```

**Fields:**
- `safe` (boolean): Whether content is safe to publish
- `toxicity_score` (float 0-1): Toxicity level
- `spam_probability` (float 0-1): Likelihood of spam
- `scam_probability` (float 0-1): Likelihood of scam
- `categories_flagged` (array): List of issues found
- `confidence` (float 0-1): Confidence in the decision
- `explanation` (string): Human-readable explanation

---

## ⚙️ **Configuration Options**

### **Adjust Thresholds**

If you want to customize what gets flagged, update the service thresholds in Tiannara:

File: `tiannara_api/services/moderation_service.py`

```python
def __init__(self):
    self.toxicity_threshold = 0.7  # Lower = stricter
    self.spam_threshold = 0.6       # Lower = stricter
    self.scam_threshold = 0.65      # Lower = stricter
```

**Recommended Thresholds:**

| Strictness | Toxicity | Spam | Scam | Use Case |
|------------|----------|------|------|----------|
| Lenient | 0.8 | 0.7 | 0.75 | Open communities |
| Balanced | 0.7 | 0.6 | 0.65 | **Default** |
| Strict | 0.5 | 0.4 | 0.5 | Professional platforms |

---

## 🔍 **Monitoring & Debugging**

### **Check Service Health**

```bash
curl http://localhost:8000/api/v1/moderate/health
```

**Response:**
```json
{
  "status": "healthy",
  "service": "moderation",
  "version": "1.0.0",
  "thresholds": {
    "toxicity": 0.7,
    "spam": 0.6,
    "scam": 0.65
  },
  "timestamp": "2026-05-01T12:00:00Z"
}
```

---

### **View Configuration**

```bash
curl http://localhost:8000/api/v1/moderate/config
```

---

### **Logs**

Check Tiannara logs for moderation activity:

```bash
# In Tiannara terminal
[MODERATION] Analyzed content in 0.023s - Safe: True
[MODERATION] Analyzed content in 0.019s - Safe: False
```

---

## 🚨 **Error Handling**

### **Graceful Degradation**

If Tiannara service is down, the integration falls back to allowing content. You can change this behavior:

```javascript
// Option 1: Allow content (current default)
return { safe: true, ... };

// Option 2: Reject content when service is down
throw new Error('Moderation service unavailable, try again later');

// Option 3: Queue for manual review
await queueForReview(content, userId);
return { safe: true, requires_review: true };
```

---

### **Common Errors**

**Error**: `Moderation API error: 500`
- **Cause**: Tiannara server crashed
- **Fix**: Restart Tiannara: `uvicorn tiannara_api.main:app --reload`

**Error**: `Cannot connect to Tiannara API server`
- **Cause**: Wrong URL or server not running
- **Fix**: Check `TIANNARA_API_URL` env var and ensure server is running

**Error**: `Content violates community guidelines`
- **Cause**: Content was flagged by moderation
- **Fix**: Review content and adjust if needed

---

## 📈 **Best Practices**

### **1. Always Moderate Before Saving**

```javascript
// ✅ Good: Moderate first
const moderation = await tiannaraService.moderateContent(content);
if (!moderation.safe) {
  return res.status(400).json({ message: 'Content flagged' });
}
await post.save();

// ❌ Bad: Save then moderate
await post.save();
const moderation = await tiannaraService.moderateContent(content);
```

---

### **2. Store Moderation Metadata**

Keep track of moderation decisions for analytics:

```javascript
const post = new Post({
  // ... other fields
  moderation: {
    checked: true,
    timestamp: new Date(),
    scores: {
      toxicity: moderationResult.toxicity_score,
      spam: moderationResult.spam_probability,
      scam: moderationResult.scam_probability
    },
    flagged: !moderationResult.safe,
    categories: moderationResult.categories_flagged
  }
});
```

---

### **3. Provide User Feedback**

Tell users WHY their content was rejected:

```javascript
if (!moderationResult.safe) {
  return res.status(400).json({
    success: false,
    message: 'Content violates community guidelines',
    reason: moderationResult.explanation,  // Helpful feedback
    suggestions: [
      'Remove offensive language',
      'Avoid excessive capitalization',
      'Don\'t include suspicious links'
    ]
  });
}
```

---

### **4. Log Moderation Decisions**

Track patterns for future improvements:

```javascript
console.log('[MODERATION]', {
  userId: req.user.id,
  postId: post._id,
  safe: moderationResult.safe,
  categories: moderationResult.categories_flagged,
  timestamp: new Date()
});
```

---

## 🎯 **Next Steps After Integration**

Once basic moderation is working:

1. **Monitor False Positives**
   - Track when safe content is incorrectly flagged
   - Adjust thresholds if needed

2. **Add Admin Override**
   - Allow admins to approve flagged content
   - Build review dashboard

3. **Implement Appeals Process**
   - Let users request review of rejected content
   - Manual review workflow

4. **Expand to Comments**
   - Moderate comments using same service
   - Apply to all user-generated content

5. **Add Batch Moderation**
   - For bulk imports or migrations
   - Use `/api/v1/moderate/batch` endpoint

---

## 📞 **Support**

**Tiannara API Docs**: Check Swagger UI at `http://localhost:8000/docs`

**Test the Service**:
```bash
cd c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic
python test_moderation_service.py
```

**Issues**: Review logs in both Tiannara and JamiiLink terminals

---

**Status**: ✅ **Service Ready** | 🚀 **Ready for Integration**

**Estimated Integration Time**: 30-60 minutes
