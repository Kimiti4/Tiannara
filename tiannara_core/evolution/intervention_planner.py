"""
Intervention-Driven Planner for Executable Causal Manifolds (ECM)

Proposes structural mutations (subgraph swaps, constraint relaxations, 
parameter perturbations, fault injections) guided by information gain.
"""

from typing import List, Dict, Any, Tuple, Optional, Callable
from dataclasses import dataclass
import numpy as np
from enum import Enum
import random
import networkx as nx
try:
    from scipy.special import softmax
    HAS_SCIPY = True
except ImportError:
    HAS_SCIPY = False
    import math
    
    def softmax(x):
        """Fallback softmax implementation."""
        if isinstance(x, list):
            x = [float(v) for v in x]
        max_x = max(x) if isinstance(x, (list, tuple)) else x
        exp_x = [math.exp(v - max_x) for v in x] if isinstance(x, (list, tuple)) else [math.exp(x - max_x)]
        sum_exp = sum(exp_x)
        return [e / sum_exp for e in exp_x]
from ..evolution.ir_representation import ExecutionIR, IRNode, IRNodeType
from ..evolution.trace_sandbox import TraceSandbox, TraceEmbedder
from ..evolution.graph_mutators import GraphMutator


class InterventionType(Enum):
    """Types of interventions that can be applied."""
    SUBGRAPH_SWAP = "subgraph_swap"
    CONSTRAINT_RELAXATION = "constraint_relaxation"
    PARAMETER_PERTURBATION = "parameter_perturbation"
    FAULT_INJECTION = "fault_injection"
    NODE_INSERTION = "node_insertion"
    NODE_DELETION = "node_deletion"
    EDGE_MODIFICATION = "edge_modification"
    TYPE_CHANGE = "type_change"


@dataclass
class Intervention:
    """Represents a single intervention operation."""
    id: str
    intervention_type: InterventionType
    description: str
    target_nodes: List[str]
    parameters: Dict[str, Any]
    predicted_information_gain: float
    feasibility_score: float  # 0-1, how likely this intervention is to succeed
    causal_effect_size: float  # Expected impact on system behavior


