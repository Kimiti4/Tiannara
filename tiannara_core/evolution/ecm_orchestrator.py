"""
Executable Causal Manifolds (ECM) Orchestrator

Main orchestrator that integrates all ECM components:
- IR representation
- Trace sandbox
- Intervention planner
- Information pruner
"""

from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass
import numpy as np
import time
from enum import Enum
import logging
from ..evolution.ir_representation import ExecutionIR, IRConverter
from ..evolution.trace_sandbox import TraceSandbox, TraceStep, TraceEmbedder
from ..evolution.intervention_planner import InterventionPlanner
from ..evolution.information_pruner import InformationPruner, PruningCriterion
from ..evolution.graph_mutators import GraphMutator


class ECMStage(Enum):
    """Stages of the ECM process."""
    IR_CONVERSION = "ir_conversion"
    BASELINE_TRACING = "baseline_tracing"
    INTERVENTION_PLANNING = "intervention_planning"
    MUTATION_EXECUTION = "mutation_execution"
    TRACE_COMPARISON = "trace_comparison"
    INFORMATION_PRUNING = "information_pruning"
    CAUSAL_INFERENCE = "causal_inference"
    HYPOTHESIS_GENERATION = "hypothesis_generation"


@dataclass
class ECMResult:
    """Result of an ECM execution."""
    stage: ECMStage
    success: bool
    data: Dict[str, Any]
    execution_time: float
    message: str = ""


