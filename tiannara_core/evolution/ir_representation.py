"""
Intermediate Representation (IR) System for Executable Causal Manifolds (ECM)

Converts artifacts into formal intermediate representations for reasoning and manipulation.
"""

from dataclasses import dataclass, field
from typing import List, Dict, Any, Optional, Tuple
import uuid
import ast
import json
from enum import Enum


class IRNodeType(Enum):
    """Types of nodes in the IR graph."""
    OPERATION = "operation"
    VARIABLE = "variable"
    CONSTANT = "constant"
    FUNCTION_CALL = "function_call"
    CONDITIONAL = "conditional"
    LOOP = "loop"
    INPUT = "input"
    OUTPUT = "output"


@dataclass
class IRNode:
    """Represents a node in the Intermediate Representation graph."""
    id: str = field(default_factory=lambda: str(uuid.uuid4())[:8])
    node_type: IRNodeType = IRNodeType.OPERATION
    operation: str = ""  # Operation name (e.g., "ADD", "CALL", "CMP")
    inputs: List[str] = field(default_factory=list)  # References to input node IDs
    outputs: List[str] = field(default_factory=list)  # References to output node IDs
    metadata: Dict[str, Any] = field(default_factory=dict)  # Additional info like types, constraints
    source_code: str = ""  # Original source representation
    value: Any = None  # Constant value if applicable
    is_constant: bool = False
    is_variable: bool = False
    data_type: str = "any"  # Type information if available


@dataclass
class ExecutionIR:
    """Complete execution IR graph with nodes and edges."""
    nodes: Dict[str, IRNode] = field(default_factory=dict)
    edges: List[Tuple[str, str]] = field(default_factory=list)  # (source_id, target_id)
    entry_points: List[str] = field(default_factory=list)  # IDs of entry nodes
    exit_points: List[str] = field(default_factory=list)    # IDs of exit nodes
    source_language: str = "python"  # Language this IR was derived from
    metadata: Dict[str, Any] = field(default_factory=dict)  # Additional metadata
    
    def add_node(self, node: IRNode):
        """Add a node to the IR."""
        self.nodes[node.id] = node
        if node.node_type == IRNodeType.INPUT:
            self.entry_points.append(node.id)
        elif node.node_type == IRNodeType.OUTPUT:
            self.exit_points.append(node.id)
    
    def add_edge(self, source_id: str, target_id: str):
        """Add an edge between two nodes."""
        if source_id in self.nodes and target_id in self.nodes:
            self.edges.append((source_id, target_id))
            # Update node connections
            if target_id not in self.nodes[source_id].outputs:
                self.nodes[source_id].outputs.append(target_id)
            if source_id not in self.nodes[target_id].inputs:
                self.nodes[target_id].inputs.append(source_id)
    
    def clone(self) -> "ExecutionIR":
        """Create a deep copy of the IR."""
        import copy
        return copy.deepcopy(self)
    
    def get_subgraph(self, node_ids: List[str]) -> "ExecutionIR":
        """Extract a subgraph containing only specified nodes."""
        subgraph = ExecutionIR(
            source_language=self.source_language,
            metadata=self.metadata.copy()
        )
        
        # Add nodes
        for node_id in node_ids:
            if node_id in self.nodes:
                subgraph.add_node(self.nodes[node_id])
        
        # Add edges that connect nodes in the subgraph
        for src_id, tgt_id in self.edges:
            if src_id in subgraph.nodes and tgt_id in subgraph.nodes:
                subgraph.add_edge(src_id, tgt_id)
        
        return subgraph
    
    def serialize(self) -> str:
        """Serialize the IR to a JSON string."""
        def node_serializer(obj):
            if isinstance(obj, IRNodeType):
                return obj.value
            raise TypeError(f"Object of type {type(obj)} is not serializable")
        
        return json.dumps({
            'nodes': {
                nid: {
                    'id': node.id,
                    'node_type': node.node_type,
                    'operation': node.operation,
                    'inputs': node.inputs,
                    'outputs': node.outputs,
                    'metadata': node.metadata,
                    'source_code': node.source_code,
                    'value': str(node.value) if node.value is not None else None,
                    'is_constant': node.is_constant,
                    'is_variable': node.is_variable,
                    'data_type': node.data_type
                } for nid, node in self.nodes.items()
            },
            'edges': self.edges,
            'entry_points': self.entry_points,
            'exit_points': self.exit_points,
            'source_language': self.source_language,
            'metadata': self.metadata
        }, default=node_serializer)
    
    @classmethod
    def deserialize(cls, serialized: str) -> "ExecutionIR":
        """Deserialize an IR from a JSON string."""
        data = json.loads(serialized)
        
        ir = cls(
            source_language=data['source_language'],
            metadata=data['metadata']
        )
        
        # Reconstruct nodes
        for nid, node_data in data['nodes'].items():
            node = IRNode(
                id=node_data['id'],
                node_type=IRNodeType(node_data['node_type']),
                operation=node_data['operation'],
                inputs=node_data['inputs'],
                outputs=node_data['outputs'],
                metadata=node_data['metadata'],
                source_code=node_data['source_code'],
                value=node_data['value'],
                is_constant=node_data['is_constant'],
                is_variable=node_data['is_variable'],
                data_type=node_data['data_type']
            )
            ir.add_node(node)
        
        # Reconstruct edges
        for src_id, tgt_id in data['edges']:
            ir.add_edge(src_id, tgt_id)
        
        ir.entry_points = data['entry_points']
        ir.exit_points = data['exit_points']
        
        return ir


