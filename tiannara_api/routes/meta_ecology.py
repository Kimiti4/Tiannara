from fastapi import APIRouter, WebSocket
from typing import Dict, Any
from pydantic import BaseModel
import asyncio

router = APIRouter(tags=["Meta Ecology"])

# Global state to hold ingested Elixir telemetry.
# This object is streamed as-is to the dashboard (truth-first pass-through).
ELIXIR_TELEMETRY_STATE: Dict[str, Any] = {}

class MutateRequest(BaseModel):
    law_type: str = "law"
    intensity: float = 1.0

@router.post("/ingest")
async def ingest_telemetry(payload: Dict[str, Any]):
    """Receives telemetry from Elixir UniverseServer and stores it verbatim."""
    global ELIXIR_TELEMETRY_STATE
    ELIXIR_TELEMETRY_STATE = payload

    return {"status": "ok"}

@router.websocket("/stream")
async def websocket_meta_ecology_stream(websocket: WebSocket):
    """
    Real-time streaming endpoint for the Meta-Ecology dashboard.
    Emits raw telemetry directly from Elixir core.
    """
    await websocket.accept()
    
    try:
        while True:
            await websocket.send_json(ELIXIR_TELEMETRY_STATE)
            await asyncio.sleep(1.0)  # Tick every 1s
            
    except Exception as e:
        print(f"WebSocket disconnected: {e}")
