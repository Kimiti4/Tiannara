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


class EvolutionRunRequest(BaseModel):
    question: str = "Optimize prosthetic grip stability"
    population_size: int = Field(default=24, ge=6, le=200)
    generations: int = Field(default=12, ge=1, le=200)
    fitness_function: str = "grip_stability"
    genome_type: str = "neural"


class AutonomousCycleRequest(BaseModel):
    question: str = Field(default="Optimize prosthetic grip stability", min_length=3)
    text: Optional[str] = None
    source: str = "autonomous_lab"
    population_size: int = Field(default=24, ge=6, le=200)
    generations: int = Field(default=12, ge=1, le=200)
    fitness_function: str = "grip_stability"
    workers: int = Field(default=4, ge=1, le=16)
    genome_type: str = "mixed"
