"""
Moderation API Routes for JamiiLink Integration

Provides REST endpoints for content moderation:
- POST /api/v1/moderate - Single content analysis
- POST /api/v1/moderate/batch - Batch content analysis
- GET /api/v1/moderate/health - Health check

Designed for clean API consumption by external services.
"""

from fastapi import APIRouter, HTTPException, Depends
from typing import List
import time

from tiannara_api.services.moderation_service import ModerationService
from tiannara_api.schemas.moderation_schemas import (
    ModerationRequest,
    ModerationResponse,
    BatchModerationRequest,
    BatchModerationResponse
)

router = APIRouter(
    prefix="/api/v1/moderate",
    tags=["moderation"],
    responses={
        400: {"description": "Invalid request"},
        429: {"description": "Rate limit exceeded"},
        500: {"description": "Internal server error"}
    }
)

# Initialize service (singleton pattern)
moderation_service = ModerationService()


@router.post("", response_model=ModerationResponse)
async def moderate_content(request: ModerationRequest):
    """
    Analyze content for toxicity, spam, and scams.
    
    This endpoint is designed for JamiiLink integration to automatically
    moderate user-generated content before publication.
    
    **Use Cases:**
    - Post creation validation
    - Comment moderation
    - User message screening
    - Marketplace listing review
    
    **Example Request:**
    ```json
    {
        "content": "This is a test post about community events"
    }
    ```
    
    **Example Response:**
    ```json
    {
        "safe": true,
        "toxicity_score": 0.05,
        "spam_probability": 0.02,
        "scam_probability": 0.01,
        "categories_flagged": [],
        "confidence": 0.9,
        "explanation": "Content appears safe. No significant issues detected."
    }
    ```
    
    **Integration with JamiiLink:**
    ```javascript
    // In JamiiLink backend before saving post
    const response = await fetch('http://localhost:8000/api/v1/moderate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content: postText })
    });
    
    const result = await response.json();
    
    if (!result.safe) {
        throw new Error(`Content flagged: ${result.explanation}`);
    }
    ```
    """
    try:
        start_time = time.time()
        
        # Analyze content
        result = moderation_service.analyze_content(request.content)
        
        processing_time = time.time() - start_time
        
        # Log for monitoring
        logger.info(f"Analyzed content in {processing_time:.3f}s - Safe: {result['safe']}")
        
        return ModerationResponse(**result)
    
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Moderation service error: {str(e)}"
        )


@router.post("/batch", response_model=BatchModerationResponse)
async def moderate_batch(request: BatchModerationRequest):
    """
    Analyze multiple content items in batch.
    
    Useful for moderating multiple posts, comments, or messages at once.
    
    **Limits:**
    - Maximum 100 items per request
    - Each item max 10,000 characters
    
    **Example Request:**
    ```json
    {
        "contents": [
            "First post content",
            "Second post content",
            "Third post content"
        ]
    }
    ```
    
    **Example Response:**
    ```json
    {
        "results": [...],
        "total_analyzed": 3,
        "flagged_count": 1
    }
    ```
    """
    try:
        start_time = time.time()
        
        # Process each content item
        results = []
        flagged_count = 0
        
        for content in request.contents:
            result = moderation_service.analyze_content(content)
            results.append(ModerationResponse(**result))
            
            if not result['safe']:
                flagged_count += 1
        
        processing_time = time.time() - start_time
        
        logger.info(f"Analyzed {len(request.contents)} items in {processing_time:.3f}s")
        
        return BatchModerationResponse(
            results=results,
            total_analyzed=len(request.contents),
            flagged_count=flagged_count
        )
    
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Batch moderation error: {str(e)}"
        )


@router.get("/health")
async def health_check():
    """
    Health check endpoint for monitoring.
    
    Returns service status and configuration.
    
    **Example Response:**
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
    """
    from datetime import datetime
    
    return {
        "status": "healthy",
        "service": "moderation",
        "version": "1.0.0",
        "thresholds": {
            "toxicity": moderation_service.toxicity_threshold,
            "spam": moderation_service.spam_threshold,
            "scam": moderation_service.scam_threshold
        },
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }


@router.get("/config")
async def get_config():
    """
    Get current moderation configuration.
    
    Returns threshold values and settings used for content analysis.
    Useful for debugging and tuning moderation behavior.
    """
    return {
        "toxicity_threshold": moderation_service.toxicity_threshold,
        "spam_threshold": moderation_service.spam_threshold,
        "scam_threshold": moderation_service.scam_threshold,
        "toxicity_keywords_count": len(moderation_service.TOXICITY_KEYWORDS),
        "spam_indicators_count": len(moderation_service.SPAM_INDICATORS),
        "scam_patterns_count": len(moderation_service.SCAM_PATTERNS)
    }