class IRConverter:
    """Converts source code to Intermediate Representation."""
    
    def __init__(self):
        self.type_map = {
            ast.Add: "ADD",
            ast.Sub: "SUB",
            ast.Mult: "MULT",
            ast.Div: "DIV",
            ast.Mod: "MOD",
            ast.Pow: "POW",
            ast.USub: "NEG",
            ast.UAdd: "POS",
            ast.Eq: "EQ",
            ast.NotEq: "NEQ",
            ast.Lt: "LT",
            ast.LtE: "LTE",
            ast.Gt: "GT",
            ast.GtE: "GTE",
            ast.And: "AND",
            ast.Or: "OR",
            ast.Not: "NOT",
        }
    
    def convert_python_to_ir(self, source_code: str) -> ExecutionIR:
        """Convert Python source code to ExecutionIR."""
        try:
            tree = ast.parse(source_code)
            visitor = PythonToIRVisitor()
            ir = visitor.visit(tree)
            ir.metadata['original_source'] = source_code
            return ir
        except SyntaxError as e:
            raise ValueError(f"Invalid Python code: {e}")
    
    def convert_function_to_ir(self, func) -> ExecutionIR:
        """Convert a Python function to ExecutionIR."""
        import inspect
        source = inspect.getsource(func)
        return self.convert_python_to_ir(source)


class PythonToIRVisitor(ast.NodeVisitor):
    """AST visitor to convert Python code to IR."""
    
    def __init__(self):
        self.ir = ExecutionIR()
        self.current_scope = []
        self.temp_counter = 0
    
    def visit_FunctionDef(self, node):
        """Visit a function definition."""
        # Create input nodes for parameters
        param_nodes = []
        for arg in node.args.args:
            input_node = IRNode(
                node_type=IRNodeType.INPUT,
                operation="PARAM",
                source_code=arg.arg,
                metadata={'param_name': arg.arg}
            )
            self.ir.add_node(input_node)
            param_nodes.append(input_node.id)
        
        # Process function body
        for stmt in node.body:
            self.visit(stmt)
        
        return self.ir
    
    def visit_Assign(self, node):
        """Visit an assignment statement."""
        # Visit the value being assigned
        value_id = self.visit(node.value)
        
        # Create variable nodes for targets
        for target in node.targets:  # Handle multiple assignments like a = b = value
            if isinstance(target, ast.Name):
                var_node = IRNode(
                    node_type=IRNodeType.VARIABLE,
                    operation="ASSIGN",
                    source_code=target.id,
                    metadata={'var_name': target.id}
                )
                self.ir.add_node(var_node)
                
                # Connect value to variable
                self.ir.add_edge(value_id, var_node.id)
    
    def visit_BinOp(self, node):
        """Visit a binary operation."""
        left_id = self.visit(node.left)
        right_id = self.visit(node.right)
        
        op_name = self.get_op_name(type(node.op))
        
        op_node = IRNode(
            node_type=IRNodeType.OPERATION,
            operation=op_name,
            source_code=ast.unparse(node) if hasattr(ast, 'unparse') else repr(node)
        )
        self.ir.add_node(op_node)
        
        # Connect operands to operation
        self.ir.add_edge(left_id, op_node.id)
        self.ir.add_edge(right_id, op_node.id)
        
        return op_node.id
    
    def visit_Constant(self, node):
        """Visit a constant value."""
        const_node = IRNode(
            node_type=IRNodeType.CONSTANT,
            operation="CONST",
            value=node.value,
            source_code=str(node.value),
            is_constant=True
        )
        self.ir.add_node(const_node)
        return const_node.id
    
    def visit_Name(self, node):
        """Visit a variable name."""
        var_node = IRNode(
            node_type=IRNodeType.VARIABLE,
            operation="VAR_REF",
            source_code=node.id,
            metadata={'var_name': node.id},
            is_variable=True
        )
        self.ir.add_node(var_node)
        return var_node.id
    
    def visit_Call(self, node):
        """Visit a function call."""
        # Visit arguments
        arg_ids = [self.visit(arg) for arg in node.args]
        
        # Create function call node
        func_name = self.get_func_name(node.func)
        call_node = IRNode(
            node_type=IRNodeType.FUNCTION_CALL,
            operation="CALL",
            source_code=ast.unparse(node) if hasattr(ast, 'unparse') else repr(node),
            metadata={'function_name': func_name}
        )
        self.ir.add_node(call_node)
        
        # Connect arguments to call
        for arg_id in arg_ids:
            self.ir.add_edge(arg_id, call_node.id)
        
        return call_node.id
    
    def get_op_name(self, op_type):
        """Get the operation name for an AST operator."""
        return self.type_map.get(op_type, str(op_type))
    
    def get_func_name(self, func_node):
        """Get the function name from a function call node."""
        if isinstance(func_node, ast.Name):
            return func_node.id
        elif isinstance(func_node, ast.Attribute):
            return func_node.attr
        else:
            return "unknown"
    
    def generic_visit(self, node):
        """Generic visit method for unhandled node types."""
        for child in ast.iter_child_nodes(node):
            self.visit(child)