class ECMOrchestrator:
    """Main orchestrator for Executable Causal Manifolds."""
    
    def __init__(self, 
                 exploration_factor: float = 0.3,
                 max_iterations: int = 10,
                 min_information_gain: float = 0.1):
        self.exploration_factor = exploration_factor
        self.max_iterations = max_iterations
        self.min_information_gain = min_information_gain
        
        # Initialize components
        self.ir_converter = IRConverter()
        self.trace_sandbox = TraceSandbox()
        self.trace_embedder = TraceEmbedder()
        self.intervention_planner = InterventionPlanner(exploration_factor=exploration_factor)
        self.information_pruner = InformationPruner()
        self.graph_mutator = GraphMutator()
        
        # Setup logging
        self.logger = logging.getLogger("tiannara.ecm.orchestrator")
        
        # Track execution history
        self.execution_history: List[ECMResult] = []
    
    def execute_ecm_cycle(self, 
                         source_code: str, 
                         inputs: Dict[str, Any],
                         target_behavior: Optional[str] = None) -> Dict[str, Any]:
        """
        Execute a complete ECM cycle on source code.
        
        Args:
            source_code: Source code to analyze
            inputs: Input values for execution
            target_behavior: Optional target behavior to achieve
            
        Returns:
            Dictionary with analysis results
        """
        start_time = time.time()
        
        # Convert source code to IR
        ir_result = self._convert_to_ir(source_code)
        if not ir_result.success:
            return {"error": ir_result.message, "success": False}
        
        ir = ir_result.data['ir']
        self.logger.info(f"Converted source to IR with {len(ir.nodes)} nodes")
        
        # Get baseline trace
        baseline_trace = self.trace_sandbox.execute_ir(ir.serialize(), inputs)
        self.logger.info(f"Generated baseline trace with {len(baseline_trace)} steps")
        
        # Main ECM loop
        current_ir = ir
        current_trace = baseline_trace
        iteration_results = []
        
        for iteration in range(self.max_iterations):
            self.logger.info(f"ECM iteration {iteration + 1}/{self.max_iterations}")
            
            # Plan intervention
            intervention_result = self.intervention_planner.select_intervention(
                current_ir, current_trace
            )
            
            if not intervention_result:
                self.logger.info("No suitable intervention found, ending cycle")
                break
            
            self.logger.info(f"Selected intervention: {intervention_result.intervention_type.value}")
            
            # Apply intervention to get modified IR
            modified_ir = self.intervention_planner._apply_intervention(
                current_ir, intervention_result
            )
            
            if modified_ir is None:
                self.logger.warning("Intervention application failed")
                continue
            
            # Execute modified IR to get new trace
            modified_trace = self.trace_sandbox.execute_ir(
                modified_ir.serialize(), inputs
            )
            
            # Compare traces to measure information gain
            baseline_embedding = self.trace_embedder.sandbox.embed_trace(current_trace)
            modified_embedding = self.trace_embedder.sandbox.embed_trace(modified_trace)
            
            distance = self.trace_embedder.distance(baseline_embedding, modified_embedding)
            kl_div = self.trace_embedder.kl_divergence(baseline_embedding, modified_embedding)
            
            information_gain = 0.3 * distance + 0.7 * max(0, kl_div)
            
            self.logger.info(f"Information gain: {information_gain:.3f}")
            
            # If information gain is too low, consider stopping
            if information_gain < self.min_information_gain:
                self.logger.info(f"Information gain below threshold ({self.min_information_gain}), stopping")
                break
            
            # Prune low-value parts of the IR
            pruned_ir, pruning_results = self.information_pruner.adaptive_pruning(
                modified_ir, [current_trace, modified_trace], 
                target_compression_ratio=0.8
            )
            
            self.logger.info(f"After pruning: {len(pruned_ir.nodes)} nodes remaining")
            
            # Update current state
            current_ir = pruned_ir
            current_trace = modified_trace
            
            # Store iteration result
            iteration_results.append({
                "iteration": iteration,
                "intervention_type": intervention_result.intervention_type.value,
                "information_gain": information_gain,
                "kl_divergence": kl_div,
                "distance": distance,
                "nodes_before": len(modified_ir.nodes),
                "nodes_after": len(pruned_ir.nodes),
                "pruning_count": len(pruning_results)
            })
        
        total_time = time.time() - start_time
        
        # Perform final causal inference
        causal_model = self._perform_causal_inference(current_trace)
        
        # Generate hypotheses
        hypotheses = self._generate_hypotheses(current_ir, current_trace, causal_model)
        
        result = {
            "success": True,
            "final_ir_nodes": len(current_ir.nodes),
            "final_ir_edges": len(current_ir.edges),
            "total_iterations": len(iteration_results),
            "total_time": total_time,
            "baseline_trace_length": len(baseline_trace),
            "final_trace_length": len(current_trace),
            "iteration_results": iteration_results,
            "causal_model": causal_model,
            "hypotheses": hypotheses,
            "execution_history": [r.__dict__ for r in self.execution_history]
        }
        
        self.logger.info(f"ECM cycle completed in {total_time:.2f}s with {len(hypotheses)} hypotheses generated")
        
        return result
    
    def _convert_to_ir(self, source_code: str) -> ECMResult:
        """Convert source code to IR."""
        start_time = time.time()
        try:
            ir = self.ir_converter.convert_python_to_ir(source_code)
            execution_time = time.time() - start_time
            
            result = ECMResult(
                stage=ECMStage.IR_CONVERSION,
                success=True,
                data={"ir": ir},
                execution_time=execution_time
            )
            self.execution_history.append(result)
            return result
        except Exception as e:
            execution_time = time.time() - start_time
            result = ECMResult(
                stage=ECMStage.IR_CONVERSION,
                success=False,
                data={},
                execution_time=execution_time,
                message=f"IR conversion failed: {str(e)}"
            )
            self.execution_history.append(result)
            return result
    
    def _perform_causal_inference(self, trace: List[TraceStep]) -> Dict[str, Any]:
        """Perform causal inference on a trace."""
        # In a real implementation, this would run advanced causal discovery
        # For now, we'll extract basic patterns from the trace
        
        variable_writes = {}
        function_calls = []
        control_flows = []
        
        for step in trace:
            if step.event_type.value == "variable_write" and step.variable_name:
                if step.variable_name not in variable_writes:
                    variable_writes[step.variable_name] = []
                variable_writes[step.variable_name].append(step.value)
            
            elif step.event_type.value == "function_call" and step.function_name:
                function_calls.append({
                    "function": step.function_name,
                    "timestamp": step.t
                })
            
            elif step.event_type.value in ["branch_taken", "branch_not_taken"]:
                control_flows.append({
                    "type": step.event_type.value,
                    "condition": step.branch_condition,
                    "timestamp": step.t
                })
        
        return {
            "variable_dependencies": self._infer_variable_dependencies(variable_writes),
            "function_sequence": function_calls,
            "control_flows": control_flows,
            "state_transitions": self._infer_state_transitions(trace)
        }
    
    def _infer_variable_dependencies(self, variable_writes: Dict[str, List]) -> Dict[str, List[str]]:
        """Infer dependencies between variables."""
        dependencies = {}
        
        # Simple inference: if variable B is written after A in the same trace,
        # A may influence B
        var_names = list(variable_writes.keys())
        for i, var_a in enumerate(var_names):
            for var_b in var_names[i+1:]:
                # If var_a was written before var_b in any trace, assume dependency
                dependencies[var_a] = dependencies.get(var_a, [])
                dependencies[var_a].append(var_b)
        
        return dependencies
    
    def _infer_state_transitions(self, trace: List[TraceStep]) -> List[Dict[str, Any]]:
        """Infer state transitions from trace."""
        transitions = []
        
        for i in range(len(trace) - 1):
            step1 = trace[i]
            step2 = trace[i+1]
            
            transition = {
                "from_event": step1.event_type.value,
                "to_event": step2.event_type.value,
                "timestamp": step1.t
            }
            
            if step1.node_id:
                transition["from_node"] = step1.node_id
            if step2.node_id:
                transition["to_node"] = step2.node_id
                
            transitions.append(transition)
        
        return transitions
    
    def _generate_hypotheses(self, ir: ExecutionIR, trace: List[TraceStep], causal_model: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Generate hypotheses based on the analysis."""
        hypotheses = []
        
        # Hypothesis 1: Critical path analysis
        if len(ir.nodes) > 1:
            entry_nodes = ir.entry_points
            exit_nodes = ir.exit_points
            
            if entry_nodes and exit_nodes:
                # Find paths from entry to exit
                paths = self._find_paths_between_nodes(ir, entry_nodes[0], exit_nodes[0])
                if paths:
                    hypotheses.append({
                        "type": "critical_path",
                        "description": f"Identified {len(paths)} possible execution paths from input to output",
                        "paths": paths,
                        "confidence": 0.8
                    })
        
        # Hypothesis 2: Variable dependency
        if causal_model.get("variable_dependencies"):
            dep_count = sum(len(deps) for deps in causal_model["variable_dependencies"].values())
            hypotheses.append({
                "type": "variable_dependency",
                "description": f"Detected {dep_count} variable dependencies",
                "dependencies": causal_model["variable_dependencies"],
                "confidence": 0.7
            })
        
        # Hypothesis 3: Performance bottleneck
        # Find nodes that appear frequently in traces
        node_frequency = {}
        for step in trace:
            if step.node_id:
                node_frequency[step.node_id] = node_frequency.get(step.node_id, 0) + 1
        
        if node_frequency:
            max_freq = max(node_frequency.values())
            bottleneck_nodes = [
                node_id for node_id, freq in node_frequency.items()
                if freq == max_freq
            ]
            
            hypotheses.append({
                "type": "performance_bottleneck",
                "description": f"Identified potential bottleneck at nodes: {bottleneck_nodes}",
                "nodes": bottleneck_nodes,
                "frequency": max_freq,
                "confidence": 0.6
            })
        
        return hypotheses
    
    def _find_paths_between_nodes(self, ir: ExecutionIR, start_node: str, end_node: str) -> List[List[str]]:
        """Find all paths between two nodes in the IR."""
        # Convert IR to NetworkX graph for pathfinding
        import networkx as nx
        
        graph = nx.DiGraph()
        
        # Add nodes
        for node_id in ir.nodes:
            graph.add_node(node_id)
        
        # Add edges
        for src, tgt in ir.edges:
            graph.add_edge(src, tgt)
        
        # Find all simple paths
        try:
            paths = list(nx.all_simple_paths(graph, start_node, end_node, cutoff=5))
            return paths
        except nx.NetworkXNoPath:
            return []


class ReverseEngineeringEngine:
    """Specialized engine for reverse engineering using ECM."""
    
    def __init__(self):
        self.ecm_orchestrator = ECMOrchestrator()
        self.logger = logging.getLogger("tiannara.ecm.reverse_engine")
    
    def reverse_engineer(self, binary_path: str, input_samples: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Perform reverse engineering on a binary using ECM principles.
        
        Args:
            binary_path: Path to the binary to reverse engineer
            input_samples: Sample inputs to observe behavior
            
        Returns:
            Analysis results including reconstructed logic
        """
        self.logger.info(f"Starting reverse engineering of {binary_path}")
        
        # In a real implementation, we would:
        # 1. Disassemble the binary
        # 2. Create an IR representation
        # 3. Execute with sample inputs to generate traces
        # 4. Apply ECM techniques to understand logic
        
        # For now, we'll simulate this process
        results = []
        
        for i, inputs in enumerate(input_samples):
            # Simulate running the binary with inputs
            simulated_output = self._simulate_binary_execution(inputs)
            
            # Apply ECM analysis to understand the transformation
            analysis = self._analyze_transformation(inputs, simulated_output)
            results.append({
                "input": inputs,
                "output": simulated_output,
                "analysis": analysis
            })
        
        # Consolidate findings into a comprehensive report
        consolidated = self._consolidate_findings(results)
        
        return {
            "success": True,
            "binary_path": binary_path,
            "sample_count": len(input_samples),
            "findings": consolidated,
            "pseudo_code": self._generate_pseudo_code(consolidated)
        }
    
    def _simulate_binary_execution(self, inputs: Dict[str, Any]) -> Dict[str, Any]:
        """Simulate binary execution for demonstration."""
        # This would normally interface with an actual disassembler/emulator
        # For simulation, transform inputs in some way
        output = {}
        
        for key, value in inputs.items():
            if isinstance(value, (int, float)):
                # Apply some transformation
                transformed = value * 2 + 10
                output[f"{key}_transformed"] = transformed
            else:
                output[key] = value
        
        return output
    
    def _analyze_transformation(self, inputs: Dict[str, Any], outputs: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze the transformation from inputs to outputs."""
        transformations = []
        
        for in_key, in_value in inputs.items():
            for out_key, out_value in outputs.items():
                if isinstance(in_value, (int, float)) and isinstance(out_value, (int, float)):
                    # Try to deduce the transformation
                    diff = out_value - in_value if isinstance(in_value, (int, float)) else None
                    ratio = out_value / in_value if isinstance(in_value, (int, float)) and in_value != 0 else None
                    
                    transformations.append({
                        "input": in_key,
                        "output": out_key,
                        "diff": diff,
                        "ratio": ratio,
                        "operation": "multiply_and_add" if ratio and diff else "unknown"
                    })
        
        return {
            "transformations": transformations,
            "input_output_mapping": [(k, k+"_transformed") for k in inputs.keys()]
        }
    
    def _consolidate_findings(self, results: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Consolidate analysis findings from multiple samples."""
        # Group by transformation patterns
        patterns = {}
        
        for result in results:
            analysis = result["analysis"]
            transformations = analysis.get("transformations", [])
            
            for t in transformations:
                op = t.get("operation", "unknown")
                if op not in patterns:
                    patterns[op] = {
                        "instances": 0,
                        "examples": []
                    }
                patterns[op]["instances"] += 1
                patterns[op]["examples"].append(t)
        
        return {
            "transformation_patterns": patterns,
            "common_operations": list(patterns.keys()),
            "total_samples_analyzed": len(results)
        }
    
    def _generate_pseudo_code(self, findings: Dict[str, Any]) -> str:
        """Generate pseudo-code based on findings."""
        # This would generate actual pseudocode in a real implementation
        operations = findings.get("common_operations", [])
        
        if "multiply_and_add" in operations:
            return """
function reverse_engineered_function(input_dict):
    output_dict = {}
    for key, value in input_dict.items():
        if type(value) in [int, float]:
            # Common pattern: multiply by 2 and add 10
            output_dict[key + "_transformed"] = value * 2 + 10
        else:
            output_dict[key] = value
    return output_dict
"""
        else:
            return "# Unable to determine clear transformation pattern"


# Example usage
if __name__ == "__main__":
    # Example 1: Basic ECM usage
    print("=== Executable Causal Manifolds Demo ===")
    
    # Sample source code to analyze
    sample_code = """
def example_function(x, y):
    if x > 5:
        z = x * 2
    else:
        z = x + 10
    result = z + y
    return result
"""
    
    # Inputs for the function
    sample_inputs = {"x": 7, "y": 3}
    
    # Create orchestrator and run ECM cycle
    ecm = ECMOrchestrator(exploration_factor=0.4, max_iterations=3)
    result = ecm.execute_ecm_cycle(sample_code, sample_inputs)
    
    print(f"Success: {result['success']}")
    print(f"Final IR nodes: {result['final_ir_nodes']}")
    print(f"Total iterations: {result['total_iterations']}")
    print(f"Generated hypotheses: {len(result['hypotheses'])}")
    
    for i, hyp in enumerate(result['hypotheses']):
        print(f"  {i+1}. {hyp['type']}: {hyp['description'][:60]}...")
    
    print("\n=== Reverse Engineering Demo ===")
    
    # Example 2: Reverse engineering
    reverser = ReverseEngineeringEngine()
    sample_inputs = [{"x": 1}, {"x": 5}, {"x": 10}]
    
    rev_result = reverser.reverse_engineer("fake_binary.exe", sample_inputs)
    
    print(f"Reverse engineering success: {rev_result['success']}")
    print(f"Found operations: {rev_result['findings']['common_operations']}")
    print(f"Pseudo code:\n{rev_result['pseudo_code']}")