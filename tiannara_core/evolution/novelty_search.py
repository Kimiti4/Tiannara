"""
Novelty Search Module for Evolution Engine

Implements novelty-driven exploration to complement fitness-based optimization.
Prevents premature convergence by maintaining behavioral diversity.

Features:
- Novelty scoring based on behavioral distance
- Archive of discovered behaviors
- Adaptive strategy selection (fitness vs novelty)
- Dynamic threshold adjustment
"""

from __future__ import annotations

import math
import random
from typing import Any, Dict, List, Optional, Tuple


class BehaviorCharacterization:
    """Extracts behavioral features from agents for novelty comparison."""
    
    def __init__(self, feature_dim: int = 5):
        self.feature_dim = feature_dim
    
    def extract_features(self, agent) -> List[float]:
        """
        Extract behavioral features from agent.
        
        Uses probe inputs to characterize agent behavior across multiple dimensions.
        """
        # Use multiple probe inputs to capture diverse behaviors
        probes = [
            [0.1, -0.2, 0.3, -0.4, 0.5],
            [-0.5, 0.4, -0.3, 0.2, -0.1],
            [0.0, 0.0, 0.0, 0.0, 0.0],
            [1.0, -1.0, 0.5, -0.5, 0.0],
            [0.25, 0.25, 0.25, 0.25, 0.25],
        ]
        
        features = []
        for probe in probes[:self.feature_dim]:
            try:
                output = agent.forward(probe)
                # Aggregate output into single feature value
                if hasattr(output, '__iter__'):
                    feature_val = sum(output) / len(output)
                else:
                    feature_val = float(output)
                features.append(feature_val)
            except Exception:
                features.append(0.0)
        
        # Pad if necessary
        while len(features) < self.feature_dim:
            features.append(0.0)
        
        return features[:self.feature_dim]


class NoveltyArchive:
    """Maintains archive of discovered behaviors for novelty assessment."""
    
    def __init__(self, max_size: int = 100, similarity_threshold: float = 0.1):
        self.max_size = max_size
        self.similarity_threshold = similarity_threshold
        self.archive: List[List[float]] = []
        self.addition_history: List[int] = []  # Track when behaviors were added
    
    def add_behavior(self, behavior: List[float]) -> bool:
        """Add behavior to archive if sufficiently novel."""
        if not self.archive:
            self.archive.append(behavior.copy())
            self.addition_history.append(len(self.addition_history))
            return True
        
        # Check if behavior is novel enough
        min_distance = self._min_distance_to_archive(behavior)
        
        if min_distance > self.similarity_threshold:
            # Add to archive
            if len(self.archive) >= self.max_size:
                # Remove oldest behavior
                oldest_idx = self.addition_history.index(min(self.addition_history))
                self.archive.pop(oldest_idx)
                self.addition_history.pop(oldest_idx)
            
            self.archive.append(behavior.copy())
            self.addition_history.append(len(self.addition_history))
            return True
        
        return False
    
    def novelty_score(self, behavior: List[float], k: int = 5) -> float:
        """
        Calculate novelty score based on distance to k-nearest neighbors in archive.
        
        Higher score = more novel behavior.
        """
        if not self.archive:
            return 1.0  # Maximum novelty if archive is empty
        
        # Calculate distances to all archived behaviors
        distances = [
            self._euclidean_distance(behavior, archived)
            for archived in self.archive
        ]
        
        # Sort and take k nearest
        distances.sort()
        k_nearest = distances[:min(k, len(distances))]
        
        # Novelty is average distance to k nearest neighbors
        if not k_nearest:
            return 0.0
        
        avg_distance = sum(k_nearest) / len(k_nearest)
        
        # Normalize to [0, 1] range
        normalized_novelty = min(1.0, avg_distance / 2.0)
        
        return normalized_novelty
    
    def _min_distance_to_archive(self, behavior: List[float]) -> float:
        """Find minimum distance from behavior to any archived behavior."""
        if not self.archive:
            return float('inf')
        
        distances = [
            self._euclidean_distance(behavior, archived)
            for archived in self.archive
        ]
        
        return min(distances)
    
    @staticmethod
    def _euclidean_distance(a: List[float], b: List[float]) -> float:
        """Calculate Euclidean distance between two behavior vectors."""
        if len(a) != len(b):
            raise ValueError("Behavior vectors must have same dimension")
        
        return math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b)))
    
    def get_stats(self) -> Dict[str, Any]:
        """Get archive statistics."""
        return {
            'size': len(self.archive),
            'max_size': self.max_size,
            'similarity_threshold': self.similarity_threshold,
            'total_added': len(self.addition_history),
        }


