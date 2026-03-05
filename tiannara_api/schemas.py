from __future__ import annotations
from pydantic import BaseModel, Field
from typing import Dict, Any, Optional, List


class DiscoveryAnalyzeRequest(BaseModel):
    question: str = Field(..., min_length=3)
    text: Optional[str] = None  # optional raw text to ingest
    source: str = "user_input"


class DiscoveryAnalyzeResponse(BaseModel):
    report: Dict[str, Any]
    approved: bool
    reason: str
    alignment_score: float


class ModuleToggleRequest(BaseModel):
    enabled: bool


class StatusResponse(BaseModel):
    status: str
    version: str
    modules: List[str]