"""
Logic Puzzle Domain - Task Generator

Generates logic puzzle tasks including:
- Pattern recognition (number sequences, letter patterns)
- Boolean logic evaluation
- Sequence completion
- Logical deduction
"""

import random
from typing import Dict, Any, List


class LogicPuzzleGenerator:
    """Generates logic puzzle tasks with adaptive difficulty."""
    
    def __init__(self, seed: int = None):
        self.rng = random.Random(seed)
        
        # Adaptive difficulty tracking
        self.episode_count = 0
        self.difficulty_level = "easy"  # easy, medium, hard
        self.success_history = []  # Track recent success rates
    
    def _get_difficulty_params(self, episode: int = None) -> Dict[str, Any]:
        """
        Adaptive difficulty: Calculate parameters based on episode and performance.
        
        Difficulty scales in 3 phases:
        - Episodes 0-30: Easy (simple patterns, short sequences)
        - Episodes 31-70: Medium (moderate complexity)
        - Episodes 71-100: Hard (complex patterns, longer sequences)
        
        Also adapts based on recent success rate:
        - If success > 70% in last 10 episodes: Increase difficulty
        - If success < 30% in last 10 episodes: Decrease difficulty
        """
        if episode is not None:
            self.episode_count = episode
        
        # Base difficulty from episode progression
        if self.episode_count < 30:
            base_difficulty = "easy"
        elif self.episode_count < 70:
            base_difficulty = "medium"
        else:
            base_difficulty = "hard"
        
        # Adjust based on recent performance
        if len(self.success_history) >= 10:
            recent_success = sum(self.success_history[-10:]) / len(self.success_history[-10:])
            
            if recent_success > 0.7 and base_difficulty != "hard":
                # Promote to next difficulty level
                if base_difficulty == "easy":
                    base_difficulty = "medium"
                elif base_difficulty == "medium":
                    base_difficulty = "hard"
            elif recent_success < 0.3 and base_difficulty != "easy":
                # Demote to previous difficulty level
                if base_difficulty == "hard":
                    base_difficulty = "medium"
                elif base_difficulty == "medium":
                    base_difficulty = "easy"
        
        self.difficulty_level = base_difficulty
        
        # Define parameters for each difficulty level
        params = {
            "easy": {
                "seq_length": (4, 6),      # Shorter sequences
                "pattern_range": (1, 5),   # Small numbers
                "bool_vars": 2,             # Few boolean variables
                "deduction_steps": 2        # Simple deductions
            },
            "medium": {
                "seq_length": (6, 8),      # Medium sequences
                "pattern_range": (1, 10),  # Moderate numbers
                "bool_vars": 3,             # More variables
                "deduction_steps": 3        # Moderate deductions
            },
            "hard": {
                "seq_length": (8, 10),     # Longer sequences
                "pattern_range": (1, 20),  # Larger numbers
                "bool_vars": 4,             # Many variables
                "deduction_steps": 4        # Complex deductions
            }
        }
        
        return params[base_difficulty]
    
    def update_performance(self, success: bool):
        """Record task outcome for adaptive difficulty."""
        self.success_history.append(1 if success else 0)
        # Keep only last 20 episodes for recency bias
        if len(self.success_history) > 20:
            self.success_history.pop(0)
    
    def generate_task(self, episode: int = None) -> Dict[str, Any]:
        """Generate a random logic puzzle task with adaptive difficulty.
        
        Args:
            episode: Current episode number (for difficulty scaling)
        
        Returns:
            Dictionary with task definition including:
                - type: Task category
                - inputs: Input parameters
                - expected_output: Ground truth answer
                - description: Human-readable description
                - difficulty: Current difficulty level
        """
        # Get difficulty parameters
        diff_params = self._get_difficulty_params(episode)
        
        # Add harder puzzle types for medium/hard difficulty
        if self.difficulty_level in ["medium", "hard"]:
            task_type = self.rng.choice([
                "pattern_recognition",
                "boolean_logic", 
                "sequence_completion",
                "logical_deduction",
                "constraint_satisfaction",  # NEW: Harder type
                "truth_table"  # NEW: Harder type
            ])
        else:
            task_type = self.rng.choice([
                "pattern_recognition",
                "boolean_logic", 
                "sequence_completion",
                "logical_deduction"
            ])
        
        if task_type == "pattern_recognition":
            return self._generate_pattern_task(diff_params)
        elif task_type == "boolean_logic":
            return self._generate_boolean_task(diff_params)
        elif task_type == "sequence_completion":
            return self._generate_sequence_task(diff_params)
        elif task_type == "logical_deduction":
            return self._generate_deduction_task(diff_params)
        elif task_type == "constraint_satisfaction":
            return self._generate_constraint_task(diff_params)
        else:  # truth_table
            return self._generate_truth_table_task(diff_params)
    
    def _generate_pattern_task(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate pattern recognition task with adaptive difficulty."""
        pattern_type = self.rng.choice(["arithmetic", "geometric", "alternating"])
        
        seq_length_range = diff_params["seq_length"]
        pattern_range = diff_params["pattern_range"]
        seq_len = self.rng.randint(*seq_length_range)
        
        if pattern_type == "arithmetic":
            # Arithmetic sequence: 2, 5, 8, 11, ...
            start = self.rng.randint(*pattern_range)
            step = self.rng.randint(2, max(3, pattern_range[1] // 2))
            sequence = [start + i * step for i in range(seq_len)]
            expected = start + seq_len * step
            return {
                "type": "pattern_recognition",
                "inputs": {"sequence": sequence},
                "expected_output": expected,
                "description": f"Find next number in arithmetic sequence: {sequence}",
                "difficulty": self.difficulty_level
            }
        elif pattern_type == "geometric":
            # Geometric sequence: 2, 6, 18, 54, ...
            start = self.rng.randint(max(2, pattern_range[0]), min(5, pattern_range[1]))
            ratio = self.rng.randint(2, 3)
            sequence = [start * (ratio ** i) for i in range(seq_len)]
            expected = start * (ratio ** seq_len)
            return {
                "type": "pattern_recognition",
                "inputs": {"sequence": sequence},
                "expected_output": expected,
                "description": f"Find next number in geometric sequence: {sequence}",
                "difficulty": self.difficulty_level
            }
        else:  # alternating
            # Alternating pattern: 1, 3, 2, 4, 3, ...
            base = self.rng.randint(*pattern_range)
            sequence = []
            for i in range(seq_len):
                if i % 2 == 0:
                    sequence.append(base + i // 2)
                else:
                    sequence.append(base + 2 + i // 2)
            expected = base + seq_len // 2
            return {
                "type": "pattern_recognition",
                "inputs": {"sequence": sequence},
                "expected_output": expected,
                "description": f"Find next number in alternating pattern: {sequence}",
                "difficulty": self.difficulty_level
            }
    
    def _generate_boolean_task(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate boolean logic evaluation task with adaptive difficulty."""
        num_vars = diff_params["bool_vars"]
        
        # Generate boolean variables
        variables = {}
        var_names = ['a', 'b', 'c', 'd'][:num_vars]
        for name in var_names:
            variables[name] = self.rng.choice([True, False])
        
        operation = self.rng.choice(["and", "or", "xor", "implies"])
        
        # Build expression based on number of variables
        if num_vars == 2:
            a, b = variables['a'], variables['b']
            if operation == "and":
                result = a and b
                expr = f"{a} AND {b}"
            elif operation == "or":
                result = a or b
                expr = f"{a} OR {b}"
            elif operation == "xor":
                result = a != b
                expr = f"{a} XOR {b}"
            else:  # implies
                result = (not a) or b
                expr = f"{a} IMPLIES {b}"
        else:
            # More complex expressions with 3+ variables
            values = list(variables.values())
            if operation == "and":
                result = all(values)
                expr = " AND ".join(str(v) for v in values)
            elif operation == "or":
                result = any(values)
                expr = " OR ".join(str(v) for v in values)
            elif operation == "xor":
                result = sum(values) % 2 == 1
                expr = " XOR ".join(str(v) for v in values)
            else:  # implies (chain)
                result = True
                for i in range(len(values) - 1):
                    result = result and ((not values[i]) or values[i+1])
                expr = " -> ".join(str(v) for v in values)
        
        return {
            "type": "boolean_logic",
            "inputs": {**variables, "operation": operation},
            "expected_output": result,
            "description": f"Evaluate: {expr}",
            "difficulty": self.difficulty_level
        }
    
    def _generate_sequence_task(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate sequence completion task with adaptive difficulty."""
        seq_type = self.rng.choice(["fibonacci", "squares", "primes"])
        
        if seq_type == "fibonacci":
            # Fibonacci: 1, 1, 2, 3, 5, 8, ...
            fib = [1, 1]
            for i in range(10):
                fib.append(fib[-1] + fib[-2])
            seq_length_range = diff_params["seq_length"]
            seq_len = self.rng.randint(*seq_length_range)
            sequence = fib[:seq_len]
            expected = fib[seq_len]
            return {
                "type": "sequence_completion",
                "inputs": {"sequence": sequence},
                "expected_output": expected,
                "description": f"Complete Fibonacci sequence: {sequence}",
                "difficulty": self.difficulty_level
            }
        elif seq_type == "squares":
            # Perfect squares: 1, 4, 9, 16, 25, ...
            pattern_range = diff_params["pattern_range"]
            n = self.rng.randint(*pattern_range)
            seq_length_range = diff_params["seq_length"]
            seq_len = self.rng.randint(*seq_length_range)
            sequence = [(n + i) ** 2 for i in range(seq_len)]
            expected = (n + seq_len) ** 2
            return {
                "type": "sequence_completion",
                "inputs": {"sequence": sequence},
                "expected_output": expected,
                "description": f"Complete square sequence: {sequence}",
                "difficulty": self.difficulty_level
            }
        else:  # primes
            # Prime numbers
            primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47]
            seq_length_range = diff_params["seq_length"]
            seq_len = self.rng.randint(*seq_length_range)
            start_idx = self.rng.randint(0, len(primes) - seq_len - 1)
            sequence = primes[start_idx:start_idx + seq_len]
            expected = primes[start_idx + seq_len]
            return {
                "type": "sequence_completion",
                "inputs": {"sequence": sequence},
                "expected_output": expected,
                "description": f"Complete prime sequence: {sequence}",
                "difficulty": self.difficulty_level
            }
    
    def _generate_deduction_task(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate logical deduction task with adaptive difficulty."""
        deduction_steps = diff_params["deduction_steps"]
        deduction_type = self.rng.choice(["transitive", "syllogism"])
        
        if deduction_type == "transitive":
            # A > B, B > C, therefore A > C (can chain multiple steps)
            values = []
            current = self.rng.randint(10 * deduction_steps, 50 * deduction_steps)
            values.append(current)
            
            for _ in range(deduction_steps):
                next_val = self.rng.randint(1, current - 1) if current > 1 else 0
                values.append(next_val)
                current = next_val
            
            # Build premises
            premises = []
            for i in range(len(values) - 1):
                premises.append(f"{values[i]} > {values[i+1]}")
            
            question = f"If {' and '.join(premises)}, is {values[0]} > {values[-1]}?"
            expected = True  # Always true by transitivity
            
            return {
                "type": "logical_deduction",
                "inputs": {"premises": premises, "question": question},
                "expected_output": expected,
                "description": question,
                "difficulty": self.difficulty_level
            }
        else:  # syllogism
            # All A are B, X is A, therefore X is B (can add more categories)
            categories = [
                ("dogs", "animals"),
                ("roses", "flowers"),
                ("cars", "vehicles"),
                ("apples", "fruits"),
                ("triangles", "polygons"),
                ("metals", "elements")
            ]
            
            # Select multiple category pairs for harder deductions
            selected_cats = self.rng.sample(categories, min(deduction_steps, len(categories)))
            
            if deduction_steps == 2:
                cat_a, cat_b = selected_cats[0]
                question = f"All {cat_a} are {cat_b}. This is a {cat_a}. Is it a {cat_b}?"
                expected = True
            else:
                # Chain multiple syllogisms
                cat_a, cat_b = selected_cats[0]
                cat_c, cat_d = selected_cats[1]
                question = f"All {cat_a} are {cat_b}. All {cat_b} are {cat_d}. This is a {cat_a}. Is it a {cat_d}?"
                expected = True
            
            return {
                "type": "logical_deduction",
                "inputs": {"question": question},
                "expected_output": expected,
                "description": question,
                "difficulty": self.difficulty_level
            }
    
    def _generate_constraint_task(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate constraint satisfaction problem (CSP) with adaptive difficulty.
        
        Examples:
        - Sudoku-like grid constraints
        - Variable assignment with inequalities
        - Scheduling/assignment problems
        """
        num_vars = diff_params["bool_vars"] + 1  # Use more variables for CSP
        
        # Generate variables with domains
        domain_size = diff_params["pattern_range"][1]  # Range of possible values
        variables = {}
        var_names = [f'x{i}' for i in range(num_vars)]
        
        for name in var_names:
            variables[name] = self.rng.randint(1, domain_size)
        
        # Generate constraints
        constraints = []
        constraint_type = self.rng.choice(["inequality", "sum", "product"])
        
        if constraint_type == "inequality":
            # X1 < X2, X2 > X3, etc.
            for i in range(len(var_names) - 1):
                op = self.rng.choice(["<", ">", "!="])
                constraints.append(f"{var_names[i]} {op} {var_names[i+1]}")
            
            # Check if solution satisfies all constraints
            satisfied = True
            for i in range(len(var_names) - 1):
                v1, v2 = variables[var_names[i]], variables[var_names[i+1]]
                op = constraints[i].split()[1]
                if op == "<" and not (v1 < v2):
                    satisfied = False
                elif op == ">" and not (v1 > v2):
                    satisfied = False
                elif op == "!=" and not (v1 != v2):
                    satisfied = False
            
            question = f"Given constraints: {', '.join(constraints)}. Is this assignment valid?"
            expected = satisfied
            
        elif constraint_type == "sum":
            # Sum constraints: X1 + X2 = target
            target_sum = sum(variables.values())
            constraint_str = f"{' + '.join(var_names)} = {target_sum}"
            constraints.append(constraint_str)
            
            # Ask if a modified assignment would still satisfy
            modified_var = self.rng.choice(var_names)
            original_val = variables[modified_var]
            new_val = original_val + self.rng.choice([-1, 1, 2])
            
            # Calculate new sum
            new_sum = target_sum - original_val + new_val
            expected = (new_sum == target_sum)
            
            question = f"If {modified_var} changes from {original_val} to {new_val}, does '{constraint_str}' still hold?"
            
        else:  # product
            # Product constraints (harder)
            product = 1
            for val in variables.values():
                product *= val
            
            constraint_str = f"{' * '.join(var_names)} = {product}"
            constraints.append(constraint_str)
            
            # Ask about divisibility
            divisor = self.rng.randint(2, max(3, domain_size))
            expected = (product % divisor == 0)
            
            question = f"Given '{constraint_str}', is the product divisible by {divisor}?"
        
        return {
            "type": "constraint_satisfaction",
            "inputs": {
                "variables": variables,
                "constraints": constraints,
                "question": question
            },
            "expected_output": expected,
            "description": question,
            "difficulty": self.difficulty_level
        }
    
    def _generate_truth_table_task(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate truth table evaluation/completion task.
        
        Examples:
        - Complete missing rows in truth table
        - Determine if formula is tautology/contradiction
        - Find satisfying assignment for complex formula
        """
        num_vars = diff_params["bool_vars"]
        
        # Generate boolean expression with multiple operators
        var_names = ['a', 'b', 'c', 'd'][:num_vars]
        
        # Build complex expression
        operators = ["and", "or", "not", "implies", "iff"]
        
        if num_vars == 2:
            # Simple: (A AND B) OR (NOT A)
            expr_type = self.rng.choice(["simple", "medium"])
            
            if expr_type == "simple":
                # Evaluate specific row
                a = self.rng.choice([True, False])
                b = self.rng.choice([True, False])
                
                expr = "(A AND B) OR (NOT A)"
                result = (a and b) or (not a)
                
                question = f"Evaluate '{expr}' when A={a}, B={b}"
                expected = result
                
            else:  # medium
                # Count satisfying assignments
                expr = "(A AND B) OR (NOT A)"
                count = 0
                for a in [True, False]:
                    for b in [True, False]:
                        if (a and b) or (not a):
                            count += 1
                
                question = f"How many rows satisfy '{expr}' in truth table?"
                expected = count
        
        elif num_vars >= 3:
            # Complex: ((A OR B) AND C) IMPLIES (NOT D)
            expr_type = self.rng.choice(["complex", "tautology"])
            
            if expr_type == "complex":
                # Evaluate complex expression
                values = {name: self.rng.choice([True, False]) for name in var_names}
                
                # Build expression based on number of vars
                if num_vars == 3:
                    a, b, c = values['a'], values['b'], values['c']
                    expr = "((A OR B) AND C)"
                    result = (a or b) and c
                else:  # 4 vars
                    a, b, c, d = values['a'], values['b'], values['c'], values['d']
                    expr = "((A OR B) AND C) IMPLIES (NOT D)"
                    result = (not ((a or b) and c)) or (not d)
                
                var_assignments = ", ".join([f"{k.upper()}={v}" for k, v in values.items()])
                question = f"Evaluate '{expr}' when {var_assignments}"
                expected = result
            
            else:  # tautology check
                # Check if expression is always true
                is_tautology = True
                total_combinations = 2 ** num_vars
                
                # Define expression
                expr = "((A OR B) AND C)" if num_vars == 3 else "((A OR B) AND C) IMPLIES (NOT D)"
                
                # Test all combinations
                for i in range(total_combinations):
                    bits = [(i >> j) & 1 == 1 for j in range(num_vars)]
                    values = {var_names[j]: bits[j] for j in range(num_vars)}
                    
                    # Evaluate expression
                    if num_vars == 3:
                        a, b, c = values['a'], values['b'], values['c']
                        result = (a or b) and c
                    else:
                        a, b, c, d = values['a'], values['b'], values['c'], values['d']
                        result = (not ((a or b) and c)) or (not d)
                    
                    if not result:
                        is_tautology = False
                        break
                
                question = f"Is '{expr}' a tautology (always true)?"
                expected = is_tautology
        
        return {
            "type": "truth_table",
            "inputs": {
                "expression": expr,
                "variables": var_names,
                "question": question
            },
            "expected_output": expected,
            "description": question,
            "difficulty": self.difficulty_level
        }
    
    def verify_solution(self, task: Dict[str, Any], output: Any) -> bool:
        """Verify if output matches expected result."""
        expected = task["expected_output"]
        
        if isinstance(expected, bool):
            return output == expected
        elif isinstance(expected, (int, float)):
            return abs(output - expected) < 1e-6
        else:
            return output == expected


# Example usage
if __name__ == "__main__":
    generator = LogicPuzzleGenerator(seed=42)
    
    print("Generating sample logic puzzle tasks:\n")
    
    for i in range(8):
        task = generator.generate_task()
        print(f"Task {i+1}: {task['description']}")
        print(f"  Type: {task['type']}")
        print(f"  Expected: {task['expected_output']}")
        print()
