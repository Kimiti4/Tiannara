"""
Information-Theoretic Pruner for Mutation Selection.

Implements ECM Layer 4: Information-Theoretic Pruner to reduce
performance degradation during long-running evolution.

Key components:
1. Surrogate model for mutation scoring (predicts yield without execution)
2. UCB-based operator selection (balances exploration/exploitation)
3. Early pruning for low-yield branches
4. Cache for repeated computations

This addresses the 4.41x performance degradation found in load testing.
"""

import math
import time
import json
import os
from typing import Dict, List, Any, Optional, Tuple
from collections import defaultdict
import hashlib


class MutationSurrogateModel:
    """
    Lightweight surrogate model that predicts mutation quality.
    
    Instead of executing every mutation, we predict its likely
    success rate based on historical patterns. This allows early
    pruning of low-yield mutations.
    """
    
    def __init__(self, learning_rate: float = 0.1):
        """
        Initialize surrogate model.
        
        Args:
            learning_rate: How quickly model adapts to new data
        """
        self.learning_rate = learning_rate
        
        # Track operator performance by context
        # Key: (task_type, operator_name) -> List[quality_scores]
        self.operator_history: Dict[Tuple[str, str], List[float]] = defaultdict(list)
        
        # Global operator statistics
        # Key: operator_name -> {mean, variance, count}
        self.operator_stats: Dict[str, Dict[str, float]] = {}
        
        # Context similarity cache
        self.context_cache: Dict[str, float] = {}
    
    def predict_quality(self, task_type: str, operator_name: str, 
                       context_features: Dict[str, Any]) -> float:
        """
        Predict quality of a mutation before execution.
        
        Args:
            task_type: Type of task (e.g., "sorting", "arithmetic")
            operator_name: Mutation operator name
            context_features: Features describing current context
            
        Returns:
            Predicted quality score [0, 1]
        """
        key = (task_type, operator_name)
        
        if key not in self.operator_history or len(self.operator_history[key]) < 3:
            # Not enough data, return neutral prediction
            return 0.5
        
        # Calculate weighted average of recent performance
        recent_scores = self.operator_history[key][-20:]  # Last 20 uses
        
        # Weight recent scores more heavily
        weights = [math.exp(-0.1 * i) for i in range(len(recent_scores))]
        weights.reverse()  # Most recent gets highest weight
        
        weighted_sum = sum(s * w for s, w in zip(recent_scores, weights))
        weight_total = sum(weights)
        
        predicted_quality = weighted_sum / weight_total if weight_total > 0 else 0.5
        
        return max(0.0, min(1.0, predicted_quality))
    
    def update(self, task_type: str, operator_name: str, actual_quality: float):
        """
        Update model with actual mutation outcome.
        
        Args:
            task_type: Type of task
            operator_name: Mutation operator used
            actual_quality: Actual quality achieved [0, 1]
        """
        key = (task_type, operator_name)
        self.operator_history[key].append(actual_quality)
        
        # Keep only last 100 observations per operator
        if len(self.operator_history[key]) > 100:
            self.operator_history[key] = self.operator_history[key][-100:]
        
        # Update global statistics
        self._update_operator_stats(operator_name, actual_quality)
    
    def _update_operator_stats(self, operator_name: str, quality: float):
        """Update global operator statistics."""
        if operator_name not in self.operator_stats:
            self.operator_stats[operator_name] = {
                "mean": quality,
                "variance": 0.0,
                "count": 1
            }
        else:
            stats = self.operator_stats[operator_name]
            old_mean = stats["mean"]
            stats["count"] += 1
            
            # Online mean update
            stats["mean"] = old_mean + (quality - old_mean) / stats["count"]
            
            # Online variance update (Welford's algorithm)
            stats["variance"] = stats["variance"] + (quality - old_mean) * (quality - stats["mean"])
    
    def get_operator_confidence(self, operator_name: str) -> float:
        """
        Get confidence in operator prediction (based on sample size).
        
        Args:
            operator_name: Operator to check
            
        Returns:
            Confidence score [0, 1]
        """
        if operator_name not in self.operator_stats:
            return 0.0
        
        count = self.operator_stats[operator_name]["count"]
        
        # Confidence increases with sample size (logarithmic)
        confidence = math.log(1 + count) / math.log(101)  # Max at 100 samples
        
        return min(1.0, confidence)
    
    def prune_low_yield_operators(self, task_type: str, operators: List[str],
                                  threshold: float = 0.3) -> List[str]:
        """
        Filter out operators predicted to have low yield.
        
        Args:
            task_type: Current task type
            operators: List of candidate operators
            threshold: Minimum predicted quality to keep
            
        Returns:
            Filtered list of promising operators
        """
        promising = []
        
        for op in operators:
            predicted = self.predict_quality(task_type, op, {})
            
            # Also consider uncertainty (UCB-style)
            confidence = self.get_operator_confidence(op)
            uncertainty_bonus = (1.0 - confidence) * 0.2  # Bonus for uncertain ops
            
            adjusted_score = predicted + uncertainty_bonus
            
            if adjusted_score >= threshold:
                promising.append(op)
        
        # Always keep at least one operator
        if not promising and operators:
            return [operators[0]]
        
        return promising


