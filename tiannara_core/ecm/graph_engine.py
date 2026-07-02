"""
ECM Graph Engine (REAL STRUCTURAL REASONING)

Graph-based execution reasoning engine that implements the 5 core mutation operators
from the ECM framework.
"""

import networkx as nx
import random
import numpy as np
from typing import List, Dict, Any, Optional, Tuple
import logging
from enum import Enum


class MutationOperator(Enum):
    """The 5 core mutation operators from ECM-RE."""
    CFTS = "control_flow_topology_surgery"
    DFTD = "data_flow_taint_diffusion"
    TSF = "temporal_state_forking"
    EMAP = "environment_mocking_api_perturbation"
    IRCP = "invariant_relaxation_constraint_probing"


class ECMGraphEngine:
    """Graph-based engine for executable causal manifolds."""
    
    def __init__(self):
        self.graph = nx.DiGraph()
        self.logger = logging.getLogger("tiannara.ecm.graph_engine")
        self.mutation_history = []
    
    def build_from_trace(self, trace: List[Dict[str, Any]]):
        """
        Build a causal graph from execution trace.
        
        Args:
            trace: Execution trace with step-by-step execution data
        """
        self.graph.clear()
        
        for i, step in enumerate(trace):
            node_id = f"step_{i}"
            self.graph.add_node(node_id, 
                               data=step,
                               timestamp=step.get('t', i),
                               event_type=step.get('event_type', 'unknown'))
            
            # Connect to previous node to form execution sequence
            if i > 0:
                prev_node = f"step_{i-1}"
                self.graph.add_edge(prev_node, node_id, 
                                   type="sequential_execution")
            
            # Extract additional causal relationships
            self._extract_causal_relationships(step, node_id)
    
    def _extract_causal_relationships(self, step: Dict[str, Any], current_node: str):
        """Extract causal relationships from trace step."""
        # Look for variable dependencies
        if 'input_state' in step and isinstance(step['input_state'], dict):
            for var_name, value in step['input_state'].items():
                var_node = f"var_{var_name}"
                self.graph.add_node(var_node, 
                                   type="variable", 
                                   name=var_name, 
                                   value=value)
                self.graph.add_edge(var_node, current_node, 
                                   type="data_dependency")
        
        # Look for function call relationships
        if step.get('function_name'):
            func_node = f"func_{step['function_name']}"
            self.graph.add_node(func_node, 
                               type="function", 
                               name=step['function_name'])
            self.graph.add_edge(func_node, current_node, 
                               type="function_invocation")
    
    def mutate_graph(self, operator: Optional[MutationOperator] = None) -> MutationOperator:
        """
        Apply a mutation to the graph using one of the core ECM operators.
        
        Args:
            operator: Specific operator to use, or None to choose randomly
            
        Returns:
            The operator that was applied
        """
        if len(self.graph.nodes) < 2:
            return None
        
        # If no specific operator provided, choose randomly
        if operator is None:
            operator = random.choice(list(MutationOperator))
        
        self.logger.info(f"Applying mutation: {operator.value}")
        
        try:
            if operator == MutationOperator.CFTS:
                self._apply_cfts_mutation()
            elif operator == MutationOperator.DFTD:
                self._apply_dftd_mutation()
            elif operator == MutationOperator.TSF:
                self._apply_tsf_mutation()
            elif operator == MutationOperator.EMAP:
                self._apply_emap_mutation()
            elif operator == MutationOperator.IRCP:
                self._applyircp_mutation()
            
            # Record mutation
            self.mutation_history.append({
                'operator': operator.value,
                'timestamp': len(self.mutation_history)
            })
            
            return operator
        except Exception as e:
            self.logger.error(f"Mutation failed: {e}")
            return operator  # Return attempted operator even if failed
    
    def _apply_cfts_mutation(self):
        """Apply Control-Flow Topology Surgery mutation."""
        # Find execution nodes (not variable/function nodes)
        exec_nodes = [n for n, attr in self.graph.nodes(data=True) 
                     if attr.get('event_type') in ['node_entry', 'function_call', 'branch_taken']]
        
        if len(exec_nodes) < 2:
            return
        
        # Randomly select a node to modify
        target_node = random.choice(exec_nodes)
        
        # Get neighbors
        predecessors = list(self.graph.predecessors(target_node))
        successors = list(self.graph.successors(target_node))
        
        if len(predecessors) > 0 and len(successors) > 0:
            # Randomly rewire one successor to a predecessor
            pred = random.choice(predecessors)
            succ = random.choice(successors)
            
            # Remove original edge and create new one
            if self.graph.has_edge(target_node, succ):
                self.graph.remove_edge(target_node, succ)
                self.graph.add_edge(pred, succ, type="rewired_control_flow")
    
    def _apply_dftd_mutation(self):
        """Apply Data-Flow Taint Diffusion mutation."""
        # Find variable nodes
        var_nodes = [n for n, attr in self.graph.nodes(data=True) 
                    if attr.get('type') == 'variable']
        
        if len(var_nodes) < 2:
            return
        
        # Select two variable nodes and connect them
        source_var, target_var = random.sample(var_nodes, 2)
        
        # Add a data flow edge between variables
        self.graph.add_edge(source_var, target_var, type="data_flow_taint")
    
    def _apply_tsf_mutation(self):
        """Apply Temporal State Forking mutation."""
        # Find execution nodes
        exec_nodes = [n for n, attr in self.graph.nodes(data=True) 
                     if attr.get('event_type') in ['node_entry', 'function_call']]
        
        if len(exec_nodes) < 1:
            return
        
        # Duplicate a node to simulate forking
        node_to_duplicate = random.choice(exec_nodes)
        attr = self.graph.nodes[node_to_duplicate]
        
        # Create a new node with same properties but different ID
        new_node_id = f"{node_to_duplicate}_fork"
        self.graph.add_node(new_node_id, **attr)
        
        # Add parallel edges for the fork
        for pred in self.graph.predecessors(node_to_duplicate):
            self.graph.add_edge(pred, new_node_id, type="temporal_fork")
        
        for succ in self.graph.successors(node_to_duplicate):
            self.graph.add_edge(new_node_id, succ, type="temporal_fork")
    
    def _apply_emap_mutation(self):
        """Apply Environment Mocking & API Perturbation mutation."""
        # Find function nodes
        func_nodes = [n for n, attr in self.graph.nodes(data=True) 
                     if attr.get('type') == 'function']
        
        if len(func_nodes) < 1:
            return
        
        # Modify a function node to simulate mocking
        func_node = random.choice(func_nodes)
        current_attr = self.graph.nodes[func_node]
        
        # Add mocking flag
        self.graph.nodes[func_node]['mocked'] = True
        self.graph.nodes[func_node]['original_behavior'] = current_attr
    
    def _applyircp_mutation(self):
        """Apply Invariant Relaxation & Constraint Probing mutation."""
        # Find constraint-related nodes
        constraint_nodes = [n for n, attr in self.graph.nodes(data=True) 
                           if 'constraint' in str(attr.get('data', {})).lower() or 
                              'bound' in str(attr.get('data', {})).lower()]
        
        if len(constraint_nodes) == 0:
            # If no explicit constraints found, pick any node and mark it as relaxed
            exec_nodes = [n for n, attr in self.graph.nodes(data=True) 
                         if attr.get('event_type') in ['node_entry', 'function_call']]
            if not exec_nodes:
                return
            constraint_nodes = [random.choice(exec_nodes)]
        
        # Mark a constraint as relaxed
        node = random.choice(constraint_nodes)
        self.graph.nodes[node]['constraint_relaxed'] = True
    
    def extract_paths(self) -> List[List[str]]:
        """
        Extract all simple paths from source to sink nodes.
        
        Returns:
            List of paths, each path is a list of node IDs
        """
        if not self.graph.nodes():
            return []
        
        # Find source nodes (nodes with no predecessors)
        sources = [n for n in self.graph.nodes() if self.graph.in_degree(n) == 0]
        # Find sink nodes (nodes with no successors)
        sinks = [n for n in self.graph.nodes() if self.graph.out_degree(n) == 0]
        
        if not sources or not sinks:
            # If no clear sources/sinks, use first and last nodes
            nodes = list(self.graph.nodes())
            sources = [nodes[0]] if nodes else []
            sinks = [nodes[-1]] if nodes else []
        
        paths = []
        for source in sources:
            for sink in sinks:
                try:
                    # Limit path length to prevent extremely long computations
                    path_generator = nx.all_simple_paths(self.graph, source, sink, cutoff=10)
                    for path in path_generator:
                        paths.append(path)
                except nx.NetworkXNoPath:
                    continue  # No path exists between source and sink
        
        return paths
    
    def get_causal_subgraph(self, node_id: str, radius: int = 2) -> nx.DiGraph:
        """
        Extract a causal subgraph around a specific node.
        
        Args:
            node_id: Center node ID
            radius: Radius of subgraph to extract
            
        Returns:
            Subgraph centered on the node
        """
        if node_id not in self.graph:
            return nx.DiGraph()
        
        subgraph_nodes = nx.ego_graph(self.graph, node_id, radius=radius).nodes()
        return self.graph.subgraph(subgraph_nodes)
    
    def analyze_causal_strength(self) -> Dict[str, float]:
        """
        Analyze causal strength between nodes based on graph structure.
        
        Returns:
            Dictionary mapping node pairs to causal strength scores
        """
        causal_strengths = {}
        
        for node in self.graph.nodes():
            # Calculate betweenness centrality as a proxy for causal importance
            try:
                centrality = nx.betweenness_centrality(self.graph)
                causal_strengths[node] = centrality.get(node, 0.0)
            except Exception:
                # If centrality calculation fails, use degree as proxy
                causal_strengths[node] = self.graph.degree(node) / (len(self.graph) - 1) if len(self.graph) > 1 else 0.0
        
        return causal_strengths