class AdaptiveStrategySelector:
    """
    Dynamically selects between fitness-based and novelty-based strategies.
    
    Adapts based on:
    - Population diversity
    - Convergence rate
    - Recent improvement history
    """
    
    def __init__(
        self,
        initial_novelty_weight: float = 0.3,
        adaptation_rate: float = 0.1,
        diversity_threshold: float = 0.2,
        stagnation_window: int = 5
    ):
        self.novelty_weight = initial_novelty_weight
        self.adaptation_rate = adaptation_rate
        self.diversity_threshold = diversity_threshold
        self.stagnation_window = stagnation_window
        
        self.fitness_history: List[float] = []
        self.diversity_history: List[float] = []
        self.strategy_history: List[str] = []
    
    def select_strategy(
        self,
        current_fitness: float,
        population_diversity: float,
        generation: int
    ) -> Tuple[str, float]:
        """
        Select evolution strategy and novelty weight.
        
        Returns:
            Tuple of (strategy_name, novelty_weight)
            - strategy_name: 'fitness', 'novelty', or 'hybrid'
            - novelty_weight: weight for novelty in combined score [0, 1]
        """
        self.fitness_history.append(current_fitness)
        self.diversity_history.append(population_diversity)
        
        # Detect stagnation
        stagnation = self._detect_stagnation()
        
        # Low diversity indicates convergence risk
        low_diversity = population_diversity < self.diversity_threshold
        
        if stagnation or low_diversity:
            # Increase novelty exploration
            self.novelty_weight = min(0.8, self.novelty_weight + self.adaptation_rate)
            strategy = 'novelty' if self.novelty_weight > 0.6 else 'hybrid'
        else:
            # Favor exploitation
            self.novelty_weight = max(0.1, self.novelty_weight - self.adaptation_rate * 0.5)
            strategy = 'fitness' if self.novelty_weight < 0.3 else 'hybrid'
        
        self.strategy_history.append(strategy)
        
        return strategy, self.novelty_weight
    
    def _detect_stagnation(self) -> bool:
        """Detect if fitness has stagnated recently."""
        if len(self.fitness_history) < self.stagnation_window:
            return False
        
        recent = self.fitness_history[-self.stagnation_window:]
        
        # Check if improvement is minimal
        if len(recent) >= 2:
            improvement = recent[-1] - recent[0]
            return abs(improvement) < 0.01
        
        return False
    
    def compute_combined_score(
        self,
        fitness_score: float,
        novelty_score: float,
        novelty_weight: Optional[float] = None
    ) -> float:
        """Compute combined fitness-novelty score."""
        weight = novelty_weight if novelty_weight is not None else self.novelty_weight
        
        # Combined score: (1-weight)*fitness + weight*novelty
        combined = (1 - weight) * fitness_score + weight * novelty_score
        
        return combined
    
    def get_stats(self) -> Dict[str, Any]:
        """Get strategy selector statistics."""
        strategy_counts = {}
        for strategy in self.strategy_history:
            strategy_counts[strategy] = strategy_counts.get(strategy, 0) + 1
        
        return {
            'current_novelty_weight': round(self.novelty_weight, 4),
            'total_generations': len(self.fitness_history),
            'strategy_distribution': strategy_counts,
            'avg_diversity': round(
                sum(self.diversity_history) / len(self.diversity_history), 4
            ) if self.diversity_history else 0.0,
        }


