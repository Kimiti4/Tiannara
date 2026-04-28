"""
Information-Theoretic Pruner for Executable Causal Manifolds (ECM)

Uses causal discovery and program verification to score branches and prune 
low-information paths early.
"""

from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass
import numpy as np
from scipy.stats import entropy
from sklearn.feature_selection import mutual_info_regression
import networkx as nx
from enum import Enum
import warnings
from ..evolution.ir_representation import ExecutionIR
from ..evolution.trace_sandbox import TraceSandbox, TraceStep
from ..evolution.intervention_planner import InterventionPlanner


class PruningCriterion(Enum):
    """Criteria for pruning branches."""
    CAUSAL_IRRELEVANCE = "causal_irrelevance"
    INFORMATION_REDUNDANCY = "information_redundancy"
    COMPUTATIONAL_COST = "computational_cost"
    VERIFICATION_FAILURE = "verification_failure"
    ENTROPY_THRESHOLD = "entropy_threshold"


@dataclass
class PruningResult:
    """Result of a pruning operation."""
    pruned_nodes: List[str]
    pruned_edges: List[Tuple[str, str]]
    reason: PruningCriterion
    information_retained: float  # 0-1, proportion of information kept
    confidence: float  # 0-1, confidence in the pruning decision


class InformationPruner:
    """Prunes low-information paths in execution graphs."""
    
    def __init__(self, 
                 entropy_threshold: float = 0.1,
                 min_causal_strength: float = 0.05,
                 redundancy_threshold: float = 0.8):
        self.entropy_threshold = entropy_threshold
        self.min_causal_strength = min_causal_strength
        self.redundancy_threshold = redundancy_threshold
        self.logger = __import__('logging').getLogger("tiannara.ecm.information_pruner")
        self.trace_sandbox = TraceSandbox()
    
    def prune_graph(self, 
                   ir: ExecutionIR, 
                   traces: List[List[TraceStep]],
                   criterion: PruningCriterion = PruningCriterion.CASUAL_IRRELEVANCE) -> Tuple[ExecutionIR, List[PruningResult]]:
        """
        Prune an execution IR based on information-theoretic criteria.
        
        Args:
            ir: ExecutionIR to prune
            traces: Execution traces to inform pruning decisions
            criterion: Criterion to use for pruning
            
        Returns:
            Tuple of (pruned_ir, pruning_results)
        """
        pruning_results = []
        
        if criterion == PruningCriterion.CASUAL_IRRELEVANCE:
            pruned_ir, results = self._prune_causal_irrelevance(ir, traces)
        elif criterion == PruningCriterion.INFORMATION_REDUNDANCY:
            pruned_ir, results = self._prune_information_redundancy(ir, traces)
        elif criterion == PruningCriterion.ENTROPY_THRESHOLD:
            pruned_ir, results = self._prune_low_entropy(ir, traces)
        else:
            # Default to causal irrelevance
            pruned_ir, results = self._prune_causal_irrelevance(ir, traces)
        
        pruning_results.extend(results)
        return pruned_ir, pruning_results
    
    def _prune_causal_irrelevance(self, 
                                 ir: ExecutionIR, 
                                 traces: List[List[TraceStep]]) -> Tuple[ExecutionIR, List[PruningResult]]:
        """Prune nodes with weak causal connections."""
        # Calculate causal strengths from traces
        causal_strengths = self._calculate_causal_strengths(ir, traces)
        
        # Identify nodes with weak causal connections
        weak_nodes = [
            node_id for node_id, strength in causal_strengths.items()
            if strength < self.min_causal_strength
        ]
        
        # Create pruned IR without weak nodes
        pruned_ir = self._remove_nodes_from_ir(ir, weak_nodes)
        
        # Create pruning results
        results = [
            PruningResult(
                pruned_nodes=[node_id],
                pruned_edges=[],
                reason=PruningCriterion.CASUAL_IRRELEVANCE,
                information_retained=1.0,
                confidence=min(causal_strengths[node_id] / self.min_causal_strength, 1.0)
            )
            for node_id in weak_nodes
        ]
        
        return pruned_ir, results
    
    def _calculate_causal_strengths(self, ir: ExecutionIR, traces: List[List[TraceStep]]) -> Dict[str, float]:
        """Calculate causal strengths for each node based on trace data."""
        causal_strengths = {}
        
        # If no traces provided, use graph structure heuristics
        if not traces:
            for node_id in ir.nodes.keys():
                # Calculate strength based on connectivity
                incoming_edges = len([e for e in ir.edges if e[1] == node_id])
                outgoing_edges = len([e for e in ir.edges if e[0] == node_id])
                
                # Normalize by total possible connections
                total_nodes = len(ir.nodes)
                max_connections = total_nodes - 1
                
                strength = (incoming_edges + outgoing_edges) / max_connections if max_connections > 0 else 0
                causal_strengths[node_id] = strength
        else:
            # Use trace data to calculate causal strengths
            for node_id in ir.nodes.keys():
                # Calculate how often this node appears in traces
                appearance_count = sum(
                    1 for trace in traces 
                    for step in trace 
                    if step.node_id == node_id
                )
                
                # Calculate strength based on trace participation
                total_steps = sum(len(trace) for trace in traces)
                strength = appearance_count / total_steps if total_steps > 0 else 0
                
                # Boost for entry/exit points
                if node_id in ir.entry_points or node_id in ir.exit_points:
                    strength *= 1.5  # Entry/exit points are more important
                
                causal_strengths[node_id] = min(strength, 1.0)
        
        return causal_strengths
    
    def _prune_information_redundancy(self, 
                                     ir: ExecutionIR, 
                                     traces: List[List[TraceStep]]) -> Tuple[ExecutionIR, List[PruningResult]]:
        """Prune nodes that contribute redundant information."""
        # Calculate mutual information between nodes based on traces
        mutual_info_matrix = self._calculate_mutual_information(ir, traces)
        
        # Identify highly redundant nodes
        redundant_nodes = []
        
        for node_id in ir.nodes.keys():
            # Check if this node is highly correlated with others
            if node_id in mutual_info_matrix:
                max_corr = max(
                    mutual_info_matrix[node_id].values(),
                    default=0
                )
                
                if max_corr > self.redundancy_threshold:
                    redundant_nodes.append(node_id)
        
        # Create pruned IR
        pruned_ir = self._remove_nodes_from_ir(ir, redundant_nodes)
        
        # Create results
        results = [
            PruningResult(
                pruned_nodes=[node_id],
                pruned_edges=[],
                reason=PruningCriterion.INFORMATION_REDUNDANCY,
                information_retained=1.0 - self.redundancy_threshold,
                confidence=0.8
            )
            for node_id in redundant_nodes
        ]
        
        return pruned_ir, results
    
    def _calculate_mutual_information(self, ir: ExecutionIR, traces: List[List[TraceStep]]) -> Dict[str, Dict[str, float]]:
        """Calculate mutual information between nodes based on trace data."""
        mutual_info = {}
        
        if not traces:
            return mutual_info
        
        # Get all unique node IDs that appear in traces
        trace_nodes = set()
        for trace in traces:
            for step in trace:
                if step.node_id:
                    trace_nodes.add(step.node_id)
        
        # Calculate mutual information between each pair of nodes
        for node_a in trace_nodes:
            mutual_info[node_a] = {}
            
            for node_b in trace_nodes:
                if node_a != node_b:
                    # Simplified mutual information calculation based on co-occurrence
                    # In a real implementation, we'd use actual variable values
                    co_occurrence = 0
                    total_occurrences = 0
                    
                    for trace in traces:
                        # Check if both nodes appear in the same trace
                        a_appears = any(step.node_id == node_a for step in trace)
                        b_appears = any(step.node_id == node_b for step in trace)
                        
                        if a_appears and b_appears:
                            co_occurrence += 1
                        if a_appears or b_appears:
                            total_occurrences += 1
                    
                    mi = co_occurrence / total_occurrences if total_occurrences > 0 else 0
                    mutual_info[node_a][node_b] = mi
        
        return mutual_info
    
    def _prune_low_entropy(self, 
                          ir: ExecutionIR, 
                          traces: List[List[TraceStep]]) -> Tuple[ExecutionIR, List[PruningResult]]:
        """Prune nodes with low entropy (predictable behavior)."""
        entropies = self._calculate_node_entropies(ir, traces)
        
        low_entropy_nodes = [
            node_id for node_id, entropy_val in entropies.items()
            if entropy_val < self.entropy_threshold
        ]
        
        # Create pruned IR
        pruned_ir = self._remove_nodes_from_ir(ir, low_entropy_nodes)
        
        # Create results
        results = [
            PruningResult(
                pruned_nodes=[node_id],
                pruned_edges=[],
                reason=PruningCriterion.ENTROPY_THRESHOLD,
                information_retained=1.0 - (entropy_val / self.entropy_threshold),
                confidence=0.7
            )
            for node_id, entropy_val in entropies.items()
            if entropy_val < self.entropy_threshold
        ]
        
        return pruned_ir, results
    
    def _calculate_node_entropies(self, ir: ExecutionIR, traces: List[List[TraceStep]]) -> Dict[str, float]:
        """Calculate entropy for each node based on trace behavior."""
        entropies = {}
        
        if not traces:
            # If no traces, return uniform entropy
            for node_id in ir.nodes.keys():
                entropies[node_id] = 0.5  # Medium entropy as default
            return entropies
        
        # Calculate entropy based on state variety for each node
        for node_id in ir.nodes.keys():
            # Collect all state values for this node across traces
            states = []
            for trace in traces:
                for step in trace:
                    if step.node_id == node_id and step.value is not None:
                        states.append(str(step.value))
            
            if not states:
                entropies[node_id] = 0.0  # No information if never activated
                continue
            
            # Calculate entropy from state distribution
            unique_states, counts = np.unique(states, return_counts=True)
            probabilities = counts / len(states)
            
            # Calculate Shannon entropy
            entropy_val = entropy(probabilities, base=2)
            entropies[node_id] = entropy_val
        
        return entropies
    
    def _remove_nodes_from_ir(self, ir: ExecutionIR, node_ids: List[str]) -> ExecutionIR:
        """Remove specified nodes from the IR and update edges."""
        new_ir = ir.clone()
        
        # Remove nodes
        for node_id in node_ids:
            if node_id in new_ir.nodes:
                del new_ir.nodes[node_id]
        
        # Remove edges involving removed nodes
        new_ir.edges = [
            (src, tgt) for src, tgt in new_ir.edges
            if src in new_ir.nodes and tgt in new_ir.nodes
        ]
        
        # Update entry and exit points
        new_ir.entry_points = [ep for ep in new_ir.entry_points if ep in new_ir.nodes]
        new_ir.exit_points = [ep for ep in new_ir.exit_points if ep in new_ir.nodes]
        
        return new_ir
    
    def adaptive_pruning(self, 
                        ir: ExecutionIR, 
                        traces: List[List[TraceStep]], 
                        target_compression_ratio: float = 0.5) -> Tuple[ExecutionIR, List[PruningResult]]:
        """
        Perform adaptive pruning to achieve a target compression ratio.
        
        Args:
            ir: ExecutionIR to prune
            traces: Execution traces to inform pruning
            target_compression_ratio: Target ratio of nodes to keep (0-1)
            
        Returns:
            Tuple of (pruned_ir, pruning_results)
        """
        original_node_count = len(ir.nodes)
        target_node_count = int(original_node_count * target_compression_ratio)
        
        current_ir = ir.clone()
        pruning_results = []
        
        # Iteratively apply different pruning criteria until target reached
        while len(current_ir.nodes) > target_node_count:
            # Calculate which criterion to apply based on current state
            if len(current_ir.nodes) / original_node_count > 0.8:
                # Early pruning - focus on causal irrelevance
                criterion = PruningCriterion.CASUAL_IRRELEVANCE
            elif len(current_ir.nodes) / original_node_count > 0.6:
                # Mid pruning - focus on redundancy
                criterion = PruningCriterion.INFORMATION_REDUNDANCY
            else:
                # Late pruning - focus on low entropy
                criterion = PruningCriterion.ENTROPY_THRESHOLD
            
            # Apply pruning
            temp_ir, results = self.prune_graph(current_ir, traces, criterion)
            
            # If no pruning happened, try a different criterion
            if len(temp_ir.nodes) == len(current_ir.nodes):
                # Cycle through other criteria
                criteria = [
                    PruningCriterion.CASUAL_IRRELEVANCE,
                    PruningCriterion.INFORMATION_REDUNDANCY,
                    PruningCriterion.ENTROPY_THRESHOLD
                ]
                
                # Remove already tried criterion
                other_criteria = [c for c in criteria if c != criterion]
                
                pruned = False
                for alt_criterion in other_criteria:
                    temp_ir, results = self.prune_graph(current_ir, traces, alt_criterion)
                    if len(temp_ir.nodes) < len(current_ir.nodes):
                        pruned = True
                        break
                
                if not pruned:
                    # If no pruning possible, break to avoid infinite loop
                    break
            
            current_ir = temp_ir
            pruning_results.extend(results)
        
        return current_ir, pruning_results