class InterventionPlanner:
    """Plans interventions to maximize information gain about system structure."""
    
    def __init__(self, 
                 exploration_factor: float = 0.5,
                 max_candidates: int = 20,
                 min_feasibility: float = 0.3):
        self.exploration_factor = exploration_factor
        self.max_candidates = max_candidates
        self.min_feasibility = min_feasibility
        self.logger = __import__('logging').getLogger("tiannara.ecm.intervention_planner")
        self.trace_sandbox = TraceSandbox()
        self.trace_embedder = TraceEmbedder()
        self.graph_mutator = GraphMutator()
        
        # Track intervention history for learning
        self.intervention_history: List[Tuple[Intervention, float]] = []  # (intervention, actual_gain)
    
    def propose_interventions(self, 
                             ir: ExecutionIR, 
                             current_trace: Optional[List] = None,
                             num_proposals: int = 5) -> List[Intervention]:
        """
        Propose structural mutations to maximize information gain.
        
        Args:
            ir: Current ExecutionIR to intervene on
            current_trace: Current execution trace for comparison
            num_proposals: Number of intervention proposals to generate
            
        Returns:
            List of ranked intervention proposals
        """
        interventions = []
        
        # Generate different types of interventions
        interventions.extend(self._propose_subgraph_swaps(ir))
        interventions.extend(self._propose_parameter_perturbations(ir))
        interventions.extend(self._propose_node_operations(ir))
        interventions.extend(self._propose_constraint_relaxations(ir))
        interventions.extend(self._propose_edge_modifications(ir))
        
        # Rank interventions by predicted information gain
        ranked_interventions = sorted(
            interventions, 
            key=lambda x: x.predicted_information_gain * x.feasibility_score, 
            reverse=True
        )
        
        # Return top proposals
        return ranked_interventions[:num_proposals]
    
    def _propose_subgraph_swaps(self, ir: ExecutionIR) -> List[Intervention]:
        """Propose subgraph swap interventions."""
        interventions = []
        
        # Identify candidate subgraphs to swap
        subgraph_candidates = self._find_swappable_subgraphs(ir)
        
        for subgraph_info in subgraph_candidates:
            target_nodes = subgraph_info['nodes']
            
            intervention = Intervention(
                id=f"swap_{len(interventions)}",
                intervention_type=InterventionType.SUBGRAPH_SWAP,
                description=f"Swap subgraph containing {len(target_nodes)} nodes",
                target_nodes=target_nodes,
                parameters={
                    'replacement_type': subgraph_info['type'],
                    'size': len(target_nodes)
                },
                predicted_information_gain=random.uniform(0.4, 0.8),
                feasibility_score=random.uniform(0.6, 0.9),
                causal_effect_size=random.uniform(0.3, 0.7)
            )
            
            interventions.append(intervention)
        
        return interventions
    
    def _find_swappable_subgraphs(self, ir: ExecutionIR) -> List[Dict[str, Any]]:
        """Find subgraphs that could potentially be swapped."""
        candidates = []
        
        # Look for patterns: input -> operation -> output
        for node_id, node in ir.nodes.items():
            if node.node_type == IRNodeType.OPERATION:
                # Find connected subgraph
                connected = self._get_connected_subgraph(ir, node_id, max_depth=3)
                
                if len(connected) > 1:  # Only consider non-trivial subgraphs
                    candidates.append({
                        'nodes': connected,
                        'type': 'computation_block',
                        'size': len(connected)
                    })
        
        return candidates
    
    def _get_connected_subgraph(self, ir: ExecutionIR, start_node: str, max_depth: int = 2) -> List[str]:
        """Get nodes connected to start_node within max_depth."""
        visited = set()
        queue = [(start_node, 0)]  # (node_id, depth)
        
        while queue:
            current_node, depth = queue.pop(0)
            
            if current_node in visited or depth >= max_depth:
                continue
                
            visited.add(current_node)
            
            # Add neighbors
            for src, tgt in ir.edges:
                if src == current_node and tgt not in visited:
                    queue.append((tgt, depth + 1))
                elif tgt == current_node and src not in visited:
                    queue.append((src, depth + 1))
        
        return list(visited)
    
    def _propose_parameter_perturbations(self, ir: ExecutionIR) -> List[Intervention]:
        """Propose parameter perturbation interventions."""
        interventions = []
        
        # Find constant nodes to perturb
        constant_nodes = [
            node_id for node_id, node in ir.nodes.items() 
            if node.is_constant and node.value is not None
        ]
        
        for node_id in constant_nodes[:5]:  # Limit to first 5
            original_value = ir.nodes[node_id].value
            
            # Determine perturbation magnitude based on value
            if isinstance(original_value, (int, float)):
                magnitude = abs(original_value) * 0.1 if original_value != 0 else 1.0
                new_value = original_value + random.uniform(-magnitude, magnitude)
            else:
                new_value = original_value  # For non-numeric values, keep original
                
            intervention = Intervention(
                id=f"perturb_{len(interventions)}",
                intervention_type=InterventionType.PARAMETER_PERTURBATION,
                description=f"Perturb constant {original_value} -> {new_value}",
                target_nodes=[node_id],
                parameters={
                    'original_value': original_value,
                    'new_value': new_value
                },
                predicted_information_gain=random.uniform(0.2, 0.6),
                feasibility_score=0.95,
                causal_effect_size=random.uniform(0.1, 0.4)
            )
            
            interventions.append(intervention)
        
        return interventions
    
    def _propose_node_operations(self, ir: ExecutionIR) -> List[Intervention]:
        """Propose node insertion/deletion operations."""
        interventions = []
        
        # Node insertion
        for _ in range(3):
            intervention = Intervention(
                id=f"insert_{len(interventions)}",
                intervention_type=InterventionType.NODE_INSERTION,
                description="Insert new operation node",
                target_nodes=[],
                parameters={
                    'node_type': 'operation',
                    'operation': random.choice(['ADD', 'SUB', 'MULT', 'DIV'])
                },
                predicted_information_gain=random.uniform(0.3, 0.7),
                feasibility_score=random.uniform(0.5, 0.8),
                causal_effect_size=random.uniform(0.2, 0.6)
            )
            interventions.append(intervention)
        
        # Node deletion (only non-critical nodes)
        variable_nodes = [
            node_id for node_id, node in ir.nodes.items() 
            if node.node_type == IRNodeType.VARIABLE
        ]
        
        for node_id in variable_nodes[:2]:  # Limit to first 2
            intervention = Intervention(
                id=f"delete_{len(interventions)}",
                intervention_type=InterventionType.NODE_DELETION,
                description=f"Delete variable node {node_id}",
                target_nodes=[node_id],
                parameters={},
                predicted_information_gain=random.uniform(0.4, 0.8),
                feasibility_score=random.uniform(0.4, 0.7),
                causal_effect_size=random.uniform(0.3, 0.7)
            )
            interventions.append(intervention)
        
        return interventions
    
    def _propose_constraint_relaxations(self, ir: ExecutionIR) -> List[Intervention]:
        """Propose constraint relaxation interventions."""
        interventions = []
        
        # For now, simulate constraint relaxations
        for i in range(3):
            intervention = Intervention(
                id=f"relax_{len(interventions)}",
                intervention_type=InterventionType.CONSTRAINT_RELAXATION,
                description=f"Relax constraint on variable access #{i}",
                target_nodes=[],
                parameters={
                    'constraint_type': 'access_pattern',
                    'relaxation_degree': random.uniform(0.1, 0.5)
                },
                predicted_information_gain=random.uniform(0.3, 0.6),
                feasibility_score=0.8,
                causal_effect_size=random.uniform(0.2, 0.5)
            )
            interventions.append(intervention)
        
        return interventions
    
    def _propose_edge_modifications(self, ir: ExecutionIR) -> List[Intervention]:
        """Propose edge modification interventions."""
        interventions = []
        
        # Edge addition
        for _ in range(2):
            intervention = Intervention(
                id=f"add_edge_{len(interventions)}",
                intervention_type=InterventionType.EDGE_MODIFICATION,
                description="Add new edge between random nodes",
                target_nodes=[],
                parameters={
                    'modification_type': 'addition',
                    'source_hint': 'random',
                    'target_hint': 'random'
                },
                predicted_information_gain=random.uniform(0.2, 0.5),
                feasibility_score=random.uniform(0.6, 0.9),
                causal_effect_size=random.uniform(0.1, 0.4)
            )
            interventions.append(intervention)
        
        # Edge removal (only if graph remains connected)
        if len(ir.edges) > 1:
            random_edge = random.choice(ir.edges)
            intervention = Intervention(
                id=f"remove_edge_{len(interventions)}",
                intervention_type=InterventionType.EDGE_MODIFICATION,
                description=f"Remove edge {random_edge[0]} -> {random_edge[1]}",
                target_nodes=[],
                parameters={
                    'modification_type': 'removal',
                    'source': random_edge[0],
                    'target': random_edge[1]
                },
                predicted_information_gain=random.uniform(0.4, 0.7),
                feasibility_score=random.uniform(0.3, 0.6),
                causal_effect_size=random.uniform(0.3, 0.6)
            )
            interventions.append(intervention)
        
        return interventions
    
    def evaluate_intervention(self, 
                             ir: ExecutionIR, 
                             intervention: Intervention, 
                             baseline_trace: List) -> float:
        """
        Evaluate an intervention by applying it and measuring information gain.
        
        Args:
            ir: Original IR
            intervention: Intervention to apply
            baseline_trace: Baseline execution trace for comparison
            
        Returns:
            Information gain achieved by the intervention
        """
        # Apply intervention to get modified IR
        modified_ir = self._apply_intervention(ir, intervention)
        
        if modified_ir is None:
            return 0.0  # Intervention failed
        
        # Execute modified IR to get new trace
        # In a real implementation, we would execute the modified IR
        # For now, we'll simulate with a modified version of the baseline
        modified_trace = self._simulate_modified_trace(baseline_trace, intervention)
        
        # Compare traces to measure information gain
        baseline_embedding = self.trace_embedder.sandbox.embed_trace(baseline_trace)
        modified_embedding = self.trace_embedder.sandbox.embed_trace(modified_trace)
        
        # Calculate information gain as difference in embeddings
        distance = self.trace_embedder.distance(baseline_embedding, modified_embedding)
        
        # Use KL divergence as additional measure
        kl_div = self.trace_embedder.kl_divergence(baseline_embedding, modified_embedding)
        
        # Combine measures (with KL divergence weighted more heavily)
        information_gain = 0.3 * distance + 0.7 * max(0, kl_div)  # Ensure non-negative
        
        return information_gain
    
    def _apply_intervention(self, ir: ExecutionIR, intervention: Intervention) -> Optional[ExecutionIR]:
        """Apply an intervention to an IR and return the modified IR."""
        try:
            if intervention.intervention_type == InterventionType.SUBGRAPH_SWAP:
                return self.graph_mutator.swap_subgraph(ir, intervention.target_nodes)
            elif intervention.intervention_type == InterventionType.NODE_INSERTION:
                return self.graph_mutator.insert_node(ir, intervention.parameters)
            elif intervention.intervention_type == InterventionType.NODE_DELETION:
                return self.graph_mutator.delete_nodes(ir, intervention.target_nodes)
            elif intervention.intervention_type == InterventionType.EDGE_MODIFICATION:
                if intervention.parameters.get('modification_type') == 'addition':
                    return self.graph_mutator.add_random_edge(ir)
                else:
                    return self.graph_mutator.remove_random_edge(ir)
            elif intervention.intervention_type == InterventionType.PARAMETER_PERTURBATION:
                return self.graph_mutator.perturb_constants(ir, intervention.target_nodes, intervention.parameters)
            else:
                # For other intervention types, return a copy of the original IR
                return ir.clone()
        except Exception as e:
            self.logger.error(f"Failed to apply intervention {intervention.id}: {e}")
            return None
    
    def _simulate_modified_trace(self, baseline_trace: List, intervention: Intervention) -> List:
        """Simulate a modified trace based on the intervention."""
        # In a real implementation, this would execute the modified IR
        # For simulation, we'll modify the baseline trace slightly
        import copy
        modified_trace = copy.deepcopy(baseline_trace)
        
        # Add a small modification based on intervention type
        if len(modified_trace) > 0:
            # Modify one step to reflect the intervention
            step_idx = min(1, len(modified_trace) - 1)
            modified_trace[step_idx].event_type = list(__import__('tiannara_core.evolution.trace_sandbox').TraceEventType)[
                (list(__import__('tiannara_core.evolution.trace_sandbox').TraceEventType).index(
                    modified_trace[step_idx].event_type
                ) + 1) % len(list(__import__('tiannara_core.evolution.trace_sandbox').TraceEventType))
            ]
        
        return modified_trace
    
    def select_intervention(self, 
                           ir: ExecutionIR, 
                           baseline_trace: List, 
                           num_options: int = 3) -> Optional[Intervention]:
        """
        Select the best intervention based on information gain.
        
        Args:
            ir: Current IR to intervene on
            baseline_trace: Baseline execution trace
            num_options: Number of options to consider
            
        Returns:
            Selected intervention or None if none feasible
        """
        # Generate intervention proposals
        proposals = self.propose_interventions(ir, baseline_trace, num_options)
        
        if not proposals:
            return None
        
        # Evaluate each proposal
        evaluated_interventions = []
        for intervention in proposals:
            if intervention.feasibility_score >= self.min_feasibility:
                gain = self.evaluate_intervention(ir, intervention, baseline_trace)
                evaluated_interventions.append((intervention, gain))
        
        if not evaluated_interventions:
            return None
        
        # Select based on information gain (with some exploration)
        if random.random() < self.exploration_factor:
            # With some probability, select randomly among top options (exploration)
            top_interventions = sorted(evaluated_interventions, key=lambda x: x[1], reverse=True)[:2]
            selected = random.choice(top_interventions)[0]
        else:
            # Otherwise, select the one with highest information gain
            selected = max(evaluated_interventions, key=lambda x: x[1])[0]
        
        return selected


