"""
Workflow management endpoints for Tiannara SaaS.
Handles CRUD operations for user workflows with Tiannara Core integration.

STARTER TIER REQUIRED - Core AI workflows available to Starter+
"""
from fastapi import APIRouter, HTTPException, Depends, status, Request
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
import uuid
import json
from tiannara_api.middleware.tier_access_control import require_starter
from tiannara_api.routes.workflow_executor import get_workflow_executor, ExecutionMode

import logging

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/workflows",
    tags=["workflows"],
)

# In-memory storage (will be replaced with database in production)
workflows_db: Dict[str, dict] = {}
executions_db: List[dict] = []


class WorkflowRunRequest(BaseModel):
    input_data: Dict[str, Any] = Field(default_factory=dict)
    execution_mode: str = Field(default="sequential", pattern="^(sequential|parallel|hybrid)$")


class WorkflowCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    description: str = Field(default="", max_length=1000)
    nodes: List[Dict[str, Any]] = Field(default_factory=list)
    edges: List[Dict[str, Any]] = Field(default_factory=list)


class WorkflowUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    nodes: Optional[List[Dict[str, Any]]] = None
    edges: Optional[List[Dict[str, Any]]] = None
    status: Optional[str] = None


class TemplateDeployRequest(BaseModel):
    """Request to deploy a workflow from template."""
    template_id: str = Field(..., description="ID of the template to deploy")


class WorkflowExecuteRequest(BaseModel):
    """Request to execute a deployed workflow through Tiannara Core."""
    workflow_id: str = Field(..., description="ID of the workflow to execute")
    input_data: Dict[str, Any] = Field(default_factory=dict, description="Input data for workflow execution")
    execution_mode: str = Field(default="sequential", pattern="^(sequential|parallel|hybrid)$")


@router.get("/")
@require_starter
async def get_workflows(request: Request):
    """Get all workflows for the authenticated user. STARTER TIER REQUIRED."""
    try:
        # TODO: Filter by user_id from JWT token
        workflows = list(workflows_db.values())
        
        return {
            "success": True,
            "data": workflows,
            "count": len(workflows)
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch workflows: {str(e)}"
        )


@router.get("/{workflow_id}")
@require_starter
async def get_workflow(workflow_id: str, request: Request):
    """Get a specific workflow by ID. STARTER TIER REQUIRED."""
    workflow = workflows_db.get(workflow_id)
    
    if not workflow:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Workflow not found"
        )
    
    return {
        "success": True,
        "data": workflow
    }


@router.post("/", status_code=status.HTTP_201_CREATED)
@require_starter
async def create_workflow(workflow_data: WorkflowCreate, request: Request):
    """Create a new workflow. STARTER TIER REQUIRED."""
    try:
        workflow_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()
        
        workflow = {
            "id": workflow_id,
            "name": workflow_data.name,
            "description": workflow_data.description,
            "nodes": workflow_data.nodes,
            "edges": workflow_data.edges,
            "status": "draft",
            "created_at": now,
            "updated_at": now,
            "last_run": None,
            "run_count": 0
        }
        
        workflows_db[workflow_id] = workflow
        
        return {
            "success": True,
            "data": workflow,
            "message": "Workflow created successfully"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create workflow: {str(e)}"
        )


@router.put("/{workflow_id}")
@require_starter
async def update_workflow(workflow_id: str, workflow_data: WorkflowUpdate, request: Request):
    """Update an existing workflow. STARTER TIER REQUIRED."""
    workflow = workflows_db.get(workflow_id)
    
    if not workflow:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Workflow not found"
        )
    
    try:
        # Update fields
        if workflow_data.name is not None:
            workflow["name"] = workflow_data.name
        if workflow_data.description is not None:
            workflow["description"] = workflow_data.description
        if workflow_data.nodes is not None:
            workflow["nodes"] = workflow_data.nodes
        if workflow_data.edges is not None:
            workflow["edges"] = workflow_data.edges
        if workflow_data.status is not None:
            workflow["status"] = workflow_data.status
        
        workflow["updated_at"] = datetime.now(timezone.utc).isoformat()
        workflows_db[workflow_id] = workflow
        
        return {
            "success": True,
            "data": workflow,
            "message": "Workflow updated successfully"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update workflow: {str(e)}"
        )


@router.delete("/{workflow_id}")
@require_starter
async def delete_workflow(workflow_id: str, request: Request):
    """Delete a workflow. STARTER TIER REQUIRED."""
    workflow = workflows_db.pop(workflow_id, None)
    
    if not workflow:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Workflow not found"
        )
    
    return {
        "success": True,
        "message": "Workflow deleted successfully"
    }


