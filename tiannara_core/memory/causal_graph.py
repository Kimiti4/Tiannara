"""
Causal Memory Graph

Knowledge graph for storing causal relationships discovered through execution traces.
"""

import networkx as nx
import logging
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime


class CausalMemory:
    """Graph-based memory system for storing causal relationships."""
    
    def __init__(self):
        self.graph = nx.DiGraph()
        self.logger = logging.getLogger("tiannara.memory.causal_graph")
        self.observation_count = 0
    
    def add_observation(self, trace: List[Dict[str, Any]], score: float = 1.0, 
                       metadata: Optional[Dict[str, Any]] = None):
        """
        Add an observation (execution trace) to the causal graph.
        
        Args:
            trace: Execution trace with step-by-step execution data
            score: Importance score for this observation
            metadata: Additional metadata about the observation
        """
        if not trace:
            return
        
        # Create a unique identifier for this trace observation
        trace_id = f"trace_{self.observation_count}_{datetime.now().strftime('%Y%m%d_%H%M%S_%f')}"
        self.observation_count += 1
        
        # Add the trace as a sequence of nodes
        for i, step in enumerate(trace):
            step_id = f"{trace_id}_step_{i}"
            
            # Extract key information from the step
            node_attrs = {
                'type': 'execution_step',
                'timestamp': step.get('t'),
                'event_type': step.get('event_type'),
                'node_id': step.get('node_id'),
                'variable_name': step.get('variable_name'),
                'function_name': step.get('function_name'),
                'value': step.get('value'),
                'score': score,
                'trace_id': trace_id,
                'step_index': i
            }
            
            # Add any additional metadata
            if metadata:
                node_attrs.update(metadata)
            
            # Add the step node to the graph
            self.graph.add_node(step_id, **node_attrs)
            
            # Connect to previous step to form execution sequence
            if i > 0:
                prev_step_id = f"{trace_id}_step_{i-1}"
                self.graph.add_edge(
                    prev_step_id, 
                    step_id, 
                    relation_type="sequential_execution",
                    weight=1.0
                )
        
        # Extract causal relationships from the trace
        self._extract_causal_relationships(trace, trace_id, score)
        
        self.logger.debug(f"Added trace observation {trace_id} with {len(trace)} steps")
    
    def _extract_causal_relationships(self, trace: List[Dict[str, Any]], 
                                     trace_id: str, score: float):
        """Extract causal relationships from trace and add to graph."""
        # Look for variable dependencies
        for i, step in enumerate(trace):
            step_id = f"{trace_id}_step_{i}"
            
            # Extract input state dependencies
            if 'input_state' in step and isinstance(step['input_state'], dict):
                for var_name, value in step['input_state'].items():
                    var_node_id = f"var_{var_name}"
                    
                    # Add variable node if it doesn't exist
                    if not self.graph.has_node(var_node_id):
                        self.graph.add_node(
                            var_node_id,
                            type='variable',
                            name=var_name,
                            value=value,
                            first_seen=step.get('t')
                        )
                    else:
                        # Update variable value if it changed
                        self.graph.nodes[var_node_id]['value'] = value
                        self.graph.nodes[var_node_id]['last_seen'] = step.get('t')
                    
                    # Add causal edge: variable influences execution step
                    self.graph.add_edge(
                        var_node_id,
                        step_id,
                        relation_type="data_dependency",
                        weight=score
                    )
            
            # Extract function call relationships
            if step.get('function_name'):
                func_node_id = f"func_{step['function_name']}"
                
                # Add function node if it doesn't exist
                if not self.graph.has_node(func_node_id):
                    self.graph.add_node(
                        func_node_id,
                        type='function',
                        name=step['function_name'],
                        first_called=step.get('t')
                    )
                else:
                    self.graph.nodes[func_node_id]['last_called'] = step.get('t')
                
                # Add causal edge: function call leads to execution step
                self.graph.add_edge(
                    func_node_id,
                    step_id,
                    relation_type="function_invocation",
                    weight=score
                )
    
    def query_high_value_paths(self, min_score: float = 0.5) -> List[Tuple[List[str], float]]:
        """
        Query for high-value causal paths in the graph.
        
        Args:
            min_score: Minimum score threshold for nodes to be considered
            
        Returns:
            List of tuples (path, cumulative_score)
        """
        high_value_paths = []
        
        # Find nodes with score above threshold
        high_value_nodes = [
            node for node, attrs in self.graph.nodes(data=True)
            if attrs.get('score', 0) >= min_score
        ]
        
        if not high_value_nodes:
            return []
        
        # Find connected components of high-value nodes
        for start_node in high_value_nodes[:5]:  # Limit to first 5 to avoid long computation
            for end_node in high_value_nodes[-5:]:  # Limit to last 5
                if start_node != end_node:
                    try:
                        # Find paths between high-value nodes
                        paths = list(nx.all_simple_paths(
                            self.graph,
                            source=start_node,
                            target=end_node,
                            cutoff=10  # Limit path length
                        ))
                        
                        for path in paths:
                            # Calculate cumulative score for the path
                            path_score = sum(
                                self.graph.nodes[node].get('score', 0)
                                for node in path
                            ) / len(path)  # Average score per node
                            
                            high_value_paths.append((path, path_score))
                    except nx.NetworkXNoPath:
                        continue  # No path exists between these nodes
        
        # Sort by score descending
        high_value_paths.sort(key=lambda x: x[1], reverse=True)
        
        return high_value_paths
    
    def find_causal_chains(self, target_node: str, max_depth: int = 3) -> List[List[str]]:
        """
        Find causal chains leading to a target node.
        
        Args:
            target_node: Node to find causes for
            max_depth: Maximum depth to search for causes
            
        Returns:
            List of causal chains (each chain is a list of node IDs)
        """
        if target_node not in self.graph:
            return []
        
        # Find predecessors recursively up to max_depth
        def find_causes_recursive(node: str, depth: int, visited: set) -> List[List[str]]:
            if depth <= 0 or node in visited:
                return [[node]]
            
            visited.add(node)
            chains = []
            
            predecessors = list(self.graph.predecessors(node))
            if not predecessors:
                return [[node]]
            
            for pred in predecessors:
                subchains = find_causes_recursive(pred, depth - 1, visited.copy())
                for chain in subchains:
                    chains.append(chain + [node])
            
            return chains
        
        return find_causes_recursive(target_node, max_depth, set())
    
    def get_most_important_nodes(self, n: int = 10) -> List[Tuple[str, float]]:
        """
        Get the most important nodes based on score and centrality.
        
        Args:
            n: Number of nodes to return
            
        Returns:
            List of tuples (node_id, importance_score)
        """
        # Calculate centrality as a measure of importance
        try:
            centrality = nx.betweenness_centrality(self.graph)
        except:
            # If betweenness fails, use degree centrality
            centrality = {node: self.graph.degree(node) / (len(self.graph) - 1) 
                         if len(self.graph) > 1 else 0.0 
                         for node in self.graph.nodes()}
        
        # Combine score and centrality
        importance_scores = {}
        for node in self.graph.nodes():
            node_attrs = self.graph.nodes[node]
            score = node_attrs.get('score', 0.0)
            cent = centrality.get(node, 0.0)
            
            # Weight score and centrality equally
            importance = 0.5 * score + 0.5 * cent
            importance_scores[node] = importance
        
        # Sort by importance and return top n
        sorted_nodes = sorted(
            importance_scores.items(), 
            key=lambda x: x[1], 
            reverse=True
        )
        
        return sorted_nodes[:n]
    
    def find_related_functions(self, func_name: str) -> List[Dict[str, Any]]:
        """
        Find functions related to a given function based on execution traces.
        
        Args:
            func_name: Name of the function to find relations for
            
        Returns:
            List of related functions with relationship details
        """
        related_funcs = []
        
        # Find the function node
        func_node_id = f"func_{func_name}"
        if not self.graph.has_node(func_node_id):
            return []
        
        # Find all other function nodes that are connected in some way
        func_nodes = [n for n in self.graph.nodes() if n.startswith("func_")]
        
        for other_func in func_nodes:
            if other_func == func_node_id:
                continue
            
            # Check if there's a path between the functions
            try:
                path_exists = nx.has_path(self.graph, func_node_id, other_func)
                if path_exists:
                    # Get the shortest path
                    shortest_path = nx.shortest_path(self.graph, func_node_id, other_func)
                    
                    related_funcs.append({
                        'function': other_func,
                        'path_length': len(shortest_path) - 1,
                        'path': shortest_path
                    })
            except nx.NetworkXNoPath:
                continue
        
        return related_funcs
    
    def serialize_to_dict(self) -> Dict[str, Any]:
        """Serialize the causal graph to a dictionary."""
        return {
            'nodes': dict(self.graph.nodes(data=True)),
            'edges': list(self.graph.edges(data=True)),
            'observation_count': self.observation_count
        }
    
    def load_from_dict(self, data: Dict[str, Any]):
        """Load the causal graph from a dictionary."""
        self.graph = nx.DiGraph()
        self.graph.add_nodes_from(data['nodes'].items())
        self.graph.add_edges_from(data['edges'])
        self.observation_count = data.get('observation_count', 0)


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
    
    # Create causal memory and add observation
    causal_memory = CausalMemory()
    causal_memory.add_observation(sample_trace, score=0.8, metadata={"experiment": "test_1"})
    
    print(f"Causal graph has {len(causal_memory.graph.nodes)} nodes and {len(causal_memory.graph.edges)} edges")
    
    # Query high-value paths
    high_value_paths = causal_memory.query_high_value_paths()
    print(f"Found {len(high_value_paths)} high-value paths")
    if high_value_paths:
        print(f"Highest scoring path score: {high_value_paths[0][1]:.3f}")
    
    # Get most important nodes
    important_nodes = causal_memory.get_most_important_nodes(5)
    print(f"Top 5 important nodes: {[(n, round(s, 3)) for n, s in important_nodes]}")
    
    # Find causal chains for the last step
    if causal_memory.graph.nodes:
        last_node = list(causal_memory.graph.nodes)[-1]
        causal_chains = causal_memory.find_causal_chains(last_node, max_depth=2)
        print(f"Found {len(causal_chains)} causal chains to {last_node}")
        if causal_chains:
            print(f"Example chain: {causal_chains[0]}")
    
    # Find related functions
    related_funcs = causal_memory.find_related_functions("add")
    print(f"Found {len(related_funcs)} related functions to 'add'")