def compute_population_diversity(population_behaviors: List[List[float]]) -> float:
    """
    Compute diversity of population based on behavioral distances.
    
    Returns diversity score in [0, 1] where 1 = maximum diversity.
    """
    if len(population_behaviors) < 2:
        return 0.0
    
    # Calculate pairwise distances
    distances = []
    for i in range(len(population_behaviors)):
        for j in range(i + 1, len(population_behaviors)):
            dist = NoveltyArchive._euclidean_distance(
                population_behaviors[i],
                population_behaviors[j]
            )
            distances.append(dist)
    
    if not distances:
        return 0.0
    
    # Normalize by maximum possible distance (assuming features in [-1, 1])
    max_possible_dist = math.sqrt(len(population_behaviors[0]) * 4)
    avg_distance = sum(distances) / len(distances)
    
    diversity = min(1.0, avg_distance / max_possible_dist)
    
    return diversity


# Example usage and testing
if __name__ == '__main__':
    print("="*80)
    print("NOVELTY SEARCH MODULE - DEMONSTRATION")
    print("="*80)
    
    # Create components
    archive = NoveltyArchive(max_size=50, similarity_threshold=0.15)
    strategy_selector = AdaptiveStrategySelector(
        initial_novelty_weight=0.3,
        adaptation_rate=0.1
    )
    
    print("\n1. Testing Novelty Archive...")
    
    # Simulate adding behaviors
    test_behaviors = [
        [random.uniform(-1, 1) for _ in range(5)]
        for _ in range(20)
    ]
    
    added_count = 0
    for i, behavior in enumerate(test_behaviors):
        novelty = archive.novelty_score(behavior)
        was_added = archive.add_behavior(behavior)
        
        if was_added:
            added_count += 1
            print(f"  Behavior {i+1}: novelty={novelty:.3f} → ADDED")
        else:
            print(f"  Behavior {i+1}: novelty={novelty:.3f} → rejected (not novel)")
    
    print(f"\n  Archive stats: {archive.get_stats()}")
    
    print("\n2. Testing Adaptive Strategy Selection...")
    
    # Simulate evolution with varying fitness and diversity
    for gen in range(15):
        # Simulate fitness (improving then stagnating)
        if gen < 8:
            fitness = 0.5 + gen * 0.05
        else:
            fitness = 0.9 + random.uniform(-0.01, 0.01)
        
        # Simulate diversity (decreasing over time)
        diversity = max(0.1, 0.8 - gen * 0.05)
        
        strategy, novelty_weight = strategy_selector.select_strategy(
            fitness, diversity, gen
        )
        
        print(f"  Gen {gen+1:2d}: fitness={fitness:.3f}, diversity={diversity:.3f} "
              f"→ strategy={strategy:8s}, novelty_weight={novelty_weight:.3f}")
    
    print(f"\n  Strategy stats: {strategy_selector.get_stats()}")
    
    print("\n3. Testing Combined Scoring...")
    
    test_cases = [
        (0.8, 0.2, 0.3),  # High fitness, low novelty
        (0.5, 0.9, 0.5),  # Medium fitness, high novelty
        (0.3, 0.3, 0.7),  # Low fitness, medium novelty
    ]
    
    for fitness, novelty, weight in test_cases:
        combined = strategy_selector.compute_combined_score(fitness, novelty, weight)
        print(f"  fitness={fitness:.2f}, novelty={novelty:.2f}, weight={weight:.2f} "
              f"→ combined={combined:.3f}")
    
    print("\n" + "="*80)
    print("✅ NOVELTY SEARCH MODULE READY FOR INTEGRATION")
    print("="*80)
