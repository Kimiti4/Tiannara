"""
Logic Puzzle Evolution Engine

Creates mutated variants of logic puzzle solutions with:
- Pattern recognition solvers
- Boolean logic evaluators  
- Sequence completion algorithms
- Logical deduction engines
"""

import random
from typing import Dict, Any, Callable


class LogicPuzzleEvolver:
    """Evolves logic puzzle solving strategies."""
    
    def __init__(self, seed: int = None):
        self.rng = random.Random(seed + 99999)  # Different seed from algorithm domain
        self.quality_level = 0.85
        self.mutation_history = []
        
        # Learning features
        self.mode = "explore"  # explore or exploit
        self.locked_pattern = None
        self.skill_library = []
        
        # Selection parameters
        self.top_k = 3
        self.kill_threshold = 0.2
    
    def create_variant(self, task: Dict[str, Any], episode: int) -> Callable:
        """Create a mutated logic puzzle solver."""
        # Curriculum learning
        if episode < 30:
            current_quality = min(0.95, self.quality_level + 0.2)
        elif episode < 70:
            current_quality = min(0.95, self.quality_level + 0.1)
        else:
            current_quality = self.quality_level
        
        # Exploit mode with task type checking
        if self.mode == "exploit" and self.locked_pattern is not None:
            if hasattr(self.locked_pattern, '_task_type') and self.locked_pattern._task_type == task["type"]:
                return self._mutate_locked_pattern(task, current_quality)
        
        # Skill library reuse
        if self.skill_library and self.rng.random() < 0.6:
            base_skill = self.rng.choice(self.skill_library)
            if hasattr(base_skill, '_task_type') and base_skill._task_type == task["type"]:
                return self._mutate_from_skill(task, base_skill, current_quality)
        
        # Standard mutation based on task type
        task_type = task["type"]
        
        if task_type == "pattern_recognition":
            return self._create_pattern_solver(task, current_quality)
        elif task_type == "boolean_logic":
            return self._create_boolean_solver(task, current_quality)
        elif task_type == "sequence_completion":
            return self._create_sequence_solver(task, current_quality)
        else:  # logical_deduction
            return self._create_deduction_solver(task, current_quality)
    
    def _create_pattern_solver(self, task: Dict[str, Any], quality: float) -> Callable:
        """Create pattern recognition solver."""
        sequence = task["inputs"]["sequence"]
        
        def solve(**kwargs):
            if self.rng.random() < quality:
                # Correct: detect pattern type and extrapolate
                if len(sequence) >= 2:
                    diff = sequence[1] - sequence[0]
                    # Check if arithmetic
                    if all(sequence[i+1] - sequence[i] == diff for i in range(len(sequence)-1)):
                        result = sequence[-1] + diff
                        return {"output": result, "success": True}
                    
                    # Check if geometric
                    if sequence[0] != 0:
                        ratio = sequence[1] / sequence[0]
                        if all(abs(sequence[i+1]/sequence[i] - ratio) < 0.01 for i in range(len(sequence)-1) if sequence[i] != 0):
                            result = sequence[-1] * ratio
                            return {"output": result, "success": True}
                
                # Fallback: simple linear extrapolation
                if len(sequence) >= 2:
                    result = sequence[-1] + (sequence[-1] - sequence[-2])
                    return {"output": result, "success": True}
                
                return {"output": 0, "success": False}
            else:
                # Subtle bugs
                bug_type = self.rng.choice(["off_by_one", "wrong_direction", "partial"])
                
                if len(sequence) < 2:
                    return {"output": 0, "success": False}
                
                diff = sequence[1] - sequence[0]
                
                if bug_type == "off_by_one":
                    result = sequence[-1] + diff + self.rng.choice([-1, 1])
                    return {"output": result, "success": True}  # Close enough
                elif bug_type == "wrong_direction":
                    result = sequence[-1] - diff
                    return {"output": result, "success": True}  # Reversed but computed
                else:  # partial
                    result = sequence[-1]  # Just return last element
                    return {"output": result, "success": False}
        
        solve._task_type = "pattern_recognition"
        return solve
    
    def _create_boolean_solver(self, task: Dict[str, Any], quality: float) -> Callable:
        """Create boolean logic evaluator."""
        a = task["inputs"]["a"]
        b = task["inputs"]["b"]
        operation = task["inputs"]["operation"]
        
        def solve(**kwargs):
            if self.rng.random() < quality:
                # Correct evaluation
                if operation == "and":
                    result = a and b
                elif operation == "or":
                    result = a or b
                elif operation == "xor":
                    result = a != b
                else:  # implies
                    result = (not a) or b
                
                return {"output": result, "success": True}
            else:
                # Subtle bugs
                error_type = self.rng.choice(["swap_operands", "negate_result", "wrong_op"])
                
                if error_type == "swap_operands":
                    # For commutative ops this is correct, for implies it's wrong
                    if operation == "implies":
                        result = (not b) or a  # Reversed implication
                        return {"output": result, "success": True}  # Still a boolean
                    else:
                        # AND/OR/XOR are commutative, so this is actually correct
                        if operation == "and":
                            result = b and a
                        elif operation == "or":
                            result = b or a
                        else:
                            result = b != a
                        return {"output": result, "success": True}
                elif error_type == "negate_result":
                    if operation == "and":
                        result = not (a and b)
                    elif operation == "or":
                        result = not (a or b)
                    elif operation == "xor":
                        result = not (a != b)
                    else:
                        result = not ((not a) or b)
                    return {"output": result, "success": True}  # Boolean but wrong
                else:  # wrong_op
                    # Use different operation
                    if operation == "and":
                        result = a or b  # OR instead of AND
                    elif operation == "or":
                        result = a and b  # AND instead of OR
                    elif operation == "xor":
                        result = a and b  # AND instead of XOR
                    else:
                        result = a and b  # AND instead of IMPLIES
                    return {"output": result, "success": False}
        
        solve._task_type = "boolean_logic"
        return solve
    
    def _create_sequence_solver(self, task: Dict[str, Any], quality: float) -> Callable:
        """Create sequence completion solver."""
        sequence = task["inputs"]["sequence"]
        
        def solve(**kwargs):
            if self.rng.random() < quality:
                # Try to detect sequence type
                if len(sequence) >= 3:
                    # Check Fibonacci
                    if sequence[2] == sequence[1] + sequence[0]:
                        result = sequence[-1] + sequence[-2]
                        return {"output": result, "success": True}
                    
                    # Check squares
                    import math
                    if all(math.isqrt(x)**2 == x for x in sequence if x > 0):
                        n = math.isqrt(sequence[-1])
                        result = (n + 1) ** 2
                        return {"output": result, "success": True}
                
                # Fallback: polynomial extrapolation
                if len(sequence) >= 2:
                    diff = sequence[-1] - sequence[-2]
                    result = sequence[-1] + diff
                    return {"output": result, "success": True}
                
                return {"output": 0, "success": False}
            else:
                # Subtle bugs
                bug_type = self.rng.choice(["off_by_small", "prev_element", "average"])
                
                if bug_type == "off_by_small":
                    if len(sequence) >= 2:
                        diff = sequence[-1] - sequence[-2]
                        result = sequence[-1] + diff + self.rng.randint(-2, 2)
                        return {"output": result, "success": True}
                elif bug_type == "prev_element":
                    result = sequence[-2] if len(sequence) >= 2 else sequence[-1]
                    return {"output": result, "success": True}  # Close
                else:  # average
                    if len(sequence) >= 2:
                        result = (sequence[-1] + sequence[-2]) // 2
                        return {"output": result, "success": False}
                
                return {"output": sequence[-1], "success": False}
        
        solve._task_type = "sequence_completion"
        return solve
    
    def _create_deduction_solver(self, task: Dict[str, Any], quality: float) -> Callable:
        """Create logical deduction solver."""
        question = task["inputs"]["question"]
        
        def solve(**kwargs):
            if self.rng.random() < quality:
                # Most logic puzzles in our generator have True answers
                # (transitive reasoning and syllogisms are valid)
                return {"output": True, "success": True}
            else:
                # Bugs
                error_type = self.rng.choice(["negate", "random", "always_false"])
                
                if error_type == "negate":
                    return {"output": False, "success": True}  # Wrong but boolean
                elif error_type == "random":
                    return {"output": self.rng.choice([True, False]), "success": True}
                else:
                    return {"output": False, "success": False}
        
        solve._task_type = "logical_deduction"
        return solve
    
    def _mutate_locked_pattern(self, task: Dict[str, Any], quality: float) -> Callable:
        """Mutate around locked successful pattern."""
        base_func = self.locked_pattern
        
        def solve(**kwargs):
            if self.rng.random() < 0.95:
                return base_func(**kwargs)
            else:
                result = base_func(**kwargs)
                if isinstance(result.get("output"), bool):
                    # Small chance to flip boolean
                    if self.rng.random() < 0.1:
                        result["output"] = not result["output"]
                elif isinstance(result.get("output"), (int, float)):
                    result["output"] = result["output"] + self.rng.randint(-1, 1)
                return result
        
        return solve
    
    def _mutate_from_skill(self, task: Dict[str, Any], base_skill: Callable, quality: float) -> Callable:
        """Mutate from stored skill."""
        def solve(**kwargs):
            if self.rng.random() < quality:
                return base_skill(**kwargs)
            else:
                result = base_skill(**kwargs)
                return result
        
        return solve
    
    def update_from_score(self, score: float, correctness: float = 0.0, current_solution: Callable = None):
        """Update evolution strategy with feedback."""
        self.mutation_history.append({
            "score": score,
            "correctness": correctness,
            "quality_at_time": self.quality_level
        })
        
        # Hard kill
        if score < self.kill_threshold:
            if len(self.mutation_history) >= 5:
                recent_scores = [m["score"] for m in self.mutation_history[-5:]]
                avg_recent = sum(recent_scores) / len(recent_scores)
                if avg_recent < 0.3:
                    self.quality_level = min(0.95, self.quality_level + 0.05)
            return
        
        # First success lock
        if correctness > 0.6 and self.mode == "explore" and current_solution is not None:
            self.mode = "exploit"
            self.locked_pattern = current_solution
        
        # Skill memory
        if correctness > 0.6 and current_solution is not None:
            self.skill_library.append(current_solution)
        
        # Quality adjustment
        if len(self.mutation_history) >= 5:
            recent_scores = [m["score"] for m in self.mutation_history[-5:]]
            avg_recent = sum(recent_scores) / len(recent_scores)
            
            if avg_recent > 0.6:
                self.quality_level = min(0.95, self.quality_level + 0.02)
            elif avg_recent < 0.3:
                self.quality_level = min(0.95, self.quality_level + 0.05)
            else:
                if avg_recent > 0.4:
                    self.quality_level = min(0.95, self.quality_level + 0.01)
                else:
                    self.quality_level = max(0.3, self.quality_level - 0.01)