class UCBOperatorSelector:
    """
    Upper Confidence Bound (UCB) operator selection.
    
    Balances exploration (trying new operators) vs exploitation
    (using known good operators) using UCB1 algorithm.
    """
    
    def __init__(self, exploration_weight: float = 2.0):
        """
        Initialize UCB selector.
        
        Args:
            exploration_weight: Controls exploration vs exploitation trade-off
        """
        self.exploration_weight = exploration_weight
        
        # Operator usage counts
        self.operator_counts: Dict[str, int] = defaultdict(int)
        
        # Operator total rewards
        self.operator_rewards: Dict[str, float] = defaultdict(float)
        
        # Total selections
        self.total_selections = 0
    
    def select_operator(self, available_operators: List[str]) -> str:
        """
        Select operator using UCB1 algorithm.
        
        Args:
            available_operators: List of operators to choose from
            
        Returns:
            Selected operator name
        """
        # If any operator hasn't been tried, try it first
        for op in available_operators:
            if self.operator_counts[op] == 0:
                return op
        
        # Calculate UCB scores
        ucb_scores = {}
        
        for op in available_operators:
            # Exploitation term: average reward
            avg_reward = self.operator_rewards[op] / self.operator_counts[op]
            
            # Exploration term: uncertainty bonus
            exploration_bonus = math.sqrt(
                (self.exploration_weight * math.log(self.total_selections))
                / self.operator_counts[op]
            )
            
            ucb_scores[op] = avg_reward + exploration_bonus
        
        # Select operator with highest UCB score
        selected = max(ucb_scores, key=ucb_scores.get)
        
        return selected
    
    def update(self, operator: str, reward: float):
        """
        Update operator statistics after execution.
        
        Args:
            operator: Operator that was used
            reward: Reward received [0, 1]
        """
        self.operator_counts[operator] += 1
        self.operator_rewards[operator] += reward
        self.total_selections += 1
    
    def reset(self):
        """Reset all statistics."""
        self.operator_counts.clear()
        self.operator_rewards.clear()
        self.total_selections = 0


