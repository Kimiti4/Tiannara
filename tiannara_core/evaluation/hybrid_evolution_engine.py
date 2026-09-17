"""Hybrid Evolution Engine - Routes tasks to appropriate domain evolvers."""

import random
from typing import Callable, Dict, Any

from .evolution_engine import AlgorithmEvolver
from .logic_evolution_engine import LogicPuzzleEvolver


class HybridEvolver:
    """Routes mutation requests to algorithm or logic evolvers based on task type."""
    
    def __init__(self, seed: int = None):
        self.rng = random.Random(seed)
        
        # Initialize domain-specific evolvers
        self.algo_evolver = AlgorithmEvolver(seed=seed)
        self.logic_evolver = LogicPuzzleEvolver(seed=seed)
        
        # Track which domain is being used
        self.current_domain = None
    
    def create_variant(self, task: Dict[str, Any], episode: int) -> Callable:
        """Create mutation by routing to appropriate domain evolver."""
        source_domain = task.get("source_domain", "algorithm")
        
        if source_domain == "algorithm":
            # Use algorithm evolver
            self.current_domain = "algorithm"
            return self.algo_evolver.create_variant(task, episode=episode)
        else:
            # Use logic evolver
            self.current_domain = "logic"
            return self.logic_evolver.create_variant(task, episode=episode)
    
    def get_domain_stats(self) -> Dict[str, Any]:
        """Get statistics from both domain evolvers."""
        return {
            "algorithm_skills": len(self.algo_evolver.skill_memory),
            "logic_quality": self.logic_evolver.quality_level,
            "current_domain": self.current_domain
        }
