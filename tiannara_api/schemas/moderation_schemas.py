"""
Pydantic schemas for moderation service API

Defines request/response models with validation.
"""

from pydantic import BaseModel, Field, validator
from typing import List, Optional


class ModerationRequest(BaseModel):
    """Request model for content moderation"""
    content: str = Field(
        ...,
        min_length=1,
        max_length=10000,
        description="Text content to analyze for moderation"
    )
    
    @validator('content')
    def content_must_not_be_empty(cls, v):
        if not v or not v.strip():
            raise ValueError('Content cannot be empty')
        return v.strip()


class ModerationResponse(BaseModel):
    """Response model for content moderation"""
    safe: bool = Field(..., description="Whether content is safe")
    toxicity_score: float = Field(..., ge=0.0, le=1.0, description="Toxicity score (0-1)")
    spam_probability: float = Field(..., ge=0.0, le=1.0, description="Spam probability (0-1)")
    scam_probability: float = Field(..., ge=0.0, le=1.0, description="Scam probability (0-1)")
    categories_flagged: List[str] = Field(..., description="List of flagged categories")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Confidence in the decision")
    explanation: str = Field(..., description="Human-readable explanation")
    
    class Config:
        schema_extra = {
            "example": {
                "safe": True,
                "toxicity_score": 0.15,
                "spam_probability": 0.05,
                "scam_probability": 0.02,
                "categories_flagged": [],
                "confidence": 0.9,
                "explanation": "Content appears safe. No significant issues detected."
            }
        }


class BatchModerationRequest(BaseModel):
    """Request model for batch moderation"""
    contents: List[str] = Field(
        ...,
        min_items=1,
        max_items=100,
        description="List of text contents to analyze"
    )


class BatchModerationResponse(BaseModel):
    """Response model for batch moderation"""
    results: List[ModerationResponse] = Field(..., description="List of moderation results")
    total_analyzed: int = Field(..., description="Total number of items analyzed")
    flagged_count: int = Field(..., description="Number of items flagged")
