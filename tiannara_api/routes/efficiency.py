"""
Efficiency Features API - REST endpoints for email, reports, and code assistance.

Provides production-ready API endpoints for:
- Email generation assistant
- Report generation from data
- Code explanation and debugging help
- Task automation workflows

Usage:
    from tiannara_api.routes.efficiency import router
    
    # Add to FastAPI app
    app.include_router(router, prefix="/api/v1/efficiency")
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
import logging

from tiannara_core.evaluation.efficiency_features import (
    EmailAssistant,
    ReportGenerator,
    CodeAssistant
)

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/efficiency",
    tags=["efficiency", "productivity", "automation"],
    responses={404: {"description": "Not found"}},
)

# Initialize assistants (singleton pattern)
_email_assistant = None
_report_generator = None
_code_helper = None


def get_email_assistant() -> EmailAssistant:
    """Get or create email assistant singleton."""
    global _email_assistant
    if _email_assistant is None:
        _email_assistant = EmailAssistant()
    return _email_assistant


def get_report_generator() -> ReportGenerator:
    """Get or create report generator singleton."""
    global _report_generator
    if _report_generator is None:
        _report_generator = ReportGenerator()
    return _report_generator


def get_code_helper() -> CodeAssistant:  # Changed return type
    """Get or create code helper singleton."""
    global _code_helper
    if _code_helper is None:
        _code_helper = CodeAssistant()  # Changed from CodeHelper()
    return _code_helper


# ============================================================================
# Request/Response Models
# ============================================================================

class EmailRequest(BaseModel):
    """Email generation request."""
    purpose: str = Field(..., description="Email purpose: follow_up, meeting_request, status_update, etc.")
    recipient: str = Field(..., description="Recipient name")
    sender: str = Field(..., description="Sender name")
    tone: str = Field(default="professional", description="Tone: professional, casual, formal, friendly")
    context: Optional[Dict[str, Any]] = Field(default=None, description="Additional context")
    topic: Optional[str] = Field(default=None, description="Email topic")


class EmailResponse(BaseModel):
    """Email generation response."""
    success: bool
    subject: str
    body: str
    full_email: str
    word_count: int
    estimated_reading_time_seconds: int


class ReportRequest(BaseModel):
    """Report generation request."""
    report_type: str = Field(..., description="Type: status_update, performance_analysis, experiment_results")
    title: str = Field(..., description="Report title")
    data_points: Optional[List[Dict[str, Any]]] = Field(default=None, description="Data to include")
    audience: str = Field(default="executive", description="Audience: executive, technical, general")
    sections: Optional[List[str]] = Field(default=None, description="Required sections")


class ReportResponse(BaseModel):
    """Report generation response."""
    success: bool
    title: str
    content: str
    format: str
    section_count: int
    word_count: int


class CodeExplanationRequest(BaseModel):
    """Code explanation request."""
    code: str = Field(..., description="Code to explain")
    language: str = Field(default="python", description="Programming language")
    explanation_level: str = Field(default="intermediate", description="Level: beginner, intermediate, advanced")
    include_examples: bool = Field(default=True, description="Include usage examples")


class CodeDebugRequest(BaseModel):
    """Code debugging request."""
    code: str = Field(..., description="Code with issues")
    error_message: Optional[str] = Field(default=None, description="Error message if any")
    expected_behavior: Optional[str] = Field(default=None, description="What code should do")


class CodeResponse(BaseModel):
    """Code assistance response."""
    success: bool
    explanation: Optional[str] = None
    suggestions: Optional[List[str]] = None
    fixed_code: Optional[str] = None
    complexity: Optional[str] = None


# ============================================================================
# API Endpoints
# ============================================================================

@router.post("/email/generate", response_model=EmailResponse)
async def generate_email(request: EmailRequest):
    """
    Generate professional email based on intent and context.
    
    Automates email writing for common business scenarios.
    
    **Example:**
    ```json
    {
        "purpose": "follow_up",
        "recipient": "John Smith",
        "sender": "Jane Doe",
        "tone": "professional",
        "topic": "project proposal",
        "context": {
            "timeframe": "last week"
        }
    }
    ```
    """
    try:
        assistant = get_email_assistant()
        
        # Generate email
        result = assistant.generate_email(
            purpose=request.purpose,
            recipient=request.recipient,
            sender=request.sender,
            tone=request.tone,
            topic=request.topic,
            context=request.context or {}
        )
        
        # Calculate metrics
        word_count = len(result["body"].split())
        reading_time = int(word_count / 3.5)  # Average reading speed
        
        return EmailResponse(
            success=True,
            subject=result["subject"],
            body=result["body"],
            full_email=result["full_email"],
            word_count=word_count,
            estimated_reading_time_seconds=reading_time
        )
        
    except Exception as e:
        logger.error(f"Email generation failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to generate email: {str(e)}")


@router.post("/report/generate", response_model=ReportResponse)
async def generate_report(request: ReportRequest):
    """
    Generate structured report from data points.
    
    Creates professional reports with sections, analysis, and recommendations.
    
    **Example:**
    ```json
    {
        "report_type": "performance_analysis",
        "title": "Q1 Performance Review",
        "audience": "executive",
        "data_points": [
            {"metric": "revenue", "value": 1250000, "change": "+15%"},
            {"metric": "users", "value": 45000, "change": "+22%"}
        ]
    }
    ```
    """
    try:
        generator = get_report_generator()
        
        # Generate report
        result = generator.generate_report(
            report_type=request.report_type,
            title=request.title,
            data_points=request.data_points or [],
            audience=request.audience,
            sections=request.sections
        )
        
        # Calculate metrics
        word_count = len(result["content"].split())
        section_count = result["content"].count("## ")
        
        return ReportResponse(
            success=True,
            title=result["title"],
            content=result["content"],
            format=result.get("format", "markdown"),
            section_count=section_count,
            word_count=word_count
        )
        
    except Exception as e:
        logger.error(f"Report generation failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to generate report: {str(e)}")


@router.post("/code/explain", response_model=CodeResponse)
async def explain_code(request: CodeExplanationRequest):
    """
    Explain code in natural language.
    
    Makes code understandable for non-developers or learning purposes.
    
    **Example:**
    ```json
    {
        "code": "def fibonacci(n):\n    if n <= 1:\n        return n\n    return fibonacci(n-1) + fibonacci(n-2)",
        "language": "python",
        "explanation_level": "beginner",
        "include_examples": true
    }
    ```
    """
    try:
        helper = get_code_helper()
        
        # Generate explanation
        result = helper.explain_code(
            code=request.code,
            language=request.language,
            level=request.explanation_level,
            include_examples=request.include_examples
        )
        
        return CodeResponse(
            success=True,
            explanation=result["explanation"],
            complexity=result.get("complexity", "unknown")
        )
        
    except Exception as e:
        logger.error(f"Code explanation failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to explain code: {str(e)}")


@router.post("/code/debug", response_model=CodeResponse)
async def debug_code(request: CodeDebugRequest):
    """
    Debug code and suggest fixes.
    
    Analyzes code for common issues and provides solutions.
    
    **Example:**
    ```json
    {
        "code": "def divide(a, b):\n    return a / b",
        "error_message": "ZeroDivisionError: division by zero",
        "expected_behavior": "Should handle division by zero gracefully"
    }
    ```
    """
    try:
        helper = get_code_helper()
        
        # Analyze and fix
        result = helper.debug_code(
            code=request.code,
            error_message=request.error_message,
            expected_behavior=request.expected_behavior
        )
        
        return CodeResponse(
            success=True,
            explanation=result.get("issue_description"),
            suggestions=result.get("suggestions", []),
            fixed_code=result.get("fixed_code")
        )
        
    except Exception as e:
        logger.error(f"Code debugging failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to debug code: {str(e)}")


@router.get("/templates/email")
async def get_email_templates():
    """Get available email templates."""
    try:
        assistant = get_email_assistant()
        templates = assistant.get_available_templates()
        
        return {
            "success": True,
            "templates": templates,
            "count": len(templates)
        }
        
    except Exception as e:
        logger.error(f"Failed to get templates: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/stats")
async def get_efficiency_stats():
    """Get efficiency feature usage statistics."""
    try:
        # TODO: Integrate with actual usage tracking
        return {
            "success": True,
            "stats": {
                "emails_generated": 0,
                "reports_created": 0,
                "code_explanations": 0,
                "bugs_fixed": 0,
                "time_saved_hours": 0
            },
            "message": "Statistics tracking will be enabled with database integration"
        }
        
    except Exception as e:
        logger.error(f"Failed to get stats: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/health")
async def health_check():
    """Health check for efficiency features."""
    return {
        "status": "healthy",
        "components": {
            "email_assistant": "ready",
            "report_generator": "ready",
            "code_helper": "ready"
        },
        "timestamp": datetime.now().isoformat()
    }