class ComputeCache:
    """
    Cache for expensive computations to avoid redundant work.
    
    Caches results of deterministic operations like:
    - Task feature extraction
    - Similarity calculations
    - Pattern matching
    """
    
    def __init__(self, max_size: int = 1000):
        """
        Initialize compute cache.
        
        Args:
            max_size: Maximum number of cached items
        """
        self.max_size = max_size
        self.cache: Dict[str, Any] = {}
        self.access_order: List[str] = []
        
        # Statistics
        self.hits = 0
        self.misses = 0
    
    def get(self, key: str) -> Optional[Any]:
        """
        Get cached result.
        
        Args:
            key: Cache key
            
        Returns:
            Cached value or None
        """
        if key in self.cache:
            self.hits += 1
            
            # Update access order (move to end)
            if key in self.access_order:
                self.access_order.remove(key)
            self.access_order.append(key)
            
            return self.cache[key]
        
        self.misses += 1
        return None
    
    def put(self, key: str, value: Any):
        """
        Store result in cache.
        
        Args:
            key: Cache key
            value: Value to cache
        """
        # Evict oldest if cache is full
        if len(self.cache) >= self.max_size and self.access_order:
            oldest_key = self.access_order.pop(0)
            del self.cache[oldest_key]
        
        self.cache[key] = value
        self.access_order.append(key)
    
    def compute_key(self, *args, **kwargs) -> str:
        """
        Generate cache key from arguments.
        
        Args:
            *args: Positional arguments
            **kwargs: Keyword arguments
            
        Returns:
            Hash string for cache key
        """
        key_data = str(args) + str(sorted(kwargs.items()))
        return hashlib.sha256(key_data.encode()).hexdigest()[:16]
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get cache statistics."""
        total = self.hits + self.misses
        return {
            "size": len(self.cache),
            "hits": self.hits,
            "misses": self.misses,
            "hit_rate": self.hits / total if total > 0 else 0,
            "max_size": self.max_size
        }
    
    def clear(self):
        """Clear all cached data."""
        self.cache.clear()
        self.access_order.clear()
        self.hits = 0
        self.misses = 0


class InformationTheoreticPruner:
    """
    Main pruner combining surrogate model, UCB selection, and caching.
    
    Implements ECM Layer 4: Information-Theoretic Pruner to efficiently
    navigate the mutation space without exhaustive evaluation.
    """
    
    def __init__(
        self,
        prune_threshold: float = 0.3,
        exploration_weight: float = 2.0,
        cache_size: int = 1000
    ):
        """
        Initialize pruner.
        
        Args:
            prune_threshold: Minimum predicted quality to evaluate mutation
            exploration_weight: UCB exploration vs exploitation balance
            cache_size: Maximum cache entries
        """
        self.prune_threshold = prune_threshold
        
        # Components
        self.surrogate_model = MutationSurrogateModel()
        self.ucb_selector = UCBOperatorSelector(exploration_weight)
        self.compute_cache = ComputeCache(cache_size)
        
        # Statistics
        self.total_mutations_evaluated = 0
        self.total_mutations_pruned = 0
        self.pruning_savings = 0.0  # Time saved by pruning
    
    def cleanup(self, max_operator_stats: int = 50):
        """
        Prune internal state to prevent unbounded growth.
        
        Args:
            max_operator_stats: Maximum number of operator stats to retain
        """
        # Trim operator_stats to most frequently used operators
        if len(self.surrogate_model.operator_stats) > max_operator_stats:
            # Sort by count (most used first)
            sorted_operators = sorted(
                self.surrogate_model.operator_stats.items(),
                key=lambda x: x[1]["count"],
                reverse=True
            )
            # Keep only top N
            self.surrogate_model.operator_stats = dict(sorted_operators[:max_operator_stats])
        
        # Clear compute cache periodically
        if len(self.compute_cache.cache) > self.compute_cache.max_size * 0.8:
            self.compute_cache.clear()
        
        # Reset UCB selector counts
        if len(self.ucb_selector.operator_counts) > max_operator_stats:
            sorted_ucb = sorted(
                self.ucb_selector.operator_counts.items(),
                key=lambda x: x[1],
                reverse=True
            )
            self.ucb_selector.operator_counts = defaultdict(int, sorted_ucb[:max_operator_stats])
    
    def should_evaluate_mutation(
        self,
        task_type: str,
        operator_name: str,
        context: Dict[str, Any] = None
    ) -> bool:
        """
        Decide whether to evaluate a mutation or prune it.
        
        Args:
            task_type: Type of task
            operator_name: Mutation operator
            context: Additional context features
            
        Returns:
            True if mutation should be evaluated, False if pruned
        """
        if context is None:
            context = {}
        
        # Check cache first
        cache_key = self.compute_cache.compute_key("prune_decision", task_type, operator_name, context)
        cached_decision = self.compute_cache.get(cache_key)
        if cached_decision is not None:
            return cached_decision
        
        # Use surrogate model to predict quality
        predicted_quality = self.surrogate_model.predict_quality(
            task_type, operator_name, context
        )
        
        # Add UCB exploration bonus
        confidence = self.surrogate_model.get_operator_confidence(operator_name)
        uncertainty_bonus = (1.0 - confidence) * 0.2
        
        adjusted_score = predicted_quality + uncertainty_bonus
        
        # Decide based on threshold
        should_evaluate = adjusted_score >= self.prune_threshold
        
        # Cache decision
        self.compute_cache.put(cache_key, should_evaluate)
        
        return should_evaluate
    
    def record_mutation_outcome(
        self,
        task_type: str,
        operator_name: str,
        actual_quality: float,
        execution_time: float = 0.0
    ):
        """
        Record actual mutation outcome for learning.
        
        Args:
            task_type: Type of task
            operator_name: Mutation operator used
            actual_quality: Quality achieved [0, 1]
            execution_time: Time taken to evaluate
        """
        # Update surrogate model
        self.surrogate_model.update(task_type, operator_name, actual_quality)
        
        # Update UCB selector
        self.ucb_selector.update(operator_name, actual_quality)
        
        # Track statistics
        self.total_mutations_evaluated += 1
    
    def prune_and_select(
        self,
        task_type: str,
        available_operators: List[str],
        context: Dict[str, Any] = None
    ) -> Optional[str]:
        """
        Prune low-yield operators and select best candidate.
        
        Args:
            task_type: Type of task
            available_operators: List of candidate operators
            context: Additional context
            
        Returns:
            Selected operator or None if all pruned
        """
        if context is None:
            context = {}
        
        # Prune low-yield operators
        promising_operators = self.surrogate_model.prune_low_yield_operators(
            task_type, available_operators, self.prune_threshold
        )
        
        pruned_count = len(available_operators) - len(promising_operators)
        self.total_mutations_pruned += pruned_count
        
        if not promising_operators:
            return None
        
        # Select from promising operators using UCB
        selected = self.ucb_selector.select_operator(promising_operators)
        
        return selected
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get comprehensive pruner statistics."""
        return {
            "total_evaluated": self.total_mutations_evaluated,
            "total_pruned": self.total_mutations_pruned,
            "pruning_rate": (
                self.total_mutations_pruned /
                (self.total_mutations_evaluated + self.total_mutations_pruned)
                if (self.total_mutations_evaluated + self.total_mutations_pruned) > 0
                else 0
            ),
            "surrogate_model_operators": len(self.surrogate_model.operator_stats),
            "ucb_total_selections": self.ucb_selector.total_selections,
            "cache_stats": self.compute_cache.get_statistics()
        }
    
    def reset(self):
        """Reset all components."""
        self.surrogate_model = MutationSurrogateModel()
        self.ucb_selector = UCBOperatorSelector()
        self.compute_cache.clear()
        self.total_mutations_evaluated = 0
        self.total_mutations_pruned = 0
    
    def save_checkpoint(self, checkpoint_dir: str = "checkpoints", episode: int = 0) -> str:
        """
        Save pruner state to disk for session persistence.
        
        Args:
            checkpoint_dir: Directory to save checkpoints
            episode: Current episode number (for filename)
            
        Returns:
            Path to saved checkpoint file
        """
        os.makedirs(checkpoint_dir, exist_ok=True)
        
        checkpoint_file = os.path.join(checkpoint_dir, f"pruner_ep{episode}.json")
        
        # Serialize surrogate model data
        operator_history_serializable = {}
        for key, values in self.surrogate_model.operator_history.items():
            # Convert tuple keys to strings
            key_str = f"{key[0]}|||{key[1]}"
            operator_history_serializable[key_str] = values
        
        checkpoint_data = {
            "metadata": {
                "episode": episode,
                "timestamp": time.time(),
                "prune_threshold": self.prune_threshold,
                "exploration_weight": self.ucb_selector.exploration_weight
            },
            "statistics": {
                "total_mutations_evaluated": self.total_mutations_evaluated,
                "total_mutations_pruned": self.total_mutations_pruned
            },
            "surrogate_model": {
                "operator_history": operator_history_serializable,
                "operator_stats": self.surrogate_model.operator_stats
            },
            "ucb_selector": {
                "operator_counts": dict(self.ucb_selector.operator_counts),
                "operator_rewards": dict(self.ucb_selector.operator_rewards),
                "total_selections": self.ucb_selector.total_selections
            },
            "cache_size": len(self.compute_cache.cache)
        }
        
        with open(checkpoint_file, 'w') as f:
            json.dump(checkpoint_data, f, indent=2)
        
        return checkpoint_file
    
    def load_checkpoint(self, checkpoint_file: str) -> bool:
        """
        Load pruner state from disk.
        
        Args:
            checkpoint_file: Path to checkpoint file
            
        Returns:
            True if loaded successfully, False otherwise
        """
        if not os.path.exists(checkpoint_file):
            print(f"Warning: Checkpoint file not found: {checkpoint_file}")
            return False
        
        try:
            with open(checkpoint_file, 'r') as f:
                checkpoint_data = json.load(f)
            
            # Restore statistics
            stats = checkpoint_data.get("statistics", {})
            self.total_mutations_evaluated = stats.get("total_mutations_evaluated", 0)
            self.total_mutations_pruned = stats.get("total_mutations_pruned", 0)
            
            # Restore surrogate model
            surrogate_data = checkpoint_data.get("surrogate_model", {})
            
            # Restore operator history (convert string keys back to tuples)
            operator_history_raw = surrogate_data.get("operator_history", {})
            self.surrogate_model.operator_history.clear()
            for key_str, values in operator_history_raw.items():
                parts = key_str.split("|||")
                if len(parts) == 2:
                    key_tuple = (parts[0], parts[1])
                    self.surrogate_model.operator_history[key_tuple] = values
            
            # Restore operator stats
            self.surrogate_model.operator_stats = surrogate_data.get("operator_stats", {})
            
            # Restore UCB selector
            ucb_data = checkpoint_data.get("ucb_selector", {})
            self.ucb_selector.operator_counts = defaultdict(int, ucb_data.get("operator_counts", {}))
            self.ucb_selector.operator_rewards = defaultdict(float, ucb_data.get("operator_rewards", {}))
            self.ucb_selector.total_selections = ucb_data.get("total_selections", 0)
            
            print(f"Loaded pruner state from checkpoint")
            print(f"  - Operator history entries: {len(self.surrogate_model.operator_history)}")
            print(f"  - Total selections: {self.ucb_selector.total_selections}")
            
            return True
            
        except Exception as e:
            print(f"Error loading checkpoint: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    def get_latest_checkpoint(self, checkpoint_dir: str = "checkpoints") -> Optional[str]:
        """
        Find the most recent checkpoint file.
        
        Args:
            checkpoint_dir: Directory containing checkpoints
            
        Returns:
            Path to latest checkpoint, or None if no checkpoints exist
        """
        if not os.path.exists(checkpoint_dir):
            return None
        
        checkpoint_files = [
            f for f in os.listdir(checkpoint_dir)
            if f.startswith("pruner_ep") and f.endswith(".json")
        ]
        
        if not checkpoint_files:
            return None
        
        # Sort by episode number
        def extract_episode(filename):
            try:
                return int(filename.replace("pruner_ep", "").replace(".json", ""))
            except ValueError:
                return 0
        
        checkpoint_files.sort(key=extract_episode, reverse=True)
        
        return os.path.join(checkpoint_dir, checkpoint_files[0])
