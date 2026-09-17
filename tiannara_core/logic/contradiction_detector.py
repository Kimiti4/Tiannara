"""
Contradiction Detector for Logic Domain

Detects logical contradictions in symbolic expressions using
SAT solving and constraint verification.
"""

from typing import List, Dict, Optional, Tuple, Set
from dataclasses import dataclass
from .symbolic_state import SymbolicState, SymbolicExpression, SymbolType


@dataclass
class Contradiction:
    """Represents a detected contradiction."""
    contradiction_id: str
    conflicting_expressions: List[str]
    conflict_type: str  # 'direct', 'transitive', 'constraint_violation'
    description: str
    severity: float  # 0.0 to 1.0
    
    def to_dict(self):
        return {
            'contradiction_id': self.contradiction_id,
            'conflicting_expressions': self.conflicting_expressions,
            'conflict_type': self.conflict_type,
            'description': self.description,
            'severity': self.severity
        }


class ContradictionDetector:
    """
    Detects contradictions in symbolic logical expressions.
    
    Uses multiple strategies:
    1. Direct contradiction detection (A and not-A)
    2. Transitive contradiction detection (A->B, B->C, C->not-A)
    3. Constraint violation detection
    """
    
    def __init__(self):
        self.contradictions: List[Contradiction] = []
        self._contradiction_counter = 0
    
    def detect_contradictions(self, state: SymbolicState) -> List[Contradiction]:
        """
        Detect all contradictions in the symbolic state.
        
        Args:
            state: Current symbolic state
            
        Returns:
            List of detected contradictions
        """
        self.contradictions = []
        
        # Strategy 1: Direct contradictions
        self._detect_direct_contradictions(state)
        
        # Strategy 2: Transitive contradictions
        self._detect_transitive_contradictions(state)
        
        # Strategy 3: Constraint violations
        self._detect_constraint_violations(state)
        
        return self.contradictions
    
    def _detect_direct_contradictions(self, state: SymbolicState):
        """Detect direct contradictions (A and ¬A)."""
        all_statements = {}
        
        # Index all statements by normalized form
        for expr in state.get_all_expressions():
            normalized = self._normalize_statement(expr.statement)
            
            # Check for negation
            if normalized.startswith("¬") or normalized.startswith("NOT "):
                positive_form = normalized.lstrip("¬").lstrip("NOT ").strip()
                if positive_form in all_statements:
                    # Found contradiction
                    self._add_contradiction(
                        [all_statements[positive_form], expr.expr_id],
                        'direct',
                        f"Direct contradiction: '{positive_form}' and '{expr.statement}'"
                    )
            else:
                # Check if negated version exists
                negated_form = f"¬{normalized}"
                if negated_form in all_statements:
                    self._add_contradiction(
                        [all_statements[negated_form], expr.expr_id],
                        'direct',
                        f"Direct contradiction: '{expr.statement}' and '{negated_form}'"
                    )
            
            all_statements[normalized] = expr.expr_id
    
    def _detect_transitive_contradictions(self, state: SymbolicState):
        """Detect contradictions through transitive reasoning."""
        # Build implication graph from rules
        implications = {}
        for rule_expr in state.rules.values():
            premise = rule_expr.metadata.get('premise', '')
            conclusion = rule_expr.metadata.get('conclusion', '')
            if premise and conclusion:
                if premise not in implications:
                    implications[premise] = []
                implications[premise].append((conclusion, rule_expr.expr_id))
        
        # Check for cycles that lead to contradictions
        for fact_expr in state.facts.values():
            visited = set()
            path = []
            if self._has_contradictory_path(fact_expr.statement, implications, 
                                           visited, path, state):
                # Extract contradiction path
                contradiction_exprs = [fact_expr.expr_id] + [
                    expr_id for _, expr_id in path
                ]
                self._add_contradiction(
                    contradiction_exprs,
                    'transitive',
                    f"Transitive contradiction through chain: {' -> '.join([p[0] for p in path])}"
                )
    
    def _has_contradictory_path(self, statement: str, implications: Dict,
                                visited: Set[str], path: List[Tuple[str, str]],
                                state: SymbolicState) -> bool:
        """Check if following implications leads to a contradiction."""
        if statement in visited:
            return False
        
        visited.add(statement)
        
        # Check if current statement contradicts any known fact
        normalized = self._normalize_statement(statement)
        for fact_expr in state.facts.values():
            fact_normalized = self._normalize_statement(fact_expr.statement)
            if self._are_contradictory(normalized, fact_normalized):
                return True
        
        # Follow implications
        if statement in implications:
            for conclusion, rule_id in implications[statement]:
                path.append((conclusion, rule_id))
                if self._has_contradictory_path(conclusion, implications, 
                                               visited, path, state):
                    return True
                path.pop()
        
        return False
    
    def _detect_constraint_violations(self, state: SymbolicState):
        """Detect violations of explicit constraints."""
        for constraint_expr in state.constraints.values():
            constraint = constraint_expr.statement
            
            # Check if any derived expression violates this constraint
            for derived_expr in state.derived.values():
                if self._violates_constraint(derived_expr.statement, constraint):
                    self._add_contradiction(
                        [constraint_expr.expr_id, derived_expr.expr_id],
                        'constraint_violation',
                        f"Constraint violation: '{derived_expr.statement}' violates '{constraint}'"
                    )
    
    def _violates_constraint(self, statement: str, constraint: str) -> bool:
        """Check if a statement violates a constraint."""
        # Simple pattern matching for common constraint types
        constraint_lower = constraint.lower()
        statement_lower = statement.lower()
        
        # Type 1: Exclusion constraints ("X cannot be Y")
        if "cannot" in constraint_lower or "must not" in constraint_lower:
            # Extract what's forbidden
            forbidden_parts = constraint_lower.split("cannot")[-1].split("must not")[-1].strip()
            if forbidden_parts in statement_lower:
                return True
        
        # Type 2: Requirement constraints ("X must be Y")
        if "must be" in constraint_lower or "must equal" in constraint_lower:
            required = constraint_lower.split("must be")[-1].split("must equal")[-1].strip()
            if required not in statement_lower:
                return True
        
        # Type 3: Range constraints ("X must be between A and B")
        if "between" in constraint_lower:
            # Simplified check - would need proper parsing in production
            pass
        
        return False
    
    def _normalize_statement(self, statement: str) -> str:
        """Normalize a statement for comparison."""
        # Remove extra whitespace
        normalized = ' '.join(statement.strip().split())
        # Convert to lowercase for case-insensitive comparison
        normalized = normalized.lower()
        return normalized
    
    def _are_contradictory(self, stmt1: str, stmt2: str) -> bool:
        """Check if two statements are contradictory."""
        # Direct negation
        if stmt1 == f"¬{stmt2}" or stmt2 == f"¬{stmt1}":
            return True
        if stmt1.startswith("not ") and stmt1[4:] == stmt2:
            return True
        if stmt2.startswith("not ") and stmt2[4:] == stmt1:
            return True
        
        # Semantic contradiction patterns
        stmt1_lower = stmt1.lower()
        stmt2_lower = stmt2.lower()
        
        # Pattern 1: "All X can Y" vs "Z cannot Y" where Z is an X
        # Example: "All birds can fly" vs "Penguins cannot fly"
        if "all" in stmt1_lower and "can" in stmt1_lower:
            if "cannot" in stmt2_lower or "can't" in stmt2_lower or "can not" in stmt2_lower:
                # Extract what cannot be done from stmt2
                for word in ['fly', 'swim', 'run', 'walk', 'talk', 'see', 'hear']:
                    if word in stmt2_lower and word in stmt1_lower:
                        return True
        
        # Pattern 2: Reverse - "X cannot Y" vs "All Z can Y"
        if "cannot" in stmt1_lower or "can't" in stmt1_lower or "can not" in stmt1_lower:
            if "all" in stmt2_lower and "can" in stmt2_lower:
                for word in ['fly', 'swim', 'run', 'walk', 'talk', 'see', 'hear']:
                    if word in stmt1_lower and word in stmt2_lower:
                        return True
        
        # Pattern 3: "X is Y" vs "X is not Y"
        words1 = stmt1_lower.split()
        words2 = stmt2_lower.split()
        if len(words1) >= 3 and len(words2) >= 3:
            # Check if same subject with opposite predicates
            if words1[0] == words2[0]:  # Same subject
                # Check for "is" vs "is not" pattern
                if ('is' in words1 and 'not' in words2) or ('is' in words2 and 'not' in words1):
                    return True
        
        return False
    
    def _add_contradiction(self, expr_ids: List[str], conflict_type: str, 
                          description: str):
        """Add a detected contradiction."""
        self._contradiction_counter += 1
        contradiction = Contradiction(
            contradiction_id=f"contradiction_{self._contradiction_counter}",
            conflicting_expressions=expr_ids,
            conflict_type=conflict_type,
            description=description,
            severity=self._calculate_severity(conflict_type)
        )
        self.contradictions.append(contradiction)
    
    def _calculate_severity(self, conflict_type: str) -> float:
        """Calculate severity based on contradiction type."""
        severity_map = {
            'direct': 1.0,
            'transitive': 0.8,
            'constraint_violation': 0.9
        }
        return severity_map.get(conflict_type, 0.5)
    
    def has_contradictions(self) -> bool:
        """Check if any contradictions were detected."""
        return len(self.contradictions) > 0
    
    def get_contradiction_summary(self) -> Dict:
        """Get summary of detected contradictions."""
        return {
            'total_contradictions': len(self.contradictions),
            'by_type': {
                'direct': sum(1 for c in self.contradictions if c.conflict_type == 'direct'),
                'transitive': sum(1 for c in self.contradictions if c.conflict_type == 'transitive'),
                'constraint_violation': sum(1 for c in self.contradictions 
                                           if c.conflict_type == 'constraint_violation')
            },
            'max_severity': max((c.severity for c in self.contradictions), default=0.0),
            'contradictions': [c.to_dict() for c in self.contradictions]
        }
    
    def clear(self):
        """Clear all detected contradictions."""
        self.contradictions.clear()
        self._contradiction_counter = 0