class CausalDiscoveryEngine:
    """Advanced causal discovery for the pruner."""
    
    def __init__(self):
        self.logger = __import__('logging').getLogger("tiannara.ecm.causal_discovery")
    
    def discover_causal_graph(self, traces: List[List[TraceStep]]) -> nx.DiGraph:
        """
        Discover causal relationships from execution traces.
        
        Args:
            traces: List of execution traces
            
        Returns:
            NetworkX DiGraph representing causal relationships
        """
        # Create a graph where nodes are variables/states in traces
        causal_graph = nx.DiGraph()
        
        if not traces:
            return causal_graph
        
        # Extract all unique variables/states from traces
        all_variables = set()
        for trace in traces:
            for step in trace:
                if step.variable_name:
                    all_variables.add(step.variable_name)
                if step.node_id:
                    all_variables.add(step.node_id)
        
        # Add nodes to the graph
        for var in all_variables:
            causal_graph.add_node(var)
        
        # Infer causal relationships based on temporal ordering in traces
        for trace in traces:
            # Look for sequential relationships in the trace
            for i in range(len(trace) - 1):
                step1 = trace[i]
                step2 = trace[i + 1]
                
                # Add edge if both have meaningful identifiers
                var1 = step1.variable_name or step1.node_id
                var2 = step2.variable_name or step2.node_id
                
                if var1 and var2 and var1 != var2:
                    # Add directional edge from earlier to later
                    if not causal_graph.has_edge(var1, var2):
                        causal_graph.add_edge(var1, var2, weight=1.0)
                    else:
                        # Increment weight if edge exists
                        causal_graph[var1][var2]['weight'] += 1.0
        
        return causal_graph
    
    def validate_causal_model(self, 
                             causal_graph: nx.DiGraph, 
                             traces: List[List[TraceStep]]) -> Dict[str, float]:
        """
        Validate the discovered causal model against traces.
        
        Args:
            causal_graph: Discovered causal graph
            traces: Execution traces for validation
            
        Returns:
            Dictionary with validation metrics
        """
        if not traces:
            return {"accuracy": 0.0, "coverage": 0.0}
        
        # Count how many trace relationships are consistent with the causal model
        total_relationships = 0
        consistent_relationships = 0
        
        for trace in traces:
            for i in range(len(trace) - 1):
                step1 = trace[i]
                step2 = trace[i + 1]
                
                var1 = step1.variable_name or step1.node_id
                var2 = step2.variable_name or step2.node_id
                
                if var1 and var2 and var1 != var2:
                    total_relationships += 1
                    
                    # Check if the causal graph supports this relationship
                    # Either direct edge or path exists
                    if (causal_graph.has_edge(var1, var2) or 
                        nx.has_path(causal_graph, var1, var2)):
                        consistent_relationships += 1
        
        accuracy = consistent_relationships / total_relationships if total_relationships > 0 else 0.0
        coverage = total_relationships / len(traces) if len(traces) > 0 else 0.0
        
        return {
            "accuracy": accuracy,
            "coverage": coverage,
            "consistent_relationships": consistent_relationships,
            "total_relationships": total_relationships
        }


