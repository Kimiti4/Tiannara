"""
Tiannara Usage API Routes
Provides API usage metrics and analytics for users
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Dict, List, Optional
from datetime import datetime

# Import auth dependencies
from tiannara_api.routes.auth import get_current_user

router = APIRouter(prefix="/usage", tags=["usage"])


@router.get("/metrics")
async def get_usage_metrics(
    range: str = Query(default="7d", description="Time range: 7d, 30d, 90d"),
    current_user: dict = Depends(get_current_user)
):
    """
    Get API usage metrics for the current user.
    
    Returns usage statistics including:
    - Total requests
    - Success rate
    - Average latency
    - Error count
    - Daily usage breakdown
    - Domain breakdown
    """
    try:
        # Import usage tracker
        from tiannara_api.gateway.usage_tracker import usage_tracker
        
        # Get user's email from the user object
        # get_current_user() returns {"success": True, "user": {...}}
        user_data = current_user.get("user", {})
        user_email = user_data.get("email", "")
        
        # Get usage data from tracker
        global_metrics = usage_tracker.get_global_metrics()
        
        # Generate mock daily usage data (in production, this would come from database)
        days = int(range.replace('d', ''))
        daily_usage = []
        for i in range(days):
            date = datetime.utcnow()
            # For simplicity, generate consistent mock data
            daily_usage.append({
                "date": date.strftime("%Y-%m-%d"),
                "requests": 150 + (i * 10),
                "success": 145 + (i * 10),
                "errors": 5
            })
        
        # Domain breakdown
        domain_breakdown = [
            {"domain": "predictive", "count": 450, "percentage": 45.0},
            {"domain": "analytics", "count": 300, "percentage": 30.0},
            {"domain": "research", "count": 150, "percentage": 15.0},
            {"domain": "other", "count": 100, "percentage": 10.0}
        ]
        
        # Calculate totals
        total_requests = sum(day["requests"] for day in daily_usage)
        total_success = sum(day["success"] for day in daily_usage)
        total_errors = sum(day["errors"] for day in daily_usage)
        success_rate = (total_success / total_requests * 100) if total_requests > 0 else 0
        avg_latency = 245.5  # Mock average latency
        
        return {
            "success": True,
            "data": {
                "total_requests": total_requests,
                "success_rate": round(success_rate, 2),
                "avg_latency_ms": avg_latency,
                "error_count": total_errors,
                "daily_usage": daily_usage,
                "domain_breakdown": domain_breakdown
            }
        }
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch usage metrics: {str(e)}"
        )
