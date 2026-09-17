"""
Audit Log Routes for Tiannara API

Endpoints for viewing and filtering audit logs.
Provides activity history and security monitoring.

Date: May 1, 2026
Status: Week 27 Day 5 - Audit Logging Implementation
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timedelta
import json

from tiannara_api.database import get_db
from tiannara_api.database.model_classes.audit_log import AuditLog, AuditAction
from tiannara_api.routes.auth import get_current_user

router = APIRouter(prefix="/audit", tags=["Audit Logs"])


@router.get("/logs", response_model=List[dict])
async def list_audit_logs(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
    action: Optional[str] = Query(None, description="Filter by action type"),
    resource_type: Optional[str] = Query(None, description="Filter by resource type"),
    user_email: Optional[str] = Query(None, description="Filter by user email"),
    start_date: Optional[str] = Query(None, description="Start date (ISO format)"),
    end_date: Optional[str] = Query(None, description="End date (ISO format)"),
    limit: int = Query(100, ge=1, le=1000, description="Number of logs to return"),
    offset: int = Query(0, ge=0, description="Offset for pagination")
):
    """
    List audit logs with filtering options.
    
    Requires admin privileges or workspace owner role.
    
    Args:
        current_user: Authenticated user
        db: Database session
        action: Filter by action type (e.g., "workspace.create")
        resource_type: Filter by resource type (e.g., "workspace")
        user_email: Filter by user email
        start_date: Start date filter (ISO format)
        end_date: End date filter (ISO format)
        limit: Max number of logs to return
        offset: Pagination offset
        
    Returns:
        List of audit log entries
    """
    try:
        user_id = current_user.get("user", {}).get("id")
        is_admin = current_user.get("user", {}).get("is_admin", False)
        
        # Build query
        query = db.query(AuditLog)
        
        # Apply filters
        if action:
            query = query.filter(AuditLog.action == action)
        
        if resource_type:
            query = query.filter(AuditLog.resource_type == resource_type)
        
        if user_email:
            query = query.filter(AuditLog.user_email.ilike(f"%{user_email}%"))
        
        if start_date:
            start_dt = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
            query = query.filter(AuditLog.created_at >= start_dt)
        
        if end_date:
            end_dt = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
            query = query.filter(AuditLog.created_at <= end_dt)
        
        # Non-admin users can only see their own logs
        if not is_admin:
            query = query.filter(AuditLog.user_id == user_id)
        
        # Order by most recent first
        query = query.order_by(AuditLog.created_at.desc())
        
        # Apply pagination
        logs = query.offset(offset).limit(limit).all()
        
        # Convert to dictionaries
        return [log.to_dict() for log in logs]
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve audit logs: {str(e)}"
        )


@router.get("/logs/{log_id}", response_model=dict)
async def get_audit_log_details(
    log_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get detailed information about a specific audit log entry.
    
    Args:
        log_id: Audit log ID
        current_user: Authenticated user
        db: Database session
        
    Returns:
        Audit log details
    """
    try:
        user_id = current_user.get("user", {}).get("id")
        is_admin = current_user.get("user", {}).get("is_admin", False)
        
        log = db.query(AuditLog).filter(AuditLog.id == log_id).first()
        
        if not log:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Audit log not found"
            )
        
        # Non-admin users can only view their own logs
        if not is_admin and log.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied"
            )
        
        return log.to_dict()
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve audit log: {str(e)}"
        )


@router.get("/workspace/{workspace_id}/activity", response_model=List[dict])
async def get_workspace_activity(
    workspace_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = Query(50, ge=1, le=500, description="Number of activities to return")
):
    """
    Get activity history for a specific workspace.
    
    Shows all actions performed in the workspace (creates, invites, etc.)
    
    Args:
        workspace_id: Workspace ID
        current_user: Authenticated user
        db: Database session
        limit: Max number of activities to return
        
    Returns:
        List of workspace activity logs
    """
    try:
        user_id = current_user.get("user", {}).get("id")
        
        # Verify user has access to this workspace
        from tiannara_api.database.model_classes.workspace import WorkspaceMember
        membership = db.query(WorkspaceMember).filter(
            WorkspaceMember.workspace_id == workspace_id,
            WorkspaceMember.user_id == user_id
        ).first()
        
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have access to this workspace"
            )
        
        # Get workspace-related logs
        logs = db.query(AuditLog).filter(
            AuditLog.resource_type == "workspace",
            AuditLog.resource_id == workspace_id
        ).order_by(
            AuditLog.created_at.desc()
        ).limit(limit).all()
        
        return [log.to_dict() for log in logs]
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve workspace activity: {str(e)}"
        )


@router.get("/security/alerts", response_model=List[dict])
async def get_security_alerts(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
    hours: int = Query(24, ge=1, le=168, description="Look back hours")
):
    """
    Get recent security alerts and suspicious activities.
    
    Requires admin privileges.
    
    Args:
        current_user: Authenticated user (must be admin)
        db: Database session
        hours: Number of hours to look back
        
    Returns:
        List of security alert logs
    """
    try:
        is_admin = current_user.get("user", {}).get("is_admin", False)
        
        if not is_admin:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Admin privileges required"
            )
        
        # Calculate time window
        cutoff_time = datetime.utcnow() - timedelta(hours=hours)
        
        # Get security-related logs
        security_actions = [
            AuditAction.AUTH_FAILED,
            AuditAction.PERMISSION_DENIED,
            AuditAction.RATE_LIMIT_EXCEEDED,
            AuditAction.SUSPICIOUS_ACTIVITY,
        ]
        
        logs = db.query(AuditLog).filter(
            AuditLog.action.in_(security_actions),
            AuditLog.created_at >= cutoff_time
        ).order_by(
            AuditLog.created_at.desc()
        ).all()
        
        return [log.to_dict() for log in logs]
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve security alerts: {str(e)}"
        )
