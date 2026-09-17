"""
Team collaboration endpoints for Tiannara SaaS.

Features:
- Real-time presence tracking
- Shared workspace activities
- Team member status
- Collaborative workflow editing
- Activity feed

Date: April 30, 2026
Status: Week 30 - Team Collaboration
"""
from fastapi import APIRouter, Depends, HTTPException, status, Request, WebSocket, WebSocketDisconnect
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
import uuid
import asyncio
from tiannara_api.middleware.tier_access_control import require_starter
from tiannara_api.security.auth_deps import require_auth
from tiannara_api.security.websocket_auth import require_websocket_auth

import logging

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/collaboration",
    tags=["collaboration"],
    dependencies=[Depends(require_auth)],
)

# In-memory presence tracking (will use Redis in production)
team_presence: Dict[str, Dict[str, Any]] = {}
activity_feed: List[Dict[str, Any]] = []


class TeamMemberPresence(BaseModel):
    user_id: str
    user_name: str
    status: str = "online"  # online, away, busy, offline
    current_activity: Optional[str] = None
    last_active: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())


class ActivityEvent(BaseModel):
    user_id: str
    user_name: str
    action: str  # "edited_workflow", "created_alert", "viewed_analytics", etc.
    resource_type: str
    resource_id: str
    description: str
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())


@router.get("/presence")
@require_starter
async def get_team_presence(request: Request):
    """Get current team member presence status."""
    try:
        # Filter out offline members older than 5 minutes
        now = datetime.now(timezone.utc)
        active_members = []
        
        for user_id, presence in team_presence.items():
            last_active = datetime.fromisoformat(presence["last_active"])
            time_diff = (now - last_active).total_seconds()
            
            if time_diff < 300:  # 5 minutes
                active_members.append(presence)
            else:
                presence["status"] = "offline"
        
        return {
            "success": True,
            "data": active_members,
            "online_count": len([m for m in active_members if m["status"] == "online"])
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get team presence: {str(e)}"
        )


@router.post("/presence")
@require_starter
async def update_presence(presence_data: TeamMemberPresence, request: Request):
    """Update current user's presence status."""
    try:
        team_presence[presence_data.user_id] = {
            "user_id": presence_data.user_id,
            "user_name": presence_data.user_name,
            "status": presence_data.status,
            "current_activity": presence_data.current_activity,
            "last_active": datetime.now(timezone.utc).isoformat()
        }
        
        return {
            "success": True,
            "message": "Presence updated"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update presence: {str(e)}"
        )


@router.get("/activity")
@require_starter
async def get_activity_feed(request: Request, limit: int = 50):
    """Get recent team activity feed."""
    try:
        recent_activity = activity_feed[-limit:]
        recent_activity.reverse()  # Most recent first
        
        return {
            "success": True,
            "data": recent_activity,
            "count": len(recent_activity)
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get activity feed: {str(e)}"
        )


@router.post("/activity")
@require_starter
async def log_activity(activity_data: ActivityEvent, request: Request):
    """Log a team activity event."""
    try:
        activity_record = {
            "id": str(uuid.uuid4()),
            "user_id": activity_data.user_id,
            "user_name": activity_data.user_name,
            "action": activity_data.action,
            "resource_type": activity_data.resource_type,
            "resource_id": activity_data.resource_id,
            "description": activity_data.description,
            "timestamp": datetime.now(timezone.utc).isoformat()
        }
        
        activity_feed.append(activity_record)
        
        # Keep only last 1000 activities
        if len(activity_feed) > 1000:
            activity_feed[:] = activity_feed[-1000:]
        
        return {
            "success": True,
            "data": activity_record,
            "message": "Activity logged"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to log activity: {str(e)}"
        )


@router.websocket("/ws/presence")
async def websocket_presence(websocket: WebSocket):
    """
    WebSocket endpoint for real-time presence updates.
    
    Clients connect to receive live presence changes.
    """
    user = await require_websocket_auth(websocket)
    if not user:
        return

    await websocket.accept()
    client_id = user.get("user_id") or f"presence_{id(websocket)}"
    
    try:
        # Send initial presence state
        await websocket.send_json({
            "type": "presence_update",
            "data": list(team_presence.values())
        })
        
        # Keep connection alive and send updates
        while True:
            # Wait for messages from client
            data = await websocket.receive_text()
            
            if data == "ping":
                await websocket.send_text("pong")
            elif data == "get_presence":
                await websocket.send_json({
                    "type": "presence_update",
                    "data": list(team_presence.values())
                })
                
    except WebSocketDisconnect:
        logger.info(f"Presence client {client_id} disconnected")
    except Exception as e:
        logger.error(f"Presence WebSocket error: {e}")


@router.get("/shared-workflows")
@require_starter
async def get_shared_workflows(request: Request):
    """Get workflows shared with the team."""
    try:
        # TODO: Query database for shared workflows
        # For now, return mock data
        shared_workflows = [
            {
                "id": "wf_shared_001",
                "name": "Customer Segmentation Pipeline",
                "owner": "John Doe",
                "shared_with": ["team_analytics", "team_marketing"],
                "permissions": ["read", "execute"],
                "last_modified": datetime.now(timezone.utc).isoformat()
            }
        ]
        
        return {
            "success": True,
            "data": shared_workflows,
            "count": len(shared_workflows)
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get shared workflows: {str(e)}"
        )


@router.post("/shared-workflows/{workflow_id}/share")
@require_starter
async def share_workflow(workflow_id: str, request: Request):
    """Share a workflow with team members."""
    try:
        # TODO: Implement workflow sharing logic
        return {
            "success": True,
            "message": "Workflow shared successfully",
            "workflow_id": workflow_id
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to share workflow: {str(e)}"
        )


@router.get("/notifications")
@require_starter
async def get_notifications(request: Request, limit: int = 20):
    """Get team notifications."""
    try:
        # Filter activity feed for notifications
        notifications = [
            activity for activity in activity_feed
            if activity.get("action") in ["mention", "share", "comment"]
        ]
        
        recent_notifications = notifications[-limit:]
        recent_notifications.reverse()
        
        return {
            "success": True,
            "data": recent_notifications,
            "count": len(recent_notifications),
            "unread_count": len([n for n in recent_notifications if not n.get("read", False)])
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get notifications: {str(e)}"
        )