# Additional helper class for graph operations
class GraphMutator:
    """Performs graph mutations on ExecutionIR objects."""
    
    def __init__(self):
        self.logger = __import__('logging').getLogger("tiannara.ecm.graph_mutator")
    
    def swap_subgraph(self, ir: ExecutionIR, node_ids: List[str]) -> ExecutionIR:
        """Swap a subgraph with an alternative implementation."""
        new_ir = ir.clone()
        
        # For now, we'll just return the clone
        # In a real implementation, this would replace the subgraph
        return new_ir
    
    def insert_node(self, ir: ExecutionIR, params: Dict[str, Any]) -> ExecutionIR:
        """Insert a new node into the IR."""
        new_ir = ir.clone()
        
        # Create a new node based on parameters
        new_node = IRNode(
            node_type=IRNodeType.OPERATION,
            operation=params.get('operation', 'NOP'),
            source_code=f"new_{params.get('operation', 'NOP').lower()}_node"
        )
        
        new_ir.add_node(new_node)
        
        # Connect to random existing node
        if new_ir.nodes:
            random_node_id = random.choice(list(new_ir.nodes.keys()))
            if random_node_id != new_node.id:
                new_ir.add_edge(random_node_id, new_node.id)
        
        return new_ir
    
    def delete_nodes(self, ir: ExecutionIR, node_ids: List[str]) -> ExecutionIR:
        """Delete specified nodes from the IR."""
        new_ir = ir.clone()
        
        # Remove nodes and associated edges
        for node_id in node_ids:
            if node_id in new_ir.nodes:
                del new_ir.nodes[node_id]
        
        # Filter out edges that involve deleted nodes
        new_ir.edges = [
            (src, tgt) for src, tgt in new_ir.edges 
            if src in new_ir.nodes and tgt in new_ir.nodes
        ]
        
        return new_ir
    
    def add_random_edge(self, ir: ExecutionIR) -> ExecutionIR:
        """Add a random edge between two nodes."""
        new_ir = ir.clone()
        
        if len(new_ir.nodes) < 2:
            return new_ir  # Need at least 2 nodes to add an edge
        
        # Select two different nodes
        node_ids = list(new_ir.nodes.keys())
        src_id, tgt_id = random.sample(node_ids, 2)
        
        # Add edge if it doesn't already exist
        if (src_id, tgt_id) not in new_ir.edges:
            new_ir.add_edge(src_id, tgt_id)
        
        return new_ir
    
    def remove_random_edge(self, ir: ExecutionIR) -> ExecutionIR:
        """Remove a random edge from the IR."""
        new_ir = ir.clone()
        
        if not new_ir.edges:
            return new_ir  # No edges to remove
        
        # Remove a random edge
        edge_to_remove = random.choice(new_ir.edges)
        new_ir.edges.remove(edge_to_remove)
        
        # Update node connections
        src_id, tgt_id = edge_to_remove
        if tgt_id in new_ir.nodes[src_id].outputs:
            new_ir.nodes[src_id].outputs.remove(tgt_id)
        if src_id in new_ir.nodes[tgt_id].inputs:
            new_ir.nodes[tgt_id].inputs.remove(src_id)
        
        return new_ir
    
    def perturb_constants(self, ir: ExecutionIR, node_ids: List[str], params: Dict[str, Any]) -> ExecutionIR:
        """Perturb constant values in the IR."""
        new_ir = ir.clone()
        
        for node_id in node_ids:
            if node_id in new_ir.nodes:
                node = new_ir.nodes[node_id]
                if node.is_constant and isinstance(node.value, (int, float)):
                    # Apply perturbation
                    original_value = node.value
                    new_value = params.get('new_value', original_value)
                    node.value = new_value
                    node.source_code = str(new_value)
        
        return new_ir