@router.post("/{workflow_id}/run")
@require_starter
async def run_workflow(workflow_id: str, run_data: Optional[WorkflowRunRequest] = None, request: Request = None):
    """Execute a workflow through Tiannara Core engines. STARTER TIER REQUIRED."""
    workflow = workflows_db.get(workflow_id)
    
    if not workflow:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Workflow not found"
        )
    
    try:
        # Get executor
        executor = get_workflow_executor()
        
        # Prepare execution data
        input_data = run_data.input_data if run_data else {}
        execution_mode = ExecutionMode(run_data.execution_mode) if run_data else ExecutionMode.SEQUENTIAL
        
        # Execute workflow through Tiannara Core
        result = await executor.execute_workflow(
            workflow_id=workflow_id,
            nodes=workflow["nodes"],
            edges=workflow["edges"],
            input_data=input_data,
            execution_mode=execution_mode
        )
        
        # Update workflow stats
        workflow["last_run"] = datetime.now(timezone.utc).isoformat()
        workflow["run_count"] += 1
        workflow["status"] = "active"
        workflows_db[workflow_id] = workflow
        
        # Store execution record
        execution_record = {
            "id": result.execution_id,
            "workflow_id": workflow_id,
            "status": result.status,
            "started_at": result.started_at,
            "completed_at": result.completed_at,
            "total_execution_time_ms": result.total_execution_time_ms,
            "node_results": {nid: node.to_dict() for nid, node in result.nodes.items()},
            "error": result.error
        }
        executions_db.append(execution_record)
        
        return {
            "success": True,
            "data": {
                "execution_id": result.execution_id,
                "status": result.status,
                "started_at": result.started_at,
                "completed_at": result.completed_at,
                "total_execution_time_ms": result.total_execution_time_ms,
                "nodes": {nid: node.to_dict() for nid, node in result.nodes.items()},
                "error": result.error
            },
            "message": f"Workflow executed successfully in {result.total_execution_time_ms:.0f}ms"
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to run workflow: {str(e)}"
        )


@router.get("/{workflow_id}/executions")
@require_starter
async def get_workflow_executions(workflow_id: str, request: Request, limit: int = 20):
    """Get execution history for a workflow. STARTER TIER REQUIRED."""
    workflow = workflows_db.get(workflow_id)
    
    if not workflow:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Workflow not found"
        )
    
    try:
        # Filter executions for this workflow
        workflow_executions = [e for e in executions_db if e["workflow_id"] == workflow_id]
        
        # Sort by started_at descending
        workflow_executions.sort(key=lambda x: x.get("started_at", ""), reverse=True)
        
        # Limit results
        recent_executions = workflow_executions[:limit]
        
        return {
            "success": True,
            "data": recent_executions,
            "count": len(recent_executions),
            "total": len(workflow_executions)
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch executions: {str(e)}"
        )


@router.get("/executions/{execution_id}")
@require_starter
async def get_execution_details(execution_id: str, request: Request):
    """Get detailed results for a specific execution. STARTER TIER REQUIRED."""
    # Find execution
    execution = None
    for e in executions_db:
        if e["id"] == execution_id:
            execution = e
            break
    
    if not execution:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Execution not found"
        )
    
    return {
        "success": True,
        "data": execution
    }


@router.post("/from-template")
@require_starter
async def create_workflow_from_template(
    request_data: TemplateDeployRequest,
    request: Request
):
    """
    Create a new workflow from a template.
    
    This endpoint:
    1. Loads the template definition
    2. Creates a new workflow with the template's nodes and edges
    3. Returns the workflow ID for redirect to builder
    
    STARTER TIER REQUIRED.
    """
    try:
        # Import templates
        import sys
        from pathlib import Path
        sys.path.insert(0, str(Path(__file__).parent.parent.parent / "tiannara_saas"))
        
        from lib.workflow_templates import WORKFLOW_TEMPLATES
        
        # Find the template
        template = None
        for t in WORKFLOW_TEMPLATES:
            if t.id == request_data.template_id:
                template = t
                break
        
        if not template:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Template '{request_data.template_id}' not found"
            )
        
        # Get user info from request context
        user_info = request.state.user_info if hasattr(request.state, 'user_info') else {
            "id": "user_demo",
            "email": "demo@tiannara.com"
        }
        
        # Create workflow from template
        workflow_id = f"wf_{uuid.uuid4().hex[:12]}"
        
        workflow = {
            "id": workflow_id,
            "name": template.name,
            "description": template.description,
            "nodes": [node.dict() if hasattr(node, 'dict') else node for node in template.nodes],
            "edges": [edge.dict() if hasattr(edge, 'dict') else edge for edge in template.edges],
            "status": "draft",
            "created_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat(),
            "user_id": user_info.get("id"),
            "template_id": template.id,
            "last_run": None,
            "run_count": 0
        }
        
        # Store workflow
        workflows_db[workflow_id] = workflow
        
        logger.info(f"✅ Workflow created from template: {workflow_id} (Template: {template.id})")
        
        return {
            "success": True,
            "workflow_id": workflow_id,
            "message": f"Workflow '{template.name}' created successfully"
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to create workflow from template: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create workflow: {str(e)}"
        )


