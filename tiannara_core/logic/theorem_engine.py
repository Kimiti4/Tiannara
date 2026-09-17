"""
Theorem Engine for Logic Domain

Performs logical deduction using forward chaining, backward chaining,
and resolution to derive new conclusions from facts and rules.
"""

from typing import Dict, List, Set, Optional, Tuple, Any
from dataclasses import dataclass, field
from .symbolic_state import SymbolicState, SymbolType
from .contradiction_detector import ContradictionDetector


@dataclass
class ProofStep:
    """Represents a single step in a logical proof."""
    step_number: int
    rule_applied: str
    premises: List[str]
    conclusion: str
    justification: str
    
    def to_dict(self):
        return {
            'step_number': self.step_number,
            'rule_applied': self.rule_applied,
            'premises': self.premises,
            'conclusion': self.conclusion,
            'justification': self.justification
        }


@dataclass
class Proof:
    """Represents a complete logical proof."""
    proof_id: str
    goal: str
    steps: List[ProofStep]
    success: bool
    derived_conclusion: Optional[str] = None
    
    def to_dict(self):
        return {
            'proof_id': self.proof_id,
            'goal': self.goal,
            'success': self.success,
            'num_steps': len(self.steps),
            'derived_conclusion': self.derived_conclusion,
            'steps': [s.to_dict() for s in self.steps]
        }


class TheoremEngine:
    """
    Performs logical deduction and theorem proving.
    
    Supports:
    - Forward chaining (data-driven reasoning)
    - Backward chaining (goal-driven reasoning)
    - Modus ponens inference
    - Resolution
    """
    
    def __init__(self):
        self.proofs: List[Proof] = []
        self._proof_counter = 0
    
    def forward_chain(self, state: SymbolicState, max_iterations: int = 100) -> List[str]:
        """
        Perform forward chaining to derive new conclusions.
        
        Args:
            state: Current symbolic state with facts and rules
            max_iterations: Maximum number of inference iterations
            
        Returns:
            List of newly derived conclusions
        """
        derived = []
        
        for iteration in range(max_iterations):
            new_derivations = []
            
            # Apply each rule to current facts
            for rule_expr in state.rules.values():
                premise = rule_expr.metadata.get('premise', '')
                conclusion = rule_expr.metadata.get('conclusion', '')
                
                if not premise or not conclusion:
                    continue
                
                # Check if premise is satisfied by existing facts
                if self._premise_satisfied(premise, state):
                    # Derive conclusion if not already known
                    if not self._statement_exists(conclusion, state):
                        derived_id = state.add_derived(
                            statement=conclusion,
                            source_ids=[rule_expr.expr_id],
                            variables=rule_expr.variables
                        )
                        new_derivations.append(conclusion)
            
            derived.extend(new_derivations)
            
            # Stop if no new derivations
            if not new_derivations:
                break
        
        return derived
    
    def backward_chain(self, state: SymbolicState, goal: str) -> Proof:
        """
        Perform backward chaining to prove a goal.
        
        Args:
            state: Current symbolic state
            goal: Statement to prove
            
        Returns:
            Proof object showing derivation path
        """
        self._proof_counter += 1
        proof = Proof(
            proof_id=f"proof_{self._proof_counter}",
            goal=goal,
            steps=[],
            success=False
        )
        
        # Check if goal is already a fact
        if self._statement_exists(goal, state):
            proof.success = True
            proof.derived_conclusion = goal
            proof.steps.append(ProofStep(
                step_number=1,
                rule_applied="fact_lookup",
                premises=[],
                conclusion=goal,
                justification="Goal is an existing fact"
            ))
            self.proofs.append(proof)
            return proof
        
        # Try to find rules that can derive the goal
        step_num = 1
        visited_rules = set()
        
        for rule_expr in state.rules.values():
            if rule_expr.expr_id in visited_rules:
                continue
            
            conclusion = rule_expr.metadata.get('conclusion', '')
            premise = rule_expr.metadata.get('premise', '')
            
            if conclusion == goal:
                # Found a rule that derives the goal
                # Now try to prove the premise
                premise_proof = self.backward_chain(state, premise)
                
                if premise_proof.success:
                    proof.success = True
                    proof.derived_conclusion = goal
                    proof.steps.extend(premise_proof.steps)
                    proof.steps.append(ProofStep(
                        step_number=len(proof.steps) + 1,
                        rule_applied="modus_ponens",
                        premises=[premise],
                        conclusion=goal,
                        justification=f"Applied rule: {premise} -> {goal}"
                    ))
                    break
                
                visited_rules.add(rule_expr.expr_id)
        
        self.proofs.append(proof)
        return proof
    
    def check_contradiction(self, state: SymbolicState) -> Dict:
        """
        Check if current state contains contradictions.
        
        Args:
            state: Symbolic state to check
            
        Returns:
            Contradiction detection results
        """
        detector = ContradictionDetector()
        contradictions = detector.detect_contradictions(state)
        return detector.get_contradiction_summary()
    
    def verify_consistency(self, state: SymbolicState) -> bool:
        """
        Verify that the symbolic state is logically consistent.
        
        Args:
            state: Symbolic state to verify
            
        Returns:
            True if consistent, False if contradictions found
        """
        summary = self.check_contradiction(state)
        return summary['total_contradictions'] == 0
    
    def _premise_satisfied(self, premise: str, state: SymbolicState) -> bool:
        """Check if a premise is satisfied by current facts."""
        # Simple exact match - would need proper unification in production
        for fact_expr in state.facts.values():
            if fact_expr.statement == premise:
                return True
        
        # Check derived statements
        for derived_expr in state.derived.values():
            if derived_expr.statement == premise:
                return True
        
        return False
    
    def _statement_exists(self, statement: str, state: SymbolicState) -> bool:
        """Check if a statement already exists in the state."""
        all_statements = [expr.statement for expr in state.get_all_expressions()]
        return statement in all_statements
    
    def get_proof_history(self) -> List[Dict]:
        """Get history of all proofs attempted."""
        return [p.to_dict() for p in self.proofs]
    
    def clear_proofs(self):
        """Clear proof history."""
        self.proofs.clear()
        self._proof_counter = 0


# Example usage
if __name__ == "__main__":
    # Create symbolic state
    state = SymbolicState()
    
    # Add facts
    state.add_fact("Human(Socrates)")
    state.add_fact("∀x Human(x) -> Mortal(x)")
    
    # Add rule
    state.add_rule(
        premise="Human(Socrates)",
        conclusion="Mortal(Socrates)"
    )
    
    # Create theorem engine
    engine = TheoremEngine()
    
    # Forward chaining
    print("Forward chaining:")
    derived = engine.forward_chain(state)
    print(f"Derived: {derived}")
    
    # Backward chaining
    print("\nBackward chaining:")
    proof = engine.backward_chain(state, "Mortal(Socrates)")
    print(f"Proof successful: {proof.success}")
    print(f"Steps: {len(proof.steps)}")
    
    # Check consistency
    print("\nConsistency check:")
    is_consistent = engine.verify_consistency(state)
    print(f"State is consistent: {is_consistent}")