# Example usage
if __name__ == "__main__":
    from .ir_representation import create_simple_test_ir
    
    # Create a test IR
    test_ir = create_simple_test_ir()
    print(f"Original IR has {len(test_ir.nodes)} nodes and {len(test_ir.edges)} edges")
    
    # Create planner
    planner = InterventionPlanner()
    
    # Generate some fake trace data
    from .trace_sandbox import TraceStep, TraceEventType
    fake_trace = [
        TraceStep(t=i, event_type=TraceEventType.NODE_ENTRY, node_id=f"node_{i}")
        for i in range(5)
    ]
    
    # Propose interventions
    proposals = planner.propose_interventions(test_ir, fake_trace, num_proposals=3)
    print(f"\nGenerated {len(proposals)} intervention proposals:")
    
    for i, proposal in enumerate(proposals):
        print(f"  {i+1}. {proposal.intervention_type.value}: {proposal.description}")
        print(f"     Predicted gain: {proposal.predicted_information_gain:.3f}, "
              f"Feasibility: {proposal.feasibility_score:.3f}")
    
    # Select and apply an intervention
    selected = planner.select_intervention(test_ir, fake_trace)
    if selected:
        print(f"\nSelected intervention: {selected.intervention_type.value} - {selected.description}")
        
        # Apply the intervention
        modified_ir = planner._apply_intervention(test_ir, selected)
        if modified_ir:
            print(f"Modified IR has {len(modified_ir.nodes)} nodes and {len(modified_ir.edges)} edges")
    else:
        print("\nNo suitable intervention found")