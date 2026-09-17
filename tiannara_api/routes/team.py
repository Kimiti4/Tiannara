"""
Team management endpoints for Tiannara SaaS.
Handles team members, invitations, roles, and activity tracking.

PROFESSIONAL TIER REQUIRED - Team collaboration is a Professional+ feature
"""
from fastapi import APIRouter, HTTPException, status, Request
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
import uuid
from tiannara_api.middleware.tier_access_control import require_professional

router = APIRouter(
    prefix="/team",
    tags=["team"],
)

# In-memory storage (replace with database in production)
team_members_db: Dict[str, dict] = {}


class TeamMemberInvite(BaseModel):
    email: str = Field(..., min_length=1)
    role: str = Field(..., pattern="^(admin|member|viewer)$")


class TeamMemberUpdate(BaseModel):
    role: Optional[str] = None
    status: Optional[str] = None


@router.get("/members")
@require_professional
async def get_team_members(request: Request):
    """Get all team members. PROFESSIONAL TIER REQUIRED."""
    try:
        # TODO: Filter by organization_id from JWT token
        members = list(team_members_db.values())
        
        return {
            "success": True,
            "data": members,
            "count": len(members)
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch team members: {str(e)}"
        )


@router.post("/invite", status_code=status.HTTP_201_CREATED)
@require_professional
async def invite_member(invite_data: TeamMemberInvite, request: Request):
    """Invite a new team member. PROFESSIONAL TIER REQUIRED."""
    try:
        member_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()
        
        member = {
            "id": member_id,
            "email": invite_data.email,
            "role": invite_data.role,
            "status": "pending",
            "invited_at": now,
            "joined_at": None,
            "last_active": None,
            "workflows": 0
        }
        
        team_members_db[member_id] = member
        
        # TODO: Send invitation email
        
        return {
            "success": True,
            "data": member,
            "message": f"Invitation sent to {invite_data.email}"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to invite member: {str(e)}"
        )


@router.put("/members/{member_id}")
@require_professional
async def update_member(member_id: str, update_data: TeamMemberUpdate, request: Request):
    """Update a team member's role or status. PROFESSIONAL TIER REQUIRED."""
    member = team_members_db.get(member_id)
    
    if not member:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team member not found"
        )
    
    try:
        if update_data.role is not None:
            member["role"] = update_data.role
        if update_data.status is not None:
            member["status"] = update_data.status
        
        team_members_db[member_id] = member
        
        return {
            "success": True,
            "data": member,
            "message": "Team member updated successfully"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update team member: {str(e)}"
        )


@router.delete("/members/{member_id}")
@require_professional
async def remove_member(member_id: str, request: Request):
    """Remove a team member. PROFESSIONAL TIER REQUIRED."""
    member = team_members_db.pop(member_id, None)
    
    if not member:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team member not found"
        )
    
    return {
        "success": True,
        "message": "Team member removed successfully"
    }


@router.get("/activity")
@require_professional
async def get_team_activity(request: Request):
    """Get recent team activity log. PROFESSIONAL TIER REQUIRED."""
    try:
        # TODO: Fetch from activity log database
        # For now, return sample activity
        
        activities = [
            {
                "id": str(uuid.uuid4()),
                "action": "workflow_created",
                "user": "John Doe",
                "description": "Created new workflow 'Customer Segmentation'",
                "timestamp": datetime.now(timezone.utc).isoformat()
            },
            {
                "id": str(uuid.uuid4()),
                "action": "member_invited",
                "user": "Admin User",
                "description": "Invited jane@example.com as viewer",
                "timestamp": datetime.now(timezone.utc).isoformat()
            },
            {
                "id": str(uuid.uuid4()),
                "action": "api_key_generated",
                "user": "Sarah Smith",
                "description": "Generated new API key for production",
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
        ]
        
        return {
            "success": True,
            "data": activities,
            "count": len(activities)
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch team activity: {str(e)}"
        )
