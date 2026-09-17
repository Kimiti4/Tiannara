"""
Sandbox Executor Module

Provides a restricted execution environment for code variants.
"""

from __future__ import annotations

from typing import Any, Dict, Optional

from dataclasses import dataclass

# Minimal safe builtins — no open, import, exec, eval, or subprocess
_SAFE_BUILTINS = {
    "abs": abs,
    "all": all,
    "any": any,
    "bool": bool,
    "dict": dict,
    "enumerate": enumerate,
    "float": float,
    "int": int,
    "len": len,
    "list": list,
    "max": max,
    "min": min,
    "range": range,
    "round": round,
    "set": set,
    "sorted": sorted,
    "str": str,
    "sum": sum,
    "tuple": tuple,
    "zip": zip,
    "True": True,
    "False": False,
    "None": None,
}


@dataclass
class ExecutionResult:
    """Result of sandbox execution."""

    success: bool
    output: Any = None
    error: Optional[str] = None
    execution_time: float = 0.0
    metadata: Dict[str, Any] = None

    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}


def run_in_sandbox(code: str, context: Optional[Dict[str, Any]] = None) -> ExecutionResult:
    """Execute code with restricted builtins (not a full isolation boundary)."""
    try:
        exec_globals: Dict[str, Any] = {"__builtins__": _SAFE_BUILTINS}
        if context:
            exec_globals.update(context)
        exec(compile(code, "<sandbox>", "exec"), exec_globals)
        return ExecutionResult(
            success=True,
            output=exec_globals.get("result"),
            execution_time=0.0,
        )
    except Exception as e:
        return ExecutionResult(
            success=False,
            error=str(e),
            execution_time=0.0,
        )


__all__ = ["run_in_sandbox", "ExecutionResult"]