def create_simple_test_ir() -> ExecutionIR:
    """Create a simple test IR for demonstration purposes."""
    ir = ExecutionIR()
    
    # Create nodes
    input_x = IRNode(
        node_type=IRNodeType.INPUT,
        operation="PARAM",
        source_code="x",
        metadata={'param_name': 'x'},
        data_type="int"
    )
    
    input_y = IRNode(
        node_type=IRNodeType.INPUT,
        operation="PARAM",
        source_code="y",
        metadata={'param_name': 'y'},
        data_type="int"
    )
    
    const_5 = IRNode(
        node_type=IRNodeType.CONSTANT,
        operation="CONST",
        value=5,
        source_code="5",
        is_constant=True,
        data_type="int"
    )
    
    add_op = IRNode(
        node_type=IRNodeType.OPERATION,
        operation="ADD",
        source_code="x + y",
        data_type="int"
    )
    
    mult_op = IRNode(
        node_type=IRNodeType.OPERATION,
        operation="MULT",
        source_code="(x + y) * 5",
        data_type="int"
    )
    
    output_z = IRNode(
        node_type=IRNodeType.OUTPUT,
        operation="RETURN",
        source_code="result",
        data_type="int"
    )
    
    # Add nodes to IR
    ir.add_node(input_x)
    ir.add_node(input_y)
    ir.add_node(const_5)
    ir.add_node(add_op)
    ir.add_node(mult_op)
    ir.add_node(output_z)
    
    # Add edges
    ir.add_edge(input_x.id, add_op.id)
    ir.add_edge(input_y.id, add_op.id)
    ir.add_edge(add_op.id, mult_op.id)
    ir.add_edge(const_5.id, mult_op.id)
    ir.add_edge(mult_op.id, output_z.id)
    
    return ir


# Example usage and testing
if __name__ == "__main__":
    # Create a simple IR
    test_ir = create_simple_test_ir()
    print("Nodes:", list(test_ir.nodes.keys()))
    print("Edges:", test_ir.edges)
    print("Entry points:", test_ir.entry_points)
    print("Exit points:", test_ir.exit_points)
    
    # Test serialization/deserialization
    serialized = test_ir.serialize()
    deserialized_ir = ExecutionIR.deserialize(serialized)
    print("Serialization test passed:", len(deserialized_ir.nodes) == len(test_ir.nodes))
    
    # Test Python to IR conversion
    converter = IRConverter()
    python_code = """
def example_function(x, y):
    z = x + y
    w = z * 5
    return w
"""
    try:
        ir_from_python = converter.convert_python_to_ir(python_code)
        print(f"Python to IR conversion created {len(ir_from_python.nodes)} nodes")
    except Exception as e:
        print(f"Python to IR conversion failed: {e}")