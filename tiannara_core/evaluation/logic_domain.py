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
    """Generates logic puzzle tasks for evaluation."""
    
    def __init__(self, seed: int = None):
        self.rng = random.Random(seed)
    
    def generate_task(self) -> Dict[str, Any]:
        """Generate a random logic puzzle task."""
        task_type = self.rng.choice([
            "pattern_recognition",
            "boolean_logic", 
            "sequence_completion",
            "logical_deduction"
        ])
        
        if task_type == "pattern_recognition":
            return self._generate_pattern_task()
        elif task_type == "boolean_logic":
            return self._generate_boolean_task()
        elif task_type == "sequence_completion":
            return self._generate_sequence_task()
        else:  # logical_deduction
            return self._generate_deduction_task()
    
    def _generate_pattern_task(self) -> Dict[str, Any]:
        """Generate pattern recognition task."""
        pattern_type = self.rng.choice(["arithmetic", "geometric", "alternating"])
        
        if pattern_type == "arithmetic":
            # Arithmetic sequence: 2, 5, 8, 11, ...
            start = self.rng.randint(1, 10)
            step = self.rng.randint(2, 5)
            sequence = [start + i * step for i in range(5)]
            expected = start + 5 * step
            return {
                "type": "pattern_recognition",
                "inputs": {"sequence": sequence},
                "expected_output": expected,
                "description": f"Find next number in arithmetic sequence: {sequence}"
            }
        elif pattern_type == "geometric":
            # Geometric sequence: 2, 6, 18, 54, ...
            start = self.rng.randint(2, 5)
            ratio = self.rng.randint(2, 3)
            sequence = [start * (ratio ** i) for i in range(5)]
            expected = start * (ratio ** 5)
            return {
                "type": "pattern_recognition",
                "inputs": {"sequence": sequence},
                "expected_output": expected,
                "description": f"Find next number in geometric sequence: {sequence}"
            }
        else:  # alternating
            # Alternating pattern: 1, 3, 2, 4, 3, ...
            base = self.rng.randint(1, 5)
            sequence = []
            for i in range(6):
                if i % 2 == 0:
                    sequence.append(base + i // 2)
                else:
                    sequence.append(base + 2 + i // 2)
            expected = base + 3
            return {
                "type": "pattern_recognition",
                "inputs": {"sequence": sequence},
                "expected_output": expected,
                "description": f"Find next number in alternating pattern: {sequence}"
            }
    
    def _generate_boolean_task(self) -> Dict[str, Any]:
        """Generate boolean logic evaluation task."""
        # Simple boolean expressions
        a = self.rng.choice([True, False])
        b = self.rng.choice([True, False])
        c = self.rng.choice([True, False])
        
        operation = self.rng.choice(["and", "or", "xor", "implies"])
        
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
        
        return {
            "type": "boolean_logic",
            "inputs": {"a": a, "b": b, "operation": operation},
            "expected_output": result,
            "description": f"Evaluate: {expr}"
        }
    
    def _generate_sequence_task(self) -> Dict[str, Any]:
        """Generate sequence completion task."""
        seq_type = self.rng.choice(["fibonacci", "squares", "primes"])
        
        if seq_type == "fibonacci":
            # Fibonacci: 1, 1, 2, 3, 5, 8, ...
            fib = [1, 1]
            for i in range(6):
                fib.append(fib[-1] + fib[-2])
            sequence = fib[:6]
            expected = fib[6]
            return {
                "type": "sequence_completion",
                "inputs": {"sequence": sequence},
                "expected_output": expected,
                "description": f"Complete Fibonacci sequence: {sequence}"
            }
        elif seq_type == "squares":
            # Perfect squares: 1, 4, 9, 16, 25, ...
            n = self.rng.randint(1, 5)
            sequence = [(n + i) ** 2 for i in range(5)]
            expected = (n + 5) ** 2
            return {
                "type": "sequence_completion",
                "inputs": {"sequence": sequence},
                "expected_output": expected,
                "description": f"Complete square sequence: {sequence}"
            }
        else:  # primes
            # Prime numbers
            primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47]
            start_idx = self.rng.randint(0, len(primes) - 6)
            sequence = primes[start_idx:start_idx + 5]
            expected = primes[start_idx + 5]
            return {
                "type": "sequence_completion",
                "inputs": {"sequence": sequence},
                "expected_output": expected,
                "description": f"Complete prime sequence: {sequence}"
            }
    
    def _generate_deduction_task(self) -> Dict[str, Any]:
        """Generate logical deduction task."""
        # Simple syllogism or transitive reasoning
        deduction_type = self.rng.choice(["transitive", "syllogism"])
        
        if deduction_type == "transitive":
            # A > B, B > C, therefore A > C
            a = self.rng.randint(10, 50)
            b = self.rng.randint(1, a - 1)
            c = self.rng.randint(1, b - 1) if b > 1 else 0
            
            question = f"If {a} > {b} and {b} > {c}, is {a} > {c}?"
            expected = True  # Always true by transitivity
            
            return {
                "type": "logical_deduction",
                "inputs": {"premises": [f"{a} > {b}", f"{b} > {c}"], "question": question},
                "expected_output": expected,
                "description": question
            }
        else:  # syllogism
            # All A are B, X is A, therefore X is B
            categories = [
                ("dogs", "animals"),
                ("roses", "flowers"),
                ("cars", "vehicles"),
                ("apples", "fruits")
            ]
            cat_a, cat_b = self.rng.choice(categories)
            
            question = f"All {cat_a} are {cat_b}. This is a {cat_a}. Is it a {cat_b}?"
            expected = True
            
            return {
                "type": "logical_deduction",
                "inputs": {"premises": [f"All {cat_a} are {cat_b}", f"This is a {cat_a}"], "question": question},
                "expected_output": expected,
                "description": question
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