# Example usage
if __name__ == "__main__":
    # Create sample trace
    sample_trace = [
        {"t": 0, "event_type": "node_entry", "node_id": "A", "input_state": {"x": 5}},
        {"t": 1, "event_type": "variable_write", "variable_name": "x", "value": 10},
        {"t": 2, "event_type": "node_entry", "node_id": "B", "input_state": {"x": 10}},
        {"t": 3, "function_name": "add", "event_type": "function_call", "input_state": {"x": 10, "y": 5}},
        {"t": 4, "event_type": "function_return", "output": 15}
    ]
    
    # Create ECM engine and build graph
    engine = ECMGraphEngine()
    engine.build_from_trace(sample_trace)
    
    print(f"Graph built with {len(engine.graph.nodes)} nodes and {len(engine.graph.edges)} edges")
    
    # Apply a mutation
    operator = engine.mutate_graph()
    print(f"Applied mutation: {operator.value}")
    print(f"Graph now has {len(engine.graph.nodes)} nodes and {len(engine.graph.edges)} edges")
    
    # Extract paths
    paths = engine.extract_paths()
    print(f"Found {len(paths)} execution paths")
    if paths:
        print(f"First path: {paths[0]}")
    
    # Analyze causal strengths
    strengths = engine.analyze_causal_strength()
    print(f"Causal strengths: {dict(list(strengths.items())[:5])}")  # Show first 5