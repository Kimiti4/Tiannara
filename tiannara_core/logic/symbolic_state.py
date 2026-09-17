"""
Symbolic State Manager for Logic Domain

Maintains formal symbolic representations of logical statements,
facts, and constraints for verification and deduction.
"""

from typing import Dict, List, Set, Optional, Any
from dataclasses import dataclass, field
from enum import Enum


class SymbolType(Enum):
    """Types of symbolic expressions."""
    FACT = "fact"
    RULE = "rule"
    CONSTRAINT = "constraint"
    QUERY = "query"
    DERIVED = "derived"


@dataclass
class SymbolicExpression:
    """Represents a symbolic logical expression."""
    expr_id: str
    expr_type: SymbolType
    statement: str
    variables: Dict[str, Any] = field(default_factory=dict)
    dependencies: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def __hash__(self):
        return hash(self.expr_id)
    
    def __eq__(self, other):
        if isinstance(other, SymbolicExpression):
            return self.expr_id == other.expr_id
        return False


class SymbolicState:
    """
    Maintains the current state of symbolic knowledge.
    
    Tracks facts, rules, constraints, and derived conclusions
    with dependency tracking for contradiction detection.
    """
    
    def __init__(self):
        self.facts: Dict[str, SymbolicExpression] = {}
        self.rules: Dict[str, SymbolicExpression] = {}
        self.constraints: Dict[str, SymbolicExpression] = {}
        self.derived: Dict[str, SymbolicExpression] = {}
        self.queries: Dict[str, SymbolicExpression] = {}
        
        # Dependency graph: expr_id -> set of expr_ids it depends on
        self.dependencies: Dict[str, Set[str]] = {}
        
        # Reverse dependency: expr_id -> set of expr_ids that depend on it
        self.reverse_dependencies: Dict[str, Set[str]] = {}
        
        # Expression counter for unique IDs
        self._expr_counter = 0
    
    def add_fact(self, statement: str, variables: Optional[Dict] = None, 
                 metadata: Optional[Dict] = None) -> str:
        """Add a factual statement to the symbolic state."""
        expr_id = self._generate_id("fact")
        fact = SymbolicExpression(
            expr_id=expr_id,
            expr_type=SymbolType.FACT,
            statement=statement,
            variables=variables or {},
            metadata=metadata or {}
        )
        self.facts[expr_id] = fact
        self.dependencies[expr_id] = set()
        return expr_id
    
    def add_rule(self, premise: str, conclusion: str, 
                 variables: Optional[Dict] = None) -> str:
        """Add a logical rule (premise -> conclusion)."""
        expr_id = self._generate_id("rule")
        rule = SymbolicExpression(
            expr_id=expr_id,
            expr_type=SymbolType.RULE,
            statement=f"{premise} -> {conclusion}",
            variables=variables or {},
            metadata={'premise': premise, 'conclusion': conclusion}
        )
        self.rules[expr_id] = rule
        self.dependencies[expr_id] = set()
        return expr_id
    
    def add_constraint(self, constraint: str, variables: Optional[Dict] = None) -> str:
        """Add a constraint that must be satisfied."""
        expr_id = self._generate_id("constraint")
        constraint_expr = SymbolicExpression(
            expr_id=expr_id,
            expr_type=SymbolType.CONSTRAINT,
            statement=constraint,
            variables=variables or {}
        )
        self.constraints[expr_id] = constraint_expr
        self.dependencies[expr_id] = set()
        return expr_id
    
    def add_derived(self, statement: str, source_ids: List[str],
                    variables: Optional[Dict] = None) -> str:
        """Add a derived conclusion with dependency tracking."""
        expr_id = self._generate_id("derived")
        derived = SymbolicExpression(
            expr_id=expr_id,
            expr_type=SymbolType.DERIVED,
            statement=statement,
            variables=variables or {},
            dependencies=source_ids
        )
        self.derived[expr_id] = derived
        
        # Update dependency graph
        self.dependencies[expr_id] = set(source_ids)
        for source_id in source_ids:
            if source_id not in self.reverse_dependencies:
                self.reverse_dependencies[source_id] = set()
            self.reverse_dependencies[source_id].add(expr_id)
        
        return expr_id
    
    def remove_expression(self, expr_id: str) -> bool:
        """Remove an expression and update dependencies."""
        removed = False
        
        # Find which collection contains this expression
        for collection in [self.facts, self.rules, self.constraints, 
                          self.derived, self.queries]:
            if expr_id in collection:
                del collection[expr_id]
                removed = True
                break
        
        if removed:
            # Clean up dependencies
            if expr_id in self.dependencies:
                del self.dependencies[expr_id]
            if expr_id in self.reverse_dependencies:
                # Remove reverse dependencies
                for dependent_id in self.reverse_dependencies[expr_id]:
                    if dependent_id in self.dependencies:
                        self.dependencies[dependent_id].discard(expr_id)
                del self.reverse_dependencies[expr_id]
        
        return removed
    
    def get_all_expressions(self) -> List[SymbolicExpression]:
        """Get all expressions in the symbolic state."""
        all_exprs = []
        for collection in [self.facts, self.rules, self.constraints, 
                          self.derived, self.queries]:
            all_exprs.extend(collection.values())
        return all_exprs
    
    def get_dependencies(self, expr_id: str) -> Set[str]:
        """Get all expressions that this expression depends on."""
        return self.dependencies.get(expr_id, set()).copy()
    
    def get_dependents(self, expr_id: str) -> Set[str]:
        """Get all expressions that depend on this expression."""
        return self.reverse_dependencies.get(expr_id, set()).copy()
    
    def clear(self):
        """Clear all expressions and reset state."""
        self.facts.clear()
        self.rules.clear()
        self.constraints.clear()
        self.derived.clear()
        self.queries.clear()
        self.dependencies.clear()
        self.reverse_dependencies.clear()
        self._expr_counter = 0
    
    def _generate_id(self, prefix: str) -> str:
        """Generate a unique expression ID."""
        self._expr_counter += 1
        return f"{prefix}_{self._expr_counter}"
    
    def to_dict(self) -> Dict[str, Any]:
        """Serialize symbolic state to dictionary."""
        return {
            'facts': {k: v.statement for k, v in self.facts.items()},
            'rules': {k: v.statement for k, v in self.rules.items()},
            'constraints': {k: v.statement for k, v in self.constraints.items()},
            'derived': {k: v.statement for k, v in self.derived.items()},
            'num_expressions': len(self.get_all_expressions())
        }
    
    def __len__(self):
        """Total number of expressions."""
        return sum(len(c) for c in [self.facts, self.rules, self.constraints, 
                                    self.derived, self.queries])
    
    def __repr__(self):
        return f"SymbolicState(facts={len(self.facts)}, rules={len(self.rules)}, " \
               f"constraints={len(self.constraints)}, derived={len(self.derived)})"
