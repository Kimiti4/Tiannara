"""
Fallback Planner System

Provides deterministic planning when LLM is unavailable or fails.
Ensures Tiannara can continue operating even with poor LLM responses.
"""

from typing import Dict, Any, Optional, List
from dataclasses import dataclass
from datetime import datetime
import re
import os
from pathlib import Path


@dataclass
class PlanStep:
    """Represents a single step in a plan."""
    id: str
    description: str
    tool: str
    action: str
    params: Dict[str, Any]
    depends_on: List[str]
    requires_approval: bool = False


@dataclass
class ExecutionPlan:
    """Complete execution plan."""
    intent: str
    steps: List[PlanStep]
    success_criteria: str
    fallback_instructions: str


def deterministic_plan(intent: str, context: Optional[Dict[str, Any]] = None) -> Optional[ExecutionPlan]:
    """
    Create a deterministic plan based on intent keywords.
    
    Args:
        intent: Natural language intent from user
        context: Additional context information
        
    Returns:
        ExecutionPlan if recognized, None otherwise
    """
    intent_lower = intent.lower().strip()
    context = context or {}
    
    # Handle file operations
    if "save" in intent_lower or "write" in intent_lower or "create file" in intent_lower:
        return _create_file_save_plan(intent, context)
    
    # Handle read operations
    elif "read" in intent_lower or "show" in intent_lower or "display" in intent_lower:
        return _create_read_plan(intent, context)
    
    # Handle list operations
    elif "list" in intent_lower or "show all" in intent_lower:
        return _create_list_plan(intent, context)
    
    # Handle delete operations
    elif "delete" in intent_lower or "remove" in intent_lower:
        return _create_delete_plan(intent, context)
    
    # Handle search operations
    elif "search" in intent_lower or "find" in intent_lower:
        return _create_search_plan(intent, context)
    
    # Handle math calculations
    elif any(op in intent_lower for op in ["calculate", "compute", "math", "+", "-", "*", "/"]):
        return _create_calculation_plan(intent, context)
    
    # Default catch-all plan
    else:
        return _create_default_plan(intent, context)


def _create_file_save_plan(intent: str, context: Dict[str, Any]) -> ExecutionPlan:
    """Create a plan for saving/writing files."""
    # Extract potential file path and content from intent
    path_match = re.search(r'([\.\/\w\-_]+\.\w+)', intent)
    path = path_match.group(1) if path_match else "./output.txt"
    
    # Extract content - anything after "save" or "write"
    content_sources = ["save (.+)", "write (.+)", "create (.+)"]
    content = "Default content"
    
    for pattern in content_sources:
        match = re.search(pattern, intent, re.IGNORECASE)
        if match:
            content = match.group(1).strip()
            break
    
    # If content is still default, use the full intent as content
    if content == "Default content":
        content = intent
    
    step = PlanStep(
        id="save_file_1",
        description=f"Save content to file: {path}",
        tool="file_system",
        action="write_file",
        params={
            "path": path,
            "content": content
        },
        depends_on=[],
        requires_approval=False
    )
    
    return ExecutionPlan(
        intent=intent,
        steps=[step],
        success_criteria=f"File {path} created successfully",
        fallback_instructions="none"
    )


def _create_read_plan(intent: str, context: Dict[str, Any]) -> ExecutionPlan:
    """Create a plan for reading files or showing information."""
    # Extract potential file path
    path_match = re.search(r'([\.\/\w\-_]+\.\w+)', intent)
    path = path_match.group(1) if path_match else "./input.txt"
    
    step = PlanStep(
        id="read_file_1",
        description=f"Read content from file: {path}",
        tool="file_system",
        action="read_file",
        params={
            "path": path
        },
        depends_on=[],
        requires_approval=False
    )
    
    return ExecutionPlan(
        intent=intent,
        steps=[step],
        success_criteria=f"Content from {path} displayed",
        fallback_instructions="none"
    )


def _create_list_plan(intent: str, context: Dict[str, Any]) -> ExecutionPlan:
    """Create a plan for listing files or directories."""
    # Extract directory path or default to current
    path_match = re.search(r'(?:in|from|directory)\s+([\.\/\w\-_]+)', intent, re.IGNORECASE)
    path = path_match.group(1) if path_match else "."
    
    step = PlanStep(
        id="list_directory_1",
        description=f"List contents of directory: {path}",
        tool="file_system",
        action="list_directory",
        params={
            "path": path
        },
        depends_on=[],
        requires_approval=False
    )
    
    return ExecutionPlan(
        intent=intent,
        steps=[step],
        success_criteria=f"Contents of {path} listed",
        fallback_instructions="none"
    )


