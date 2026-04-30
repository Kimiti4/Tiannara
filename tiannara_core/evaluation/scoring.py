"""
Weighted Intelligence Scoring - Combines metrics into final score.

Applies configurable weights to different metric dimensions
to produce a unified intelligence score (0.0-1.0).
"""


class Scorer:
    """Computes weighted intelligence score from multiple metrics."""

    def __init__(self, weights: dict = None):
        """
        Initialize scorer with configurable weights.
        
        Args:
            weights: Dictionary of metric weights (will be normalized)
                    Default weights optimized for general learning scenarios
        """
        if weights is None:
            self.weights = {
                "correctness": 0.35,
                "efficiency": 0.15,
                "stability": 0.20,
                "novelty": 0.15,
                "error_penalty": 0.15,
            }
        else:
            # Normalize weights to sum to 1.0
            total = sum(weights.values())
            self.weights = {k: v / total for k, v in weights.items()}

    def compute(self, metrics: dict) -> float:
        """
        Compute final intelligence score from metric bundle.
        
        Args:
            metrics: Dictionary containing:
                - correctness: Success rate (0.0-1.0)
                - runtime: Execution time in seconds
                - error: Error rate (0.0-1.0)
                - stability: Consistency score (0.0-1.0)
                - novelty: Novelty score (typically 0.0-1.0+)
                
        Returns:
            Final score clamped to [0.0, 1.0]
        """
        score = 0.0

        # Correctness contribution (higher is better)
        score += self.weights["correctness"] * metrics.get("correctness", 0.0)

        # Efficiency contribution (lower runtime is better)
        runtime = metrics.get("runtime", 1.0)
        efficiency = 1.0 / (1.0 + runtime)
        score += self.weights["efficiency"] * efficiency

        # Stability contribution (higher is better)
        score += self.weights["stability"] * metrics.get("stability", 0.0)

        # Novelty contribution (higher is better for exploration)
        score += self.weights["novelty"] * metrics.get("novelty", 0.0)

        # Error penalty (higher error rate reduces score)
        score -= self.weights["error_penalty"] * metrics.get("error", 0.0)

        # Clamp to valid range
        return max(0.0, min(1.0, score))

    def get_weight_breakdown(self) -> dict:
        """Get current weight configuration."""
        return self.weights.copy()

    def update_weights(self, new_weights: dict):
        """
        Update scoring weights.
        
        Args:
            new_weights: New weight dictionary (will be normalized)
        """
        total = sum(new_weights.values())
        self.weights = {k: v / total for k, v in new_weights.items()}
