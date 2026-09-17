"""
Constraint Solver for Logic Domain

Solves constraint satisfaction problems using backtracking
and constraint propagation.
"""

from typing import Dict, List, Optional, Set, Tuple, Any, Callable
from dataclasses import dataclass, field


@dataclass
class Constraint:
    """Represents a logical constraint."""
    constraint_id: str
    variables: List[str]
    constraint_func: Callable
    description: str
    
    def evaluate(self, assignment: Dict[str, Any]) -> bool:
        """Evaluate if constraint is satisfied given variable assignments."""
        try:
            # Extract relevant variables
            relevant_vars = {v: assignment[v] for v in self.variables if v in assignment}
            if len(relevant_vars) < len(self.variables):
                return True  # Not all variables assigned yet
            return self.constraint_func(**relevant_vars)
        except Exception:
            return False


class ConstraintSolver:
    """
    Solves constraint satisfaction problems (CSP).
    
    Supports:
    - Variable domains
    - Binary and n-ary constraints
    - Backtracking search with constraint propagation
    """
    
    def __init__(self):
        self.variables: Dict[str, List[Any]] = {}  # var -> domain
        self.constraints: List[Constraint] = []
        self._constraint_counter = 0
    
    def add_variable(self, var_name: str, domain: List[Any]):
        """Add a variable with its domain of possible values."""
        self.variables[var_name] = domain.copy()
    
    def add_constraint(self, variables: List[str], constraint_func: Callable,
                      description: str = "") -> str:
        """
        Add a constraint over variables.
        
        Args:
            variables: List of variable names involved in constraint
            constraint_func: Function that returns True if constraint satisfied
            description: Human-readable description
            
        Returns:
            Constraint ID
        """
        self._constraint_counter += 1
        constraint = Constraint(
            constraint_id=f"constraint_{self._constraint_counter}",
            variables=variables,
            constraint_func=constraint_func,
            description=description or f"Constraint on {', '.join(variables)}"
        )
        self.constraints.append(constraint)
        return constraint.constraint_id
    
    def solve(self, find_all: bool = False) -> List[Dict[str, Any]]:
        """
        Solve the constraint satisfaction problem.
        
        Args:
            find_all: If True, find all solutions; otherwise find first
            
        Returns:
            List of valid assignments (dictionaries mapping variables to values)
        """
        solutions = []
        assignment = {}
        self._backtrack(assignment, solutions, find_all)
        return solutions
    
    def _backtrack(self, assignment: Dict[str, Any], 
                   solutions: List[Dict[str, Any]],
                   find_all: bool):
        """Backtracking search with constraint checking."""
        # Check if assignment is complete
        if len(assignment) == len(self.variables):
            if self._is_consistent(assignment):
                solutions.append(assignment.copy())
                return not find_all  # Stop if only need one solution
            return False
        
        # Select unassigned variable (MRV heuristic)
        var = self._select_unassigned_variable(assignment)
        
        # Try each value in domain
        for value in self.variables[var]:
            assignment[var] = value
            
            # Check if assignment is still consistent
            if self._is_consistent(assignment):
                result = self._backtrack(assignment, solutions, find_all)
                if result:  # Found solution and only need one
                    return True
            
            # Remove assignment (backtrack)
            del assignment[var]
        
        return False
    
    def _select_unassigned_variable(self, assignment: Dict[str, Any]) -> str:
        """Select next variable using Minimum Remaining Values (MRV) heuristic."""
        unassigned = [v for v in self.variables if v not in assignment]
        
        if not unassigned:
            raise ValueError("No unassigned variables")
        
        # MRV: choose variable with fewest legal values remaining
        return min(unassigned, key=lambda v: len(self.variables[v]))
    
    def _is_consistent(self, assignment: Dict[str, Any]) -> bool:
        """Check if current assignment satisfies all constraints."""
        for constraint in self.constraints:
            if not constraint.evaluate(assignment):
                return False
        return True
    
    def is_satisfiable(self) -> bool:
        """Check if the CSP has at least one solution."""
        solutions = self.solve(find_all=False)
        return len(solutions) > 0
    
    def get_solution_count(self) -> int:
        """Get total number of solutions."""
        solutions = self.solve(find_all=True)
        return len(solutions)
    
    def clear(self):
        """Clear all variables and constraints."""
        self.variables.clear()
        self.constraints.clear()
        self._constraint_counter = 0
    
    def to_dict(self) -> Dict:
        """Serialize solver state."""
        return {
            'num_variables': len(self.variables),
            'num_constraints': len(self.constraints),
            'variables': {k: len(v) for k, v in self.variables.items()},
            'constraints': [c.description for c in self.constraints]
        }


# Example usage and common constraint patterns
def create_all_different_constraint(variables: List[str]) -> Tuple[List[str], Callable]:
    """Create an all-different constraint."""
    def all_different(**kwargs):
        values = list(kwargs.values())
        return len(values) == len(set(values))
    return variables, all_different


def create_equality_constraint(var1: str, var2: str) -> Tuple[List[str], Callable]:
    """Create an equality constraint."""
    def equal(**kwargs):
        return kwargs[var1] == kwargs[var2]
    return [var1, var2], equal


def create_inequality_constraint(var1: str, var2: str) -> Tuple[List[str], Callable]:
    """Create an inequality constraint."""
    def not_equal(**kwargs):
        return kwargs[var1] != kwargs[var2]
    return [var1, var2], not_equal


if __name__ == "__main__":
    # Example: Graph coloring problem
    solver = ConstraintSolver()
    
    # Variables: nodes with colors as domain
    colors = ['red', 'green', 'blue']
    for node in ['A', 'B', 'C', 'D']:
        solver.add_variable(node, colors)
    
    # Constraints: adjacent nodes must have different colors
    edges = [('A', 'B'), ('A', 'C'), ('B', 'C'), ('B', 'D'), ('C', 'D')]
    for var1, var2 in edges:
        vars_list, constraint_func = create_inequality_constraint(var1, var2)
        solver.add_constraint(vars_list, constraint_func, 
                             f"{var1} != {var2}")
    
    # Solve
    solutions = solver.solve(find_all=True)
    print(f"Found {len(solutions)} solutions:")
    for i, sol in enumerate(solutions[:5]):  # Show first 5
        print(f"  Solution {i+1}: {sol}")
