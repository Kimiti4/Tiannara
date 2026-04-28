"""
Trace Embedding Sandbox for Executable Causal Manifolds (ECM)

Runs IR variants in a lightweight executor, logs execution traces,
and embeds traces into a continuous latent space.
"""

from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass
import numpy as np
import sys
import time
from enum import Enum
import threading
import pickle
from ..sandbox.executor import run_in_sandbox, ExecutionResult


class TraceEventType(Enum):
    """Types of events recorded in execution traces."""
    NODE_ENTRY = "node_entry"
    NODE_EXIT = "node_exit"
    VARIABLE_READ = "variable_read"
    VARIABLE_WRITE = "variable_write"
    BRANCH_TAKEN = "branch_taken"
    BRANCH_NOT_TAKEN = "branch_not_taken"
    FUNCTION_CALL = "function_call"
    FUNCTION_RETURN = "function_return"
    EXCEPTION_RAISED = "exception_raised"
    MEMORY_ACCESS = "memory_access"


@dataclass
class TraceStep:
    """A single step in an execution trace."""
    t: int  # Timestamp
    event_type: TraceEventType
    node_id: Optional[str] = None
    variable_name: Optional[str] = None
    value: Optional[Any] = None
    memory_address: Optional[int] = None
    branch_condition: Optional[str] = None
    branch_result: Optional[bool] = None
    function_name: Optional[str] = None
    input_state: Optional[Dict[str, Any]] = None
    output_state: Optional[Dict[str, Any]] = None
    execution_time: Optional[float] = None
    error: Optional[str] = None


