"""
Hard Fallback Planner - No LLM Dependency

Provides deterministic planning when LLM fails or is unavailable.
This ensures Tiannara NEVER fails completely.
"""

from typing import Dict, Any, Optional
from dataclasses import dataclass
import json
import os
from pathlib import Path


@dataclass
class PlanStep:
    id: str
    description: str
    tool: str
    action: str
    params: Dict[str, Any]
    depends_on: list[str]
    requires_approval: bool = False


@dataclass
class FallbackPlan:
    intent: str
    steps: list[PlanStep]
    success_criteria: str
    fallback_instructions: str = "none"
    confidence: float = 0.4  # Low confidence for fallback plans


class FallbackPlanner:
    """
    Deterministic planner that works without LLM.
    Uses pattern matching and heuristics to generate basic plans.
    """
    
    def __init__(self):
        self.intent_patterns = {
            "save": self._create_save_plan,
            "write": self._create_save_plan,
            "create": self._create_create_plan,
            "read": self._create_read_plan,
            "open": self._create_read_plan,
            "list": self._create_list_plan,
            "search": self._create_search_plan,
            "help": self._create_help_plan,
            "status": self._create_status_plan,
            "test": self._create_test_plan,
            "run": self._create_run_plan,
            "execute": self._create_run_plan,
            "build": self._create_build_plan,
            "deploy": self._create_deploy_plan,
            "analyze": self._create_analyze_plan,
            "debug": self._create_debug_plan,
        }
    
    def plan(self, intent: str, context: Optional[Dict[str, Any]] = None) -> Optional[FallbackPlan]:
        """
        Generate a deterministic plan based on intent pattern matching.
        """
        if not intent:
            return None
        
        intent_lower = intent.lower().strip()
        context = context or {}
        
        # Try to match intent patterns
        for keyword, planner_func in self.intent_patterns.items():
            if keyword in intent_lower:
                try:
                    return planner_func(intent, context)
                except Exception:
                    continue
        
        # Default fallback plan
        return self._create_default_plan(intent, context)
    
    def _create_save_plan(self, intent: str, context: Dict[str, Any]) -> FallbackPlan:
        """Create a plan for saving/writing files."""
        return FallbackPlan(
            intent=intent,
            steps=[
                PlanStep(
                    id="s1",
                    description="Save content to file",
                    tool="file_system",
                    action="write_file",
                    params={
                        "path": context.get("path", "~/fallback_save.txt"),
                        "content": context.get("content", intent)
                    },
                    depends_on=[],
                    requires_approval=False
                )
            ],
            success_criteria="file saved successfully",
            fallback_instructions="Verify file permissions and try again"
        )
    
    def _create_create_plan(self, intent: str, context: Dict[str, Any]) -> FallbackPlan:
        """Create a plan for creating new resources."""
        return FallbackPlan(
            intent=intent,
            steps=[
                PlanStep(
                    id="s1",
                    description="Create new resource",
                    tool="file_system",
                    action="create_resource",
                    params={
                        "type": context.get("type", "file"),
                        "name": context.get("name", "new_resource"),
                        "content": context.get("content", "")
                    },
                    depends_on=[],
                    requires_approval=True
                )
            ],
            success_criteria="resource created successfully",
            fallback_instructions="Check if resource already exists"
        )
    
    def _create_read_plan(self, intent: str, context: Dict[str, Any]) -> FallbackPlan:
        """Create a plan for reading files."""
        return FallbackPlan(
            intent=intent,
            steps=[
                PlanStep(
                    id="s1",
                    description="Read file content",
                    tool="file_system",
                    action="read_file",
                    params={
                        "path": context.get("path", "~/fallback_read.txt")
                    },
                    depends_on=[],
                    requires_approval=False
                )
            ],
            success_criteria="file read successfully",
            fallback_instructions="Verify file exists and is readable"
        )
    
    def _create_list_plan(self, intent: str, context: Dict[str, Any]) -> FallbackPlan:
        """Create a plan for listing directory contents."""
        return FallbackPlan(
            intent=intent,
            steps=[
                PlanStep(
                    id="s1",
                    description="List directory contents",
                    tool="file_system",
                    action="list_directory",
                    params={
                        "path": context.get("path", ".")
                    },
                    depends_on=[],
                    requires_approval=False
                )
            ],
            success_criteria="directory listed successfully",
            fallback_instructions="Check directory permissions"
        )
    
    def _create_search_plan(self, intent: str, context: Dict[str, Any]) -> FallbackPlan:
        """Create a plan for searching content."""
        return FallbackPlan(
            intent=intent,
            steps=[
                PlanStep(
                    id="s1",
                    description="Search for content",
                    tool="search",
                    action="find_text",
                    params={
                        "query": context.get("query", intent),
                        "path": context.get("path", "."),
                        "file_pattern": context.get("pattern", "*.py")
                    },
                    depends_on=[],
                    requires_approval=False
                )
            ],
            success_criteria="search completed",
            fallback_instructions="Try broader search terms"
        )
    
    def _create_help_plan(self, intent: str, context: Dict[str, Any]) -> FallbackPlan:
        """Create a plan for providing help."""
        return FallbackPlan(
            intent=intent,
            steps=[
                PlanStep(
                    id="s1",
                    description="Show available commands",
                    tool="system",
                    action="show_help",
                    params={},
                    depends_on=[],
                    requires_approval=False
                )
            ],
            success_criteria="help displayed",
            fallback_instructions="Check documentation"
        )
    
    def _create_status_plan(self, intent: str, context: Dict[str, Any]) -> FallbackPlan:
        """Create a plan for showing system status."""
        return FallbackPlan(
            intent=intent,
            steps=[
                PlanStep(
                    id="s1",
                    description="Check system status",
                    tool="system",
                    action="status_check",
                    params={},
                    depends_on=[],
                    requires_approval=False
                )
            ],
            success_criteria="status retrieved",
            fallback_instructions="Check system logs"
        )
    
    def _create_test_plan(self, intent: str, context: Dict[str, Any]) -> FallbackPlan:
        """Create a plan for running tests."""
        return FallbackPlan(
            intent=intent,
            steps=[
                PlanStep(
                    id="s1",
                    description="Run basic functionality test",
                    tool="testing",
                    action="run_test",
                    params={
                        "test_type": context.get("test_type", "basic"),
                        "target": context.get("target", "system")
                    },
                    depends_on=[],
                    requires_approval=False
                )
            ],
            success_criteria="tests completed",
            fallback_instructions="Check test configuration"
        )
    
    def _create_run_plan(self, intent: str, context: Dict[str, Any]) -> FallbackPlan:
        """Create a plan for running commands."""
        return FallbackPlan(
            intent=intent,
            steps=[
                PlanStep(
                    id="s1",
                    description="Execute command",
                    tool="executor",
                    action="run_command",
                    params={
                        "command": context.get("command", "echo 'fallback execution'"),
                        "cwd": context.get("cwd", ".")
                    },
                    depends_on=[],
                    requires_approval=True
                )
            ],
            success_criteria="command executed",
            fallback_instructions="Check command syntax and permissions"
        )
    
    def _create_build_plan(self, intent: str, context: Dict[str, Any]) -> FallbackPlan:
        """Create a plan for building projects."""
        return FallbackPlan(
            intent=intent,
            steps=[
                PlanStep(
                    id="s1",
                    description="Prepare build environment",
                    tool="build",
                    action="prepare",
                    params={},
                    depends_on=[],
                    requires_approval=False
                ),
                PlanStep(
                    id="s2",
                    description="Execute build",
                    tool="build",
                    action="build",
                    params={
                        "target": context.get("target", "default")
                    },
                    depends_on=["s1"],
                    requires_approval=True
                )
            ],
            success_criteria="build completed",
            fallback_instructions="Check build dependencies"
        )
    
    def _create_deploy_plan(self, intent: str, context: Dict[str, Any]) -> FallbackPlan:
        """Create a plan for deployment."""
        return FallbackPlan(
            intent=intent,
            steps=[
                PlanStep(
                    id="s1",
                    description="Validate deployment readiness",
                    tool="deployment",
                    action="validate",
                    params={},
                    depends_on=[],
                    requires_approval=False
                ),
                PlanStep(
                    id="s2",
                    description="Execute deployment",
                    tool="deployment",
                    action="deploy",
                    params={
                        "target": context.get("target", "default"),
                        "environment": context.get("environment", "development")
                    },
                    depends_on=["s1"],
                    requires_approval=True
                )
            ],
            success_criteria="deployment successful",
            fallback_instructions="Check deployment configuration"
        )
    
    def _create_analyze_plan(self, intent: str, context: Dict[str, Any]) -> FallbackPlan:
        """Create a plan for analysis."""
        return FallbackPlan(
            intent=intent,
            steps=[
                PlanStep(
                    id="s1",
                    description="Collect data for analysis",
                    tool="analytics",
                    action="collect",
                    params={
                        "source": context.get("source", "system")
                    },
                    depends_on=[],
                    requires_approval=False
                ),
                PlanStep(
                    id="s2",
                    description="Perform analysis",
                    tool="analytics",
                    action="analyze",
                    params={
                        "type": context.get("analysis_type", "basic")
                    },
                    depends_on=["s1"],
                    requires_approval=False
                )
            ],
            success_criteria="analysis completed",
            fallback_instructions="Check data availability"
        )
    
    def _create_debug_plan(self, intent: str, context: Dict[str, Any]) -> FallbackPlan:
        """Create a plan for debugging."""
        return FallbackPlan(
            intent=intent,
            steps=[
                PlanStep(
                    id="s1",
                    description="Collect debug information",
                    tool="debug",
                    action="collect_info",
                    params={
                        "component": context.get("component", "system")
                    },
                    depends_on=[],
                    requires_approval=False
                ),
                PlanStep(
                    id="s2",
                    description="Analyze issues",
                    tool="debug",
                    action="analyze_issues",
                    params={},
                    depends_on=["s1"],
                    requires_approval=False
                )
            ],
            success_criteria="debug information collected",
            fallback_instructions="Check system logs"
        )
    
    def _create_default_plan(self, intent: str, context: Dict[str, Any]) -> FallbackPlan:
        """Create a minimal fallback plan when no pattern matches."""
        return FallbackPlan(
            intent=intent,
            steps=[
                PlanStep(
                    id="s1",
                    description="Execute fallback action",
                    tool="fallback",
                    action="default",
                    params={
                        "intent": intent,
                        "context": context
                    },
                    depends_on=[],
                    requires_approval=False
                )
            ],
            success_criteria="fallback action completed",
            fallback_instructions="Manual intervention required"
        )
    
    def can_handle(self, intent: str) -> bool:
        """Check if this planner can handle the given intent."""
        if not intent:
            return False
        
        intent_lower = intent.lower().strip()
        return any(keyword in intent_lower for keyword in self.intent_patterns.keys())


# Global fallback planner instance
_fallback_planner = None

def get_fallback_planner() -> FallbackPlanner:
    """Get or create the global fallback planner instance."""
    global _fallback_planner
    if _fallback_planner is None:
        _fallback_planner = FallbackPlanner()
    return _fallback_planner

def deterministic_plan(intent: str, context: Optional[Dict[str, Any]] = None) -> Optional[FallbackPlan]:
    """
    Quick access function for deterministic planning.
    This is the main entry point for fallback planning.
    """
    planner = get_fallback_planner()
    return planner.plan(intent, context)
