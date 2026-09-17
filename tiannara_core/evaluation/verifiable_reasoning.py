"""
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
    provenance_refs: List[Dict[str, str]] = field(default_factory=list)  # References to source data
    
    def add_provenance_ref(self, source_type: str, source_id: str, relationship: str = "used_in"):
        """Add reference to provenance source."""
        self.provenance_refs.append({
            "source_type": source_type,
            "source_id": source_id,
            "relationship": relationship
        })
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "step_id": self.step_id,
            "step_type": self.step_type.value,
            "description": self.description,
            "timestamp": self.timestamp,
            "input_nodes": self.input_nodes,
            "output": str(self.output) if self.output is not None else None,
            "confidence": self.confidence,
            "metadata": self.metadata,
            "provenance_refs": self.provenance_refs
        }


@dataclass
class DataNode:
    """Represents a cited data point in reasoning."""
    node_id: str
    data_type: str
    value: Any
    source: str = ""
    timestamp: float = field(default_factory=time.time)
    provenance_chain: List[Dict[str, Any]] = field(default_factory=list)  # Track data lineage
    
    def add_provenance(self, source_type: str, source_id: str, relationship: str = "derived_from"):
        """Add provenance record to this data node."""
        self.provenance_chain.append({
            "source_type": source_type,
            "source_id": source_id,
            "relationship": relationship,
            "timestamp": time.time()
        })
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "node_id": self.node_id,
            "data_type": self.data_type,
            "value": str(self.value),
            "source": self.source,
            "timestamp": self.timestamp,
            "provenance_chain": self.provenance_chain
        }


class ReasoningTrace:
    """Complete trace of reasoning process for a single decision with full provenance."""
    
    def __init__(self, task_id: str, task_type: str):
        self.task_id = task_id
        self.task_type = task_type
        self.start_time = time.time()
        self.steps: List[ReasoningStep] = []
        self.data_nodes: Dict[str, DataNode] = {}
        self.current_step_number = 0
        self.final_confidence = 0.0
        self.outcome: Optional[str] = None
        self.provenance_metadata: Dict[str, Any] = {}  # Top-level provenance info
        
    def add_data_node(self, node_id: str, data_type: str, value: Any, 
                     source: str = "", provenance_info: Dict[str, Any] = None) -> str:
        """
        Add a data node with optional provenance information.
        
        Args:
            node_id: Unique identifier for the node
            data_type: Type of data (input, intermediate, output, etc.)
            value: The actual data value
            source: Source of the data (task_generator, skill_memory, etc.)
            provenance_info: Optional dict with source_type, source_id, relationship
        """
        node = DataNode(node_id=node_id, data_type=data_type, value=value, source=source)
        
        # Add provenance chain if provided
        if provenance_info:
            node.add_provenance(
                source_type=provenance_info.get("source_type", "unknown"),
                source_id=provenance_info.get("source_id", ""),
                relationship=provenance_info.get("relationship", "derived_from")
            )
        
        self.data_nodes[node_id] = node
        return node_id
    
    def add_step(self, step_type: ReasoningStepType, description: str, 
                 input_nodes: List[str] = None, output: Any = None,
                 confidence: float = 1.0, metadata: Dict[str, Any] = None,
                 provenance_refs: List[Dict[str, str]] = None) -> str:
        """
        Add a reasoning step with optional provenance references.
        
        Args:
            step_type: Type of reasoning step
            description: Human-readable description
            input_nodes: List of data node IDs used as input
            output: Output value from this step
            confidence: Confidence score (0-1)
            metadata: Additional metadata
            provenance_refs: List of dicts with source_type, source_id, relationship
        """
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
        
        # Add provenance references if provided
        if provenance_refs:
            for ref in provenance_refs:
                step.add_provenance_ref(
                    source_type=ref.get("source_type", "unknown"),
                    source_id=ref.get("source_id", ""),
                    relationship=ref.get("relationship", "used_in")
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
        
        # Generate summary based on outcome and steps
        if self.outcome == "success":
            summary = f"Successfully completed {self.task_type} task in {len(self.steps)} steps with {self.final_confidence:.1%} confidence"
        elif self.outcome == "failure":
            summary = f"Failed to complete {self.task_type} task after {len(self.steps)} steps"
        else:
            summary = f"{self.task_type.capitalize()} task execution: {self.outcome}"
        
        return {
            "task_id": self.task_id,
            "task_type": self.task_type,
            "total_steps": len(self.steps),
            "total_nodes": len(self.data_nodes),
            "duration_seconds": duration,
            "outcome": self.outcome,
            "final_confidence": self.final_confidence,
            "summary": summary,
            "provenance_metadata": self.provenance_metadata
        }
    
    def get_full_provenance_chain(self) -> Dict[str, Any]:
        """
        Get complete provenance chain for this reasoning trace.
        
        Returns:
            Dictionary with all provenance information including:
            - Top-level metadata
            - All data nodes with their provenance chains
            - All steps with their provenance references
        """
        return {
            "task_id": self.task_id,
            "task_type": self.task_type,
            "provenance_metadata": self.provenance_metadata,
            "data_nodes": {
                node_id: node.to_dict() 
                for node_id, node in self.data_nodes.items()
            },
            "steps": [
                {
                    "step_id": step.step_id,
                    "step_type": step.step_type.value,
                    "provenance_refs": step.provenance_refs
                }
                for step in self.steps
            ]
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
        
        return "\n".join(lines)


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
    
    def get_trace(self, task_id: str):
        """Retrieve a reasoning trace by task ID."""
        return self.traces.get(task_id)
    
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
