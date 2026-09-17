"""
WebSocket endpoint for real-time workflow execution progress streaming.

Provides live updates during workflow execution:
- Node status changes (pending → running → completed/failed)
- Execution progress percentage
- Real-time results from each node
- Error notifications

Date: May 1, 2026
Status: Week 30 - Real-Time Streaming Implementation
"""

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import Dict, List
import asyncio
import json
import logging
from datetime import datetime, timezone

from tiannara_api.security.websocket_auth import require_websocket_auth

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/ws",
    tags=["websocket"],
)

# Connection manager for WebSocket connections
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = {}
    
    async def connect(self, websocket: WebSocket, execution_id: str):
        await websocket.accept()
        if execution_id not in self.active_connections:
            self.active_connections[execution_id] = []
        self.active_connections[execution_id].append(websocket)
    
    def disconnect(self, websocket: WebSocket, execution_id: str):
        if execution_id in self.active_connections:
            self.active_connections[execution_id].remove(websocket)
            if not self.active_connections[execution_id]:
                del self.active_connections[execution_id]
    
    async def broadcast(self, execution_id: str, message: dict):
        """Send message to all clients subscribed to an execution."""
        if execution_id in self.active_connections:
            disconnected = []
            for connection in self.active_connections[execution_id]:
                try:
                    await connection.send_json(message)
                except Exception:
                    disconnected.append(connection)
            
            # Clean up disconnected clients
            for conn in disconnected:
                self.disconnect(conn, execution_id)

manager = ConnectionManager()


@router.websocket("/workflow/{execution_id}")
async def workflow_progress_websocket(websocket: WebSocket, execution_id: str):
    """
    WebSocket endpoint for real-time workflow execution progress.
    
    Clients connect to receive live updates about workflow execution:
    - Node execution status
    - Progress percentage
    - Intermediate results
    - Errors
    
    Example client usage:
    ```javascript
    const ws = new WebSocket('ws://localhost:8004/ws/workflow/exec_123');
    ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        console.log('Progress:', data);
    };
    ```
    """
    user = await require_websocket_auth(websocket)
    if not user:
        return

    await manager.connect(websocket, execution_id)
    
    try:
        # Send initial connection confirmation
        await websocket.send_json({
            "type": "connected",
            "execution_id": execution_id,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "message": "Connected to execution stream"
        })
        
        # Keep connection alive and listen for client messages
        while True:
            data = await websocket.receive_text()
            
            # Handle client messages (e.g., pause, cancel)
            try:
                message = json.loads(data)
                
                if message.get("type") == "ping":
                    await websocket.send_json({
                        "type": "pong",
                        "timestamp": datetime.now(timezone.utc).isoformat()
                    })
                elif message.get("type") == "unsubscribe":
                    break
                    
            except json.JSONDecodeError:
                pass
    
    except WebSocketDisconnect:
        manager.disconnect(websocket, execution_id)
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        manager.disconnect(websocket, execution_id)


async def send_execution_update(execution_id: str, update: dict):
    """
    Helper function to send execution updates to connected clients.
    
    This should be called by the workflow executor during execution.
    
    Args:
        execution_id: ID of the execution
        update: Update data to send
    """
    message = {
        "type": "execution_update",
        "execution_id": execution_id,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        **update
    }
    await manager.broadcast(execution_id, message)


async def send_node_update(execution_id: str, node_id: str, status: str, result: dict = None):
    """
    Send node-specific update to clients.
    
    Args:
        execution_id: ID of the execution
        node_id: ID of the node
        status: Node status (running, completed, failed)
        result: Optional node result data
    """
    update = {
        "update_type": "node_status",
        "node_id": node_id,
        "status": status,
        "result": result
    }
    await send_execution_update(execution_id, update)


async def send_progress_update(execution_id: str, progress: float, completed_nodes: int = None, total_nodes: int = None):
    """
    Send overall progress update to clients.
    
    Args:
        execution_id: ID of the execution
        progress: Progress percentage (0-100)
        completed_nodes: Number of completed nodes (optional)
        total_nodes: Total number of nodes (optional)
    """
    update = {
        "update_type": "progress",
        "progress": progress,
        "completed_nodes": completed_nodes,
        "total_nodes": total_nodes
    }
    await send_execution_update(execution_id, update)


async def send_execution_complete(execution_id: str, status: str, total_time_ms: int):
    """
    Send execution completion notification.
    
    Args:
        execution_id: ID of the execution
        status: Final status (completed, failed)
        total_time_ms: Total execution time in milliseconds
    """
    update = {
        "update_type": "execution_complete",
        "status": status,
        "total_execution_time_ms": total_time_ms
    }
    await send_execution_update(execution_id, update)


async def send_error_update(execution_id: str, error: str, node_id: str = None):
    """
    Send error notification to clients.
    
    Args:
        execution_id: ID of the execution
        error: Error message
        node_id: Optional node ID where error occurred
    """
    update = {
        "update_type": "error",
        "error": error,
        "node_id": node_id
    }
    await send_execution_update(execution_id, update)