@router.get("/executions/{execution_id}")
@require_starter
async def get_execution_details(
    execution_id: str,
    request: Request
):
    """
    Fetch detailed execution results by execution ID.
    
    Returns complete execution trace with node results,
    timing information, and any errors encountered.
    
    STARTER TIER REQUIRED.
    """
    try:
        # Search for execution in database
        execution = None
        for exec_record in executions_db:
            if exec_record.get("execution_id") == execution_id:
                execution = exec_record
                break
        
        if not execution:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Execution '{execution_id}' not found"
            )
        
        return {
            "success": True,
            "data": execution
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to fetch execution details: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch execution: {str(e)}"
        )


@router.post("/execute")
@require_starter
async def execute_workflow(
    request_data: WorkflowExecuteRequest,
    request: Request
):
    """
    Execute a deployed workflow through Tiannara Core engines.
    
    This endpoint:
    1. Loads the workflow definition
    2. Maps nodes to Tiannara Core intelligence domains
    3. Executes the workflow using the Workflow Executor
    4. Returns execution results with reasoning traces
    
    STARTER TIER REQUIRED.
    """
    try:
        # Get workflow from database
        workflow = workflows_db.get(request_data.workflow_id)
        if not workflow:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Workflow '{request_data.workflow_id}' not found"
            )
        
        # Get workflow executor
        executor = get_workflow_executor()
        
        # Convert execution mode string to enum
        exec_mode = ExecutionMode(request_data.execution_mode)
        
        # Execute workflow
        result = await executor.execute_workflow(
            workflow_id=request_data.workflow_id,
            nodes=workflow.get("nodes", []),
            edges=workflow.get("edges", []),
            input_data=request_data.input_data,
            execution_mode=exec_mode
        )
        
        # Store execution result
        execution_record = {
            "execution_id": result.execution_id,
            "workflow_id": result.workflow_id,
            "status": result.status,
            "started_at": result.started_at,
            "completed_at": result.completed_at,
            "total_execution_time_ms": result.total_execution_time_ms,
            "nodes": {nid: node.to_dict() for nid, node in result.nodes.items()},
            "error": result.error
        }
        executions_db.append(execution_record)
        
        # Update workflow stats
        workflow["last_run"] = datetime.now(timezone.utc).isoformat()
        workflow["run_count"] = workflow.get("run_count", 0) + 1
        workflows_db[request_data.workflow_id] = workflow
        
        logger.info(f"✅ Workflow executed: {result.execution_id} (Status: {result.status})")
        
        return {
            "success": True,
            "execution_id": result.execution_id,
            "status": result.status,
            "started_at": result.started_at,
            "completed_at": result.completed_at,
            "total_execution_time_ms": result.total_execution_time_ms,
            "nodes": execution_record["nodes"],
            "error": result.error,
            "message": f"Workflow execution {result.status}"
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Failed to execute workflow: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to execute workflow: {str(e)}"
        )
        
    except HTTPException:
        raise
    except ImportError as e:
        # Fallback if import fails - create mock workflow
        logger.error(f"⚠️  Template import failed: {e}, creating mock workflow")
        
        workflow_id = f"wf_{uuid.uuid4().hex[:12]}"
        workflow = {
            "id": workflow_id,
            "name": f"Workflow from {request_data.template_id}",
            "description": "Created from template",
            "nodes": [],
            "edges": [],
            "status": "draft",
            "created_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat(),
            "user_id": "user_demo",
            "template_id": request_data.template_id,
            "last_run": None,
            "run_count": 0
        }
        
        workflows_db[workflow_id] = workflow
        
        return {
            "success": True,
            "workflow_id": workflow_id,
            "message": "Workflow created (mock mode)"
        }
    except Exception as e:
        logger.error(f"❌ Error creating workflow from template: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create workflow from template: {str(e)}"
        )