def _create_delete_plan(intent: str, context: Dict[str, Any]) -> ExecutionPlan:
    """Create a plan for deleting files."""
    # Extract potential file path
    path_match = re.search(r'([\.\/\w\-_]+\.\w+)', intent)
    path = path_match.group(1) if path_match else None
    
    if not path:
        # If no file path, we can't create a valid deletion plan
        step = PlanStep(
            id="invalid_delete_1",
            description="Invalid deletion request - no file specified",
            tool="console",
            action="output",
            params={
                "message": "Cannot delete: no file path specified in intent"
            },
            depends_on=[],
            requires_approval=False
        )
    else:
        step = PlanStep(
            id="delete_file_1",
            description=f"Delete file: {path}",
            tool="file_system",
            action="delete_file",
            params={
                "path": path
            },
            depends_on=[],
            requires_approval=True  # Require approval for deletions
        )
    
    return ExecutionPlan(
        intent=intent,
        steps=[step],
        success_criteria=f"File {path} deleted successfully" if path else "Deletion prevented due to missing path",
        fallback_instructions="none"
    )


def _create_search_plan(intent: str, context: Dict[str, Any]) -> ExecutionPlan:
    """Create a plan for searching content."""
    # Extract search term
    term_match = re.search(r'(?:for|about|searching for)\s+(.+?)(?:\s|$)', intent, re.IGNORECASE)
    search_term = term_match.group(1) if term_match else intent.replace("search", "").replace("find", "").strip()
    
    step = PlanStep(
        id="search_content_1",
        description=f"Search for term: {search_term}",
        tool="search_engine",
        action="text_search",
        params={
            "query": search_term,
            "limit": 10
        },
        depends_on=[],
        requires_approval=False
    )
    
    return ExecutionPlan(
        intent=intent,
        steps=[step],
        success_criteria=f"Results for '{search_term}' displayed",
        fallback_instructions="none"
    )


def _create_calculation_plan(intent: str, context: Dict[str, Any]) -> ExecutionPlan:
    """Create a plan for mathematical calculations."""
    # Extract mathematical expression
    expr = intent
    for word in ["calculate", "compute", "math", "evaluate"]:
        expr = expr.replace(word, "")
    expr = re.sub(r'[^\d+\-*/().\s]', '', expr).strip()
    
    step = PlanStep(
        id="calculate_1",
        description=f"Calculate: {expr}",
        tool="calculator",
        action="evaluate",
        params={
            "expression": expr
        },
        depends_on=[],
        requires_approval=False
    )
    
    return ExecutionPlan(
        intent=intent,
        steps=[step],
        success_criteria=f"Calculation result for '{expr}' displayed",
        fallback_instructions="none"
    )


def _create_default_plan(intent: str, context: Dict[str, Any]) -> ExecutionPlan:
    """Create a default plan when intent is not recognized."""
    step = PlanStep(
        id="default_output_1",
        description=f"Output intent: {intent}",
        tool="console",
        action="output",
        params={
            "message": f"Intent received: {intent}",
            "context": context
        },
        depends_on=[],
        requires_approval=False
    )
    
    return ExecutionPlan(
        intent=intent,
        steps=[step],
        success_criteria="Intent acknowledged",
        fallback_instructions="none"
    )


def get_fallback_planner():
    """Get the fallback planner instance."""
    class FallbackPlanner:
        def plan(self, intent: str, context: Optional[Dict[str, Any]] = None):
            return deterministic_plan(intent, context)
    
    return FallbackPlanner()


# Additional utility functions for confidence scoring
def calculate_deterministic_confidence(intent: str) -> float:
    """Calculate confidence in deterministic plan based on intent keywords."""
    intent_lower = intent.lower()
    
    # Higher confidence for well-defined operations
    if any(keyword in intent_lower for keyword in ["save", "write", "create", "read", "list", "calculate"]):
        return 0.8
    
    # Medium confidence for other operations
    elif any(keyword in intent_lower for keyword in ["delete", "search", "find", "show", "display"]):
        return 0.6
    
    # Lower confidence for ambiguous operations
    else:
        return 0.4