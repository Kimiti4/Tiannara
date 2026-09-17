"""
Football Prediction API Routes
"""

from fastapi import APIRouter, HTTPException
from typing import Dict, List, Any, Optional
from pydantic import BaseModel
import logging

# Import prediction engine
try:
    from tiannara_core.prediction import FootballPredictionEngine
    ENGINE_AVAILABLE = True
except ImportError:
    ENGINE_AVAILABLE = False
    FootballPredictionEngine = None

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/football-predictions",
    tags=["football-predictions"],
)

# Global engine instance
_engine = None


def get_engine():
    """Get or create prediction engine instance"""
    global _engine
    
    if not ENGINE_AVAILABLE:
        raise HTTPException(
            status_code=503,
            detail="Football prediction engine not available"
        )
    
    if _engine is None:
        _engine = FootballPredictionEngine(use_mock_data=True)
    
    return _engine


class PredictionRequest(BaseModel):
    match_id: str


class BatchPredictionRequest(BaseModel):
    match_ids: List[str]


@router.get("/status")
async def get_engine_status():
    """Get prediction engine status"""
    try:
        engine = get_engine()
        return {
            "success": True,
            "data": engine.get_engine_status()
        }
    except Exception as e:
        logger.error(f"Error getting engine status: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/upcoming-matches")
async def get_upcoming_matches(limit: int = 10):
    """Get list of upcoming matches"""
    try:
        engine = get_engine()
        matches = engine.get_upcoming_matches(limit)
        
        return {
            "success": True,
            "data": matches,
            "count": len(matches)
        }
    except Exception as e:
        logger.error(f"Error fetching upcoming matches: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/predict")
async def predict_match(request: PredictionRequest):
    """Generate prediction for a specific match"""
    try:
        engine = get_engine()
        prediction = engine.predict_match(request.match_id)
        
        if not prediction:
            raise HTTPException(
                status_code=404,
                detail=f"Could not generate prediction for match: {request.match_id}"
            )
        
        return {
            "success": True,
            "data": prediction.to_dict()
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error predicting match: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/predict-batch")
async def predict_batch(request: BatchPredictionRequest):
    """Generate predictions for multiple matches"""
    try:
        engine = get_engine()
        predictions = engine.predict_multiple_matches(request.match_ids)
        
        return {
            "success": True,
            "data": [p.to_dict() for p in predictions],
            "count": len(predictions)
        }
    except Exception as e:
        logger.error(f"Error in batch prediction: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/agent-stats")
async def get_agent_stats():
    """Get performance statistics for all agents"""
    try:
        engine = get_engine()
        stats = engine.get_agent_stats()
        
        return {
            "success": True,
            "data": stats
        }
    except Exception as e:
        logger.error(f"Error getting agent stats: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/history")
async def get_prediction_history(limit: int = 50):
    """Get recent prediction history"""
    try:
        engine = get_engine()
        history = engine.get_prediction_history(limit)
        
        return {
            "success": True,
            "data": history,
            "count": len(history)
        }
    except Exception as e:
        logger.error(f"Error getting prediction history: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/history")
async def clear_prediction_history():
    """Clear prediction history"""
    try:
        engine = get_engine()
        engine.reset_history()
        
        return {
            "success": True,
            "message": "Prediction history cleared"
        }
    except Exception as e:
        logger.error(f"Error clearing history: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
