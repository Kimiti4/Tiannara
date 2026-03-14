from __future__ import annotations
from pydantic import BaseModel, Field
from typing import Dict, Any, Optional


class DiscoveryAnalyzeRequest(BaseModel):
    question: str = Field(..., min_length=3)
    text: Optional[str] = None
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
    modules: list[str]


class DiscoveryMemoryItem(BaseModel):
    id: str
    ts: float
    question: str
    source: str
    tags: list[str] = []


class DiscoveryMemoryListResponse(BaseModel):
    items: list[DiscoveryMemoryItem]


class DiscoveryMemoryGetResponse(BaseModel):
    item: Dict[str, Any]