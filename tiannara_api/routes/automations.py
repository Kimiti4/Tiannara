"""
Automation management endpoints for Tiannara SaaS.
Handles scheduled tasks, event triggers, and threshold monitoring.

PROFESSIONAL TIER REQUIRED - Advanced automation is a Professional+ feature
"""
from fastapi import APIRouter, HTTPException, status, Request
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
import uuid
from tiannara_api.middleware.tier_access_control import require_professional

router = APIRouter(
    prefix="/automations",
    tags=["automations"],
)

# In-memory storage (replace with database in production)
automations_db: Dict[str, dict] = {}


class AutomationCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    description: str = Field(default="", max_length=1000)
    trigger_type: str = Field(..., pattern="^(scheduled|event|threshold)$")
    trigger_config: Dict[str, Any] = Field(default_factory=dict)
    workflow_id: str = Field(..., min_length=1)


class AutomationUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    trigger_config: Optional[Dict[str, Any]] = None
    status: Optional[str] = None


@router.get("/")
@require_professional
async def get_automations(request: Request):
    """Get all automations for the authenticated user. PROFESSIONAL TIER REQUIRED."""
    try:
        automations = list(automations_db.values())
        
        return {
            "success": True,
            "data": automations,
            "count": len(automations)
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch automations: {str(e)}"
        )


@router.get("/{automation_id}")
@require_professional
async def get_automation(automation_id: str, request: Request):
    """Get a specific automation by ID. PROFESSIONAL TIER REQUIRED."""
    automation = automations_db.get(automation_id)
    
    if not automation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Automation not found"
        )
    
    return {
        "success": True,
        "data": automation
    }


@router.post("/", status_code=status.HTTP_201_CREATED)
@require_professional
async def create_automation(automation_data: AutomationCreate, request: Request):
    """Create a new automation. PROFESSIONAL TIER REQUIRED."""
    try:
        automation_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()
        
        automation = {
            "id": automation_id,
            "name": automation_data.name,
            "description": automation_data.description,
            "trigger_type": automation_data.trigger_type,
            "trigger_config": automation_data.trigger_config,
            "workflow_id": automation_data.workflow_id,
            "status": "active",
            "last_triggered": None,
            "created_at": now
        }
        
        automations_db[automation_id] = automation
        
        return {
            "success": True,
            "data": automation,
            "message": "Automation created successfully"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create automation: {str(e)}"
        )


@router.put("/{automation_id}")
@require_professional
async def update_automation(automation_id: str, automation_data: AutomationUpdate, request: Request):
    """Update an existing automation. PROFESSIONAL TIER REQUIRED."""
    automation = automations_db.get(automation_id)
    
    if not automation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Automation not found"
        )
    
    try:
        # Update fields
        if automation_data.name is not None:
            automation["name"] = automation_data.name
        if automation_data.description is not None:
            automation["description"] = automation_data.description
        if automation_data.trigger_config is not None:
            automation["trigger_config"] = automation_data.trigger_config
        if automation_data.status is not None:
            automation["status"] = automation_data.status
        
        automations_db[automation_id] = automation
        
        return {
            "success": True,
            "data": automation,
            "message": "Automation updated successfully"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update automation: {str(e)}"
        )


@router.delete("/{automation_id}")
@require_professional
async def delete_automation(automation_id: str, request: Request):
    """Delete an automation. PROFESSIONAL TIER REQUIRED."""
    automation = automations_db.pop(automation_id, None)
    
    if not automation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Automation not found"
        )
    
    return {
        "success": True,
        "message": "Automation deleted successfully"
    }


@router.post("/{automation_id}/toggle")
@require_professional
async def toggle_automation(automation_id: str, request: Request):
    """Toggle automation status (active/paused). PROFESSIONAL TIER REQUIRED."""
    automation = automations_db.get(automation_id)
    
    if not automation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Automation not found"
        )
    
    try:
        # Toggle status
        new_status = "paused" if automation["status"] == "active" else "active"
        automation["status"] = new_status
        automations_db[automation_id] = automation
        
        return {
            "success": True,
            "data": automation,
            "message": f"Automation {new_status}"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to toggle automation: {str(e)}"
        )
