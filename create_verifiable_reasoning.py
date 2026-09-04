"""Script to create verifiable_reasoning.py module."""

content = '''"""
Verifiable Reasoning System for Auditable Decision Paths.

Implements upgrades.md requirement for verifiable reasoning:
- Auditable logic trees showing decision paths
- Step-by-step proofs with cited data nodes
- Visual decision paths for transparency
- Quantitative metrics tracking
"""

import time
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, field
from enum import Enum


class ReasoningStepType(Enum):
    """Types of reasoning steps."""
    OBSERVATION = "observation"
    HYPOTHESIS = "hypothesis"
    INFERENCE = "inference"
    CALCULATION = "calculation"
    DECISION = "decision"
    VERIFICATION = "verification"
    CONCLUSION = "conclusion"


@dataclass
class ReasoningStep:
    """Represents a single step in the reasoning process."""
    step_id: str
    step_type: ReasoningStepType
    description: str
    timestamp: float = field(default_factory=time.time)
    input_nodes: List[str] = field(default_factory=list)
    output: Any = None
    confidence: float = 1.0
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "step_id": self.step_id,
            "step_type": self.step_type.value,
            "description": self.description,
            "timestamp": self.timestamp,
            "input_nodes": self.input_nodes,
            "output": str(self.output) if self.output is not None else None,
            "confidence": self.confidence,
            "metadata": self.metadata
        }


@dataclass
class DataNode:
    """Represents a cited data point in reasoning."""
    node_id: str
    data_type: str
    value: Any
    source: str = ""
    timestamp: float = field(default_factory=time.time)
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "node_id": self.node_id,
            "data_type": self.data_type,
            "value": str(self.value),
            "source": self.source,
            "timestamp": self.timestamp
        }


class ReasoningTrace:
    """Complete trace of reasoning process for a single decision."""
    
    def __init__(self, task_id: str, task_type: str):
        self.task_id = task_id
        self.task_type = task_type
        self.start_time = time.time()
        self.steps: List[ReasoningStep] = []
        self.data_nodes: Dict[str, DataNode] = {}
        self.current_step_number = 0
        self.final_confidence = 0.0
        self.outcome: Optional[str] = None
        
    def add_data_node(self, node_id: str, data_type: str, value: Any, source: str = "") -> str:
        node = DataNode(node_id=node_id, data_type=data_type, value=value, source=source)
        self.data_nodes[node_id] = node
        return node_id
    
    def add_step(self, step_type: ReasoningStepType, description: str, 
                 input_nodes: List[str] = None, output: Any = None,
                 confidence: float = 1.0, metadata: Dict[str, Any] = None) -> str:
        self.current_step_number += 1
        step_id = f"{self.task_id}_step_{self.current_step_number}"
        
        step = ReasoningStep(
            step_id=step_id,
            step_type=step_type,
            description=description,
            input_nodes=input_nodes or [],
            output=output,
            confidence=confidence,
            metadata=metadata or {}
        )
        
        self.steps.append(step)
        return step_id
    
    def finalize(self, outcome: str, final_confidence: float):
        self.outcome = outcome
        self.final_confidence = final_confidence
        self.add_step(
            step_type=ReasoningStepType.CONCLUSION,
            description=f"Final outcome: {outcome} with confidence {final_confidence:.2f}",
            output=outcome,
            confidence=final_confidence
        )
    
    def get_summary(self) -> Dict[str, Any]:
        duration = time.time() - self.start_time
        return {
            "task_id": self.task_id,
            "task_type": self.task_type,
            "total_steps": len(self.steps),
            "total_nodes": len(self.data_nodes),
            "duration_seconds": duration,
            "outcome": self.outcome,
            "final_confidence": self.final_confidence
        }
    
    def visualize_ascii(self) -> str:
        lines = [
            f"Reasoning Trace: {self.task_id}",
            f"Task Type: {self.task_type}",
            f"Outcome: {self.outcome} (confidence: {self.final_confidence:.2f})",
            "=" * 60,
            ""
        ]
        
        for i, step in enumerate(self.steps, 1):
            lines.append(f"Step {i}: {step.step_type.value.upper()}")
            lines.append(f"  Description: {step.description}")
            if step.output is not None:
                lines.append(f"  Output: {str(step.output)[:100]}")
            lines.append(f"  Confidence: {step.confidence:.2f}")
            lines.append("")
        
        return "\\n".join(lines)


class VerifiableReasoner:
    """Main interface for creating and managing verifiable reasoning traces."""
    
    def __init__(self):
        self.traces: Dict[str, ReasoningTrace] = {}
        self.total_traces = 0
        self.successful_traces = 0
    
    def start_trace(self, task_id: str, task_type: str) -> ReasoningTrace:
        trace = ReasoningTrace(task_id, task_type)
        self.traces[task_id] = trace
        self.total_traces += 1
        return trace
    
    def record_outcome(self, task_id: str, outcome: str, confidence: float):
        trace = self.traces.get(task_id)
        if trace:
            trace.finalize(outcome, confidence)
            if outcome == "success":
                self.successful_traces += 1
    
    def get_statistics(self) -> Dict[str, Any]:
        success_rate = (
            self.successful_traces / self.total_traces
            if self.total_traces > 0 else 0
        )
        return {
            "total_traces": self.total_traces,
            "successful_traces": self.successful_traces,
            "success_rate": success_rate
        }
    
    def export_all_traces(self) -> List[Dict[str, Any]]:
        return [trace.get_summary() for trace in self.traces.values()]
'''

with open('tiannara_core/evaluation/verifiable_reasoning.py', 'w') as f:
    f.write(content)

print("Created verifiable_reasoning.py successfully")
