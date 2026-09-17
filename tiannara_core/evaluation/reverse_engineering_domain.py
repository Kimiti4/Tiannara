"""Reverse Engineering Domain - Input/Output Mapping Recovery & Black-Box Function Inference.

This domain tests the system's ability to:
1. Recover hidden functions from input-output examples
2. Infer transformation rules from limited data
3. Generalize patterns to unseen inputs

Best for ECM (Evolutionary Causal Modeling) testing.
"""

import random
from typing import Dict, Any, List, Callable


class ReverseEngineeringGenerator:
    """Generates reverse engineering tasks."""
    
    def __init__(self, seed: int = None):
        self.rng = random.Random(seed)
        
        # Adaptive difficulty tracking
        self.episode_count = 0
        self.difficulty_level = "easy"
        self.success_history = []
    
    def _get_difficulty_params(self, episode: int = None) -> Dict[str, Any]:
        """Calculate difficulty parameters based on episode and performance."""
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
                if base_difficulty == "easy":
                    base_difficulty = "medium"
                elif base_difficulty == "medium":
                    base_difficulty = "hard"
            elif recent_success < 0.3 and base_difficulty != "easy":
                if base_difficulty == "hard":
                    base_difficulty = "medium"
                elif base_difficulty == "medium":
                    base_difficulty = "easy"
        
        self.difficulty_level = base_difficulty
        
        # Define parameters for each difficulty level
        params = {
            "easy": {
                "num_examples": 5,      # Few examples to learn from
                "input_range": (1, 10), # Small input range
                "complexity": 1         # Simple transformations
            },
            "medium": {
                "num_examples": 8,
                "input_range": (1, 20),
                "complexity": 2
            },
            "hard": {
                "num_examples": 12,
                "input_range": (1, 50),
                "complexity": 3
            }
        }
        
        return params[base_difficulty]
    
    def update_performance(self, success: bool):
        """Record task outcome for adaptive difficulty."""
        self.success_history.append(1 if success else 0)
        if len(self.success_history) > 20:
            self.success_history.pop(0)
    
    def generate_task(self, episode: int = None) -> Dict[str, Any]:
        """Generate a reverse engineering task."""
        diff_params = self._get_difficulty_params(episode)
        
        task_type = self.rng.choice([
            "linear_function",
            "polynomial",
            "piecewise",
            "modulo_pattern"
        ])
        
        if task_type == "linear_function":
            return self._generate_linear_task(diff_params)
        elif task_type == "polynomial":
            return self._generate_polynomial_task(diff_params)
        elif task_type == "piecewise":
            return self._generate_piecewise_task(diff_params)
        else:  # modulo_pattern
            return self._generate_modulo_task(diff_params)
    
    def _generate_linear_task(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate linear function recovery task: f(x) = ax + b"""
        num_examples = diff_params["num_examples"]
        input_range = diff_params["input_range"]
        
        # Generate hidden linear function
        a = self.rng.randint(1, 5)
        b = self.rng.randint(-10, 10)
        
        def hidden_func(x):
            return a * x + b
        
        # Generate training examples
        examples = []
        test_inputs = []
        
        for _ in range(num_examples):
            x = self.rng.randint(*input_range)
            y = hidden_func(x)
            examples.append({"input": x, "output": y})
        
        # Generate test input
        test_x = self.rng.randint(*input_range)
        while any(e["input"] == test_x for e in examples):
            test_x = self.rng.randint(*input_range)
        
        expected_output = hidden_func(test_x)
        
        return {
            "type": "reverse_engineering",
            "subtype": "linear_function",
            "inputs": {
                "examples": examples,
                "test_input": test_x
            },
            "expected_output": expected_output,
            "description": f"Infer function from {num_examples} examples, predict f({test_x})",
            "difficulty": self.difficulty_level,
            "hidden_params": {"a": a, "b": b}  # For verification only
        }
    
    def _generate_polynomial_task(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate polynomial function recovery: f(x) = ax² + bx + c"""
        num_examples = diff_params["num_examples"]
        input_range = diff_params["input_range"]
        complexity = diff_params["complexity"]
        
        # Generate hidden polynomial (degree depends on complexity)
        degree = min(complexity + 1, 3)  # max degree 3
        coeffs = [self.rng.randint(-3, 3) for _ in range(degree + 1)]
        
        def hidden_func(x):
            result = 0
            for i, coeff in enumerate(coeffs):
                result += coeff * (x ** i)
            return result
        
        # Generate training examples
        examples = []
        for _ in range(num_examples):
            x = self.rng.randint(*input_range)
            y = hidden_func(x)
            examples.append({"input": x, "output": y})
        
        # Generate test input
        test_x = self.rng.randint(*input_range)
        while any(e["input"] == test_x for e in examples):
            test_x = self.rng.randint(*input_range)
        
        expected_output = hidden_func(test_x)
        
        return {
            "type": "reverse_engineering",
            "subtype": "polynomial",
            "inputs": {
                "examples": examples,
                "test_input": test_x
            },
            "expected_output": expected_output,
            "description": f"Infer polynomial from {num_examples} examples, predict f({test_x})",
            "difficulty": self.difficulty_level,
            "hidden_params": {"coeffs": coeffs}
        }
    
    def _generate_piecewise_task(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate piecewise function recovery."""
        num_examples = diff_params["num_examples"]
        input_range = diff_params["input_range"]
        
        # Generate hidden piecewise function
        threshold = self.rng.randint(*input_range)
        
        def hidden_func(x):
            if x < threshold:
                return 2 * x + 1
            else:
                return x - 3
        
        # Generate training examples
        examples = []
        for _ in range(num_examples):
            x = self.rng.randint(*input_range)
            y = hidden_func(x)
            examples.append({"input": x, "output": y})
        
        # Generate test input
        test_x = self.rng.randint(*input_range)
        while any(e["input"] == test_x for e in examples):
            test_x = self.rng.randint(*input_range)
        
        expected_output = hidden_func(test_x)
        
        return {
            "type": "reverse_engineering",
            "subtype": "piecewise",
            "inputs": {
                "examples": examples,
                "test_input": test_x
            },
            "expected_output": expected_output,
            "description": f"Infer piecewise function from {num_examples} examples, predict f({test_x})",
            "difficulty": self.difficulty_level,
            "hidden_params": {"threshold": threshold}
        }
    
    def _generate_modulo_task(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate modulo pattern recovery: f(x) = x mod n"""
        num_examples = diff_params["num_examples"]
        input_range = diff_params["input_range"]
        
        # Generate hidden modulo
        n = self.rng.randint(2, 7)
        
        def hidden_func(x):
            return x % n
        
        # Generate training examples
        examples = []
        for _ in range(num_examples):
            x = self.rng.randint(*input_range)
            y = hidden_func(x)
            examples.append({"input": x, "output": y})
        
        # Generate test input
        test_x = self.rng.randint(*input_range)
        while any(e["input"] == test_x for e in examples):
            test_x = self.rng.randint(*input_range)
        
        expected_output = hidden_func(test_x)
        
        return {
            "type": "reverse_engineering",
            "subtype": "modulo_pattern",
            "inputs": {
                "examples": examples,
                "test_input": test_x
            },
            "expected_output": expected_output,
            "description": f"Infer modulo pattern from {num_examples} examples, predict f({test_x})",
            "difficulty": self.difficulty_level,
            "hidden_params": {"n": n}
        }
    
    def verify_solution(self, task: Dict[str, Any], output: Any) -> bool:
        """Verify if predicted output matches expected."""
        expected = task["expected_output"]
        return abs(output - expected) < 1e-6


# Example usage
if __name__ == "__main__":
    generator = ReverseEngineeringGenerator(seed=42)
    
    print("=" * 80)
    print("REVERSE ENGINEERING DOMAIN - SAMPLE TASKS")
    print("=" * 80)
    print()
    
    for i in range(5):
        task = generator.generate_task(episode=i+1)
        print(f"Task {i+1}: {task['description']}")
        print(f"  Type: {task['subtype']}")
        print(f"  Difficulty: {task['difficulty']}")
        print(f"  Examples: {len(task['inputs']['examples'])}")
        print(f"  Test Input: {task['inputs']['test_input']}")
        print(f"  Expected Output: {task['expected_output']}")
        print()