# Example usage
if __name__ == "__main__":
    from .ir_representation import create_simple_test_ir
    from .trace_sandbox import TraceStep, TraceEventType
    
    # Create a test IR
    test_ir = create_simple_test_ir()
    print(f"Original IR has {len(test_ir.nodes)} nodes and {len(test_ir.edges)} edges")
    
    # Create some test traces
    test_traces = [
        [
            TraceStep(t=0, event_type=TraceEventType.VARIABLE_WRITE, variable_name="x", value=5),
            TraceStep(t=1, event_type=TraceEventType.VARIABLE_WRITE, variable_name="y", value=3),
            TraceStep(t=2, event_type=TraceEventType.NODE_ENTRY, node_id="node_0"),
            TraceStep(t=3, event_type=TraceEventType.NODE_ENTRY, node_id="node_1"),
            TraceStep(t=4, event_type=TraceEventType.FUNCTION_RETURN, output_state={"result": 42})
        ],
        [
            TraceStep(t=0, event_type=TraceEventType.VARIABLE_WRITE, variable_name="x", value=10),
            TraceStep(t=1, event_type=TraceEventType.VARIABLE_WRITE, variable_name="y", value=7),
            TraceStep(t=2, event_type=TraceEventType.NODE_ENTRY, node_id="node_0"),
            TraceStep(t=3, event_type=TraceEventType.NODE_ENTRY, node_id="node_1"),
            TraceStep(t=4, event_type=TraceEventType.FUNCTION_RETURN, output_state={"result": 85})
        ]
    ]
    
    # Create pruner
    pruner = InformationPruner(entropy_threshold=0.2, min_causal_strength=0.1)
    
    # Perform different types of pruning
    print("\n--- Causal Irrelevance Pruning ---")
    pruned_ir1, results1 = pruner.prune_graph(test_ir, test_traces, PruningCriterion.CASUAL_IRRELEVANCE)
    print(f"Pruned to {len(pruned_ir1.nodes)} nodes, {len(pruned_ir1.edges)} edges")
    print(f"Pruning results: {len(results1)} nodes pruned")
    
    print("\n--- Information Redundancy Pruning ---")
    pruned_ir2, results2 = pruner.prune_graph(test_ir, test_traces, PruningCriterion.INFORMATION_REDUNDANCY)
    print(f"Pruned to {len(pruned_ir2.nodes)} nodes, {len(pruned_ir2.edges)} edges")
    print(f"Pruning results: {len(results2)} nodes pruned")
    
    print("\n--- Adaptive Pruning (50% compression) ---")
    pruned_ir3, results3 = pruner.adaptive_pruning(test_ir, test_traces, target_compression_ratio=0.5)
    print(f"Pruned to {len(pruned_ir3.nodes)} nodes, {len(pruned_ir3.edges)} edges")
    print(f"Pruning results: {len(results3)} total pruning operations")
    
    # Test causal discovery
    print("\n--- Causal Discovery ---")
    causal_engine = CausalDiscoveryEngine()
    causal_graph = causal_engine.discover_causal_graph(test_traces)
    print(f"Discovered causal graph with {len(causal_graph.nodes)} nodes and {len(causal_graph.edges)} edges")
    
    validation = causal_engine.validate_causal_model(causal_graph, test_traces)
    print(f"Validation metrics: {validation}")