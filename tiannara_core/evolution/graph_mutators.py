"""
Graph Mutators for Executable Causal Manifolds (ECM)

Performs graph mutations on ExecutionIR objects.
"""

from typing import List, Dict, Any, Optional
from ..evolution.ir_representation import ExecutionIR, IRNode, IRNodeType
import random
import copy


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
            node_ids = list(new_ir.nodes.keys())
            if len(node_ids) > 1:
                random_node_id = random.choice([nid for nid in node_ids if nid != new_node.id])
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
                    # Get new value from params or calculate based on original
                    if 'new_value' in params:
                        new_value = params['new_value']
                    else:
                        # Calculate a small perturbation
                        perturbation = random.uniform(-0.1, 0.1) * abs(original_value) if original_value != 0 else 0.1
                        new_value = original_value + perturbation
                    
                    node.value = new_value
                    node.source_code = str(new_value)
        
        return new_ir
    
    def mutate_structure(self, ir: ExecutionIR, mutation_rate: float = 0.1) -> ExecutionIR:
        """Apply random structural mutations to the IR."""
        new_ir = ir.clone()
        
        # Randomly decide which mutations to apply based on mutation rate
        if random.random() < mutation_rate:
            # Add a random node
            node_types = ['ADD', 'SUB', 'MULT', 'DIV', 'CMP', 'AND', 'OR']
            new_ir = self.insert_node(new_ir, {'operation': random.choice(node_types)})
        
        if random.random() < mutation_rate and len(new_ir.nodes) > 1:
            # Remove a random node (not an entry or exit point)
            removable_nodes = [
                nid for nid in new_ir.nodes.keys() 
                if nid not in new_ir.entry_points and nid not in new_ir.exit_points
            ]
            if removable_nodes:
                node_to_remove = random.choice(removable_nodes)
                new_ir = self.delete_nodes(new_ir, [node_to_remove])
        
        if random.random() < mutation_rate and new_ir.edges:
            # Remove a random edge
            new_ir = self.remove_random_edge(new_ir)
        
        if random.random() < mutation_rate and len(new_ir.nodes) >= 2:
            # Add a random edge
            new_ir = self.add_random_edge(new_ir)
        
        return new_ir


# Example usage
if __name__ == "__main__":
    # Since we can't import ExecutionIR directly due to circular dependencies,
    # we'll create a minimal test
    print("GraphMutator class created successfully")
    mutator = GraphMutator()
    print("Mutator instantiated successfully")