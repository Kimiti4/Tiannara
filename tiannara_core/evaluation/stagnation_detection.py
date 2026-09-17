"""
Stagnation Detection and Strategy Switching.

Detects when learning plateaus and automatically switches strategies
to prevent local optima and force exploration.

Task IDs: stagnation_detect_1a2b3c, strategy_switch_4d5e6f
"""

import numpy as np
from typing import Dict, List, Optional, Tuple
from collections import deque


class StagnationDetector:
    """
    Detects learning stagnation based on performance metrics.
    
    Monitors success rate trends and triggers strategy switches
    when improvement stalls.
    """
    
    def __init__(self, window_size: int = 20, threshold: float = 0.02):
        """
        Initialize stagnation detector.
        
        Args:
            window_size: Number of episodes to analyze for trends
            threshold: Minimum improvement rate to avoid stagnation flag
        """
        self.window_size = window_size
        self.threshold = threshold
        
        # Performance history
        self.success_history = deque(maxlen=window_size * 2)
        self.quality_history = deque(maxlen=window_size * 2)
        
        # Stagnation tracking
        self.stagnation_episodes = 0
        self.last_improvement_episode = 0
        self.best_success_rate = 0.0
        
        # Strategy switching
        self.strategy_switch_count = 0
        self.current_strategy = None
        self.strategy_performance: Dict[str, List[float]] = {}
    
    def record_episode(self, episode: int, success: bool, quality: float, 
                      strategy: str = None):
        """Record episode results for stagnation analysis."""
        
        self.success_history.append(1 if success else 0)
        self.quality_history.append(quality)
        
        if strategy:
            self.current_strategy = strategy
            if strategy not in self.strategy_performance:
                self.strategy_performance[strategy] = []
            self.strategy_performance[strategy].append(quality)
        
        # Check for improvement
        current_rate = self._calculate_recent_success_rate()
        
        if current_rate > self.best_success_rate:
            self.best_success_rate = current_rate
            self.last_improvement_episode = episode
            self.stagnation_episodes = 0
        else:
            self.stagnation_episodes += 1
    
    def _calculate_recent_success_rate(self, window: int = None) -> float:
        """Calculate success rate over recent episodes."""
        if window is None:
            window = self.window_size
        
        if len(self.success_history) < window:
            return 0.0
        
        recent = list(self.success_history)[-window:]
        return sum(recent) / len(recent)
    
    def is_stagnant(self) -> bool:
        """
        Check if learning has stagnated.
        
        Returns True if:
        - No improvement in last N episodes
        - Success rate trend is flat or declining
        """
        if len(self.success_history) < self.window_size:
            return False
        
        # Check 1: No improvement for too long
        if self.stagnation_episodes > self.window_size:
            return True
        
        # Check 2: Declining trend
        recent_rate = self._calculate_recent_success_rate(self.window_size)
        older_rate = self._calculate_recent_success_rate(self.window_size * 2)
        
        if older_rate > 0 and (recent_rate - older_rate) / older_rate < -self.threshold:
            return True
        
        # Check 3: Flat trend (no meaningful improvement)
        if older_rate > 0 and abs(recent_rate - older_rate) / older_rate < self.threshold:
            if self.stagnation_episodes > self.window_size // 2:
                return True
        
        return False
    
    def get_stagnation_severity(self) -> float:
        """
        Calculate stagnation severity (0.0 to 1.0).
        
        0.0 = No stagnation
        1.0 = Severe stagnation
        """
        if not self.is_stagnant():
            return 0.0
        
        # Severity based on duration and trend
        duration_factor = min(1.0, self.stagnation_episodes / (self.window_size * 2))
        
        recent_rate = self._calculate_recent_success_rate(self.window_size)
        trend_factor = 1.0 - min(1.0, recent_rate / max(0.01, self.best_success_rate))
        
        severity = 0.6 * duration_factor + 0.4 * trend_factor
        
        return min(1.0, severity)
    
    def recommend_strategy_switch(self) -> Optional[str]:
        """
        Recommend a new strategy based on performance history.
        
        Returns suggested strategy name or None if no switch needed.
        """
        if not self.is_stagnant():
            return None
        
        if not self.strategy_performance:
            return None
        
        # Find best performing strategy historically
        best_strategy = None
        best_avg_quality = 0.0
        
        for strategy, qualities in self.strategy_performance.items():
            if strategy == self.current_strategy:
                continue  # Don't recommend current strategy
            
            avg_quality = sum(qualities) / len(qualities)
            if avg_quality > best_avg_quality:
                best_avg_quality = avg_quality
                best_strategy = strategy
        
        # Only switch if alternative is significantly better
        if best_strategy and best_avg_quality > 0.7:
            return best_strategy
        
        return None
    
    def get_exploration_boost(self) -> float:
        """
        Calculate exploration boost factor.
        
        Returns multiplier for exploration vs exploitation.
        1.0 = Normal balance
        2.0+ = Increase exploration
        """
        severity = self.get_stagnation_severity()
        
        if severity == 0:
            return 1.0
        
        # Boost exploration proportionally to stagnation severity
        boost = 1.0 + (severity * 2.0)  # Range: 1.0 to 3.0
        
        return boost
    
    def reset(self):
        """Reset detector after strategy switch."""
        self.stagnation_episodes = 0
        self.strategy_switch_count += 1
        
        # Keep history but mark reset point
        self.success_history.clear()
        self.quality_history.clear()
    
    def get_diagnostics(self) -> Dict:
        """Get detailed stagnation diagnostics."""
        return {
            "is_stagnant": self.is_stagnant(),
            "severity": self.get_stagnation_severity(),
            "stagnation_episodes": self.stagnation_episodes,
            "best_success_rate": self.best_success_rate,
            "current_success_rate": self._calculate_recent_success_rate(),
            "strategy_switches": self.strategy_switch_count,
            "current_strategy": self.current_strategy,
            "recommended_switch": self.recommend_strategy_switch(),
            "exploration_boost": self.get_exploration_boost()
        }