class TraceSandbox:
    """Sandbox for executing IR and capturing execution traces."""
    
    def __init__(self, max_trace_length: int = 1000, timeout: float = 10.0):
        self.max_trace_length = max_trace_length
        self.timeout = timeout
        self.logger = __import__('logging').getLogger("tiannara.ecm.trace_sandbox")
    
    def execute_ir(self, ir_code: str, inputs: Dict[str, Any]) -> List[TraceStep]:
        """
        Execute IR code and return execution trace.
        
        Args:
            ir_code: String representation of the IR code to execute
            inputs: Input values for the execution
            
        Returns:
            List of TraceStep objects representing the execution trace
        """
        # In a real implementation, this would execute the IR directly
        # For now, we'll simulate execution based on the IR structure
        trace = []
        
        # Simulate execution trace
        t = 0
        for var_name, value in inputs.items():
            trace.append(TraceStep(
                t=t,
                event_type=TraceEventType.VARIABLE_WRITE,
                variable_name=var_name,
                value=value,
                input_state=inputs.copy()
            ))
            t += 1
        
        # Simulate computation steps
        # This is a simplified simulation - in a real system, we'd execute the actual IR
        for i in range(min(10, self.max_trace_length - len(trace))):
            trace.append(TraceStep(
                t=t,
                event_type=TraceEventType.NODE_ENTRY,
                node_id=f"node_{i}",
                input_state=inputs.copy(),
                output_state={f"temp_var_{i}": i * 2}
            ))
            t += 1
            
            if len(trace) >= self.max_trace_length:
                break
        
        # Add output step
        if len(trace) < self.max_trace_length:
            trace.append(TraceStep(
                t=t,
                event_type=TraceEventType.FUNCTION_RETURN,
                output_state={"result": 42},  # Simulated result
                execution_time=0.001  # Simulated time
            ))
        
        return trace
    
    def execute_python_function(self, func, inputs: Tuple, kwargs: Dict = None) -> List[TraceStep]:
        """
        Execute a Python function and capture execution trace.
        
        Args:
            func: Python function to execute
            inputs: Input arguments
            kwargs: Keyword arguments
            
        Returns:
            List of TraceStep objects representing the execution trace
        """
        if kwargs is None:
            kwargs = {}
        
        # Use the existing sandbox executor to run safely
        def traced_function(*args, **kw):
            trace = []
            t = 0
            
            # Record inputs
            for i, val in enumerate(args):
                trace.append(TraceStep(
                    t=t,
                    event_type=TraceEventType.VARIABLE_WRITE,
                    variable_name=f"arg_{i}",
                    value=val
                ))
                t += 1
            
            for key, val in kw.items():
                trace.append(TraceStep(
                    t=t,
                    event_type=TraceEventType.VARIABLE_WRITE,
                    variable_name=key,
                    value=val
                ))
                t += 1
            
            # Set up tracing
            def trace_calls(frame, event, arg):
                if event == "call":
                    trace.append(TraceStep(
                        t=t,
                        event_type=TraceEventType.FUNCTION_CALL,
                        function_name=frame.f_code.co_name,
                        input_state={key: val for key, val in frame.f_locals.items()}
                    ))
                elif event == "return":
                    trace.append(TraceStep(
                        t=t,
                        event_type=TraceEventType.FUNCTION_RETURN,
                        function_name=frame.f_code.co_name,
                        output_state={"return_value": arg}
                    ))
                elif event == "line":
                    trace.append(TraceStep(
                        t=t,
                        event_type=TraceEventType.NODE_ENTRY,
                        node_id=f"line_{frame.f_lineno}",
                        input_state={key: val for key, val in frame.f_locals.items()}
                    ))
                
                return trace_calls
            
            # Install tracer
            old_trace = sys.gettrace()
            sys.settrace(trace_calls)
            
            try:
                result = func(*args, **kw)
            finally:
                sys.settrace(old_trace)
            
            # Record result
            trace.append(TraceStep(
                t=t,
                event_type=TraceEventType.FUNCTION_RETURN,
                output_state={"result": result},
                execution_time=time.time()
            ))
            
            return trace
        
        # Execute in sandbox
        result = run_in_sandbox(traced_function, args=(inputs, kwargs))
        
        if result.success:
            return result.output
        else:
            # Return error trace
            return [TraceStep(
                t=0,
                event_type=TraceEventType.EXCEPTION_RAISED,
                error=result.error
            )]
    
    def compare_traces(self, trace1: List[TraceStep], trace2: List[TraceStep]) -> float:
        """
        Compare two execution traces and return a similarity score.
        
        Args:
            trace1: First execution trace
            trace2: Second execution trace
            
        Returns:
            Similarity score between 0 and 1 (higher = more similar)
        """
        if not trace1 and not trace2:
            return 1.0
        if not trace1 or not trace2:
            return 0.0
        
        # Simple comparison based on trace length and event types
        len_sim = min(len(trace1), len(trace2)) / max(len(trace1), len(trace2))
        
        # Compare event types
        event_matches = 0
        for step1, step2 in zip(trace1, trace2):
            if step1.event_type == step2.event_type:
                event_matches += 1
        
        event_sim = event_matches / max(len(trace1), len(trace2))
        
        # Combine similarities
        return 0.5 * len_sim + 0.5 * event_sim
    
    def embed_trace(self, trace: List[TraceStep]) -> np.ndarray:
        """
        Embed an execution trace into a continuous latent space.
        
        Args:
            trace: Execution trace to embed
            
        Returns:
            Numpy array representing the trace embedding
        """
        if not trace:
            return np.zeros(64)  # Default embedding size
        
        # Create a simple embedding based on trace characteristics
        embedding = np.zeros(64)
        
        # Encode trace statistics
        event_counts = {event_type: 0 for event_type in TraceEventType}
        for step in trace:
            event_counts[step.event_type] += 1
        
        # Fill embedding with normalized counts (first 10 positions)
        total_events = len(trace)
        for i, event_type in enumerate(list(TraceEventType)[:10]):
            embedding[i] = event_counts[event_type] / max(total_events, 1)
        
        # Encode temporal information (next 10 positions)
        for i, step in enumerate(trace[:10]):
            embedding[10 + i] = step.t / max(len(trace), 1)
        
        # Encode value information (next 20 positions)
        values = []
        for step in trace:
            if step.value is not None:
                try:
                    val = float(step.value)
                    values.append(val)
                except (ValueError, TypeError):
                    continue
        
        if values:
            values_array = np.array(values)
            # Mean, std, min, max
            embedding[20] = np.mean(values_array)
            embedding[21] = np.std(values_array)
            embedding[22] = np.min(values_array)
            embedding[23] = np.max(values_array)
        
        # Fill remaining positions with hash of trace signature
        trace_signature = "".join([
            f"{step.event_type.value}_{step.node_id or ''}_{step.variable_name or ''}" 
            for step in trace
        ])
        signature_hash = hash(trace_signature) % (2**32)
        
        # Convert hash to binary and spread across remaining positions
        for i in range(24, 64):
            bit_pos = (signature_hash >> (i - 24)) & 1
            embedding[i] = float(bit_pos)
        
        return embedding


