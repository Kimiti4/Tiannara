"""Hybrid Domain - Combines Algorithm and Logic Puzzle tasks for cross-domain transfer testing."""

import random
from typing import Dict, Any, List

from .algorithm_domain import AlgorithmTaskGenerator
from .logic_domain import LogicPuzzleGenerator


class HybridTaskGenerator:
    """Generates tasks from both algorithm and logic domains to test cross-domain transfer."""
    
    def __init__(self, seed: int = None):
        self.rng = random.Random(seed)
        
        # Initialize sub-generators
        self.algo_gen = AlgorithmTaskGenerator(seed=seed)
        self.logic_gen = LogicPuzzleGenerator(seed=seed)
        
        # Adaptive difficulty tracking (shared across domains)
        self.episode_count = 0
        self.difficulty_level = "easy"
        self.success_history = []
        
        # Domain mixing ratio (can be adjusted)
        self.algo_ratio = 0.5  # 50% algorithm, 50% logic
        
    def _get_difficulty_params(self, episode: int = None) -> Dict[str, Any]:
        """Shared adaptive difficulty calculation."""
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
        
        return {
            "difficulty": base_difficulty,
            "episode": self.episode_count
        }
    
    def update_performance(self, success: bool):
        """Record task outcome for adaptive difficulty."""
        self.success_history.append(1 if success else 0)
        if len(self.success_history) > 20:
            self.success_history.pop(0)
        
        # Update both sub-generators
        self.algo_gen.update_performance(success)
        self.logic_gen.update_performance(success)
    
    def generate_task(self, episode: int = None) -> Dict[str, Any]:
        """Generate a task from either algorithm or logic domain."""
        diff_params = self._get_difficulty_params(episode)
        
        # Decide which domain to sample from
        if self.rng.random() < self.algo_ratio:
            # Generate algorithm task
            task = self.algo_gen.generate_task(episode=episode)
            task["source_domain"] = "algorithm"
        else:
            # Generate logic puzzle task
            task = self.logic_gen.generate_task(episode=episode)
            task["source_domain"] = "logic"
        
        # Add hybrid metadata
        task["difficulty"] = self.difficulty_level
        task["hybrid_episode"] = episode
        
        return task
    
    def verify_solution(self, task: Dict[str, Any], output: Any) -> bool:
        """Verify solution using appropriate domain verifier."""
        source = task.get("source_domain", "algorithm")
        
        if source == "algorithm":
            return self.algo_gen.verify_solution(task, output)
        else:
            return self.logic_gen.verify_solution(task, output)


# Example usage
if __name__ == "__main__":
    generator = HybridTaskGenerator(seed=42)
    
    print("=" * 80)
    print("HYBRID DOMAIN - SAMPLE TASKS")
    print("=" * 80)
    print()
    
    for i in range(10):
        task = generator.generate_task(episode=i+1)
        print(f"Episode {i+1}:")
        print(f"  Source: {task['source_domain']}")
        print(f"  Type: {task['type']}")
        print(f"  Difficulty: {task['difficulty']}")
        print(f"  Description: {task['description'][:80]}...")
        print()