class AdaptiveStrategySelector:
    """
    Automatically switches strategies when stagnation detected.
    
    Integrates with StagnationDetector to implement forced exploration.
    """
    
    def __init__(self, available_strategies: List[str]):
        """
        Initialize strategy selector.
        
        Args:
            available_strategies: List of strategy names to choose from
        """
        self.available_strategies = available_strategies
        self.detector = StagnationDetector(window_size=20, threshold=0.02)
        
        # Strategy rotation
        self.strategy_index = 0
        self.episodes_per_strategy = 0
        self.max_episodes_per_strategy = 50
    
    def select_strategy(self, episode: int, success: bool, quality: float,
                       current_strategy: str) -> str:
        """
        Select next strategy based on stagnation detection.
        
        Args:
            episode: Current episode number
            success: Whether last episode succeeded
            quality: Quality score of last episode
            current_strategy: Currently used strategy
            
        Returns:
            Selected strategy for next episode
        """
        # Record performance
        self.detector.record_episode(episode, success, quality, current_strategy)
        self.episodes_per_strategy += 1
        
        # Check for stagnation
        if self.detector.is_stagnant():
            severity = self.detector.get_stagnation_severity()
            
            # Get recommended switch
            recommended = self.detector.recommend_strategy_switch()
            
            if recommended:
                print(f"[Stagnation Detected] Severity: {severity:.2f}, "
                      f"Switching from {current_strategy} to {recommended}")
                self.detector.reset()
                self.episodes_per_strategy = 0
                return recommended
            
            # If no recommendation, force rotation
            if severity > 0.5 or self.episodes_per_strategy >= self.max_episodes_per_strategy:
                next_strategy = self._rotate_strategy(current_strategy)
                print(f"[Forced Exploration] Rotating from {current_strategy} to {next_strategy}")
                self.detector.reset()
                self.episodes_per_strategy = 0
                return next_strategy
        
        return current_strategy
    
    def _rotate_strategy(self, current: str) -> str:
        """Rotate to next strategy in list."""
        if current in self.available_strategies:
            idx = self.available_strategies.index(current)
            next_idx = (idx + 1) % len(self.available_strategies)
        else:
            next_idx = self.strategy_index % len(self.available_strategies)
        
        self.strategy_index = next_idx
        return self.available_strategies[next_idx]
    
    def get_exploration_parameters(self) -> Dict:
        """Get parameters for exploration-exploitation balance."""
        boost = self.detector.get_exploration_boost()
        
        return {
            "exploration_boost": boost,
            "temperature": 0.5 * boost,  # For softmax selection
            "epsilon": min(0.3, 0.1 * boost),  # For epsilon-greedy
            "should_explore": self.detector.is_stagnant()
        }


# Integration example for ReverseEngineeringEvolver
def integrate_stagnation_detection(evolver, episode: int, success: bool, 
                                   quality: float, current_strategy: str) -> str:
    """
    Integrate stagnation detection into evolver.
    
    Usage in create_variant:
        next_strategy = integrate_stagnation_detection(
            self, episode, last_success, last_quality, current_strategy
        )
    """
    # Initialize detector if not exists
    if not hasattr(evolver, 'stagnation_detector'):
        evolver.stagnation_detector = StagnationDetector(window_size=20)
        evolver.strategy_selector = AdaptiveStrategySelector([
            "polynomial_fit", "piecewise_infer", "linear_fit",
            "rule_extraction", "pattern_generalize"
        ])
    
    # Select next strategy
    next_strategy = evolver.strategy_selector.select_strategy(
        episode, success, quality, current_strategy
    )
    
    return next_strategy