class TraceEmbedder:
    """Manages trace embedding and comparison operations."""
    
    def __init__(self, embedding_dim: int = 64):
        self.embedding_dim = embedding_dim
        self.sandbox = TraceSandbox()
        self.logger = __import__('logging').getLogger("tiannara.ecm.trace_embedder")
    
    def encode_pair(self, trace1: List[TraceStep], trace2: List[TraceStep]) -> Tuple[np.ndarray, np.ndarray]:
        """Encode two traces into embeddings."""
        emb1 = self.sandbox.embed_trace(trace1)
        emb2 = self.sandbox.embed_trace(trace2)
        return emb1, emb2
    
    def kl_divergence(self, p: np.ndarray, q: np.ndarray, epsilon: float = 1e-8) -> float:
        """
        Estimate KL divergence between two trace embeddings.
        
        Args:
            p: First probability distribution (embedding)
            q: Second probability distribution (embedding)
            epsilon: Small value to prevent division by zero
            
        Returns:
            Estimated KL divergence
        """
        # Normalize embeddings to probability distributions
        p_norm = (p - p.min()) / (p.max() - p.min() + epsilon)
        q_norm = (q - q.min()) / (q.max() - q.min() + epsilon)
        
        # Normalize to sum to 1
        p_prob = p_norm / (p_norm.sum() + epsilon)
        q_prob = q_norm / (q_norm.sum() + epsilon)
        
        # Calculate KL divergence
        kl_div = np.sum(p_prob * np.log((p_prob + epsilon) / (q_prob + epsilon)))
        return float(kl_div)
    
    def distance(self, emb1: np.ndarray, emb2: np.ndarray) -> float:
        """Calculate distance between two embeddings."""
        return float(np.linalg.norm(emb1 - emb2))
    
    def similarity(self, emb1: np.ndarray, emb2: np.ndarray) -> float:
        """Calculate similarity between two embeddings."""
        dist = self.distance(emb1, emb2)
        # Convert distance to similarity (higher distance = lower similarity)
        return 1.0 / (1.0 + dist)


# Example usage
if __name__ == "__main__":
    # Test trace sandbox
    sandbox = TraceSandbox()
    
    # Create a simple function to trace
    def sample_function(x, y):
        z = x + y
        w = z * 2
        return w
    
    # Execute with tracing
    inputs = (5, 3)
    trace = sandbox.execute_python_function(sample_function, inputs, {})
    
    print(f"Generated trace with {len(trace)} steps")
    for i, step in enumerate(trace[:5]):  # Show first 5 steps
        print(f"Step {i}: {step.event_type.value} - {step.node_id or step.variable_name}")
    
    # Test embedding
    embedder = TraceEmbedder()
    embedding = sandbox.embed_trace(trace)
    print(f"Trace embedding shape: {embedding.shape}")
    print(f"Sample embedding values: {embedding[:10]}")
    
    # Test comparison
    trace2 = sandbox.execute_python_function(sample_function, (10, 7), {})
    similarity = sandbox.compare_traces(trace, trace2)
    print(f"Trace similarity: {similarity:.3f}")
    
    # Test embedding comparison
    emb1, emb2 = embedder.encode_pair(trace, trace2)
    emb_similarity = embedder.similarity(emb1, emb2)
    print(f"Embedding similarity: {emb_similarity:.3f}")
    kl_div = embedder.kl_divergence(emb1, emb2)
    print(f"KL divergence: {kl_div:.3f}")